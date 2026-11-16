-- DRAFT ONLY — DO NOT APPLY TO PRODUCTION.
-- Atomic DigiArz exact-decimal rollout candidate.
-- Prerequisite: migration history reconciliation, full PostgreSQL 17 CI success,
-- fresh production preflight, backup/rollback plan, and explicit release approval.
-- Base-asset quantity/price precision becomes 18 places; USDT settlement remains 8.
-- A 5-second lock timeout intentionally aborts instead of waiting behind live traffic.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';

DO $preflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.orders
    WHERE amount IS NULL OR amount <= 0 OR amount > 1000000
       OR scale(amount) > 18
       OR (price IS NOT NULL AND
           (price <= 0 OR price >= 10000000000000000::numeric OR scale(price) > 18))
       OR filled_amount IS NULL OR filled_amount < 0
       OR abs(filled_amount) >= 10000000000000000::numeric OR scale(filled_amount) > 18
       OR remaining_amount IS NULL OR remaining_amount < 0
       OR abs(remaining_amount) >= 10000000000000000::numeric OR scale(remaining_amount) > 18
  ) THEN
    RAISE EXCEPTION 'orders contains values outside numeric(34,18) contract';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.trades
    WHERE amount IS NULL OR amount <= 0 OR scale(amount) > 18
       OR abs(amount) >= 10000000000000000::numeric
       OR price IS NULL OR price <= 0 OR scale(price) > 18
       OR price >= 10000000000000000::numeric
  ) THEN
    RAISE EXCEPTION 'trades contains values outside numeric(34,18) contract';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.asset_balances
    WHERE balance IS NULL OR balance < 0 OR scale(balance) > 18
       OR abs(balance) >= 100000000000000000000::numeric
  ) THEN
    RAISE EXCEPTION 'asset_balances contains values outside numeric(38,18) contract';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.order_reservations
    WHERE reserved_amount IS NULL OR reserved_amount < 0 OR scale(reserved_amount) > 18
       OR abs(reserved_amount) >= 100000000000000000000::numeric
       OR released_amount IS NULL OR released_amount < 0 OR scale(released_amount) > 18
       OR abs(released_amount) >= 100000000000000000000::numeric
       OR consumed_amount IS NULL OR consumed_amount < 0 OR scale(consumed_amount) > 18
       OR abs(consumed_amount) >= 100000000000000000000::numeric
  ) THEN
    RAISE EXCEPTION 'order_reservations contains values outside numeric(38,18) contract';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.conditional_orders
    WHERE amount IS NULL OR amount <= 0 OR amount > 1000000 OR scale(amount) > 18
       OR trigger_price IS NULL OR trigger_price <= 0
       OR trigger_price >= 10000000000000000::numeric OR scale(trigger_price) > 18
       OR (limit_price IS NOT NULL AND
           (limit_price <= 0 OR limit_price >= 10000000000000000::numeric OR scale(limit_price) > 18))
       OR (executed_price IS NOT NULL AND
           (executed_price <= 0 OR executed_price >= 10000000000000000::numeric OR scale(executed_price) > 18))
  ) THEN
    RAISE EXCEPTION 'conditional_orders contains values outside numeric(34,18) contract';
  END IF;
END
$preflight$;

ALTER TABLE public.orders
  ALTER COLUMN amount TYPE numeric(34,18) USING amount::numeric(34,18),
  ALTER COLUMN price TYPE numeric(34,18) USING price::numeric(34,18),
  ALTER COLUMN filled_amount TYPE numeric(34,18) USING filled_amount::numeric(34,18),
  ALTER COLUMN remaining_amount TYPE numeric(34,18) USING remaining_amount::numeric(34,18);

ALTER TABLE public.trades
  ALTER COLUMN amount TYPE numeric(34,18) USING amount::numeric(34,18),
  ALTER COLUMN price TYPE numeric(34,18) USING price::numeric(34,18);

ALTER TABLE public.asset_balances
  ALTER COLUMN balance TYPE numeric(38,18) USING balance::numeric(38,18);

ALTER TABLE public.order_reservations
  ALTER COLUMN reserved_amount TYPE numeric(38,18) USING reserved_amount::numeric(38,18),
  ALTER COLUMN released_amount TYPE numeric(38,18) USING released_amount::numeric(38,18),
  ALTER COLUMN consumed_amount TYPE numeric(38,18) USING consumed_amount::numeric(38,18);

ALTER TABLE public.conditional_orders
  ALTER COLUMN amount TYPE numeric(34,18) USING amount::numeric(34,18),
  ALTER COLUMN trigger_price TYPE numeric(34,18) USING trigger_price::numeric(34,18),
  ALTER COLUMN limit_price TYPE numeric(34,18) USING limit_price::numeric(34,18),
  ALTER COLUMN executed_price TYPE numeric(34,18) USING executed_price::numeric(34,18);

-- DRAFT ONLY — DO NOT APPLY TO PRODUCTION.
-- Candidate public entry-point validation/settlement updates for exact-decimal phase.
-- Prerequisite: coordinated 18-place typmods and reviewed process_limit_orders
-- candidate. Rehearse all worker chains, ownership/auth grants, active-account
-- checks, pair checks, and reservation lifecycle before approval.
-- Quote settlement remains 8 decimals; reject zero-rounded USDT notional.
-- CREATE OR REPLACE preserves existing grants, but verify exact grants in rehearsal.

CREATE OR REPLACE FUNCTION public.execute_demo_trade(p_symbol text, p_side text, p_amount numeric, p_price numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_uid uuid;
    v_symbol text;
    v_base text;
    v_side text;
    v_price numeric;
    v_balance numeric;
    v_asset_balance numeric;
    v_reserved numeric := 0;
    v_available numeric := 0;
    v_gross numeric;
    v_total numeric;
    v_fee numeric;
    v_fee_rate numeric;
    v_order_id uuid;
BEGIN
    v_uid := auth.uid();

    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF NOT public.current_account_is_active() THEN
        RAISE EXCEPTION 'Account is inactive';
    END IF;

    v_symbol := upper(trim(p_symbol));
    v_side := lower(trim(p_side));

    IF v_symbol IS NULL
       OR v_symbol !~ '^[A-Z0-9]{2,15}USDT$' THEN
        RAISE EXCEPTION 'Unsupported trading pair';
    END IF;

    v_base := left(v_symbol, length(v_symbol) - 4);

    IF v_side IS NULL OR v_side NOT IN ('buy', 'sell')
       OR v_base = 'USDT' THEN
        RAISE EXCEPTION 'Invalid trade parameters';
    END IF;

    IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 1000000
       OR pg_catalog.scale(p_amount) > 18 THEN
        RAISE EXCEPTION 'Invalid amount';
    END IF;

    PERFORM 1
    FROM public.demo_trading_pairs AS dp
    WHERE dp.pair_symbol = v_symbol
      AND dp.quote_asset = 'USDT'
      AND dp.is_enabled IS TRUE
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Trading pair is not enabled';
    END IF;

    SELECT mp.price
    INTO v_price
    FROM public.market_prices AS mp
    WHERE mp.symbol = v_symbol
      AND mp.updated_at >= now() - interval '1 minute'
    FOR SHARE;

    IF NOT FOUND OR v_price IS NULL OR v_price <= 0
       OR v_price >= 10000000000000000::numeric
       OR pg_catalog.scale(v_price) > 18 THEN
        RAISE EXCEPTION 'Market price unavailable, outdated, or outside supported precision';
    END IF;

    v_fee_rate := public.get_demo_trading_fee_rate('USDT', 'taker');
    v_gross := round(p_amount * v_price, 8);
    IF v_gross <= 0 THEN
        RAISE EXCEPTION 'Trade notional rounds to zero USDT';
    END IF;
    v_fee := round(v_gross * v_fee_rate, 8);

    INSERT INTO public.wallets (user_id)
    VALUES (v_uid)
    ON CONFLICT (user_id) DO NOTHING;

    SELECT balance_usdt
    INTO v_balance
    FROM public.wallets
    WHERE user_id = v_uid
    FOR UPDATE;

    IF v_balance IS NULL THEN
        v_balance := 0;
    END IF;

    IF v_side = 'buy' THEN
        SELECT COALESCE(
            SUM(r.reserved_amount - r.released_amount - r.consumed_amount),
            0
        )
        INTO v_reserved
        FROM public.order_reservations AS r
        WHERE r.user_id = v_uid
          AND r.asset = 'USDT'
          AND r.status = 'reserved';

        v_available := v_balance - v_reserved;
        v_total := v_gross + v_fee;
        IF v_total > 9999999999999999.99999999::numeric THEN
            RAISE EXCEPTION 'Buy settlement exceeds numeric(24,8) USDT capacity';
        END IF;

        IF v_available < v_total THEN
            RAISE EXCEPTION 'Insufficient available USDT balance';
        END IF;

        UPDATE public.wallets
        SET balance_usdt = balance_usdt - v_total
        WHERE user_id = v_uid;

        INSERT INTO public.asset_balances (
            user_id, asset, balance, updated_at
        )
        VALUES (v_uid, v_base, p_amount, now())
        ON CONFLICT (user_id, asset)
        DO UPDATE SET
            balance = public.asset_balances.balance + EXCLUDED.balance,
            updated_at = now();
    ELSE
        INSERT INTO public.asset_balances (user_id, asset, balance)
        VALUES (v_uid, v_base, 0)
        ON CONFLICT (user_id, asset) DO NOTHING;

        SELECT balance
        INTO v_asset_balance
        FROM public.asset_balances
        WHERE user_id = v_uid
          AND asset = v_base
        FOR UPDATE;

        SELECT COALESCE(
            SUM(r.reserved_amount - r.released_amount - r.consumed_amount),
            0
        )
        INTO v_reserved
        FROM public.order_reservations AS r
        WHERE r.user_id = v_uid
          AND r.asset = v_base
          AND r.status = 'reserved';

        v_available := COALESCE(v_asset_balance, 0) - v_reserved;

        IF v_available < p_amount THEN
            RAISE EXCEPTION 'Insufficient available asset balance';
        END IF;

        v_total := v_gross - v_fee;
        IF v_total <= 0 OR v_total > 9999999999999999.99999999::numeric THEN
            RAISE EXCEPTION 'Sell settlement is outside numeric(24,8) USDT capacity';
        END IF;

        UPDATE public.asset_balances
        SET balance = balance - p_amount,
            updated_at = now()
        WHERE user_id = v_uid
          AND asset = v_base;

        UPDATE public.wallets
        SET balance_usdt = balance_usdt + v_total
        WHERE user_id = v_uid;
    END IF;

    INSERT INTO public.orders (
        user_id, symbol, side, order_type, amount, price, status,
        filled_amount, remaining_amount
    )
    VALUES (
        v_uid, v_symbol, v_side, 'market', p_amount, v_price, 'filled',
        p_amount, 0
    )
    RETURNING id INTO v_order_id;

    INSERT INTO public.trades (
        order_id, user_id, symbol, side, amount, price
    )
    VALUES (
        v_order_id, v_uid, v_symbol, v_side, p_amount, v_price
    );

    INSERT INTO public.transactions (
        user_id, currency, amount, transaction_type, description
    )
    VALUES (
        v_uid, 'USDT', v_total, v_side,
        'DigiArz demo trade: ' || v_symbol
    );

    RETURN jsonb_build_object(
        'success', true,
        'order_id', v_order_id,
        'symbol', v_symbol,
        'side', v_side,
        'amount', p_amount,
        'price', v_price,
        'fee', v_fee,
        'total', v_total,
        'currency', 'USDT'
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.place_limit_order(p_symbol text, p_side text, p_amount numeric, p_limit_price numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_uid uuid;
    v_symbol text;
    v_side text;
    v_base_asset text;
    v_asset text;
    v_wallet_balance numeric := 0;
    v_asset_balance numeric := 0;
    v_reserved_balance numeric := 0;
    v_required_amount numeric := 0;
    v_order_id uuid;
    v_fee_rate numeric;
BEGIN
    v_uid := auth.uid();

    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF NOT public.current_account_is_active() THEN
        RAISE EXCEPTION 'Account is inactive';
    END IF;

    v_symbol := upper(btrim(p_symbol));
    v_side := lower(btrim(p_side));

    IF v_symbol IS NULL
       OR v_symbol !~ '^[A-Z0-9]{2,15}USDT$' THEN
        RAISE EXCEPTION 'Invalid trading symbol';
    END IF;

    IF v_side IS NULL OR v_side NOT IN ('buy', 'sell') THEN
        RAISE EXCEPTION 'Order side must be buy or sell';
    END IF;

    IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 1000000
           OR pg_catalog.scale(p_amount) > 18 THEN
        RAISE EXCEPTION 'Invalid order amount';
    END IF;

    IF p_limit_price IS NULL OR p_limit_price <= 0
           OR p_limit_price >= 10000000000000000::numeric
           OR pg_catalog.scale(p_limit_price) > 18 THEN
        RAISE EXCEPTION 'Invalid limit price';
    END IF;

    v_base_asset := left(v_symbol, length(v_symbol) - 4);

    IF v_base_asset = '' OR v_base_asset = 'USDT' THEN
        RAISE EXCEPTION 'Invalid base asset';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.demo_trading_pairs AS p
        WHERE p.pair_symbol = v_symbol
          AND p.quote_asset = 'USDT'
          AND p.is_enabled IS TRUE
    ) THEN
        RAISE EXCEPTION 'Trading pair is not enabled';
    END IF;

    SELECT w.balance_usdt
    INTO v_wallet_balance
    FROM public.wallets AS w
    WHERE w.user_id = v_uid
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User wallet not found';
    END IF;

    IF round(p_amount * p_limit_price, 8) <= 0 THEN
        RAISE EXCEPTION 'Limit order notional rounds to zero USDT';
    END IF;

    v_fee_rate := public.get_demo_trading_fee_rate('USDT', 'maker');
    IF v_side = 'buy' THEN
        v_asset := 'USDT';
        v_required_amount := round(p_amount * p_limit_price, 8)
            + round(round(p_amount * p_limit_price, 8) * v_fee_rate, 8)
            + 0.0000001::numeric;
        IF v_required_amount > 9999999999999999.99999999::numeric THEN
            RAISE EXCEPTION 'Buy reservation exceeds numeric(24,8) USDT capacity';
        END IF;
        IF v_required_amount <= 0 THEN
            RAISE EXCEPTION 'Buy order notional rounds to zero USDT';
        END IF;

        SELECT COALESCE(
            SUM(GREATEST(
                r.reserved_amount - r.consumed_amount - r.released_amount,
                0
            )),
            0
        )
        INTO v_reserved_balance
        FROM public.order_reservations AS r
        WHERE r.user_id = v_uid
          AND r.asset = v_asset
          AND r.status = 'reserved';

        IF v_wallet_balance - v_reserved_balance < v_required_amount THEN
            RAISE EXCEPTION 'Insufficient available USDT balance';
        END IF;
    ELSE
        v_asset := v_base_asset;

        SELECT COALESCE(ab.balance, 0)
        INTO v_asset_balance
        FROM public.asset_balances AS ab
        WHERE ab.user_id = v_uid
          AND ab.asset = v_asset
        FOR UPDATE;

        IF NOT FOUND THEN
            v_asset_balance := 0;
        END IF;

        SELECT COALESCE(
            SUM(GREATEST(
                r.reserved_amount - r.consumed_amount - r.released_amount,
                0
            )),
            0
        )
        INTO v_reserved_balance
        FROM public.order_reservations AS r
        WHERE r.user_id = v_uid
          AND r.asset = v_asset
          AND r.status = 'reserved';

        IF v_asset_balance - v_reserved_balance < p_amount THEN
            RAISE EXCEPTION 'Insufficient available asset balance';
        END IF;

        v_required_amount := p_amount;
    END IF;

    INSERT INTO public.orders (
        user_id, symbol, side, order_type, amount, price, status,
        filled_amount, remaining_amount
    )
    VALUES (
        v_uid, v_symbol, v_side, 'limit', p_amount, p_limit_price,
        'pending', 0, p_amount
    )
    RETURNING id INTO v_order_id;

    INSERT INTO public.order_reservations (
        order_id, user_id, asset, reserved_amount,
        released_amount, consumed_amount, status
    )
    VALUES (
        v_order_id, v_uid, v_asset, v_required_amount,
        0, 0, 'reserved'
    );

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Limit order placed successfully',
        'order_id', v_order_id,
        'symbol', v_symbol,
        'side', v_side,
        'order_type', 'limit',
        'amount', p_amount,
        'limit_price', p_limit_price,
        'reserved_asset', v_asset,
        'reserved_amount', v_required_amount,
        'fee_rate', v_fee_rate,
        'status', 'pending'
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.place_stop_limit_order(
  p_symbol text,
  p_side text,
  p_amount numeric,
  p_stop_price numeric,
  p_limit_price numeric
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_symbol text := upper(btrim(p_symbol));
  v_side text := lower(btrim(p_side));
  v_base text;
  v_wallet numeric := 0;
  v_asset_balance numeric := 0;
  v_reserved numeric := 0;
  v_required numeric := 0;
  v_fee_rate numeric := 0;
  v_reserve_asset text;
  v_order_id uuid;
  v_conditional_id uuid;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  IF NOT public.current_account_is_active() THEN RAISE EXCEPTION 'Account is inactive'; END IF;
  IF v_symbol IS NULL OR v_symbol !~ '^[A-Z0-9]{2,15}USDT$' THEN
    RAISE EXCEPTION 'Invalid trading symbol';
  END IF;
  IF v_side IS NULL OR v_side NOT IN ('buy','sell') THEN
    RAISE EXCEPTION 'Order side must be buy or sell';
  END IF;
  IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 1000000
     OR pg_catalog.scale(p_amount) > 18 THEN
    RAISE EXCEPTION 'Invalid order amount';
  END IF;
  IF p_stop_price IS NULL OR p_stop_price <= 0
     OR p_limit_price IS NULL OR p_limit_price <= 0
     OR p_stop_price >= 10000000000000000::numeric
     OR p_limit_price >= 10000000000000000::numeric
     OR pg_catalog.scale(p_stop_price) > 18
     OR pg_catalog.scale(p_limit_price) > 18 THEN
    RAISE EXCEPTION 'Stop and limit prices must be positive';
  END IF;
  IF (v_side='buy' AND p_limit_price < p_stop_price)
     OR (v_side='sell' AND p_limit_price > p_stop_price) THEN
    RAISE EXCEPTION 'Invalid stop-limit price relationship';
  END IF;

  IF round(p_amount * p_limit_price, 8) <= 0 THEN
    RAISE EXCEPTION 'Stop-Limit order notional rounds to zero USDT';
  END IF;

  v_base := left(v_symbol,length(v_symbol)-4);
  IF v_base IS NULL OR v_base='' OR v_base='USDT' THEN
    RAISE EXCEPTION 'Invalid base asset';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.demo_trading_pairs p
    WHERE p.pair_symbol=v_symbol AND p.quote_asset='USDT' AND p.is_enabled IS TRUE
  ) THEN RAISE EXCEPTION 'Trading pair is not enabled'; END IF;

  SELECT w.balance_usdt INTO v_wallet
  FROM public.wallets w WHERE w.user_id=v_uid FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'User wallet not found'; END IF;

  v_fee_rate := public.get_demo_trading_fee_rate('USDT','maker');
  IF v_side='buy' THEN
    v_reserve_asset := 'USDT';
    v_required := round(p_amount*p_limit_price,8)
      + round(round(p_amount*p_limit_price,8)*v_fee_rate,8)
      + 0.0000001::numeric;
    IF v_required > 9999999999999999.99999999::numeric THEN
      RAISE EXCEPTION 'Stop-Limit buy reservation exceeds numeric(24,8) USDT capacity';
    END IF;
    IF v_required <= 0 THEN
      RAISE EXCEPTION 'Stop-Limit buy notional rounds to zero USDT';
    END IF;
    SELECT COALESCE(sum(greatest(r.reserved_amount-r.consumed_amount-r.released_amount,0)),0)
      INTO v_reserved
    FROM public.order_reservations r
    WHERE r.user_id=v_uid AND r.asset='USDT' AND r.status='reserved';
    IF v_wallet-v_reserved < v_required THEN
      RAISE EXCEPTION 'Insufficient available USDT balance';
    END IF;
  ELSE
    v_reserve_asset := v_base;
    SELECT COALESCE(ab.balance,0) INTO v_asset_balance
    FROM public.asset_balances ab
    WHERE ab.user_id=v_uid AND ab.asset=v_base FOR UPDATE;
    IF NOT FOUND THEN v_asset_balance:=0; END IF;
    SELECT COALESCE(sum(greatest(r.reserved_amount-r.consumed_amount-r.released_amount,0)),0)
      INTO v_reserved
    FROM public.order_reservations r
    WHERE r.user_id=v_uid AND r.asset=v_base AND r.status='reserved';
    v_required := p_amount;
    IF v_asset_balance-v_reserved < v_required THEN
      RAISE EXCEPTION 'Insufficient available asset balance';
    END IF;
  END IF;

  INSERT INTO public.orders(
    user_id,symbol,side,order_type,amount,price,status,filled_amount,remaining_amount
  ) VALUES(v_uid,v_symbol,v_side,'conditional',p_amount,p_limit_price,'pending',0,p_amount)
  RETURNING id INTO v_order_id;

  INSERT INTO public.order_reservations(
    order_id,user_id,asset,reserved_amount,released_amount,consumed_amount,status
  ) VALUES(v_order_id,v_uid,v_reserve_asset,v_required,0,0,'reserved');

  INSERT INTO public.conditional_orders(
    order_id,user_id,symbol,side,order_kind,trigger_price,limit_price,amount
  ) VALUES(v_order_id,v_uid,v_symbol,v_side,'stop_limit',p_stop_price,p_limit_price,p_amount)
  RETURNING id INTO v_conditional_id;

  RETURN jsonb_build_object(
    'success',true,'conditional_order_id',v_conditional_id,'order_id',v_order_id,
    'symbol',v_symbol,'side',v_side,'order_kind','stop_limit',
    'stop_price',p_stop_price,'limit_price',p_limit_price,'amount',p_amount,
    'reserved_asset',v_reserve_asset,'reserved_amount',v_required,'status','pending'
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.place_conditional_exit_order(p_symbol text, p_order_kind text, p_amount numeric, p_trigger_price numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_symbol text := upper(btrim(p_symbol));
  v_kind text := lower(btrim(p_order_kind));
  v_base text;
  v_wallet numeric;
  v_balance numeric;
  v_reserved numeric := 0;
  v_order_id uuid;
  v_conditional_id uuid;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  IF NOT public.current_account_is_active() THEN RAISE EXCEPTION 'Account is inactive'; END IF;
  IF v_symbol IS NULL OR v_symbol !~ '^[A-Z0-9]{2,15}USDT$' THEN
    RAISE EXCEPTION 'Invalid trading symbol';
  END IF;
  IF v_kind NOT IN ('take_profit','stop_loss') THEN RAISE EXCEPTION 'Invalid conditional order kind'; END IF;
  IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 1000000
     OR pg_catalog.scale(p_amount) > 18 THEN
    RAISE EXCEPTION 'Invalid order amount';
  END IF;
  IF p_trigger_price IS NULL OR p_trigger_price <= 0
     OR p_trigger_price >= 10000000000000000::numeric
     OR pg_catalog.scale(p_trigger_price) > 18 THEN
    RAISE EXCEPTION 'Invalid trigger price';
  END IF;
  IF round(p_amount * p_trigger_price, 8) <= 0 THEN
    RAISE EXCEPTION 'Conditional exit notional rounds to zero USDT';
  END IF;
  v_base := left(v_symbol,length(v_symbol)-4);
  IF v_base IS NULL OR v_base='' OR v_base='USDT' THEN RAISE EXCEPTION 'Invalid base asset'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.demo_trading_pairs p
    WHERE p.pair_symbol=v_symbol AND p.quote_asset='USDT' AND p.is_enabled IS TRUE
  ) THEN RAISE EXCEPTION 'Trading pair is not enabled'; END IF;

  SELECT w.balance_usdt INTO v_wallet
  FROM public.wallets w WHERE w.user_id=v_uid FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'User wallet not found'; END IF;

  SELECT ab.balance INTO v_balance
  FROM public.asset_balances ab
  WHERE ab.user_id=v_uid AND ab.asset=v_base FOR UPDATE;
  IF NOT FOUND THEN v_balance:=0; END IF;

  SELECT COALESCE(sum(greatest(r.reserved_amount-r.consumed_amount-r.released_amount,0)),0)
  INTO v_reserved
  FROM public.order_reservations r
  WHERE r.user_id=v_uid AND r.asset=v_base AND r.status='reserved';

  IF v_balance-v_reserved < p_amount THEN
    RAISE EXCEPTION 'Insufficient available asset balance';
  END IF;

  INSERT INTO public.orders(
    user_id,symbol,side,order_type,amount,price,status,filled_amount,remaining_amount
  ) VALUES(v_uid,v_symbol,'sell','conditional',p_amount,p_trigger_price,'pending',0,p_amount)
  RETURNING id INTO v_order_id;

  INSERT INTO public.order_reservations(
    order_id,user_id,asset,reserved_amount,released_amount,consumed_amount,status
  ) VALUES(v_order_id,v_uid,v_base,p_amount,0,0,'reserved');

  INSERT INTO public.conditional_orders(
    order_id,user_id,symbol,side,order_kind,trigger_price,amount
  ) VALUES(v_order_id,v_uid,v_symbol,'sell',v_kind,p_trigger_price,p_amount)
  RETURNING id INTO v_conditional_id;

  RETURN jsonb_build_object(
    'success',true,'conditional_order_id',v_conditional_id,'order_id',v_order_id,
    'symbol',v_symbol,'side','sell','order_kind',v_kind,'trigger_price',p_trigger_price,
    'amount',p_amount,'reserved_asset',v_base,'reserved_amount',p_amount,'status','pending'
  );
END;
$function$
;


-- DRAFT ONLY — DO NOT APPLY TO PRODUCTION.
-- Requires coordinated 18-place typmod migration for orders/trades/asset_balances
-- and isolated end-to-end tests of placement, reservations, cancellation,
-- Stop-Limit child synchronization, and conditional exits before approval.
-- Preserves the live worker's advisory lock, SKIP LOCKED, account/pair/price
-- checks, reservation lifecycle, and transaction model. Lock order is
-- order row -> reservation row -> wallet row, matching cancellation's
-- order row -> reservation row sequence.
-- Adds 18-place base fills, 8-place USDT settlement, and blocks zero-gross fills.
-- CREATE OR REPLACE preserves existing function grants; still verify grants
-- and worker callers during release rehearsal.

CREATE OR REPLACE FUNCTION public.process_limit_orders()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_order RECORD;
    v_reservation RECORD;
    v_market_price numeric;
    v_qty numeric;
    v_gross numeric;
    v_fee numeric;
    v_fee_rate numeric;
    v_total numeric;
    v_net numeric;
    v_remaining numeric;
    v_new_filled numeric;
    v_new_remaining numeric;
    v_consumed numeric;
    v_released numeric;
    v_target_remaining_reserve numeric;
    v_base_asset text;
    v_processed integer := 0;
    v_partial integer := 0;
    v_completed integer := 0;
    v_skipped integer := 0;
    v_rows integer;
BEGIN
    IF NOT pg_catalog.pg_try_advisory_xact_lock(739201126) THEN
        RETURN jsonb_build_object(
            'success', true,
            'message', 'Another execution cycle is running',
            'processed', 0
        );
    END IF;

    FOR v_order IN
        SELECT
            o.id,
            o.user_id,
            o.symbol,
            o.side,
            o.amount,
            o.price,
            o.filled_amount,
            o.remaining_amount
        FROM public.orders AS o
        WHERE o.order_type = 'limit'
          AND o.status IN ('pending', 'partially_filled')
          AND o.remaining_amount > 0
          AND EXISTS (SELECT 1 FROM public.profiles AS p WHERE p.id = o.user_id AND p.is_active IS TRUE)
        ORDER BY o.created_at ASC
        FOR UPDATE SKIP LOCKED
    LOOP
        IF v_order.symbol IS NULL
           OR v_order.symbol !~ '^[A-Z0-9]{2,15}USDT$'
           OR v_order.side IS NULL
           OR v_order.side NOT IN ('buy', 'sell')
           OR v_order.amount IS NULL
           OR v_order.amount <= 0
           OR v_order.amount > 1000000
           OR pg_catalog.scale(v_order.amount) > 18
           OR v_order.filled_amount IS NULL
           OR v_order.filled_amount < 0
           OR v_order.filled_amount > v_order.amount
           OR pg_catalog.scale(v_order.filled_amount) > 18
           OR v_order.price IS NULL
           OR v_order.price <= 0
           OR v_order.price >= 10000000000000000::numeric
           OR pg_catalog.scale(v_order.price) > 18
           OR v_order.remaining_amount IS NULL
           OR v_order.remaining_amount <= 0
           OR pg_catalog.scale(v_order.remaining_amount) > 18 THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        v_base_asset := left(v_order.symbol, length(v_order.symbol) - 4);

        IF v_base_asset = '' OR v_base_asset = 'USDT' THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        IF NOT EXISTS (
            SELECT 1
            FROM public.demo_trading_pairs AS p
            WHERE p.pair_symbol = v_order.symbol
              AND p.quote_asset = 'USDT'
              AND p.is_enabled IS TRUE
        ) THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        SELECT mp.price
        INTO v_market_price
        FROM public.market_prices AS mp
        WHERE mp.symbol = v_order.symbol
          AND mp.updated_at >= now() - interval '1 minute';

        IF NOT FOUND OR v_market_price IS NULL OR v_market_price <= 0
           OR v_market_price >= 10000000000000000::numeric
           OR pg_catalog.scale(v_market_price) > 18 THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        IF v_order.side = 'buy' AND v_market_price > v_order.price THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        IF v_order.side = 'sell' AND v_market_price < v_order.price THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        SELECT
            r.id,
            r.user_id,
            r.asset,
            r.reserved_amount,
            r.consumed_amount,
            r.released_amount,
            r.status
        INTO v_reservation
        FROM public.order_reservations AS r
        WHERE r.order_id = v_order.id
        FOR UPDATE;

        IF NOT FOUND
           OR v_reservation.user_id <> v_order.user_id
           OR v_reservation.status <> 'reserved'
           OR v_reservation.reserved_amount <= 0
           OR v_reservation.consumed_amount < 0
           OR v_reservation.released_amount < 0
           OR v_reservation.consumed_amount + v_reservation.released_amount
                > v_reservation.reserved_amount THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        -- Lock order here is order row -> reservation row -> wallet row.
        -- cancel_limit_order locks order row -> reservation row, so the
        -- shared prefix prevents worker/cancel lock-order inversion.
        PERFORM 1
        FROM public.wallets AS w
        WHERE w.user_id = v_order.user_id
        FOR UPDATE;

        IF NOT FOUND THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        v_remaining := v_order.remaining_amount;
        v_qty := LEAST(v_remaining, round(v_order.amount * 0.25, 18));
        IF v_qty = 0 THEN
            v_qty := LEAST(v_remaining, 0.000000000000000001::numeric);
        END IF;

        IF v_qty <= 0 OR v_qty > v_remaining THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        -- Avoid leaving a dust remainder whose quote value rounds to zero.
        -- If the remainder cannot settle independently, include it in this fill.
        IF v_remaining > v_qty
           AND round((v_remaining - v_qty) * v_market_price, 8) <= 0 THEN
            v_qty := v_remaining;
        END IF;

        v_gross := round(v_qty * v_market_price, 8);
        -- Do not create or destroy base units when the 8-place USDT ledger
        -- cannot represent a positive quote amount.
        IF v_gross <= 0 THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;
        v_fee_rate := public.get_demo_trading_fee_rate('USDT', 'maker');
        v_fee := round(v_gross * v_fee_rate, 8);

        IF v_order.side = 'buy' THEN
            v_total := v_gross + v_fee;
            v_net := 0;
            IF v_total > 9999999999999999.99999999::numeric THEN
                v_skipped := v_skipped + 1;
                CONTINUE;
            END IF;

            IF v_reservation.asset <> 'USDT'
               OR v_reservation.consumed_amount
                  + v_reservation.released_amount + v_total
                  > v_reservation.reserved_amount THEN
                v_skipped := v_skipped + 1;
                CONTINUE;
            END IF;

            UPDATE public.wallets
            SET balance_usdt = balance_usdt - v_total
            WHERE user_id = v_order.user_id
              AND balance_usdt >= v_total;

            IF NOT FOUND THEN
                v_skipped := v_skipped + 1;
                CONTINUE;
            END IF;

            INSERT INTO public.asset_balances (
                user_id, asset, balance, updated_at
            )
            VALUES (
                v_order.user_id, v_base_asset, v_qty, now()
            )
            ON CONFLICT (user_id, asset)
            DO UPDATE SET
                balance = public.asset_balances.balance + EXCLUDED.balance,
                updated_at = now();
        ELSE
            v_total := 0;
            v_net := v_gross - v_fee;
            IF v_net <= 0 OR v_net > 9999999999999999.99999999::numeric THEN
                v_skipped := v_skipped + 1;
                CONTINUE;
            END IF;

            IF v_reservation.asset <> v_base_asset
               OR v_reservation.consumed_amount
                  + v_reservation.released_amount + v_qty
                  > v_reservation.reserved_amount THEN
                v_skipped := v_skipped + 1;
                CONTINUE;
            END IF;

            UPDATE public.asset_balances
            SET balance = balance - v_qty,
                updated_at = now()
            WHERE user_id = v_order.user_id
              AND asset = v_base_asset
              AND balance >= v_qty;

            IF NOT FOUND THEN
                v_skipped := v_skipped + 1;
                CONTINUE;
            END IF;

            UPDATE public.wallets
            SET balance_usdt = balance_usdt + v_net
            WHERE user_id = v_order.user_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Wallet not found for order %', v_order.id;
            END IF;
        END IF;

        v_new_filled := v_order.filled_amount + v_qty;
        IF v_new_filled > v_order.amount THEN
            RAISE EXCEPTION 'Fill quantity exceeds order amount for order %', v_order.id;
        END IF;
        v_new_remaining := v_order.amount - v_new_filled;

        UPDATE public.orders
        SET filled_amount = v_new_filled,
            remaining_amount = v_new_remaining,
            status = CASE
                WHEN v_new_remaining <= 0 THEN 'filled'
                ELSE 'partially_filled'
            END
        WHERE id = v_order.id
          AND user_id = v_order.user_id;

        GET DIAGNOSTICS v_rows = ROW_COUNT;

        IF v_rows <> 1 THEN
            RAISE EXCEPTION 'Order update failed for order %', v_order.id;
        END IF;

        IF v_order.side = 'buy' THEN
            v_consumed := v_reservation.consumed_amount + v_total;
            v_target_remaining_reserve :=
                round(v_new_remaining * v_order.price, 8)
                + round(round(v_new_remaining * v_order.price, 8) * v_fee_rate, 8)
                + CASE WHEN v_new_remaining > 0 THEN 0.0000001::numeric ELSE 0 END;
        ELSE
            v_consumed := v_reservation.consumed_amount + v_qty;
            v_target_remaining_reserve := v_new_remaining;
        END IF;

        v_released := GREATEST(
            v_reservation.released_amount,
            v_reservation.reserved_amount
                - v_consumed
                - v_target_remaining_reserve
        );

        v_released := LEAST(
            v_released,
            v_reservation.reserved_amount - v_consumed
        );

        UPDATE public.order_reservations
        SET consumed_amount = v_consumed,
            released_amount = v_released,
            status = CASE
                WHEN v_new_remaining <= 0 THEN
                    CASE WHEN v_released > 0 THEN 'released'
                         ELSE 'consumed' END
                ELSE 'reserved'
            END,
            updated_at = now()
        WHERE id = v_reservation.id
          AND order_id = v_order.id
          AND user_id = v_order.user_id
          AND status = 'reserved';

        GET DIAGNOSTICS v_rows = ROW_COUNT;

        IF v_rows <> 1 THEN
            RAISE EXCEPTION 'Reservation update failed for order %', v_order.id;
        END IF;

        INSERT INTO public.trades (
            order_id, user_id, symbol, side, amount, price
        )
        VALUES (
            v_order.id, v_order.user_id, v_order.symbol,
            v_order.side, v_qty, v_market_price
        );

        IF v_order.side = 'buy' THEN
            INSERT INTO public.transactions (
                user_id, currency, amount, transaction_type, description
            )
            VALUES (
                v_order.user_id, 'USDT', v_total,
                'limit_buy', 'Limit buy execution: ' || v_order.symbol
            );
        ELSE
            INSERT INTO public.transactions (
                user_id, currency, amount, transaction_type, description
            )
            VALUES (
                v_order.user_id, 'USDT', v_net,
                'limit_sell', 'Limit sell execution: ' || v_order.symbol
            );
        END IF;

        v_processed := v_processed + 1;

        IF v_new_remaining <= 0 THEN
            v_completed := v_completed + 1;
        ELSE
            v_partial := v_partial + 1;
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'processed', v_processed,
        'partially_filled', v_partial,
        'completed', v_completed,
        'skipped', v_skipped,
        'fee_rate', v_fee_rate
    );
END;
$function$;

-- DRAFT ONLY — DO NOT APPLY TO PRODUCTION.
-- Candidate Stop-Limit worker with child-row locking during parent synchronization.
-- Rehearse with Limit execution and Stop-Limit cancellation before rollout.
CREATE OR REPLACE FUNCTION public.process_stop_limit_orders()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_cond record;
  v_res public.order_reservations%ROWTYPE;
  v_market_price numeric;
  v_result jsonb;
  v_child_id uuid;
  v_attempt integer;
  v_processed integer:=0;
  v_triggered integer:=0;
  v_synced integer:=0;
  v_rejected integer:=0;
  v_skipped integer:=0;
  v_rows integer;
BEGIN
  IF NOT pg_catalog.pg_try_advisory_xact_lock(739201128) THEN
    RETURN jsonb_build_object('success',true,'message','Another Stop-Limit cycle is running','processed',0);
  END IF;

  -- Keep the parent order in sync with its child Limit order after triggering.
  FOR v_cond IN
    SELECT c.id,c.order_id,c.user_id,c.execution_order_id,
           child.status AS child_status,child.filled_amount AS child_filled,
           child.remaining_amount AS child_remaining
    FROM public.conditional_orders c
    JOIN public.orders parent ON parent.id=c.order_id AND parent.user_id=c.user_id
    JOIN public.orders child ON child.id=c.execution_order_id AND child.user_id=c.user_id
    WHERE c.order_kind='stop_limit' AND c.status='triggered'
    ORDER BY c.updated_at
    FOR UPDATE OF c,parent,child SKIP LOCKED
  LOOP
    IF v_cond.child_status IN ('filled','cancelled','rejected') THEN
      UPDATE public.orders
      SET status=v_cond.child_status,
          filled_amount=v_cond.child_filled,
          remaining_amount=v_cond.child_remaining
      WHERE id=v_cond.order_id AND user_id=v_cond.user_id AND status='triggered';
      UPDATE public.conditional_orders
      SET status=v_cond.child_status,updated_at=now()
      WHERE id=v_cond.id AND status='triggered';
    ELSE
      UPDATE public.orders
      SET filled_amount=v_cond.child_filled,
          remaining_amount=v_cond.child_remaining
      WHERE id=v_cond.order_id AND user_id=v_cond.user_id AND status='triggered';
    END IF;
    v_synced:=v_synced+1;
  END LOOP;

  FOR v_cond IN
    SELECT c.id,c.order_id,c.user_id,c.symbol,c.side,c.trigger_price,c.limit_price,c.amount
    FROM public.conditional_orders c
    JOIN public.orders o ON o.id=c.order_id AND o.user_id=c.user_id
    JOIN public.profiles p ON p.id=c.user_id AND p.is_active IS TRUE
    WHERE c.order_kind='stop_limit' AND c.status='pending'
      AND o.status='pending' AND o.order_type='conditional'
    ORDER BY c.created_at
    FOR UPDATE OF c,o SKIP LOCKED
  LOOP
    IF v_cond.symbol IS NULL OR v_cond.symbol !~ '^[A-Z0-9]{2,15}USDT$'
       OR v_cond.side NOT IN ('buy','sell')
       OR v_cond.amount IS NULL OR v_cond.amount<=0
       OR v_cond.trigger_price IS NULL OR v_cond.trigger_price<=0
       OR v_cond.limit_price IS NULL OR v_cond.limit_price<=0
       OR (v_cond.side='buy' AND v_cond.limit_price<v_cond.trigger_price)
       OR (v_cond.side='sell' AND v_cond.limit_price>v_cond.trigger_price) THEN
      v_skipped:=v_skipped+1;
      CONTINUE;
    END IF;

    SELECT mp.price INTO v_market_price
    FROM public.market_prices mp
    WHERE mp.symbol=v_cond.symbol
      AND mp.updated_at>=now()-interval '1 minute'
    FOR SHARE;
    IF NOT FOUND OR v_market_price IS NULL OR v_market_price<=0 THEN
      v_skipped:=v_skipped+1;
      CONTINUE;
    END IF;

    IF (v_cond.side='buy' AND v_market_price<v_cond.trigger_price)
       OR (v_cond.side='sell' AND v_market_price>v_cond.trigger_price) THEN
      v_skipped:=v_skipped+1;
      CONTINUE;
    END IF;

    SELECT * INTO v_res
    FROM public.order_reservations r
    WHERE r.order_id=v_cond.order_id AND r.user_id=v_cond.user_id
    FOR UPDATE;
    IF NOT FOUND OR v_res.status<>'reserved'
       OR v_res.reserved_amount<=0 OR v_res.consumed_amount<0
       OR v_res.released_amount<0
       OR v_res.consumed_amount+v_res.released_amount>v_res.reserved_amount
       OR (v_cond.side='buy' AND v_res.asset<>'USDT')
       OR (v_cond.side='sell' AND v_res.asset<>left(v_cond.symbol,length(v_cond.symbol)-4)) THEN
      UPDATE public.conditional_orders
      SET attempt_count=attempt_count+1,
          last_error='Reservation validation failed; manual review required',
          updated_at=now()
      WHERE id=v_cond.id
      RETURNING attempt_count INTO v_attempt;

      IF v_attempt>=10 THEN
        -- Fail closed: stop retrying, but never release an invalid reservation.
        -- An operator must reconcile ownership and arithmetic before recovery.
        UPDATE public.orders
        SET status='rejected',remaining_amount=amount-filled_amount
        WHERE id=v_cond.order_id AND user_id=v_cond.user_id AND status='pending';

        UPDATE public.conditional_orders
        SET status='rejected',updated_at=now()
        WHERE id=v_cond.id AND status='pending';

        v_rejected:=v_rejected+1;
      ELSE
        v_skipped:=v_skipped+1;
      END IF;
      CONTINUE;
    END IF;

    BEGIN
      -- Release the trigger-stage reservation and create a fresh Limit reservation
      -- atomically. If placing the child order fails, the subtransaction restores it.
      UPDATE public.order_reservations
      SET released_amount=reserved_amount-consumed_amount,
          status='released',updated_at=now()
      WHERE id=v_res.id AND status='reserved';

      PERFORM pg_catalog.set_config('request.jwt.claim.sub',v_cond.user_id::text,true);
      PERFORM pg_catalog.set_config('request.jwt.claims',
        pg_catalog.jsonb_build_object('sub',v_cond.user_id::text,'role','authenticated')::text,true);

      v_result:=public.place_limit_order(v_cond.symbol,v_cond.side,v_cond.amount,v_cond.limit_price);
      IF COALESCE((v_result->>'success')::boolean,false) IS NOT TRUE THEN
        RAISE EXCEPTION 'Limit engine did not confirm Stop-Limit trigger';
      END IF;
      v_child_id:=(v_result->>'order_id')::uuid;
      IF v_child_id IS NULL THEN RAISE EXCEPTION 'Stop-Limit child order id missing'; END IF;

      UPDATE public.orders
      SET status='triggered',filled_amount=0,remaining_amount=amount
      WHERE id=v_cond.order_id AND user_id=v_cond.user_id AND status='pending';
      GET DIAGNOSTICS v_rows=ROW_COUNT;
      IF v_rows<>1 THEN RAISE EXCEPTION 'Stop-Limit parent order update failed'; END IF;

      UPDATE public.conditional_orders
      SET status='triggered',execution_order_id=v_child_id,
          triggered_at=now(),last_error=NULL,updated_at=now()
      WHERE id=v_cond.id AND status='pending';
      GET DIAGNOSTICS v_rows=ROW_COUNT;
      IF v_rows<>1 THEN RAISE EXCEPTION 'Stop-Limit trigger state update failed'; END IF;

      PERFORM pg_catalog.set_config('request.jwt.claim.sub','',true);
      PERFORM pg_catalog.set_config('request.jwt.claims','',true);
      v_processed:=v_processed+1;
      v_triggered:=v_triggered+1;
    EXCEPTION WHEN OTHERS THEN
      PERFORM pg_catalog.set_config('request.jwt.claim.sub','',true);
      PERFORM pg_catalog.set_config('request.jwt.claims','',true);
      UPDATE public.conditional_orders
      SET attempt_count=attempt_count+1,last_error=left(SQLERRM,500),updated_at=now()
      WHERE id=v_cond.id
      RETURNING attempt_count INTO v_attempt;

      IF v_attempt>=10 THEN
        SELECT * INTO v_res
        FROM public.order_reservations
        WHERE order_id=v_cond.order_id AND user_id=v_cond.user_id
        FOR UPDATE;
        IF FOUND AND v_res.status='reserved'
           AND v_res.consumed_amount>=0
           AND v_res.consumed_amount+v_res.released_amount<=v_res.reserved_amount THEN
          UPDATE public.order_reservations
          SET released_amount=reserved_amount-consumed_amount,
              status='released',updated_at=now()
          WHERE id=v_res.id;
        END IF;
        UPDATE public.orders
        SET status='rejected',remaining_amount=amount-filled_amount
        WHERE id=v_cond.order_id AND user_id=v_cond.user_id AND status='pending';
        UPDATE public.conditional_orders
        SET status='rejected',updated_at=now()
        WHERE id=v_cond.id AND status='pending';
        v_rejected:=v_rejected+1;
      ELSE
        v_skipped:=v_skipped+1;
      END IF;
    END;
  END LOOP;

  RETURN jsonb_build_object('success',true,'processed',v_processed,
    'triggered',v_triggered,'synced',v_synced,'rejected',v_rejected,'skipped',v_skipped);
END;
$function$;



-- Match the already-verified Production execution model explicitly.
REVOKE ALL ON FUNCTION public.execute_demo_trade(text,text,numeric,numeric) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.execute_demo_trade(text,text,numeric,numeric) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.place_limit_order(text,text,numeric,numeric) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.place_limit_order(text,text,numeric,numeric) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.place_stop_limit_order(text,text,numeric,numeric,numeric) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.place_stop_limit_order(text,text,numeric,numeric,numeric) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.place_conditional_exit_order(text,text,numeric,numeric) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.place_conditional_exit_order(text,text,numeric,numeric) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.process_limit_orders() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_limit_orders() TO service_role;
REVOKE ALL ON FUNCTION public.process_stop_limit_orders() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_stop_limit_orders() TO service_role;



DO $postflight$
DECLARE v_type text;
BEGIN
 SELECT format_type(a.atttypid,a.atttypmod) INTO v_type FROM pg_attribute a
 WHERE a.attrelid='public.orders'::regclass AND a.attname='amount' AND NOT a.attisdropped;
 IF v_type<>'numeric(34,18)' THEN RAISE EXCEPTION 'orders.amount postflight type mismatch: %',v_type; END IF;
 SELECT format_type(a.atttypid,a.atttypmod) INTO v_type FROM pg_attribute a
 WHERE a.attrelid='public.trades'::regclass AND a.attname='price' AND NOT a.attisdropped;
 IF v_type<>'numeric(34,18)' THEN RAISE EXCEPTION 'trades.price postflight type mismatch: %',v_type; END IF;
 SELECT format_type(a.atttypid,a.atttypmod) INTO v_type FROM pg_attribute a
 WHERE a.attrelid='public.asset_balances'::regclass AND a.attname='balance' AND NOT a.attisdropped;
 IF v_type<>'numeric(38,18)' THEN RAISE EXCEPTION 'asset_balances.balance postflight type mismatch: %',v_type; END IF;
 SELECT format_type(a.atttypid,a.atttypmod) INTO v_type FROM pg_attribute a
 WHERE a.attrelid='public.wallets'::regclass AND a.attname='balance_usdt' AND NOT a.attisdropped;
 IF v_type<>'numeric(24,8)' THEN RAISE EXCEPTION 'wallets.balance_usdt must remain numeric(24,8): %',v_type; END IF;
 SELECT format_type(a.atttypid,a.atttypmod) INTO v_type FROM pg_attribute a
 WHERE a.attrelid='public.transactions'::regclass AND a.attname='amount' AND NOT a.attisdropped;
 IF v_type<>'numeric(24,8)' THEN RAISE EXCEPTION 'transactions.amount must remain numeric(24,8): %',v_type; END IF;
END
$postflight$;


COMMIT;

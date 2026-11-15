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
        v_required_amount := round(p_amount * p_limit_price * (1 + v_fee_rate), 8);
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
    v_required := round(p_amount*p_limit_price*(1+v_fee_rate),8);
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

\set ON_ERROR_STOP on
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS private;
DROP TABLE IF EXISTS public.conditional_orders CASCADE;
DROP TABLE IF EXISTS public.order_reservations CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.asset_balances CASCADE;
DROP TABLE IF EXISTS public.wallets CASCADE;
DROP TABLE IF EXISTS public.demo_trading_pairs CASCADE;
DROP TABLE IF EXISTS public.demo_trading_fees CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY,
  is_active boolean NOT NULL DEFAULT true,
  deactivated_at timestamptz
);
CREATE TABLE public.wallets (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id),
  balance_usdt numeric NOT NULL DEFAULT 0
);
CREATE TABLE public.asset_balances (
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  asset text NOT NULL,
  balance numeric NOT NULL DEFAULT 0,
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY(user_id,asset)
);
CREATE TABLE public.demo_trading_pairs (
  pair_symbol text PRIMARY KEY,
  quote_asset text NOT NULL,
  is_enabled boolean NOT NULL DEFAULT true
);
CREATE TABLE public.demo_trading_fees (
  quote_asset text PRIMARY KEY,
  maker_fee_rate numeric NOT NULL,
  taker_fee_rate numeric NOT NULL,
  is_enabled boolean NOT NULL DEFAULT true
);
CREATE TABLE public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  symbol text NOT NULL,
  side text NOT NULL,
  order_type text NOT NULL,
  amount numeric NOT NULL,
  price numeric NOT NULL,
  status text NOT NULL,
  filled_amount numeric NOT NULL DEFAULT 0,
  remaining_amount numeric NOT NULL DEFAULT 0,
  execution_order_id uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.order_reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  asset text NOT NULL,
  reserved_amount numeric NOT NULL,
  released_amount numeric NOT NULL DEFAULT 0,
  consumed_amount numeric NOT NULL DEFAULT 0,
  status text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.conditional_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  symbol text NOT NULL,
  side text NOT NULL,
  order_kind text NOT NULL,
  trigger_price numeric NOT NULL,
  limit_price numeric,
  amount numeric NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  execution_order_id uuid,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid LANGUAGE sql STABLE
AS $auth_uid$
  SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$auth_uid$;

INSERT INTO public.demo_trading_pairs(pair_symbol,quote_asset,is_enabled)
VALUES ('BTCUSDT','USDT',true);
INSERT INTO public.demo_trading_fees(quote_asset,maker_fee_rate,taker_fee_rate,is_enabled)
VALUES ('USDT',0.001,0.002,true);
INSERT INTO public.profiles(id,is_active) VALUES
('11111111-1111-4111-8111-111111111111',true),
('22222222-2222-4222-8222-222222222222',true),
('33333333-3333-4333-8333-333333333333',true),
('44444444-4444-4444-8444-444444444444',true),
('55555555-5555-4555-8555-555555555555',true),
('66666666-6666-4666-8666-666666666666',true);
INSERT INTO public.wallets(user_id,balance_usdt)
SELECT id,100000 FROM public.profiles;
INSERT INTO public.asset_balances(user_id,asset,balance)
SELECT id,'BTC',100 FROM public.profiles;

-- The function definitions below are copied verbatim from the read-only
-- 2026-11-25 Production SECURITY DEFINER manifest. The tables above are
-- minimal disposable test doubles, not a Production schema migration.
CREATE OR REPLACE FUNCTION private.guard_active_account_writes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_active boolean;
begin
  select p.is_active into v_active
  from public.profiles p
  where p.id = new.user_id
  for share;

  if coalesce(v_active, false) is not true then
    raise exception 'Account is inactive; reactivate the account before trading';
  end if;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.current_account_is_active()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce((
    select p.is_active
    from public.profiles p
    where p.id = auth.uid()
  ), false);
$function$
;

CREATE OR REPLACE FUNCTION public.get_demo_trading_fee_rate(p_quote_asset text, p_liquidity_type text)
 RETURNS numeric
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_rate numeric;
BEGIN
    IF p_liquidity_type NOT IN ('maker', 'taker') THEN
        RAISE EXCEPTION 'Invalid liquidity type';
    END IF;

    SELECT CASE WHEN p_liquidity_type = 'maker'
                THEN f.maker_fee_rate ELSE f.taker_fee_rate END
      INTO v_rate
      FROM public.demo_trading_fees AS f
     WHERE f.quote_asset = upper(btrim(p_quote_asset))
       AND f.is_enabled IS TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Trading fee is not configured for quote asset %', p_quote_asset;
    END IF;

    RETURN v_rate;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.deactivate_my_account()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_cancelled integer:=0;
  v_released integer:=0;
  v_cond_cancelled integer:=0;
  v_cond_released integer:=0;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;

  UPDATE public.profiles
  SET is_active=false,deactivated_at=pg_catalog.now()
  WHERE id=v_uid AND is_active IS TRUE;

  IF NOT FOUND THEN
    IF EXISTS(SELECT 1 FROM public.profiles p WHERE p.id=v_uid AND p.is_active IS FALSE) THEN
      RETURN jsonb_build_object('success',true,'status','inactive',
        'cancelled_orders',0,'released_reservations',0);
    END IF;
    RAISE EXCEPTION 'Account profile not found';
  END IF;

  UPDATE public.order_reservations r
  SET released_amount=r.reserved_amount-r.consumed_amount,
      status=CASE WHEN r.consumed_amount>=r.reserved_amount THEN 'consumed' ELSE 'released' END,
      updated_at=pg_catalog.now()
  FROM public.orders o
  WHERE r.order_id=o.id AND r.user_id=v_uid AND o.user_id=v_uid
    AND o.order_type='limit' AND o.status IN ('pending','partially_filled')
    AND r.status='reserved' AND r.consumed_amount>=0 AND r.consumed_amount<=r.reserved_amount;
  GET DIAGNOSTICS v_released=ROW_COUNT;

  UPDATE public.orders SET status='cancelled',remaining_amount=amount-filled_amount
  WHERE user_id=v_uid AND order_type='limit' AND status IN ('pending','partially_filled');
  GET DIAGNOSTICS v_cancelled=ROW_COUNT;

  UPDATE public.order_reservations r
  SET released_amount=r.reserved_amount-r.consumed_amount,
      status=CASE WHEN r.consumed_amount>=r.reserved_amount THEN 'consumed' ELSE 'released' END,
      updated_at=pg_catalog.now()
  FROM public.orders o JOIN public.conditional_orders c ON c.order_id=o.id
  WHERE r.order_id=o.id AND r.user_id=v_uid AND o.user_id=v_uid
    AND o.order_type='conditional' AND o.status='pending' AND c.status='pending'
    AND r.status='reserved' AND r.consumed_amount>=0
    AND r.consumed_amount<=r.reserved_amount;
  GET DIAGNOSTICS v_cond_released=ROW_COUNT;

  UPDATE public.orders SET status='cancelled',remaining_amount=amount-filled_amount
  WHERE user_id=v_uid AND order_type='conditional' AND status='pending';
  GET DIAGNOSTICS v_cond_cancelled=ROW_COUNT;

  -- The child Limit orders above have already been cancelled and released.
  -- Mirror their final state into triggered Stop-Limit parent records.
  UPDATE public.orders parent
  SET status=CASE child.status WHEN 'filled' THEN 'filled'
                               WHEN 'rejected' THEN 'rejected'
                               ELSE 'cancelled' END,
      filled_amount=child.filled_amount,
      remaining_amount=child.remaining_amount
  FROM public.conditional_orders c
  JOIN public.orders child ON child.id=c.execution_order_id AND child.user_id=c.user_id
  WHERE parent.id=c.order_id AND parent.user_id=c.user_id
    AND c.user_id=v_uid AND c.order_kind='stop_limit'
    AND c.status='triggered' AND parent.status='triggered';

  UPDATE public.conditional_orders
  SET status=CASE
    WHEN EXISTS (
      SELECT 1 FROM public.orders child
      WHERE child.id=conditional_orders.execution_order_id
        AND child.status='filled'
    ) THEN 'filled'
    WHEN EXISTS (
      SELECT 1 FROM public.orders child
      WHERE child.id=conditional_orders.execution_order_id
        AND child.status='rejected'
    ) THEN 'rejected'
    ELSE 'cancelled'
  END,
  updated_at=pg_catalog.now()
  WHERE user_id=v_uid AND order_kind='stop_limit' AND status='triggered';

  UPDATE public.conditional_orders
  SET status='cancelled',updated_at=pg_catalog.now()
  WHERE user_id=v_uid AND status='pending';

  RETURN jsonb_build_object('success',true,'status','inactive',
    'cancelled_orders',v_cancelled+v_cond_cancelled,
    'released_reservations',v_released+v_cond_released);
END;
$function$
;

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

    IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 1000000 THEN
        RAISE EXCEPTION 'Invalid order amount';
    END IF;

    IF p_limit_price IS NULL OR p_limit_price <= 0 THEN
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

    v_fee_rate := public.get_demo_trading_fee_rate('USDT', 'maker');
    IF v_side = 'buy' THEN
        v_asset := 'USDT';
        v_required_amount := p_amount * p_limit_price * (1 + v_fee_rate);

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
$function$
;

CREATE OR REPLACE FUNCTION public.place_stop_limit_order(p_symbol text, p_side text, p_amount numeric, p_stop_price numeric, p_limit_price numeric)
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
  IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 1000000 THEN
    RAISE EXCEPTION 'Invalid order amount';
  END IF;
  IF p_stop_price IS NULL OR p_stop_price <= 0
     OR p_limit_price IS NULL OR p_limit_price <= 0 THEN
    RAISE EXCEPTION 'Stop and limit prices must be positive';
  END IF;
  IF (v_side='buy' AND p_limit_price < p_stop_price)
     OR (v_side='sell' AND p_limit_price > p_stop_price) THEN
    RAISE EXCEPTION 'Invalid stop-limit price relationship';
  END IF;

  v_base := left(v_symbol,length(v_symbol)-4);
  IF v_base IS NULL OR v_base='' OR v_base='USDT' THEN
    RAISE EXCEPTION 'Invalid base asset';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.demo_trading_pairs p
    WHERE p.pair_symbol=v_symbol AND p.quote_asset='USDT' AND p.is_enabled IS TRUE
  ) THEN RAISE EXCEPTION 'Trading pair is not enabled'; END IF;

  -- Match the wallet-first lock order used by the existing trading RPCs.
  SELECT w.balance_usdt INTO v_wallet
  FROM public.wallets w WHERE w.user_id=v_uid FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'User wallet not found'; END IF;

  v_fee_rate := public.get_demo_trading_fee_rate('USDT','maker');
  IF v_side='buy' THEN
    v_reserve_asset := 'USDT';
    v_required := p_amount*p_limit_price*(1+v_fee_rate);
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
$function$
;

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
  IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 1000000 THEN
    RAISE EXCEPTION 'Invalid order amount';
  END IF;
  IF p_trigger_price IS NULL OR p_trigger_price <= 0 THEN
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

CREATE TRIGGER guard_active_account_orders
BEFORE INSERT ON public.orders
FOR EACH ROW EXECUTE FUNCTION private.guard_active_account_writes();

-- Additional columns and market snapshot required by the captured Stop-Limit worker.
ALTER TABLE public.conditional_orders
  ADD COLUMN attempt_count integer NOT NULL DEFAULT 0,
  ADD COLUMN last_error text,
  ADD COLUMN triggered_at timestamptz,
  ADD COLUMN executed_at timestamptz,
  ADD COLUMN executed_price numeric;
CREATE TABLE public.market_prices (
  symbol text PRIMARY KEY,
  price numeric NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Exact Stop-Limit worker body from the read-only 2026-11-25 Production manifest.
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
    FOR UPDATE OF c,parent SKIP LOCKED
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
$function$
;

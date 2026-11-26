ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_type_valid;

ALTER TABLE public.orders ADD CONSTRAINT orders_type_valid CHECK (order_type = ANY (ARRAY['market'::text,'limit'::text,'conditional'::text]));

CREATE TABLE public.conditional_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL UNIQUE REFERENCES public.orders(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  symbol text NOT NULL CHECK (symbol ~ '^[A-Z0-9]{2,15}USDT$'),
  side text NOT NULL DEFAULT 'sell' CHECK (side = 'sell'),
  order_kind text NOT NULL CHECK (order_kind IN ('take_profit','stop_loss')),
  trigger_price numeric NOT NULL CHECK (trigger_price > 0),
  amount numeric NOT NULL CHECK (amount > 0),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','filled','cancelled','rejected')),
  execution_order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  executed_price numeric CHECK (executed_price IS NULL OR executed_price > 0),
  attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  last_error text,
  triggered_at timestamptz,
  executed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX conditional_orders_user_status_created_idx ON public.conditional_orders(user_id,status,created_at DESC);

CREATE INDEX conditional_orders_pending_created_idx ON public.conditional_orders(created_at) WHERE status='pending';

ALTER TABLE public.conditional_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY conditional_orders_select_own ON public.conditional_orders FOR SELECT TO authenticated USING ((select auth.uid()) = user_id);

GRANT SELECT ON public.conditional_orders TO authenticated;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public.conditional_orders FROM anon, authenticated;

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

CREATE OR REPLACE FUNCTION public.cancel_conditional_exit_order(p_order_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_cond public.conditional_orders%ROWTYPE;
  v_res public.order_reservations%ROWTYPE;
  v_rows integer;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  IF NOT public.current_account_is_active() THEN RAISE EXCEPTION 'Account is inactive'; END IF;

  SELECT * INTO v_cond
  FROM public.conditional_orders
  WHERE order_id=p_order_id AND user_id=v_uid
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Conditional order not found'; END IF;
  IF v_cond.status <> 'pending' THEN RAISE EXCEPTION 'Conditional order cannot be cancelled'; END IF;

  SELECT * INTO v_res
  FROM public.order_reservations
  WHERE order_id=p_order_id AND user_id=v_uid
  FOR UPDATE;
  IF NOT FOUND OR v_res.status <> 'reserved'
     OR v_res.consumed_amount < 0
     OR v_res.consumed_amount+v_res.released_amount > v_res.reserved_amount THEN
    RAISE EXCEPTION 'Valid active reservation not found';
  END IF;

  UPDATE public.order_reservations
  SET released_amount=reserved_amount-consumed_amount,
      status=CASE WHEN consumed_amount>=reserved_amount THEN 'consumed' ELSE 'released' END,
      updated_at=now()
  WHERE id=v_res.id AND status='reserved';
  GET DIAGNOSTICS v_rows=ROW_COUNT;
  IF v_rows<>1 THEN RAISE EXCEPTION 'Reservation release failed'; END IF;

  UPDATE public.orders
  SET status='cancelled',remaining_amount=amount-filled_amount
  WHERE id=p_order_id AND user_id=v_uid AND order_type='conditional'
    AND status IN ('pending','partially_filled');
  GET DIAGNOSTICS v_rows=ROW_COUNT;
  IF v_rows<>1 THEN RAISE EXCEPTION 'Order cancellation failed'; END IF;

  UPDATE public.conditional_orders
  SET status='cancelled',updated_at=now()
  WHERE id=v_cond.id AND status='pending';
  GET DIAGNOSTICS v_rows=ROW_COUNT;
  IF v_rows<>1 THEN RAISE EXCEPTION 'Conditional order cancellation failed'; END IF;

  RETURN jsonb_build_object('success',true,'status','cancelled','order_id',p_order_id,
    'released_amount',v_res.reserved_amount-v_res.consumed_amount);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.process_conditional_orders()
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
  v_execution_order_id uuid;
  v_processed integer:=0;
  v_triggered integer:=0;
  v_rejected integer:=0;
  v_skipped integer:=0;
  v_rows integer;
BEGIN
  IF NOT pg_catalog.pg_try_advisory_xact_lock(739201127) THEN
    RETURN jsonb_build_object('success',true,'message','Another conditional cycle is running','processed',0);
  END IF;

  FOR v_cond IN
    SELECT c.id,c.order_id,c.user_id,c.symbol,c.order_kind,c.trigger_price,c.amount,
           o.filled_amount,o.remaining_amount
    FROM public.conditional_orders c
    JOIN public.orders o ON o.id=c.order_id AND o.user_id=c.user_id
    JOIN public.profiles p ON p.id=c.user_id AND p.is_active IS TRUE
    WHERE c.status='pending' AND o.status='pending' AND o.order_type='conditional'
    ORDER BY c.created_at
    FOR UPDATE OF c,o SKIP LOCKED
  LOOP
    IF v_cond.symbol IS NULL OR v_cond.symbol !~ '^[A-Z0-9]{2,15}USDT$'
       OR v_cond.amount IS NULL OR v_cond.amount<=0
       OR v_cond.trigger_price IS NULL OR v_cond.trigger_price<=0 THEN
      v_skipped:=v_skipped+1; CONTINUE;
    END IF;

    SELECT mp.price INTO v_market_price
    FROM public.market_prices mp
    WHERE mp.symbol=v_cond.symbol
      AND mp.updated_at>=now()-interval '1 minute'
;
    IF NOT FOUND OR v_market_price IS NULL OR v_market_price<=0 THEN
      v_skipped:=v_skipped+1; CONTINUE;
    END IF;

    IF (v_cond.order_kind='take_profit' AND v_market_price<v_cond.trigger_price)
       OR (v_cond.order_kind='stop_loss' AND v_market_price>v_cond.trigger_price) THEN
      v_skipped:=v_skipped+1; CONTINUE;
    END IF;

    SELECT * INTO v_res
    FROM public.order_reservations r
    WHERE r.order_id=v_cond.order_id AND r.user_id=v_cond.user_id
    FOR UPDATE;
    IF NOT FOUND OR v_res.status<>'reserved'
       OR v_res.asset<>left(v_cond.symbol,length(v_cond.symbol)-4)
       OR v_res.reserved_amount<v_cond.amount
       OR v_res.consumed_amount<0
       OR v_res.consumed_amount+v_res.released_amount>v_res.reserved_amount THEN
      UPDATE public.conditional_orders
      SET attempt_count=attempt_count+1,last_error='Reservation validation failed',updated_at=now()
      WHERE id=v_cond.id;
      v_skipped:=v_skipped+1; CONTINUE;
    END IF;

    BEGIN
      -- Release this order's own reservation inside the same transaction before
      -- calling the market engine; if execution fails, this subtransaction rolls back.
      UPDATE public.order_reservations
      SET released_amount=reserved_amount-consumed_amount,
          status='released',updated_at=now()
      WHERE id=v_res.id AND status='reserved';

      PERFORM pg_catalog.set_config('request.jwt.claim.sub',v_cond.user_id::text,true);
      PERFORM pg_catalog.set_config('request.jwt.claims',
        pg_catalog.jsonb_build_object('sub',v_cond.user_id::text,'role','authenticated')::text,true);

      v_result:=public.execute_demo_trade(v_cond.symbol,'sell',v_cond.amount,v_market_price);
      IF COALESCE((v_result->>'success')::boolean,false) IS NOT TRUE THEN
        RAISE EXCEPTION 'Market engine did not confirm conditional execution';
      END IF;
      v_execution_order_id:=(v_result->>'order_id')::uuid;

      UPDATE public.orders
      SET status='filled',filled_amount=amount,remaining_amount=0
      WHERE id=v_cond.order_id AND user_id=v_cond.user_id AND status='pending';
      GET DIAGNOSTICS v_rows=ROW_COUNT;
      IF v_rows<>1 THEN RAISE EXCEPTION 'Conditional parent order update failed'; END IF;

      UPDATE public.conditional_orders
      SET status='filled',execution_order_id=v_execution_order_id,
          executed_price=(v_result->>'price')::numeric,
          triggered_at=now(),executed_at=now(),last_error=NULL,updated_at=now()
      WHERE id=v_cond.id AND status='pending';
      GET DIAGNOSTICS v_rows=ROW_COUNT;
      IF v_rows<>1 THEN RAISE EXCEPTION 'Conditional order completion update failed'; END IF;

      PERFORM pg_catalog.set_config('request.jwt.claim.sub','',true);
      PERFORM pg_catalog.set_config('request.jwt.claims','',true);
      v_processed:=v_processed+1;
      v_triggered:=v_triggered+1;
    EXCEPTION WHEN OTHERS THEN
      PERFORM pg_catalog.set_config('request.jwt.claim.sub','',true);
      PERFORM pg_catalog.set_config('request.jwt.claims','',true);
      -- The failed execution block rolled back the reservation release.
      UPDATE public.conditional_orders
      SET attempt_count=attempt_count+1,last_error=left(SQLERRM,500),updated_at=now()
      WHERE id=v_cond.id;
      SELECT * INTO v_res FROM public.order_reservations WHERE order_id=v_cond.order_id AND user_id=v_cond.user_id FOR UPDATE;
      IF FOUND AND (SELECT attempt_count FROM public.conditional_orders WHERE id=v_cond.id)>=10
         AND v_res.status='reserved'
         AND v_res.consumed_amount>=0
         AND v_res.consumed_amount+v_res.released_amount<=v_res.reserved_amount THEN
        UPDATE public.order_reservations
        SET released_amount=reserved_amount-consumed_amount,status='released',updated_at=now()
        WHERE id=v_res.id;
        UPDATE public.orders SET status='rejected',remaining_amount=amount-filled_amount
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
    'triggered',v_triggered,'rejected',v_rejected,'skipped',v_skipped);
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

  UPDATE public.conditional_orders
  SET status='cancelled',updated_at=pg_catalog.now()
  WHERE user_id=v_uid AND status='pending';

  RETURN jsonb_build_object('success',true,'status','inactive',
    'cancelled_orders',v_cancelled+v_cond_cancelled,
    'released_reservations',v_released+v_cond_released);
END;
$function$
;

REVOKE ALL ON FUNCTION public.place_conditional_exit_order(text,text,numeric,numeric) FROM PUBLIC,anon;

GRANT EXECUTE ON FUNCTION public.place_conditional_exit_order(text,text,numeric,numeric) TO authenticated;

REVOKE ALL ON FUNCTION public.cancel_conditional_exit_order(uuid) FROM PUBLIC,anon;

GRANT EXECUTE ON FUNCTION public.cancel_conditional_exit_order(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.process_conditional_orders() FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.process_conditional_orders() TO service_role;

SELECT cron.schedule('digiarz-conditional-orders','* * * * *','SELECT public.process_conditional_orders();');

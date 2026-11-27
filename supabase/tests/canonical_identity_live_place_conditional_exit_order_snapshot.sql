-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: place_conditional_exit_order(text,text,numeric,numeric)
-- PostgreSQL md5(pg_get_functiondef(...)): e4de4667d89e6663f04d92d47ac4d5cf
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
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

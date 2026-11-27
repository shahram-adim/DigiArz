-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: cancel_conditional_exit_order(uuid)
-- PostgreSQL md5(pg_get_functiondef(...)): efa4c8a200d299f76b0d2cbe2d0b49e9
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
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

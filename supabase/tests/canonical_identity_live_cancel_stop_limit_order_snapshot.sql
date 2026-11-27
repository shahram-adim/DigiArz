-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: cancel_stop_limit_order(uuid)
-- PostgreSQL md5(pg_get_functiondef(...)): 82cedc2c442b0c826a8684044aed5f8d
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.cancel_stop_limit_order(p_order_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_cond public.conditional_orders%ROWTYPE;
  v_parent public.orders%ROWTYPE;
  v_child public.orders%ROWTYPE;
  v_res public.order_reservations%ROWTYPE;
  v_cancel_result jsonb;
  v_final_status text;
  v_rows integer;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;

  SELECT * INTO v_cond
  FROM public.conditional_orders
  WHERE order_id=p_order_id AND user_id=v_uid AND order_kind='stop_limit'
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Stop-Limit order not found'; END IF;

  SELECT * INTO v_parent
  FROM public.orders
  WHERE id=p_order_id AND user_id=v_uid AND order_type='conditional'
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Parent order not found'; END IF;

  IF v_cond.status='pending' THEN
    SELECT * INTO v_res
    FROM public.order_reservations
    WHERE order_id=p_order_id AND user_id=v_uid
    FOR UPDATE;
    IF NOT FOUND OR v_res.status<>'reserved'
       OR v_res.consumed_amount<0 OR v_res.released_amount<0
       OR v_res.consumed_amount+v_res.released_amount>v_res.reserved_amount THEN
      RAISE EXCEPTION 'Valid active reservation not found';
    END IF;

    UPDATE public.order_reservations
    SET released_amount=reserved_amount-consumed_amount,
        status=CASE WHEN consumed_amount>=reserved_amount THEN 'consumed' ELSE 'released' END,
        updated_at=now()
    WHERE id=v_res.id AND status='reserved';
    GET DIAGNOSTICS v_rows=ROW_COUNT;
    IF v_rows<>1 THEN RAISE EXCEPTION 'Stop-Limit reservation release failed'; END IF;

    UPDATE public.orders
    SET status='cancelled',remaining_amount=amount-filled_amount
    WHERE id=p_order_id AND user_id=v_uid AND status='pending';
    GET DIAGNOSTICS v_rows=ROW_COUNT;
    IF v_rows<>1 THEN RAISE EXCEPTION 'Stop-Limit parent cancellation failed'; END IF;

    UPDATE public.conditional_orders
    SET status='cancelled',updated_at=now()
    WHERE id=v_cond.id AND status='pending';
    GET DIAGNOSTICS v_rows=ROW_COUNT;
    IF v_rows<>1 THEN RAISE EXCEPTION 'Stop-Limit cancellation state update failed'; END IF;

    RETURN jsonb_build_object('success',true,'status','cancelled','order_id',p_order_id,
      'released_amount',v_res.reserved_amount-v_res.consumed_amount);
  END IF;

  IF v_cond.status<>'triggered' OR v_cond.execution_order_id IS NULL THEN
    RAISE EXCEPTION 'Stop-Limit order is no longer cancellable';
  END IF;

  SELECT * INTO v_child
  FROM public.orders
  WHERE id=v_cond.execution_order_id AND user_id=v_uid AND order_type='limit'
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Triggered limit order not found'; END IF;

  IF v_child.status IN ('pending','partially_filled') THEN
    v_cancel_result:=public.cancel_limit_order(v_child.id);
    SELECT * INTO v_child FROM public.orders WHERE id=v_child.id AND user_id=v_uid;
  END IF;

  v_final_status := CASE
    WHEN v_child.status='filled' THEN 'filled'
    WHEN v_child.status='rejected' THEN 'rejected'
    ELSE 'cancelled'
  END;

  UPDATE public.orders
  SET status=v_final_status,
      filled_amount=v_child.filled_amount,
      remaining_amount=v_child.remaining_amount
  WHERE id=p_order_id AND user_id=v_uid AND status='triggered';
  GET DIAGNOSTICS v_rows=ROW_COUNT;
  IF v_rows<>1 THEN RAISE EXCEPTION 'Stop-Limit parent state update failed'; END IF;

  UPDATE public.conditional_orders
  SET status=v_final_status,updated_at=now()
  WHERE id=v_cond.id AND status='triggered';
  GET DIAGNOSTICS v_rows=ROW_COUNT;
  IF v_rows<>1 THEN RAISE EXCEPTION 'Stop-Limit state update failed'; END IF;

  RETURN jsonb_build_object('success',true,'status',v_final_status,
    'order_id',p_order_id,'execution_order_id',v_child.id,
    'filled_amount',v_child.filled_amount,'remaining_amount',v_child.remaining_amount);
END;
$function$
;

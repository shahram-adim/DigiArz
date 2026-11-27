DO $verify$
DECLARE v_parent text; v_child text; v_cond text; v_reserved numeric; v_consumed numeric;
 v_released numeric; v_res_status text;
BEGIN
 SELECT status INTO v_parent FROM public.orders
 WHERE id='79000000-0000-0000-0000-000000000019';
 SELECT status INTO v_child FROM public.orders
 WHERE id='79000000-0000-0000-0000-000000000029';
 SELECT status INTO v_cond FROM public.conditional_orders
 WHERE order_id='79000000-0000-0000-0000-000000000019';
 IF v_parent<>'cancelled' OR v_child<>'cancelled' OR v_cond<>'cancelled' THEN
  RAISE EXCEPTION 'Parent/child cancellation statuses mismatch: parent %, child %, conditional %',v_parent,v_child,v_cond;
 END IF;
 SELECT reserved_amount,consumed_amount,released_amount,status
 INTO v_reserved,v_consumed,v_released,v_res_status
 FROM public.order_reservations WHERE order_id='79000000-0000-0000-0000-000000000029';
 IF v_reserved<>10.01 OR v_consumed<>0 OR v_released<>10.01 OR v_res_status<>'released' THEN
  RAISE EXCEPTION 'Child reservation mismatch after overlapping cancellations: %, %, %, %',
   v_reserved,v_consumed,v_released,v_res_status;
 END IF;
 SELECT reserved_amount,consumed_amount,released_amount,status
 INTO v_reserved,v_consumed,v_released,v_res_status
 FROM public.order_reservations WHERE order_id='79000000-0000-0000-0000-000000000019';
 IF v_reserved<>10.01 OR v_consumed<>0 OR v_released<>10.01 OR v_res_status<>'released' THEN
  RAISE EXCEPTION 'Parent reservation mismatch after overlapping cancellations: %, %, %, %',
   v_reserved,v_consumed,v_released,v_res_status;
 END IF;
 IF EXISTS(SELECT 1 FROM public.trades WHERE user_id='79000000-0000-0000-0000-000000000009')
    OR EXISTS(SELECT 1 FROM public.transactions WHERE user_id='79000000-0000-0000-0000-000000000009') THEN
  RAISE EXCEPTION 'Cancellation race unexpectedly created financial ledger entries';
 END IF;
 IF (SELECT count(*) FROM public.orders WHERE user_id='79000000-0000-0000-0000-000000000009')<>2
    OR (SELECT count(*) FROM public.order_reservations WHERE user_id='79000000-0000-0000-0000-000000000009')<>2 THEN
  RAISE EXCEPTION 'Cancellation race created duplicate orders or reservations';
 END IF;
END
$verify$;
DROP TRIGGER digiarz_delay_parent_child_cancel ON public.order_reservations;
DROP FUNCTION public.digiarz_delay_parent_child_cancel();
SELECT 'two-session Stop-Limit parent cancellation vs child cancellation race: PASS' AS result;

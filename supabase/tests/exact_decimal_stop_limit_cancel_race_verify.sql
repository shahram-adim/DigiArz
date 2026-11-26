DO $verify$
DECLARE v_status text; v_filled numeric; v_remaining numeric;
 v_consumed numeric; v_released numeric; v_res_status text;
 v_balance numeric; v_asset numeric; v_parent_status text; v_cond_status text;
BEGIN
 SELECT status,filled_amount,remaining_amount INTO v_status,v_filled,v_remaining
 FROM public.orders WHERE id='73000000-0000-0000-0000-000000000014';
 IF v_status<>'cancelled' OR v_filled<>0.25 OR v_remaining<>0.75 THEN
   RAISE EXCEPTION 'Child-worker-first mismatch: %, %, %',v_status,v_filled,v_remaining;
 END IF;
 SELECT status,filled_amount INTO v_parent_status,v_filled FROM public.orders
 WHERE id='73000000-0000-0000-0000-000000000013';
 IF v_parent_status<>'cancelled' OR v_filled<>0.25 THEN
   RAISE EXCEPTION 'Parent did not inherit child partial fill before cancellation: %, %',v_parent_status,v_filled;
 END IF;
 SELECT status INTO v_cond_status FROM public.conditional_orders
 WHERE order_id='73000000-0000-0000-0000-000000000013';
 IF v_cond_status<>'cancelled' THEN RAISE EXCEPTION 'Conditional status mismatch: %',v_cond_status; END IF;
 IF (SELECT count(*) FROM public.trades WHERE order_id='73000000-0000-0000-0000-000000000014')<>1 THEN
   RAISE EXCEPTION 'Child-worker-first must create exactly one trade';
 END IF;
 SELECT consumed_amount,released_amount,status INTO v_consumed,v_released,v_res_status
 FROM public.order_reservations WHERE order_id='73000000-0000-0000-0000-000000000014';
 IF v_consumed<>2.5025 OR v_released<>7.5075 OR v_res_status<>'released' THEN
   RAISE EXCEPTION 'Child-worker-first reservation mismatch: %, %, %',v_consumed,v_released,v_res_status;
 END IF;
 SELECT balance_usdt INTO v_balance FROM public.wallets WHERE user_id='73000000-0000-0000-0000-000000000003';
 SELECT balance INTO v_asset FROM public.asset_balances WHERE user_id='73000000-0000-0000-0000-000000000003' AND asset='BTC';
 IF v_balance<>97.4975 OR v_asset<>0.25 THEN
   RAISE EXCEPTION 'Child-worker-first ledger mismatch: wallet %, asset %',v_balance,v_asset;
 END IF;
 IF (SELECT sum(amount) FROM public.transactions WHERE user_id='73000000-0000-0000-0000-000000000003' AND currency='USDT')<>2.5025 THEN
   RAISE EXCEPTION 'Child-worker-first USDT transaction mismatch';
 END IF;

 SELECT status,filled_amount,remaining_amount INTO v_status,v_filled,v_remaining
 FROM public.orders WHERE id='74000000-0000-0000-0000-000000000025';
 IF v_status<>'cancelled' OR v_filled<>0 OR v_remaining<>1 THEN
   RAISE EXCEPTION 'Cancel-first child mismatch: %, %, %',v_status,v_filled,v_remaining;
 END IF;
 SELECT status,filled_amount INTO v_parent_status,v_filled FROM public.orders
 WHERE id='74000000-0000-0000-0000-000000000024';
 IF v_parent_status<>'cancelled' OR v_filled<>0 THEN
   RAISE EXCEPTION 'Cancel-first parent mismatch: %, %',v_parent_status,v_filled;
 END IF;
 SELECT status INTO v_cond_status FROM public.conditional_orders
 WHERE order_id='74000000-0000-0000-0000-000000000024';
 IF v_cond_status<>'cancelled' THEN RAISE EXCEPTION 'Cancel-first conditional mismatch: %',v_cond_status; END IF;
 IF EXISTS(SELECT 1 FROM public.trades WHERE order_id='74000000-0000-0000-0000-000000000025') THEN
   RAISE EXCEPTION 'Cancel-first unexpectedly executed child';
 END IF;
 SELECT consumed_amount,released_amount,status INTO v_consumed,v_released,v_res_status
 FROM public.order_reservations WHERE order_id='74000000-0000-0000-0000-000000000025';
 IF v_consumed<>0 OR v_released<>10.01 OR v_res_status<>'released' THEN
   RAISE EXCEPTION 'Cancel-first reservation mismatch: %, %, %',v_consumed,v_released,v_res_status;
 END IF;
 SELECT balance_usdt INTO v_balance FROM public.wallets WHERE user_id='74000000-0000-0000-0000-000000000004';
 IF v_balance<>100 THEN RAISE EXCEPTION 'Cancel-first wallet changed: %',v_balance; END IF;
 IF (SELECT count(*) FROM public.trades WHERE order_id='74000000-0000-0000-0000-000000000025')<>0 THEN
   RAISE EXCEPTION 'Cancel-first child trade duplicate check failed';
 END IF;

 IF (SELECT status FROM public.orders WHERE id='77000000-0000-0000-0000-000000000033')<>'triggered'
    OR (SELECT filled_amount FROM public.orders WHERE id='77000000-0000-0000-0000-000000000033')<>0.5
    OR (SELECT remaining_amount FROM public.orders WHERE id='77000000-0000-0000-0000-000000000033')<>0.5 THEN
   RAISE EXCEPTION 'Stop-Limit parent sync did not catch up to the child second fill';
 END IF;
 IF (SELECT filled_amount FROM public.orders WHERE id='77000000-0000-0000-0000-000000000034')<>0.5
    OR (SELECT remaining_amount FROM public.orders WHERE id='77000000-0000-0000-0000-000000000034')<>0.5 THEN
   RAISE EXCEPTION 'Stop-Limit child second fill mismatch';
 END IF;
 IF (SELECT count(*) FROM public.trades WHERE order_id='77000000-0000-0000-0000-000000000034')<>2
    OR (SELECT sum(amount) FROM public.trades WHERE order_id='77000000-0000-0000-0000-000000000034')<>0.5 THEN
   RAISE EXCEPTION 'Stop-Limit child sync race duplicated or lost a trade';
 END IF;
 IF (SELECT consumed_amount FROM public.order_reservations WHERE order_id='77000000-0000-0000-0000-000000000034')<>5.005 THEN
   RAISE EXCEPTION 'Stop-Limit child sync race reservation mismatch';
 END IF;
END
$verify$;
DROP TRIGGER digiarz_delay_stop_child_trade ON public.trades;
DROP FUNCTION public.digiarz_delay_stop_child_trade();
SELECT 'two-session Stop-Limit child execution/cancellation race integration: PASS' AS result;

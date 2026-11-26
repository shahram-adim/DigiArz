DO $verify$
DECLARE v_status text; v_balance numeric; v_asset numeric; v_consumed numeric; v_released numeric; v_res_status text;
BEGIN
 IF (SELECT status FROM public.orders WHERE id='75000000-0000-0000-0000-000000000015')<>'filled'
   OR (SELECT status FROM public.conditional_orders WHERE order_id='75000000-0000-0000-0000-000000000015')<>'filled' THEN
   RAISE EXCEPTION 'Worker-first conditional parent did not complete';
 END IF;
 IF (SELECT count(*) FROM public.trades WHERE user_id='75000000-0000-0000-0000-000000000005')<>1 THEN
   RAISE EXCEPTION 'Worker-first conditional should create exactly one trade';
 END IF;
 SELECT consumed_amount,released_amount,status INTO v_consumed,v_released,v_res_status
 FROM public.order_reservations WHERE order_id='75000000-0000-0000-0000-000000000015';
 IF v_consumed<>1.000000000000000001 OR v_released<>0 OR v_res_status<>'consumed' THEN
   RAISE EXCEPTION 'Worker-first conditional reservation mismatch: %, %, %',v_consumed,v_released,v_res_status;
 END IF;
 SELECT balance_usdt INTO v_balance FROM public.wallets WHERE user_id='75000000-0000-0000-0000-000000000005';
 SELECT balance INTO v_asset FROM public.asset_balances WHERE user_id='75000000-0000-0000-0000-000000000005' AND asset='BTC';
 IF v_balance<>11.988 OR v_asset<>0 THEN
   RAISE EXCEPTION 'Worker-first conditional balances mismatch: wallet %, asset %',v_balance,v_asset;
 END IF;
 IF (SELECT sum(amount) FROM public.transactions WHERE user_id='75000000-0000-0000-0000-000000000005' AND currency='USDT')<>11.988 THEN
   RAISE EXCEPTION 'Worker-first conditional ledger mismatch';
 END IF;

 IF (SELECT status FROM public.orders WHERE id='76000000-0000-0000-0000-000000000026')<>'cancelled'
   OR (SELECT status FROM public.conditional_orders WHERE order_id='76000000-0000-0000-0000-000000000026')<>'cancelled' THEN
   RAISE EXCEPTION 'Cancel-first conditional did not remain cancelled';
 END IF;
 IF EXISTS(SELECT 1 FROM public.trades WHERE user_id='76000000-0000-0000-0000-000000000006') THEN
   RAISE EXCEPTION 'Cancel-first conditional unexpectedly created a trade';
 END IF;
 SELECT consumed_amount,released_amount,status INTO v_consumed,v_released,v_res_status
 FROM public.order_reservations WHERE order_id='76000000-0000-0000-0000-000000000026';
 IF v_consumed<>0 OR v_released<>1.000000000000000001 OR v_res_status<>'released' THEN
   RAISE EXCEPTION 'Cancel-first conditional reservation mismatch: %, %, %',v_consumed,v_released,v_res_status;
 END IF;
 SELECT balance_usdt INTO v_balance FROM public.wallets WHERE user_id='76000000-0000-0000-0000-000000000006';
 SELECT balance INTO v_asset FROM public.asset_balances WHERE user_id='76000000-0000-0000-0000-000000000006' AND asset='BTC';
 IF v_balance<>0 OR v_asset<>1.000000000000000001 THEN
   RAISE EXCEPTION 'Cancel-first conditional balances changed: wallet %, asset %',v_balance,v_asset;
 END IF;
END
$verify$;
DROP TRIGGER digiarz_delay_conditional_trade ON public.trades;
DROP FUNCTION public.digiarz_delay_conditional_trade();
SELECT 'two-session TP/SL conditional execution/cancellation race integration: PASS' AS result;

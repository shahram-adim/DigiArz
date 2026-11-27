DO $verify$
DECLARE
 v_parent_status text; v_cond_status text; v_filled numeric; v_remaining numeric;
 v_wallet numeric; v_asset numeric; v_consumed numeric; v_released numeric; v_res_status text;
BEGIN
 SELECT status,filled_amount,remaining_amount INTO v_parent_status,v_filled,v_remaining
 FROM public.orders WHERE id='78000000-0000-0000-0000-000000000018';
 IF v_parent_status<>'filled' OR v_filled<>1.000000000000000001 OR v_remaining<>0 THEN
  RAISE EXCEPTION 'Conditional parent state mismatch: %, %, %',v_parent_status,v_filled,v_remaining;
 END IF;
 SELECT status INTO v_cond_status FROM public.conditional_orders
 WHERE order_id='78000000-0000-0000-0000-000000000018';
 IF v_cond_status<>'filled' THEN RAISE EXCEPTION 'Conditional state mismatch: %',v_cond_status; END IF;
 IF (SELECT count(*) FROM public.trades WHERE user_id='78000000-0000-0000-0000-000000000008')<>1 THEN
  RAISE EXCEPTION 'Expected exactly one conditional settlement trade';
 END IF;
 SELECT balance_usdt INTO v_wallet FROM public.wallets
 WHERE user_id='78000000-0000-0000-0000-000000000008';
 SELECT balance INTO v_asset FROM public.asset_balances
 WHERE user_id='78000000-0000-0000-0000-000000000008' AND asset='BTC';
 IF v_wallet<>11.988 OR v_asset<>0.5 THEN
  RAISE EXCEPTION 'Conditional settlement balances mismatch: wallet %, BTC %',v_wallet,v_asset;
 END IF;
 SELECT consumed_amount,released_amount,status INTO v_consumed,v_released,v_res_status
 FROM public.order_reservations WHERE order_id='78000000-0000-0000-0000-000000000018';
 IF v_consumed<>1.000000000000000001 OR v_released<>0 OR v_res_status<>'consumed' THEN
  RAISE EXCEPTION 'Conditional reservation mismatch: %, %, %',v_consumed,v_released,v_res_status;
 END IF;
 IF (SELECT count(*) FROM public.orders WHERE user_id='78000000-0000-0000-0000-000000000008')<>2 THEN
  RAISE EXCEPTION 'Competing placement unexpectedly created an order';
 END IF;
 IF (SELECT count(*) FROM public.order_reservations WHERE user_id='78000000-0000-0000-0000-000000000008')<>1 THEN
  RAISE EXCEPTION 'Competing placement unexpectedly created a reservation';
 END IF;
 IF (SELECT sum(amount) FROM public.transactions WHERE user_id='78000000-0000-0000-0000-000000000008' AND currency='USDT')<>11.988 THEN
  RAISE EXCEPTION 'Conditional settlement transaction ledger mismatch';
 END IF;
END
$verify$;
DROP TRIGGER digiarz_delay_conditional_placement_trade ON public.trades;
DROP FUNCTION public.digiarz_delay_conditional_placement_trade();
SELECT 'two-session conditional worker vs same-user sell placement race: PASS' AS result;

-- TP/SL exact-decimal lifecycle integration; disposable CI DB only.
INSERT INTO public.profiles VALUES('50000000-0000-0000-0000-000000000005',true);
INSERT INTO public.demo_trading_pairs VALUES('BTCUSDT','USDT',true),('ETHUSDT','USDT',true);
INSERT INTO public.market_prices VALUES('BTCUSDT',12.000000000000000001,now()),('ETHUSDT',8.000000000000000001,now());
-- Explicit zero starting balance for deterministic settlement assertions.
INSERT INTO public.wallets(user_id,balance_usdt) VALUES('50000000-0000-0000-0000-000000000005',0);
INSERT INTO public.asset_balances(user_id,asset,balance) VALUES
 ('50000000-0000-0000-0000-000000000005','BTC',2.000000000000000002),
 ('50000000-0000-0000-0000-000000000005','ETH',3.000000000000000003);
SELECT set_config('request.jwt.claim.sub','50000000-0000-0000-0000-000000000005',false);
DO $test$
DECLARE
 v_tp jsonb; v_sl jsonb; v_wait jsonb;
 v_tp_id uuid; v_sl_id uuid; v_wait_id uuid;
 v_result jsonb;
BEGIN
 v_tp:=public.place_conditional_exit_order('BTCUSDT','take_profit',1.000000000000000001,11.000000000000000001);
 v_tp_id:=(v_tp->>'order_id')::uuid;
 v_sl:=public.place_conditional_exit_order('ETHUSDT','stop_loss',1.000000000000000001,9.000000000000000001);
 v_sl_id:=(v_sl->>'order_id')::uuid;
 v_wait:=public.place_conditional_exit_order('BTCUSDT','take_profit',0.5,15.000000000000000001);
 v_wait_id:=(v_wait->>'order_id')::uuid;
 v_result:=public.process_conditional_orders();
 IF (v_result->>'triggered')::int<>2 THEN RAISE EXCEPTION 'Expected TP and SL triggers, got %',v_result; END IF;
 IF (SELECT status FROM public.orders WHERE id=v_tp_id)<>'filled'
    OR (SELECT status FROM public.orders WHERE id=v_sl_id)<>'filled' THEN
   RAISE EXCEPTION 'TP/SL parent orders were not filled';
 END IF;
 IF (SELECT status FROM public.conditional_orders WHERE order_id=v_tp_id)<>'filled'
    OR (SELECT status FROM public.conditional_orders WHERE order_id=v_sl_id)<>'filled' THEN
   RAISE EXCEPTION 'TP/SL conditional metadata did not complete';
 END IF;
 IF (SELECT filled_amount FROM public.orders WHERE id=v_tp_id)<>1.000000000000000001::numeric
    OR (SELECT filled_amount FROM public.orders WHERE id=v_sl_id)<>1.000000000000000001::numeric THEN
   RAISE EXCEPTION 'TP/SL exact quantity precision mismatch';
 END IF;
 IF (SELECT count(*) FROM public.trades WHERE order_id=(SELECT execution_order_id FROM public.conditional_orders WHERE order_id=v_tp_id))<>1
    OR (SELECT count(*) FROM public.trades WHERE order_id=(SELECT execution_order_id FROM public.conditional_orders WHERE order_id=v_sl_id))<>1
    OR (SELECT sum(amount) FROM public.trades WHERE order_id=(SELECT execution_order_id FROM public.conditional_orders WHERE order_id=v_tp_id))<>1.000000000000000001::numeric
    OR (SELECT sum(amount) FROM public.trades WHERE order_id=(SELECT execution_order_id FROM public.conditional_orders WHERE order_id=v_sl_id))<>1.000000000000000001::numeric THEN
   RAISE EXCEPTION 'TP/SL execution trade rows or exact quantities mismatch';
 END IF;
 IF (SELECT price FROM public.trades WHERE order_id=(SELECT execution_order_id FROM public.conditional_orders WHERE order_id=v_tp_id))<>12.000000000000000001::numeric
    OR (SELECT price FROM public.trades WHERE order_id=(SELECT execution_order_id FROM public.conditional_orders WHERE order_id=v_sl_id))<>8.000000000000000001::numeric
    OR (SELECT executed_price FROM public.conditional_orders WHERE order_id=v_tp_id)<>12.000000000000000001::numeric
    OR (SELECT executed_price FROM public.conditional_orders WHERE order_id=v_sl_id)<>8.000000000000000001::numeric THEN
   RAISE EXCEPTION 'TP/SL execution price lost 18-place precision';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM public.order_reservations WHERE order_id=v_tp_id AND consumed_amount=1.000000000000000001 AND released_amount=0 AND status='consumed')
    OR NOT EXISTS(SELECT 1 FROM public.order_reservations WHERE order_id=v_sl_id AND consumed_amount=1.000000000000000001 AND released_amount=0 AND status='consumed') THEN
   RAISE EXCEPTION 'TP/SL base reservation consumption mismatch';
 END IF;
 IF (SELECT status FROM public.orders WHERE id=v_wait_id)<>'pending'
    OR NOT EXISTS(SELECT 1 FROM public.order_reservations WHERE order_id=v_wait_id AND status='reserved' AND released_amount=0) THEN
   RAISE EXCEPTION 'Non-triggered TP order should remain pending and reserved';
 END IF;
 IF (SELECT balance FROM public.asset_balances WHERE asset='BTC' AND user_id='50000000-0000-0000-0000-000000000005')<>1.000000000000000001::numeric
    OR (SELECT balance FROM public.asset_balances WHERE asset='ETH' AND user_id='50000000-0000-0000-0000-000000000005')<>2.000000000000000002::numeric THEN
   RAISE EXCEPTION 'TP/SL base asset balance delta mismatch';
 END IF;
 IF (SELECT balance_usdt FROM public.wallets WHERE user_id='50000000-0000-0000-0000-000000000005')<>19.98::numeric THEN
   RAISE EXCEPTION 'TP/SL quote settlement mismatch: %',(SELECT balance_usdt FROM public.wallets WHERE user_id='50000000-0000-0000-0000-000000000005');
 END IF;
 IF (SELECT sum(amount) FROM public.transactions WHERE user_id='50000000-0000-0000-0000-000000000005'
      AND currency='USDT' AND transaction_type='sell')<>19.98::numeric THEN
   RAISE EXCEPTION 'TP/SL USDT transaction ledger mismatch';
 END IF;
 v_result:=public.process_conditional_orders();
 IF (SELECT count(*) FROM public.trades WHERE order_id IN (
      SELECT execution_order_id FROM public.conditional_orders WHERE order_id IN (v_tp_id,v_sl_id)
    ))<>2 THEN
   RAISE EXCEPTION 'Repeated TP/SL worker cycle duplicated execution trades';
 END IF;
 IF (SELECT sum(amount) FROM public.transactions WHERE user_id='50000000-0000-0000-0000-000000000005'
      AND currency='USDT' AND transaction_type='sell')<>19.98::numeric THEN
   RAISE EXCEPTION 'Repeated TP/SL worker cycle changed USDT ledger';
 END IF;
END $test$;
SELECT 'TP/SL exact-decimal conditional exit integration: PASS' AS result;

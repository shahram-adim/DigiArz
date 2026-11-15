-- TP/SL exact-decimal lifecycle integration; disposable CI DB only.
INSERT INTO public.profiles VALUES('50000000-0000-0000-0000-000000000005',true);
INSERT INTO public.demo_trading_pairs VALUES('BTCUSDT','USDT',true),('ETHUSDT','USDT',true);
INSERT INTO public.market_prices VALUES('BTCUSDT',12,now()),('ETHUSDT',8,now());
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
 v_tp:=public.place_conditional_exit_order('BTCUSDT','take_profit',1.000000000000000001,11);
 v_tp_id:=(v_tp->>'order_id')::uuid;
 v_sl:=public.place_conditional_exit_order('ETHUSDT','stop_loss',1.000000000000000001,9);
 v_sl_id:=(v_sl->>'order_id')::uuid;
 v_wait:=public.place_conditional_exit_order('BTCUSDT','take_profit',0.5,15);
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
 IF (SELECT sum(amount) FROM public.trades t JOIN public.orders o ON o.id=t.order_id WHERE o.id=v_tp_id)<>1.000000000000000001::numeric
    OR (SELECT sum(amount) FROM public.trades t JOIN public.orders o ON o.id=t.order_id WHERE o.id=v_sl_id)<>1.000000000000000001::numeric THEN
   RAISE EXCEPTION 'TP/SL trade amount mismatch';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM public.order_reservations WHERE order_id=v_tp_id AND consumed_amount=1.000000000000000001 AND released_amount=0 AND status='consumed')
    OR NOT EXISTS(SELECT 1 FROM public.order_reservations WHERE order_id=v_sl_id AND consumed_amount=1.000000000000000001 AND released_amount=0 AND status='consumed') THEN
   RAISE EXCEPTION 'TP/SL base reservation consumption mismatch';
 END IF;
 IF (SELECT status FROM public.orders WHERE id=v_wait_id)<>'pending'
    OR NOT EXISTS(SELECT 1 FROM public.order_reservations WHERE order_id=v_wait_id AND status='reserved' AND released_amount=0) THEN
   RAISE EXCEPTION 'Non-triggered TP order should remain pending and reserved';
 END IF;
 IF (SELECT balance FROM public.asset_balances WHERE asset='BTC' AND user_id='50000000-0000-0000-0000-000000000005')<>0.500000000000000001::numeric
    OR (SELECT balance FROM public.asset_balances WHERE asset='ETH' AND user_id='50000000-0000-0000-0000-000000000005')<>2.000000000000000002::numeric THEN
   RAISE EXCEPTION 'TP/SL base asset balance delta mismatch';
 END IF;
 IF (SELECT balance_usdt FROM public.wallets WHERE user_id='50000000-0000-0000-0000-000000000005')<>19.98::numeric THEN
   RAISE EXCEPTION 'TP/SL quote settlement mismatch: %',(SELECT balance_usdt FROM public.wallets WHERE user_id='50000000-0000-0000-0000-000000000005');
 END IF;
END $test$;
SELECT 'TP/SL exact-decimal conditional exit integration: PASS' AS result;

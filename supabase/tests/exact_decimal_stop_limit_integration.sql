-- Stop-Limit parent/child lifecycle integration; disposable CI DB only.
INSERT INTO public.profiles VALUES('40000000-0000-0000-0000-000000000004',true);
INSERT INTO public.demo_trading_pairs VALUES('BTCUSDT','USDT',true);
INSERT INTO public.market_prices VALUES('BTCUSDT',10,now());
INSERT INTO public.wallets VALUES('40000000-0000-0000-0000-000000000004',1000);
SELECT set_config('request.jwt.claim.sub','40000000-0000-0000-0000-000000000004',false);
DO $test$
DECLARE v_result jsonb; v_parent uuid; v_child uuid; v_value numeric;
BEGIN
 v_result:=public.place_stop_limit_order('BTCUSDT','buy',1.000000000000000001,9.5,10.5);
 v_parent:=(v_result->>'order_id')::uuid;
 v_result:=public.process_stop_limit_orders();
 SELECT execution_order_id INTO v_child FROM public.conditional_orders WHERE order_id=v_parent;
 IF v_child IS NULL THEN RAISE EXCEPTION 'Stop-Limit did not create child Limit order'; END IF;
 IF (SELECT status FROM public.orders WHERE id=v_parent)<>'triggered' THEN RAISE EXCEPTION 'Parent did not enter triggered state'; END IF;
 PERFORM public.process_limit_orders(); PERFORM public.process_limit_orders(); PERFORM public.process_limit_orders(); PERFORM public.process_limit_orders();
 v_result:=public.process_stop_limit_orders();
 IF (SELECT status FROM public.orders WHERE id=v_child)<>'filled' THEN RAISE EXCEPTION 'Child Limit order did not fill'; END IF;
 IF (SELECT status FROM public.orders WHERE id=v_parent)<>'filled' THEN RAISE EXCEPTION 'Parent order did not synchronize final child status'; END IF;
 IF (SELECT filled_amount FROM public.orders WHERE id=v_parent)<>1.000000000000000001::numeric THEN RAISE EXCEPTION 'Parent fill precision mismatch'; END IF;
 IF (SELECT status FROM public.conditional_orders WHERE order_id=v_parent)<>'filled' THEN RAISE EXCEPTION 'Conditional parent metadata did not complete'; END IF;
 SELECT sum(amount) INTO v_value FROM public.trades WHERE order_id=v_child;
 IF v_value<>1.000000000000000001::numeric THEN RAISE EXCEPTION 'Child trade precision mismatch: %',v_value; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.order_reservations WHERE order_id=v_parent AND status='released') THEN RAISE EXCEPTION 'Parent reservation was not released on trigger'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.order_reservations WHERE order_id=v_child AND consumed_amount=10.01 AND status='released') THEN RAISE EXCEPTION 'Child reservation settlement mismatch'; END IF;
END $test$;
SELECT 'Stop-Limit parent/child integration: PASS' AS result;

-- Bounded TP/SL reservation-validation retries; disposable PostgreSQL CI only.
-- Invalid reservations must never be auto-released or rewritten.
INSERT INTO public.profiles(id,is_active)
VALUES ('60000000-0000-0000-0000-000000000006',true);
INSERT INTO public.demo_trading_pairs(pair_symbol,quote_asset,is_enabled)
VALUES ('BTCUSDT','USDT',true);
INSERT INTO public.market_prices(symbol,price,updated_at)
VALUES ('BTCUSDT',2,now());

INSERT INTO public.orders(id,user_id,symbol,side,order_type,amount,price,filled_amount,remaining_amount,status)
VALUES
 ('60000000-0000-0000-0000-000000000101','60000000-0000-0000-0000-000000000006','BTCUSDT','sell','conditional',1,1,0,1,'pending'),
 ('60000000-0000-0000-0000-000000000102','60000000-0000-0000-0000-000000000006','BTCUSDT','sell','conditional',1,1,0,1,'pending'),
 ('60000000-0000-0000-0000-000000000103','60000000-0000-0000-0000-000000000006','BTCUSDT','sell','conditional',1,1,0,1,'pending'),
 ('60000000-0000-0000-0000-000000000104','60000000-0000-0000-0000-000000000006','BTCUSDT','sell','conditional',1,1,0,1,'pending');

INSERT INTO public.conditional_orders(id,order_id,user_id,symbol,side,order_kind,trigger_price,amount,status)
VALUES
 ('60000000-0000-0000-0000-000000000201','60000000-0000-0000-0000-000000000101','60000000-0000-0000-0000-000000000006','BTCUSDT','sell','take_profit',1,1,'pending'),
 ('60000000-0000-0000-0000-000000000202','60000000-0000-0000-0000-000000000102','60000000-0000-0000-0000-000000000006','BTCUSDT','sell','take_profit',1,1,'pending'),
 ('60000000-0000-0000-0000-000000000203','60000000-0000-0000-0000-000000000103','60000000-0000-0000-0000-000000000006','BTCUSDT','sell','take_profit',1,1,'pending'),
 ('60000000-0000-0000-0000-000000000204','60000000-0000-0000-0000-000000000104','60000000-0000-0000-0000-000000000006','BTCUSDT','sell','take_profit',1,1,'pending');

-- Case 1: reservation row missing.
-- Case 2: reservation already released.
-- Case 3: reservation asset does not match BTC.
-- Case 4: reservation amount is smaller than the conditional amount.
INSERT INTO public.order_reservations(order_id,user_id,asset,reserved_amount,consumed_amount,released_amount,status)
VALUES
 ('60000000-0000-0000-0000-000000000102','60000000-0000-0000-0000-000000000006','BTC',1,0,1,'released'),
 ('60000000-0000-0000-0000-000000000103','60000000-0000-0000-0000-000000000006','ETH',1,0,0,'reserved'),
 ('60000000-0000-0000-0000-000000000104','60000000-0000-0000-0000-000000000006','BTC',0.5,0,0,'reserved');

DO $test$
DECLARE
  v_cycle integer;
  v_result jsonb;
BEGIN
  FOR v_cycle IN 1..9 LOOP
    v_result:=public.process_conditional_orders();
  END LOOP;

  IF EXISTS(
    SELECT 1 FROM public.conditional_orders
    WHERE order_id IN (
      '60000000-0000-0000-0000-000000000101',
      '60000000-0000-0000-0000-000000000102',
      '60000000-0000-0000-0000-000000000103',
      '60000000-0000-0000-0000-000000000104'
    ) AND (status<>'pending' OR attempt_count<>9)
  ) THEN
    RAISE EXCEPTION 'Invalid-reservation orders should remain pending through retry 9';
  END IF;

  v_result:=public.process_conditional_orders();
  IF COALESCE((v_result->>'rejected')::integer,0)<>4 THEN
    RAISE EXCEPTION 'Expected four bounded rejections on attempt 10, got %',v_result;
  END IF;

  IF EXISTS(
    SELECT 1 FROM public.conditional_orders
    WHERE order_id IN (
      '60000000-0000-0000-0000-000000000101',
      '60000000-0000-0000-0000-000000000102',
      '60000000-0000-0000-0000-000000000103',
      '60000000-0000-0000-0000-000000000104'
    ) AND (status<>'rejected' OR attempt_count<>10
           OR last_error<>'Reservation validation failed; manual review required')
  ) THEN
    RAISE EXCEPTION 'Conditional metadata did not move to rejected/manual-review at retry 10';
  END IF;

  IF EXISTS(
    SELECT 1 FROM public.orders
    WHERE id IN (
      '60000000-0000-0000-0000-000000000101',
      '60000000-0000-0000-0000-000000000102',
      '60000000-0000-0000-0000-000000000103',
      '60000000-0000-0000-0000-000000000104'
    ) AND status<>'rejected'
  ) THEN
    RAISE EXCEPTION 'Parent orders were not rejected with their conditional metadata';
  END IF;

  IF EXISTS(
    SELECT 1 FROM public.order_reservations
    WHERE order_id='60000000-0000-0000-0000-000000000102'
      AND (status<>'released' OR released_amount<>1)
  ) OR EXISTS(
    SELECT 1 FROM public.order_reservations
    WHERE order_id='60000000-0000-0000-0000-000000000103'
      AND (status<>'reserved' OR asset<>'ETH' OR released_amount<>0)
  ) OR EXISTS(
    SELECT 1 FROM public.order_reservations
    WHERE order_id='60000000-0000-0000-0000-000000000104'
      AND (status<>'reserved' OR reserved_amount<>0.5 OR released_amount<>0)
  ) OR EXISTS(
    SELECT 1 FROM public.order_reservations
    WHERE order_id='60000000-0000-0000-0000-000000000101'
  ) THEN
    RAISE EXCEPTION 'Invalid/missing reservations were modified during bounded rejection';
  END IF;

  PERFORM public.process_conditional_orders();
  IF EXISTS(
    SELECT 1 FROM public.conditional_orders
    WHERE order_id IN (
      '60000000-0000-0000-0000-000000000101',
      '60000000-0000-0000-0000-000000000102',
      '60000000-0000-0000-0000-000000000103',
      '60000000-0000-0000-0000-000000000104'
    ) AND attempt_count<>10
  ) THEN
    RAISE EXCEPTION 'Rejected invalid-reservation orders were retried after terminal rejection';
  END IF;
END
$test$;

SELECT 'TP/SL bounded invalid-reservation retry regression: PASS' AS result;

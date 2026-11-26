-- End-to-end cancellation accounting on disposable PostgreSQL only.
INSERT INTO public.orders (
  id,user_id,symbol,side,order_type,amount,price,filled_amount,remaining_amount,status
) VALUES (
  'd4000000-0000-0000-0000-000000000004',
  '10000000-0000-0000-0000-000000000001',
  'BTCUSDT','buy','limit',
  1.000000000000000001,10,0.250000000000000001,0.750000000000000000,
  'partially_filled'
);

INSERT INTO public.order_reservations (
  id,order_id,user_id,asset,reserved_amount,consumed_amount,released_amount,status
) VALUES (
  'd4000000-0000-0000-0000-000000000044',
  'd4000000-0000-0000-0000-000000000004',
  '10000000-0000-0000-0000-000000000001',
  'USDT',10.01,2.5025,0,'reserved'
);

DO $test$
DECLARE
  v_result jsonb;
  v_status text;
  v_filled numeric;
  v_remaining numeric;
  v_reserved numeric;
  v_consumed numeric;
  v_released numeric;
  v_res_status text;
BEGIN
  PERFORM pg_catalog.set_config(
    'request.jwt.claim.sub',
    '10000000-0000-0000-0000-000000000001',
    true
  );

  v_result := public.cancel_limit_order(
    'd4000000-0000-0000-0000-000000000004'
  );

  IF COALESCE((v_result->>'success')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Cancellation RPC did not confirm success: %',v_result;
  END IF;

  SELECT status,filled_amount,remaining_amount
  INTO v_status,v_filled,v_remaining
  FROM public.orders
  WHERE id='d4000000-0000-0000-0000-000000000004';

  IF v_status <> 'cancelled'
     OR v_filled <> 0.250000000000000001::numeric
     OR v_remaining <> 0.750000000000000000::numeric THEN
    RAISE EXCEPTION 'Cancelled partial order state mismatch: %, %, %',
      v_status,v_filled,v_remaining;
  END IF;

  SELECT reserved_amount,consumed_amount,released_amount,status
  INTO v_reserved,v_consumed,v_released,v_res_status
  FROM public.order_reservations
  WHERE order_id='d4000000-0000-0000-0000-000000000004';

  IF v_res_status <> 'released'
     OR v_consumed <> 2.5025::numeric
     OR v_released <> v_reserved-v_consumed THEN
    RAISE EXCEPTION 'Cancellation reservation reconciliation mismatch: %, %, %, %',
      v_reserved,v_consumed,v_released,v_res_status;
  END IF;

  -- A different authenticated user must not be able to cancel this order.
  PERFORM pg_catalog.set_config(
    'request.jwt.claim.sub',
    '20000000-0000-0000-0000-000000000002',
    true
  );
  BEGIN
    PERFORM public.cancel_limit_order(
      'd4000000-0000-0000-0000-000000000004'
    );
    RAISE EXCEPTION 'Expected ownership rejection was not raised';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Expected ownership rejection was not raised' THEN
      RAISE;
    END IF;
    IF SQLERRM <> 'Order not found' THEN
      RAISE EXCEPTION 'Unexpected ownership rejection: %',SQLERRM;
    END IF;
  END;
END
$test$;

SELECT 'exact-decimal Limit cancellation integration: PASS' AS result;

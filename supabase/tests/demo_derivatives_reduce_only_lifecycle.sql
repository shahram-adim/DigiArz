\set ON_ERROR_STOP on

-- Run after demo_derivatives_schema_integration.sql and the RPC draft.
SET ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',false);

DO $reduce_only_lifecycle$
DECLARE
  v_first uuid;
  v_retry uuid;
  v_second uuid;
  v_cancelled boolean;
  v_reserved numeric(38,18);
BEGIN
  v_first := public.place_demo_reduce_only_limit_order(
    '20000000-0000-0000-0000-000000000001',
    'BTCUSDT','long',0.6,99000,
    'a1000000-0000-0000-0000-000000000001'
  );

  v_retry := public.place_demo_reduce_only_limit_order(
    '20000000-0000-0000-0000-000000000001',
    'BTCUSDT','long',0.6,99000,
    'a1000000-0000-0000-0000-000000000001'
  );
  IF v_retry<>v_first THEN
    RAISE EXCEPTION 'idempotent retry returned a different order id';
  END IF;

  SELECT COALESCE(sum(remaining_quantity),0) INTO v_reserved
  FROM public.demo_derivative_orders
  WHERE account_id='20000000-0000-0000-0000-000000000001'
    AND symbol='BTCUSDT' AND position_side='long'
    AND reduce_only AND status IN ('pending','partially_filled');
  IF v_reserved<>0.6 THEN
    RAISE EXCEPTION 'first Reduce-only reservation mismatch: %',v_reserved;
  END IF;

  BEGIN
    PERFORM public.place_demo_reduce_only_limit_order(
      '20000000-0000-0000-0000-000000000001',
      'BTCUSDT','long',0.5,98000,
      'a1000000-0000-0000-0000-000000000002'
    );
    RAISE EXCEPTION 'over-allocation unexpectedly accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    PERFORM public.place_demo_reduce_only_limit_order(
      '20000000-0000-0000-0000-000000000001',
      'BTCUSDT','long',0.7,98000,
      'a1000000-0000-0000-0000-000000000001'
    );
    RAISE EXCEPTION 'idempotency key parameter mismatch unexpectedly accepted';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;

  v_cancelled := public.cancel_demo_reduce_only_order(v_first);
  IF NOT v_cancelled THEN
    RAISE EXCEPTION 'active Reduce-only order was not cancelled';
  END IF;
  IF public.cancel_demo_reduce_only_order(v_first) THEN
    RAISE EXCEPTION 'repeated cancellation should be a no-op';
  END IF;

  SELECT COALESCE(sum(remaining_quantity),0) INTO v_reserved
  FROM public.demo_derivative_orders
  WHERE account_id='20000000-0000-0000-0000-000000000001'
    AND symbol='BTCUSDT' AND position_side='long'
    AND reduce_only AND status IN ('pending','partially_filled');
  IF v_reserved<>0 THEN
    RAISE EXCEPTION 'cancel did not release Reduce-only reservation';
  END IF;

  v_second := public.place_demo_reduce_only_limit_order(
    '20000000-0000-0000-0000-000000000001',
    'BTCUSDT','long',1,97000,
    'a1000000-0000-0000-0000-000000000003'
  );
  IF v_second=v_first THEN
    RAISE EXCEPTION 'new request unexpectedly reused cancelled order id';
  END IF;

  IF NOT public.cancel_demo_reduce_only_order(v_second) THEN
    RAISE EXCEPTION 'second Reduce-only order could not be cancelled';
  END IF;

  BEGIN
    PERFORM public.place_demo_reduce_only_limit_order(
      '20000000-0000-0000-0000-000000000002',
      'BTCUSDT','long',0.1,99000,
      'a1000000-0000-0000-0000-000000000004'
    );
    RAISE EXCEPTION 'cross-user account access unexpectedly accepted';
  EXCEPTION WHEN no_data_found THEN
    NULL;
  END;
END;
$reduce_only_lifecycle$;

RESET ROLE;
SELECT 'demo derivatives Reduce-only placement/cancel lifecycle passed' AS result;

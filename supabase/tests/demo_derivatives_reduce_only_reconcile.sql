\set ON_ERROR_STOP on

-- Runs after the concurrent ETHUSDT fill race in disposable PostgreSQL.
-- The direct quantity update simulates an already-accounted external risk
-- reduction; this test isolates reservation reconciliation only.

SET ROLE authenticated;
DO $permission_check$
BEGIN
  BEGIN
    PERFORM public.reconcile_demo_reduce_only_reservations(
      '4e000000-0000-0000-0000-000000000001'
    );
    RAISE EXCEPTION 'authenticated unexpectedly executed trusted reconciliation RPC';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END;
$permission_check$;
RESET ROLE;

UPDATE public.demo_derivative_positions
SET quantity=0.3,version=version+1,updated_at=now()
WHERE id='4e000000-0000-0000-0000-000000000001'
  AND quantity=0.6 AND status='open';
DO $external_reduction_check$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.demo_derivative_positions
    WHERE id='4e000000-0000-0000-0000-000000000001'
      AND quantity=0.3 AND status='open'
  ) THEN
    RAISE EXCEPTION 'external reduction fixture did not update the expected open position';
  END IF;
END;
$external_reduction_check$;

SET ROLE service_role;
DO $reconcile$
DECLARE
  v_cancelled uuid[];
  v_main_order uuid;
  v_older_extra uuid;
  v_newer_extra uuid;
  v_reserved numeric(38,18);
BEGIN
  SELECT id INTO v_main_order
  FROM public.demo_derivative_orders
  WHERE client_request_id='a5000000-0000-0000-0000-000000000001';
  SELECT id INTO v_older_extra
  FROM public.demo_derivative_orders
  WHERE client_request_id='a5000000-0000-0000-0000-000000000004';
  SELECT id INTO v_newer_extra
  FROM public.demo_derivative_orders
  WHERE client_request_id='a5000000-0000-0000-0000-000000000005';

  v_cancelled := public.reconcile_demo_reduce_only_reservations(
    '4e000000-0000-0000-0000-000000000001'
  );

  IF cardinality(v_cancelled)<>2
     OR v_cancelled[1]<>v_newer_extra
     OR v_cancelled[2]<>v_older_extra THEN
    RAISE EXCEPTION 'newest-first cancellation order mismatch: %',v_cancelled;
  END IF;

  IF (SELECT status FROM public.demo_derivative_orders WHERE id=v_newer_extra)<>'cancelled'
     OR (SELECT status FROM public.demo_derivative_orders WHERE id=v_older_extra)<>'cancelled'
     OR (SELECT status FROM public.demo_derivative_orders WHERE id=v_main_order)<>'partially_filled' THEN
    RAISE EXCEPTION 'reconciliation cancelled the wrong Reduce-only orders';
  END IF;

  SELECT COALESCE(sum(remaining_quantity),0)::numeric(38,18)
    INTO v_reserved
  FROM public.demo_derivative_orders
  WHERE account_id='20000000-0000-0000-0000-000000000002'
    AND product_type='futures' AND symbol='ETHUSDT' AND position_side='long'
    AND reduce_only AND status IN ('pending','partially_filled');

  IF v_reserved<>0.2 OR v_reserved>0.3 THEN
    RAISE EXCEPTION 'remaining reservation is incorrect after reconciliation: %',v_reserved;
  END IF;

  IF cardinality(public.reconcile_demo_reduce_only_reservations(
    '4e000000-0000-0000-0000-000000000001'
  ))<>0 THEN
    RAISE EXCEPTION 'reconciliation retry should be idempotent and cancel nothing';
  END IF;
END;
$reconcile$;
RESET ROLE;

SELECT 'demo derivatives newest-first Reduce-only reservation reconciliation passed' AS result;

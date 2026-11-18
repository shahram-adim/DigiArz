\set ON_ERROR_STOP on

-- Runs after the concurrent ETHUSDT fill race in disposable PostgreSQL.
-- A trusted external reduction must update PnL/ledger and reconcile reservations
-- in one transaction; no direct fixture mutation of the position is used.

SET ROLE authenticated;
DO $permission_check$
BEGIN
  BEGIN
    PERFORM public.apply_demo_external_futures_position_reduction(
      '4e000000-0000-0000-0000-000000000001',
      'b6000000-0000-0000-0000-000000000001',
      0.3,110,0.01
    );
    RAISE EXCEPTION 'authenticated unexpectedly executed trusted external reduction';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END;
$permission_check$;
RESET ROLE;

SET ROLE service_role;
DO $external_reduction$
DECLARE
  v_result jsonb;
  v_retry jsonb;
  v_cancelled uuid[];
  v_main_order uuid;
  v_older_extra uuid;
  v_newer_extra uuid;
  v_cash numeric(38,18);
  v_reserved numeric(38,18);
  v_position_state jsonb;
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

  v_result := public.apply_demo_external_futures_position_reduction(
    '4e000000-0000-0000-0000-000000000001',
    'b6000000-0000-0000-0000-000000000001',
    0.3,110,0.01
  );
  v_retry := public.apply_demo_external_futures_position_reduction(
    '4e000000-0000-0000-0000-000000000001',
    'b6000000-0000-0000-0000-000000000001',
    0.3,110,0.01
  );

  IF v_retry IS DISTINCT FROM v_result THEN
    RAISE EXCEPTION 'external reduction retry did not return the original result';
  END IF;

  SELECT array_agg(x.value::uuid ORDER BY x.ordinality)
    INTO v_cancelled
  FROM jsonb_array_elements_text(v_result->'cancelled_order_ids')
       WITH ORDINALITY AS x(value,ordinality);

  IF COALESCE(cardinality(v_cancelled),0)<>2
     OR v_cancelled[1]<>v_newer_extra
     OR v_cancelled[2]<>v_older_extra THEN
    RAISE EXCEPTION 'external reduction did not cancel newest reservations first: %',v_cancelled;
  END IF;

  IF (v_result->>'remaining_quantity')::numeric<>0.3
     OR (v_result->>'realized_pnl_usdt')::numeric<>3
     OR (v_result->>'fee_usdt')::numeric<>0.01
     OR (v_result->>'isolated_margin_released_usdt')::numeric<>0 THEN
    RAISE EXCEPTION 'external reduction returned incorrect accounting result: %',v_result;
  END IF;

  SELECT jsonb_build_object(
    'quantity',p.quantity,
    'status',p.status,
    'realized_pnl_usdt',p.realized_pnl_usdt,
    'margin_mode',p.margin_mode,
    'entry_price',p.entry_price,
    'version',p.version
  ) INTO v_position_state
  FROM public.demo_derivative_positions AS p
  WHERE p.id='4e000000-0000-0000-0000-000000000001';

  IF v_position_state IS NULL
     OR (v_position_state->>'quantity')::numeric<>0.3
     OR v_position_state->>'status'<>'open'
     OR (v_position_state->>'realized_pnl_usdt')::numeric<>3
     OR v_position_state->>'margin_mode'<>'cross' THEN
    RAISE EXCEPTION 'position reduction/PnL update is incorrect: %',v_position_state;
  END IF;

  IF (SELECT status FROM public.demo_derivative_orders WHERE id=v_newer_extra)<>'cancelled'
     OR (SELECT status FROM public.demo_derivative_orders WHERE id=v_older_extra)<>'cancelled'
     OR (SELECT status FROM public.demo_derivative_orders WHERE id=v_main_order)<>'partially_filled' THEN
    RAISE EXCEPTION 'external reduction cancelled the wrong Reduce-only orders';
  END IF;

  SELECT COALESCE(sum(remaining_quantity),0)::numeric(38,18)
    INTO v_reserved
  FROM public.demo_derivative_orders
  WHERE account_id='20000000-0000-0000-0000-000000000002'
    AND product_type='futures' AND symbol='ETHUSDT' AND position_side='long'
    AND reduce_only AND status IN ('pending','partially_filled');

  IF v_reserved<>0.2 OR v_reserved>0.3 THEN
    RAISE EXCEPTION 'remaining Reduce-only reservation violates position ceiling: %',v_reserved;
  END IF;

  IF (SELECT count(*) FROM public.demo_derivative_risk_events
      WHERE id='b6000000-0000-0000-0000-000000000001'
        AND event_type='external_reduction')<>1 THEN
    RAISE EXCEPTION 'external reduction risk event was not recorded exactly once';
  END IF;

  IF (SELECT count(*) FROM public.demo_derivative_ledger_transactions
      WHERE user_id='10000000-0000-0000-0000-000000000002'
        AND idempotency_key='b6000000-0000-0000-0000-000000000001'
        AND event_type='position_reduction')<>1 THEN
    RAISE EXCEPTION 'external reduction ledger transaction was not recorded exactly once';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.demo_derivative_ledger_entries e
    JOIN public.demo_derivative_ledger_transactions t
      ON t.id=e.transaction_id AND t.user_id=e.user_id
    WHERE t.idempotency_key='b6000000-0000-0000-0000-000000000001'
    GROUP BY e.asset
    HAVING sum(e.debit_amount)<>sum(e.credit_amount)
  ) THEN
    RAISE EXCEPTION 'external reduction ledger transaction is unbalanced';
  END IF;

  SELECT COALESCE(sum(e.debit_amount-e.credit_amount),0)::numeric(38,18)
    INTO v_cash
  FROM public.demo_derivative_ledger_entries e
  WHERE e.user_id='10000000-0000-0000-0000-000000000002'
    AND e.asset='USDT' AND e.account_bucket='futures_cash';

  IF v_cash<>2.99 THEN
    RAISE EXCEPTION 'ledger-derived Futures cash should equal 2.99, got %',v_cash;
  END IF;

  -- Reusing an event id with changed payload must fail without a second effect.
  BEGIN
    PERFORM public.apply_demo_external_futures_position_reduction(
      '4e000000-0000-0000-0000-000000000001',
      'b6000000-0000-0000-0000-000000000001',
      0.2,110,0.01
    );
    RAISE EXCEPTION 'external reduction event id accepted a changed payload';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;

  -- A distinct event cannot reduce more than the remaining open quantity.
  BEGIN
    PERFORM public.apply_demo_external_futures_position_reduction(
      '4e000000-0000-0000-0000-000000000001',
      'b6000000-0000-0000-0000-000000000002',
      0.4,110,0
    );
    RAISE EXCEPTION 'external reduction over-reduced the position';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END;
$external_reduction$;
RESET ROLE;

SELECT 'demo derivatives atomic external position reduction and reservation reconciliation passed' AS result;

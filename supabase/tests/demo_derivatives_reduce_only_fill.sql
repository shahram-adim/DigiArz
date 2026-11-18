\set ON_ERROR_STOP on

-- Runs after schema integration, Reduce-only placement/cancel lifecycle and
-- the trusted-worker fill RPC draft in disposable PostgreSQL only.

SET ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',false);

DO $fill_permission_check$
BEGIN
  BEGIN
    PERFORM public.apply_demo_reduce_only_limit_fill(
      '30000000-0000-0000-0000-000000000001',
      'a3000000-0000-0000-0000-000000000099',0.1,110,0
    );
    RAISE EXCEPTION 'authenticated unexpectedly executed trusted fill RPC';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END;
$fill_permission_check$;

SELECT public.place_demo_reduce_only_limit_order(
  '20000000-0000-0000-0000-000000000001',
  'BTCUSDT','long',1,105,
  'a2000000-0000-0000-0000-000000000001'
);

RESET ROLE;
SET ROLE service_role;

DO $partial_fill$
DECLARE
  v_order_id uuid;
  v_first_fill uuid := 'a3000000-0000-0000-0000-000000000001';
  v_retry uuid;
  v_position_quantity numeric(38,18);
  v_position_margin numeric(38,18);
  v_position_pnl numeric(38,18);
  v_order_filled numeric(38,18);
  v_order_remaining numeric(38,18);
  v_order_average numeric(38,18);
  v_order_status text;
  v_fill_count integer;
  v_ledger_count integer;
BEGIN
  SELECT id INTO v_order_id
  FROM public.demo_derivative_orders
  WHERE client_request_id='a2000000-0000-0000-0000-000000000001';
  IF v_order_id IS NULL THEN
    RAISE EXCEPTION 'Reduce-only Limit order fixture was not created';
  END IF;

  v_retry := public.apply_demo_reduce_only_limit_fill(
    v_order_id,v_first_fill,0.4,110,0.02
  );
  IF v_retry<>v_first_fill THEN
    RAISE EXCEPTION 'first fill returned unexpected id';
  END IF;

  -- Exact replay must not duplicate fill, position mutation or ledger posting.
  PERFORM public.apply_demo_reduce_only_limit_fill(
    v_order_id,v_first_fill,0.4,110,0.02
  );

  SELECT quantity,isolated_margin_usdt,realized_pnl_usdt
    INTO v_position_quantity,v_position_margin,v_position_pnl
  FROM public.demo_derivative_positions
  WHERE id='40000000-0000-0000-0000-000000000001';
  IF v_position_quantity<>0.6 OR v_position_margin<>12 OR v_position_pnl<>4 THEN
    RAISE EXCEPTION 'partial position accounting mismatch: qty %, margin %, pnl %',
      v_position_quantity,v_position_margin,v_position_pnl;
  END IF;

  SELECT filled_quantity,remaining_quantity,average_fill_price,status
    INTO v_order_filled,v_order_remaining,v_order_average,v_order_status
  FROM public.demo_derivative_orders WHERE id=v_order_id;
  IF v_order_filled<>0.4 OR v_order_remaining<>0.6
     OR v_order_average<>110 OR v_order_status<>'partially_filled' THEN
    RAISE EXCEPTION 'partial order lifecycle mismatch';
  END IF;

  SELECT count(*) INTO v_fill_count
  FROM public.demo_derivative_fills WHERE id=v_first_fill;
  SELECT count(*) INTO v_ledger_count
  FROM public.demo_derivative_ledger_transactions
  WHERE idempotency_key=v_first_fill;
  IF v_fill_count<>1 OR v_ledger_count<>1 THEN
    RAISE EXCEPTION 'fill retry duplicated persisted records';
  END IF;

  BEGIN
    PERFORM public.apply_demo_reduce_only_limit_fill(
      v_order_id,v_first_fill,0.4,111,0.02
    );
    RAISE EXCEPTION 'fill id reused with different execution payload unexpectedly accepted';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;

  BEGIN
    PERFORM public.apply_demo_reduce_only_limit_fill(
      v_order_id,'a3000000-0000-0000-0000-000000000002',0.7,110,0.02
    );
    RAISE EXCEPTION 'fill above remaining order quantity unexpectedly accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    PERFORM public.apply_demo_reduce_only_limit_fill(
      v_order_id,'a3000000-0000-0000-0000-000000000003',0.1,104,0.01
    );
    RAISE EXCEPTION 'Sell fill below Limit unexpectedly accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  PERFORM public.apply_demo_reduce_only_limit_fill(
    v_order_id,'a3000000-0000-0000-0000-000000000004',0.6,105,0.03
  );

  SELECT quantity,isolated_margin_usdt,realized_pnl_usdt,status
    INTO v_position_quantity,v_position_margin,v_position_pnl,v_order_status
  FROM public.demo_derivative_positions
  WHERE id='40000000-0000-0000-0000-000000000001';
  IF v_position_quantity<>0 OR v_position_margin<>0 OR v_position_pnl<>7
     OR v_order_status<>'closed' THEN
    RAISE EXCEPTION 'final position close accounting mismatch';
  END IF;

  SELECT filled_quantity,remaining_quantity,average_fill_price,status
    INTO v_order_filled,v_order_remaining,v_order_average,v_order_status
  FROM public.demo_derivative_orders WHERE id=v_order_id;
  IF v_order_filled<>1 OR v_order_remaining<>0
     OR v_order_average<>107 OR v_order_status<>'filled' THEN
    RAISE EXCEPTION 'final order lifecycle mismatch';
  END IF;

  IF (SELECT count(*) FROM public.demo_derivative_fills WHERE order_id=v_order_id)<>2 THEN
    RAISE EXCEPTION 'expected exactly two fill records';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.demo_derivative_ledger_transactions t
    JOIN public.demo_derivative_ledger_entries e ON e.transaction_id=t.id
    WHERE t.reference_id IN (v_first_fill,'a3000000-0000-0000-0000-000000000004')
    GROUP BY t.id,e.asset
    HAVING sum(e.debit_amount)<>sum(e.credit_amount)
  ) THEN
    RAISE EXCEPTION 'fill ledger transaction is not balanced';
  END IF;
END;
$partial_fill$;

RESET ROLE;
SET ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',false);

DO $cash_projection$
DECLARE
  v_cash numeric(38,18);
BEGIN
  SELECT futures_cash_usdt INTO v_cash
  FROM public.demo_derivative_futures_cash_balances
  WHERE user_id='10000000-0000-0000-0000-000000000001';
  -- 10 initial free cash - 5 settled funding + 20 released isolated margin
  -- + 7 realized PnL - 0.05 execution fees = 31.95 USDT.
  IF v_cash<>31.95 THEN
    RAISE EXCEPTION 'ledger-derived cash after funding settlement and two fills mismatch: %',v_cash;
  END IF;
END;
$cash_projection$;

RESET ROLE;
SELECT 'demo derivatives Reduce-only partial-fill accounting passed' AS result;

-- Disposable PostgreSQL CI assertion for exact-decimal type widening.
DO $test$
DECLARE
  v_type text;
BEGIN
  IF (SELECT amount FROM public.orders WHERE price IS NOT NULL) IS DISTINCT FROM 1.25::numeric
     OR (SELECT price FROM public.orders WHERE price IS NOT NULL) IS DISTINCT FROM 10.5::numeric
     OR (SELECT count(*) FROM public.orders WHERE price IS NULL) IS DISTINCT FROM 1
     OR (SELECT balance FROM public.asset_balances) IS DISTINCT FROM 1.25::numeric
     OR (SELECT reserved_amount FROM public.order_reservations) IS DISTINCT FROM 10.5::numeric
     OR (SELECT amount FROM public.conditional_orders) IS DISTINCT FROM 0.5::numeric THEN
    RAISE EXCEPTION 'type widening changed existing financial values';
  END IF;

  SELECT format_type(a.atttypid, a.atttypmod) INTO v_type
  FROM pg_attribute a WHERE a.attrelid='public.orders'::regclass AND a.attname='amount';
  IF v_type <> 'numeric(34,18)' THEN RAISE EXCEPTION 'orders.amount type: %',v_type; END IF;
  SELECT format_type(a.atttypid, a.atttypmod) INTO v_type
  FROM pg_attribute a WHERE a.attrelid='public.orders'::regclass AND a.attname='price';
  IF v_type <> 'numeric(34,18)' THEN RAISE EXCEPTION 'orders.price type: %',v_type; END IF;
  IF EXISTS (SELECT 1 FROM public.orders WHERE amount=0.5 AND price IS NOT NULL) THEN
    RAISE EXCEPTION 'nullable market order price was not preserved';
  END IF;
  SELECT format_type(a.atttypid, a.atttypmod) INTO v_type
  FROM pg_attribute a WHERE a.attrelid='public.trades'::regclass AND a.attname='price';
  IF v_type <> 'numeric(34,18)' THEN RAISE EXCEPTION 'trades.price type: %',v_type; END IF;
  SELECT format_type(a.atttypid, a.atttypmod) INTO v_type
  FROM pg_attribute a WHERE a.attrelid='public.asset_balances'::regclass AND a.attname='balance';
  IF v_type <> 'numeric(38,18)' THEN RAISE EXCEPTION 'asset_balances.balance type: %',v_type; END IF;
  SELECT format_type(a.atttypid, a.atttypmod) INTO v_type
  FROM pg_attribute a WHERE a.attrelid='public.order_reservations'::regclass AND a.attname='reserved_amount';
  IF v_type <> 'numeric(38,18)' THEN RAISE EXCEPTION 'order_reservations.reserved_amount type: %',v_type; END IF;
  SELECT format_type(a.atttypid, a.atttypmod) INTO v_type
  FROM pg_attribute a WHERE a.attrelid='public.conditional_orders'::regclass AND a.attname='trigger_price';
  IF v_type <> 'numeric(34,18)' THEN RAISE EXCEPTION 'conditional_orders.trigger_price type: %',v_type; END IF;

  SELECT format_type(a.atttypid, a.atttypmod) INTO v_type
  FROM pg_attribute a WHERE a.attrelid='public.wallets'::regclass AND a.attname='balance_usdt';
  IF v_type <> 'numeric(24,8)' THEN RAISE EXCEPTION 'wallets.balance_usdt unexpectedly changed: %',v_type; END IF;
  SELECT format_type(a.atttypid, a.atttypmod) INTO v_type
  FROM pg_attribute a WHERE a.attrelid='public.transactions'::regclass AND a.attname='amount';
  IF v_type <> 'numeric(24,8)' THEN RAISE EXCEPTION 'transactions.amount unexpectedly changed: %',v_type; END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.orders'::regclass AND conname='orders_amount_accounting_chk')
     OR NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.orders'::regclass AND conname='orders_price_positive')
     OR NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.conditional_orders'::regclass AND conname='conditional_orders_stop_limit_fields_chk')
     OR (SELECT count(*) FROM pg_constraint WHERE conrelid='public.orders'::regclass AND contype='c') IS DISTINCT FROM 9
     OR (SELECT count(*) FROM pg_constraint WHERE conrelid='public.trades'::regclass AND contype='c') IS DISTINCT FROM 3
     OR (SELECT count(*) FROM pg_constraint WHERE conrelid='public.asset_balances'::regclass AND contype='c') IS DISTINCT FROM 2
     OR (SELECT count(*) FROM pg_constraint WHERE conrelid='public.order_reservations'::regclass AND contype='c') IS DISTINCT FROM 5
     OR (SELECT count(*) FROM pg_constraint WHERE conrelid='public.conditional_orders'::regclass AND contype='c') IS DISTINCT FROM 9 THEN
    RAISE EXCEPTION 'A production-style check constraint was lost during widening; inspect pg_constraint for each fixture table';
  END IF;

  RAISE NOTICE 'Exact-decimal type-widening rehearsal: PASS';
END
$test$;

-- Verify every widened numeric column, not only one representative per table.
-- Then round-trip an 18-place value through each financial quantity/price field.
DO $precision$
DECLARE
  v_bad text;
BEGIN
  WITH expected(table_name,column_name,expected_type) AS (
    VALUES
      ('orders','amount','numeric(34,18)'),
      ('orders','price','numeric(34,18)'),
      ('orders','filled_amount','numeric(34,18)'),
      ('orders','remaining_amount','numeric(34,18)'),
      ('trades','amount','numeric(34,18)'),
      ('trades','price','numeric(34,18)'),
      ('asset_balances','balance','numeric(38,18)'),
      ('order_reservations','reserved_amount','numeric(38,18)'),
      ('order_reservations','released_amount','numeric(38,18)'),
      ('order_reservations','consumed_amount','numeric(38,18)'),
      ('conditional_orders','amount','numeric(34,18)'),
      ('conditional_orders','trigger_price','numeric(34,18)'),
      ('conditional_orders','limit_price','numeric(34,18)'),
      ('conditional_orders','executed_price','numeric(34,18)')
  ),
  actual AS (
    SELECT e.table_name,e.column_name,e.expected_type,
           format_type(a.atttypid,a.atttypmod) AS actual_type
    FROM expected e
    LEFT JOIN pg_class c ON c.relname=e.table_name
      AND c.relnamespace=(SELECT oid FROM pg_namespace WHERE nspname='public')
    LEFT JOIN pg_attribute a ON a.attrelid=c.oid AND a.attname=e.column_name
      AND a.attnum>0 AND NOT a.attisdropped
  )
  SELECT string_agg(
    format('%s.%s expected %s, got %s',table_name,column_name,expected_type,COALESCE(actual_type,'<missing>')),
    '; '
  )
  INTO v_bad
  FROM actual
  WHERE actual_type IS DISTINCT FROM expected_type;

  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'not all widened financial columns have the expected typmod: %',v_bad;
  END IF;

  UPDATE public.orders
  SET amount=1.234567890123456789,
      price=10.123456789012345678,
      filled_amount=0.234567890123456789,
      remaining_amount=1.000000000000000000
  WHERE id='10000000-0000-4000-8000-000000000001';

  UPDATE public.trades
  SET amount=0.234567890123456789,
      price=10.123456789012345678
  WHERE order_id='10000000-0000-4000-8000-000000000001';

  UPDATE public.asset_balances
  SET balance=1.234567890123456789
  WHERE user_id='20000000-0000-4000-8000-000000000001' AND asset='BTC';

  UPDATE public.order_reservations
  SET reserved_amount=10.123456789012345678,
      released_amount=1.234567890123456789,
      consumed_amount=2.345678901234567890
  WHERE order_id='10000000-0000-4000-8000-000000000001';

  UPDATE public.conditional_orders
  SET order_kind='stop_limit',
      status='filled',
      amount=0.123456789012345678,
      trigger_price=12.123456789012345678,
      limit_price=12.223456789012345678,
      executed_price=12.323456789012345678
  WHERE order_id='10000000-0000-4000-8000-000000000002';

  IF (SELECT amount FROM public.orders WHERE id='10000000-0000-4000-8000-000000000001') IS DISTINCT FROM 1.234567890123456789
     OR (SELECT price FROM public.orders WHERE id='10000000-0000-4000-8000-000000000001') IS DISTINCT FROM 10.123456789012345678
     OR (SELECT filled_amount FROM public.orders WHERE id='10000000-0000-4000-8000-000000000001') IS DISTINCT FROM 0.234567890123456789
     OR (SELECT remaining_amount FROM public.orders WHERE id='10000000-0000-4000-8000-000000000001') IS DISTINCT FROM 1.000000000000000000
     OR (SELECT amount FROM public.trades WHERE order_id='10000000-0000-4000-8000-000000000001') IS DISTINCT FROM 0.234567890123456789
     OR (SELECT price FROM public.trades WHERE order_id='10000000-0000-4000-8000-000000000001') IS DISTINCT FROM 10.123456789012345678
     OR (SELECT balance FROM public.asset_balances WHERE asset='BTC') IS DISTINCT FROM 1.234567890123456789
     OR (SELECT reserved_amount FROM public.order_reservations WHERE order_id='10000000-0000-4000-8000-000000000001') IS DISTINCT FROM 10.123456789012345678
     OR (SELECT released_amount FROM public.order_reservations WHERE order_id='10000000-0000-4000-8000-000000000001') IS DISTINCT FROM 1.234567890123456789
     OR (SELECT consumed_amount FROM public.order_reservations WHERE order_id='10000000-0000-4000-8000-000000000001') IS DISTINCT FROM 2.345678901234567890
     OR (SELECT amount FROM public.conditional_orders WHERE order_id='10000000-0000-4000-8000-000000000002') IS DISTINCT FROM 0.123456789012345678
     OR (SELECT trigger_price FROM public.conditional_orders WHERE order_id='10000000-0000-4000-8000-000000000002') IS DISTINCT FROM 12.123456789012345678
     OR (SELECT limit_price FROM public.conditional_orders WHERE order_id='10000000-0000-4000-8000-000000000002') IS DISTINCT FROM 12.223456789012345678
     OR (SELECT executed_price FROM public.conditional_orders WHERE order_id='10000000-0000-4000-8000-000000000002') IS DISTINCT FROM 12.323456789012345678 THEN
    RAISE EXCEPTION 'one or more widened columns did not preserve an exact 18-place value';
  END IF;

  RAISE NOTICE 'All 14 widened columns preserve exact 18-place values: PASS';
END
$precision$;


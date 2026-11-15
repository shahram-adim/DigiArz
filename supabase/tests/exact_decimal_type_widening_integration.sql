-- Disposable PostgreSQL CI assertion for exact-decimal type widening.
DO $test$
DECLARE
  v_type text;
BEGIN
  IF (SELECT amount FROM public.orders WHERE price IS NOT NULL) <> 1.25::numeric
     OR (SELECT price FROM public.orders WHERE price IS NOT NULL) <> 10.5::numeric
     OR (SELECT count(*) FROM public.orders WHERE price IS NULL) <> 1
     OR (SELECT balance FROM public.asset_balances) <> 1.25::numeric
     OR (SELECT reserved_amount FROM public.order_reservations) <> 10.5::numeric
     OR (SELECT amount FROM public.conditional_orders) <> 0.5::numeric THEN
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

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='orders_amount_accounting_chk')
     OR NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='orders_price_positive')
     OR NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='trades_amount_check')
     OR NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='asset_balances_balance_check')
     OR NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='order_reservations_consumed_amount_check')
     OR NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='conditional_orders_stop_limit_fields_chk') THEN
    RAISE EXCEPTION 'A production-style numeric constraint was lost during widening';
  END IF;

  RAISE NOTICE 'Exact-decimal type-widening rehearsal: PASS';
END
$test$;

-- Verify a lock-timeout failure leaves every widened column at its original type.
DO $verify$
DECLARE
  v_bad text;
BEGIN
  SELECT string_agg(format('%s.%s=%s', c.table_name, c.column_name, c.actual_type), ', ')
    INTO v_bad
  FROM (
    SELECT x.table_name, x.column_name, format_type(a.atttypid,a.atttypmod) AS actual_type,
           x.expected_type
    FROM (VALUES
      ('orders','amount','numeric(24,8)'),
      ('orders','price','numeric(24,8)'),
      ('orders','filled_amount','numeric'),
      ('orders','remaining_amount','numeric'),
      ('trades','amount','numeric(24,8)'),
      ('trades','price','numeric(24,8)'),
      ('asset_balances','balance','numeric(28,8)'),
      ('order_reservations','reserved_amount','numeric'),
      ('order_reservations','released_amount','numeric'),
      ('order_reservations','consumed_amount','numeric'),
      ('conditional_orders','amount','numeric'),
      ('conditional_orders','trigger_price','numeric'),
      ('conditional_orders','limit_price','numeric'),
      ('conditional_orders','executed_price','numeric')
    ) AS x(table_name,column_name,expected_type)
    JOIN pg_attribute a
      ON a.attrelid = format('public.%I',x.table_name)::regclass
     AND a.attname = x.column_name
     AND NOT a.attisdropped
  ) c
  WHERE c.actual_type <> c.expected_type;

  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'lock-timeout changed schema unexpectedly: %', v_bad;
  END IF;
END
$verify$;

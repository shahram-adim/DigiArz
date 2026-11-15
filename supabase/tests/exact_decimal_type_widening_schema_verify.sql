-- Assert representative schema objects survive the widening rehearsal unchanged.
DO $verify$
DECLARE
  v_missing text;
BEGIN
  SELECT string_agg(required_object, ', ')
    INTO v_missing
  FROM (VALUES
    ('constraint:orders_amount_accounting_chk'),
    ('constraint:orders_amount_positive'),
    ('constraint:trades_amount_check'),
    ('constraint:asset_balances_balance_check'),
    ('constraint:conditional_orders_amount_check'),
    ('index:orders_widening_fixture_idx'),
    ('index:trades_widening_fixture_idx'),
    ('index:asset_balances_widening_fixture_idx'),
    ('index:order_reservations_widening_fixture_idx'),
    ('index:conditional_orders_widening_fixture_idx'),
    ('trigger:orders_widening_fixture_trigger')
  ) AS expected(required_object)
  WHERE CASE
    WHEN required_object LIKE 'constraint:%' THEN NOT EXISTS (
      SELECT 1 FROM pg_constraint
      WHERE conname = split_part(required_object,':',2)
    )
    WHEN required_object LIKE 'index:%' THEN to_regclass('public.' || split_part(required_object,':',2)) IS NULL
    WHEN required_object LIKE 'trigger:%' THEN NOT EXISTS (
      SELECT 1 FROM pg_trigger
      WHERE tgname = split_part(required_object,':',2)
        AND tgrelid = 'public.orders'::regclass AND NOT tgisinternal
    )
    ELSE true
  END;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'widening lost schema objects: %', v_missing;
  END IF;

  IF NOT has_table_privilege('authenticated','public.orders','SELECT')
     OR NOT has_table_privilege('service_role','public.orders','INSERT')
     OR NOT has_table_privilege('service_role','public.order_reservations','UPDATE') THEN
    RAISE EXCEPTION 'widening changed expected table grants';
  END IF;

  IF (SELECT pg_get_expr(d.adbin,d.adrelid) FROM pg_attrdef d
      WHERE d.adrelid='public.orders'::regclass
        AND d.adnum=(SELECT attnum FROM pg_attribute WHERE attrelid='public.orders'::regclass AND attname='filled_amount')) <> '0' THEN
    RAISE EXCEPTION 'orders.filled_amount default changed';
  END IF;
  IF (SELECT pg_get_expr(d.adbin,d.adrelid) FROM pg_attrdef d
      WHERE d.adrelid='public.asset_balances'::regclass
        AND d.adnum=(SELECT attnum FROM pg_attribute WHERE attrelid='public.asset_balances'::regclass AND attname='balance')) <> '0' THEN
    RAISE EXCEPTION 'asset_balances.balance default changed';
  END IF;
END
$verify$;

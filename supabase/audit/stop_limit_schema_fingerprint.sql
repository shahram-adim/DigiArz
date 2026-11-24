-- DigiArz Stop-Limit production schema fingerprint
-- READ ONLY: this query reads PostgreSQL catalogs and pg_cron metadata only.
-- It does not inspect user rows or change schema, data, permissions, or schedules.
-- Run against the intended Supabase project and save the single JSON result for QA parity review.

WITH target_tables AS (
  SELECT c.oid, n.nspname, c.relname, c.relrowsecurity, c.relforcerowsecurity
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relkind IN ('r','p')
    AND c.relname = ANY (ARRAY[
      'orders','conditional_orders','order_reservations','trades',
      'asset_balances','wallets','market_prices'
    ])
),
column_snapshot AS (
  SELECT jsonb_agg(jsonb_build_object(
    'table', table_name,
    'position', ordinal_position,
    'column', column_name,
    'data_type', data_type,
    'udt_name', udt_name,
    'nullable', is_nullable,
    'default', column_default,
    'numeric_precision', numeric_precision,
    'numeric_scale', numeric_scale
  ) ORDER BY table_name, ordinal_position) AS data
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = ANY (ARRAY[
      'orders','conditional_orders','order_reservations','trades',
      'asset_balances','wallets','market_prices'
    ])
),
constraint_snapshot AS (
  SELECT jsonb_agg(jsonb_build_object(
    'table', conrelid::regclass::text,
    'name', conname,
    'type', contype,
    'definition', pg_get_constraintdef(oid, true),
    'validated', convalidated,
    'deferrable', condeferrable,
    'initially_deferred', condeferred
  ) ORDER BY conrelid::regclass::text, contype, conname) AS data
  FROM pg_constraint
  WHERE conrelid IN (SELECT oid FROM target_tables)
),
index_snapshot AS (
  SELECT jsonb_agg(jsonb_build_object(
    'table', tablename,
    'name', indexname,
    'definition', indexdef
  ) ORDER BY tablename, indexname) AS data
  FROM pg_indexes
  WHERE schemaname = 'public'
    AND tablename = ANY (ARRAY[
      'orders','conditional_orders','order_reservations','trades',
      'asset_balances','wallets','market_prices'
    ])
),
trigger_snapshot AS (
  SELECT jsonb_agg(jsonb_build_object(
    'table', c.relname,
    'name', t.tgname,
    'definition', pg_get_triggerdef(t.oid, true)
  ) ORDER BY c.relname, t.tgname) AS data
  FROM pg_trigger t
  JOIN pg_class c ON c.oid = t.tgrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND NOT t.tgisinternal
    AND c.relname = ANY (ARRAY[
      'orders','conditional_orders','order_reservations','trades',
      'asset_balances','wallets','market_prices'
    ])
),
policy_snapshot AS (
  SELECT jsonb_agg(jsonb_build_object(
    'table', tablename,
    'name', policyname,
    'roles', roles,
    'command', cmd,
    'using', qual,
    'with_check', with_check
  ) ORDER BY tablename, policyname) AS data
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = ANY (ARRAY[
      'orders','conditional_orders','order_reservations','trades',
      'asset_balances','wallets','market_prices'
    ])
),
table_grant_snapshot AS (
  SELECT jsonb_agg(jsonb_build_object(
    'table', table_name,
    'grantee', grantee,
    'privilege', privilege_type,
    'grantable', is_grantable
  ) ORDER BY table_name, grantee, privilege_type) AS data
  FROM information_schema.role_table_grants
  WHERE table_schema = 'public'
    AND table_name = ANY (ARRAY[
      'orders','conditional_orders','order_reservations','trades',
      'asset_balances','wallets','market_prices'
    ])
),
function_snapshot AS (
  SELECT jsonb_agg(jsonb_build_object(
    'schema', n.nspname,
    'name', p.proname,
    'arguments', pg_get_function_identity_arguments(p.oid),
    'returns', pg_get_function_result(p.oid),
    'language', l.lanname,
    'security_definer', p.prosecdef,
    'volatility', p.provolatile,
    'settings', p.proconfig,
    'owner', pg_get_userbyid(p.proowner),
    'acl', p.proacl::text,
    'anon_execute', has_function_privilege('anon', p.oid, 'EXECUTE'),
    'authenticated_execute', has_function_privilege('authenticated', p.oid, 'EXECUTE'),
    'service_role_execute', has_function_privilege('service_role', p.oid, 'EXECUTE'),
    'definition', pg_get_functiondef(p.oid)
  ) ORDER BY n.nspname, p.proname, pg_get_function_identity_arguments(p.oid)) AS data
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  JOIN pg_language l ON l.oid = p.prolang
  WHERE n.nspname IN ('public','private')
    AND p.proname = ANY (ARRAY[
      'place_stop_limit_order','cancel_stop_limit_order','process_stop_limit_orders',
      'place_limit_order','cancel_limit_order','process_limit_orders',
      'place_conditional_exit_order','cancel_conditional_exit_order',
      'process_conditional_orders','current_account_is_active',
      'guard_active_account_writes'
    ])
),
cron_snapshot AS (
  SELECT jsonb_agg(jsonb_build_object(
    'jobid', jobid,
    'jobname', jobname,
    'schedule', schedule,
    'command', command
  ) ORDER BY jobid) AS data
  FROM cron.job
  WHERE jobname IN ('digiarz-limit-orders','digiarz-stop-limit-orders')
),
rls_snapshot AS (
  SELECT jsonb_agg(jsonb_build_object(
    'table', relname,
    'enabled', relrowsecurity,
    'forced', relforcerowsecurity
  ) ORDER BY relname) AS data
  FROM target_tables
)
SELECT jsonb_pretty(jsonb_build_object(
  'captured_at_utc', timezone('utc', now()),
  'server_version', current_setting('server_version'),
  'columns', COALESCE((SELECT data FROM column_snapshot), '[]'::jsonb),
  'constraints', COALESCE((SELECT data FROM constraint_snapshot), '[]'::jsonb),
  'indexes', COALESCE((SELECT data FROM index_snapshot), '[]'::jsonb),
  'triggers', COALESCE((SELECT data FROM trigger_snapshot), '[]'::jsonb),
  'policies', COALESCE((SELECT data FROM policy_snapshot), '[]'::jsonb),
  'table_grants', COALESCE((SELECT data FROM table_grant_snapshot), '[]'::jsonb),
  'functions', COALESCE((SELECT data FROM function_snapshot), '[]'::jsonb),
  'cron_jobs', COALESCE((SELECT data FROM cron_snapshot), '[]'::jsonb),
  'rls', COALESCE((SELECT data FROM rls_snapshot), '[]'::jsonb)
)) AS schema_fingerprint;

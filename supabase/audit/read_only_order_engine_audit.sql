-- DigiArz: READ-ONLY backend audit
-- This script performs SELECTs only. It does not modify schema, data, grants, or functions.
-- Run in the Supabase SQL Editor and review every result set.

-- 1) Full definitions and security properties of critical RPCs/triggers.
SELECT
  n.nspname AS schema_name,
  p.proname AS function_name,
  pg_get_function_identity_arguments(p.oid) AS identity_arguments,
  pg_get_function_result(p.oid) AS result_type,
  p.prosecdef AS security_definer,
  p.provolatile AS volatility,
  p.proconfig AS function_settings,
  pg_get_userbyid(p.proowner) AS owner_name,
  p.proacl AS function_acl,
  has_function_privilege('anon', p.oid, 'EXECUTE') AS anon_can_execute,
  has_function_privilege('authenticated', p.oid, 'EXECUTE') AS authenticated_can_execute,
  has_function_privilege('service_role', p.oid, 'EXECUTE') AS service_role_can_execute,
  pg_get_functiondef(p.oid) AS full_definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'place_limit_order',
    'cancel_limit_order',
    'process_limit_orders',
    'execute_demo_trade',
    'new_user_setup'
  )
ORDER BY p.proname, pg_get_function_identity_arguments(p.oid);

-- 2) Column contracts for the order, reservation, wallet, and market tables.
SELECT
  c.table_schema,
  c.table_name,
  c.ordinal_position,
  c.column_name,
  c.data_type,
  c.udt_name,
  c.is_nullable,
  c.column_default,
  c.numeric_precision,
  c.numeric_scale
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND c.table_name IN (
    'orders',
    'order_reservations',
    'trades',
    'asset_balances',
    'wallets',
    'transactions',
    'market_prices',
    'demo_trading_pairs'
  )
ORDER BY c.table_name, c.ordinal_position;

-- 3) Primary keys, unique/check constraints, and foreign-key delete behavior.
SELECT
  conrelid::regclass AS table_name,
  conname AS constraint_name,
  contype AS constraint_type,
  pg_get_constraintdef(oid, true) AS definition
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace
  AND conrelid IN (
    SELECT oid FROM pg_class
    WHERE relnamespace = 'public'::regnamespace
      AND relname IN (
        'orders','order_reservations','trades','asset_balances',
        'wallets','transactions','profiles','demo_trading_pairs'
      )
  )
ORDER BY conrelid::regclass::text, contype, conname;

-- 4) Indexes, including uniqueness and partial-index predicates.
SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN (
    'orders','order_reservations','trades','asset_balances',
    'wallets','transactions','profiles','demo_trading_pairs'
  )
ORDER BY tablename, indexname;

-- 5) RLS flags and policies for sensitive tables.
SELECT
  c.relname AS table_name,
  c.relrowsecurity AS rls_enabled,
  c.relforcerowsecurity AS force_rls
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind IN ('r','p')
  AND c.relname IN (
    'orders','order_reservations','trades','asset_balances',
    'wallets','transactions','profiles','demo_trading_pairs'
  )
ORDER BY c.relname;

SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'orders','order_reservations','trades','asset_balances',
    'wallets','transactions','profiles','demo_trading_pairs'
  )
ORDER BY tablename, policyname;

-- 6) Table-level grants on the sensitive tables.
SELECT
  table_schema,
  table_name,
  grantee,
  privilege_type,
  is_grantable
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name IN (
    'orders','order_reservations','trades','asset_balances',
    'wallets','transactions','profiles','demo_trading_pairs'
  )
ORDER BY table_name, grantee, privilege_type;

-- 7) Triggers touching the core order tables and auth signup.
SELECT
  trigger_schema,
  event_object_schema,
  event_object_table,
  trigger_name,
  event_manipulation,
  action_timing,
  action_orientation,
  action_statement
FROM information_schema.triggers
WHERE (event_object_schema = 'public'
       AND event_object_table IN (
         'orders','order_reservations','trades','asset_balances',
         'wallets','transactions','profiles','demo_trading_pairs'
       ))
   OR (event_object_schema = 'auth' AND event_object_table = 'users')
ORDER BY event_object_schema, event_object_table, trigger_name, event_manipulation;

-- 8) All foreign keys referencing auth.users and their ON DELETE actions.
SELECT
  conrelid::regclass AS referencing_table,
  conname AS constraint_name,
  pg_get_constraintdef(oid, true) AS definition
FROM pg_constraint
WHERE contype = 'f'
  AND confrelid = 'auth.users'::regclass
ORDER BY conrelid::regclass::text, conname;

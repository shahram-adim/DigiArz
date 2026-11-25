-- DigiArz SECURITY DEFINER exact-signature catalog contract test
-- Read-only: catalog inspection only; raises on drift. No DDL or privilege changes.
-- Expected values are the read-only Production snapshot dated 2026-11-25.
-- Run only on a dedicated test database with matching role/schema grants.
-- The ephemeral PostgreSQL 17 smoke fixture seeds all 46 signatures/ACLs;
-- 43 are inert metadata-only stubs and are never invoked. Three reviewed
-- SECURITY DEFINER bodies are real; only the read-only report RPC is exercised.
-- This is a CURRENT-STATE regression contract, not a proposed hardening target.

DO $catalog_test$
DECLARE
  unexpected_functions text;
  unsafe_search_paths text;
  public_execute_functions text;
  role_acl_drift text;
  schema_usage_drift text;
BEGIN
  -- Exact inventory: schema + function name + identity argument signature.
  -- This detects new overloads as well as unexpected/missing functions.
  WITH expected(schema_name, function_name, identity_arguments,
                anon_execute, authenticated_execute, service_role_execute) AS (
    VALUES
      ('private', 'admin_adjust_wallet', 'p_user_id uuid, p_currency text, p_direction text, p_amount numeric, p_reason text', false, true, false),
      ('private', 'admin_list_users', '', false, true, false),
      ('private', 'auto_activate_verified_exchange_pairs', '', false, false, false),
      ('private', 'auto_list_verified_exchange_asset', '', false, false, false),
      ('private', 'enforce_unique_admin_market_listing_symbol', '', false, false, false),
      ('private', 'guard_active_account_writes', '', false, false, false),
      ('private', 'is_current_user_super_admin', '', false, true, false),
      ('private', 'is_super_admin', '', false, false, false),
      ('private', 'request_market_price_overflow', '', false, false, false),
      ('public', 'admin_add_market_listing', 'p_coingecko_id text', false, true, true),
      ('public', 'admin_disable_market_pair', 'p_coingecko_id text, p_reason text', false, true, true),
      ('public', 'admin_enable_market_pair', 'p_coingecko_id text', false, true, true),
      ('public', 'admin_exchange_asset_sync_report', '', false, true, true),
      ('public', 'admin_remove_market_listing', 'p_coingecko_id text', false, true, true),
      ('public', 'admin_request_exchange_asset_sync', '', false, true, true),
      ('public', 'admin_review_market_listings', '', false, true, true),
      ('public', 'admin_search_market_assets', 'p_search text, p_limit integer', false, true, true),
      ('public', 'cancel_conditional_exit_order', 'p_order_id uuid', false, true, true),
      ('public', 'cancel_limit_order', 'p_order_id uuid', false, true, true),
      ('public', 'cancel_stop_limit_order', 'p_order_id uuid', false, true, true),
      ('public', 'claim_admin_asset_refresh', 'p_coingecko_id text, p_admin_user_id uuid', false, false, true),
      ('public', 'current_account_is_active', '', false, true, true),
      ('public', 'deactivate_my_account', '', false, true, true),
      ('public', 'execute_demo_trade', 'p_symbol text, p_side text, p_amount numeric, p_price numeric', false, true, true),
      ('public', 'get_admin_market_listings', '', true, true, true),
      ('public', 'get_demo_trading_fee_rate', 'p_quote_asset text, p_liquidity_type text', false, true, true),
      ('public', 'get_exchange_discovered_market_assets', '', true, true, true),
      ('public', 'get_my_order_reservations', 'p_order_ids uuid[]', false, true, true),
      ('public', 'new_user_setup', '', false, false, true),
      ('public', 'place_conditional_exit_order', 'p_symbol text, p_order_kind text, p_amount numeric, p_trigger_price numeric', false, true, true),
      ('public', 'place_limit_order', 'p_symbol text, p_side text, p_amount numeric, p_limit_price numeric', false, true, true),
      ('public', 'place_stop_limit_order', 'p_symbol text, p_side text, p_amount numeric, p_stop_price numeric, p_limit_price numeric', false, true, true),
      ('public', 'process_bit24_exchange_sync', '', false, false, true),
      ('public', 'process_conditional_orders', '', false, false, true),
      ('public', 'process_iran_exchange_asset_sync', '', false, false, true),
      ('public', 'process_limit_orders', '', false, false, true),
      ('public', 'process_stop_limit_orders', '', false, false, true),
      ('public', 'reactivate_my_account', '', false, true, true),
      ('public', 'recover_stale_crypto_assets_sync', '', false, false, true),
      ('public', 'refresh_crypto_assets', '', false, false, true),
      ('public', 'refresh_crypto_assets_toman', '', false, false, true),
      ('public', 'refresh_market_fx_rate', '', false, false, true),
      ('public', 'refresh_market_prices', '', false, false, false),
      ('public', 'request_bit24_exchange_sync', '', false, false, true),
      ('public', 'request_iran_exchange_asset_sync', '', false, false, true),
      ('public', 'request_market_price_refresh', '', false, true, true)
  ),
  actual AS (
    SELECT n.nspname AS schema_name,
           p.proname AS function_name,
           pg_get_function_identity_arguments(p.oid) AS identity_arguments,
           has_function_privilege('anon', p.oid, 'EXECUTE') AS anon_execute,
           has_function_privilege('authenticated', p.oid, 'EXECUTE') AS authenticated_execute,
           has_function_privilege('service_role', p.oid, 'EXECUTE') AS service_role_execute
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname IN ('public','private') AND p.prosecdef
  )
  SELECT string_agg(
    format('%I.%I(%s)', d.schema_name, d.function_name, d.identity_arguments),
    ', ' ORDER BY d.schema_name, d.function_name, d.identity_arguments
  )
  INTO unexpected_functions
  FROM (
    (SELECT * FROM actual EXCEPT SELECT * FROM expected)
    UNION ALL
    (SELECT * FROM expected EXCEPT SELECT * FROM actual)
  ) AS d;

  IF unexpected_functions IS NOT NULL THEN
    RAISE EXCEPTION 'Exact SECURITY DEFINER signature/role ACL drift: %', unexpected_functions;
  END IF;

  SELECT string_agg(
    format('%I.%I(%s)', n.nspname, p.proname,
           pg_get_function_identity_arguments(p.oid)),
    ', ' ORDER BY n.nspname,p.proname,pg_get_function_identity_arguments(p.oid)
  )
  INTO unsafe_search_paths
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname IN ('public','private')
    AND p.prosecdef
    AND NOT (
      COALESCE(p.proconfig, ARRAY[]::text[]) @> ARRAY['search_path=""']
      OR COALESCE(p.proconfig, ARRAY[]::text[]) @> ARRAY['search_path=pg_catalog']
    );

  IF unsafe_search_paths IS NOT NULL THEN
    RAISE EXCEPTION 'SECURITY DEFINER function(s) missing constrained search_path: %',
      unsafe_search_paths;
  END IF;

  SELECT string_agg(
    format('%I.%I(%s)', n.nspname, p.proname,
           pg_get_function_identity_arguments(p.oid)),
    ', ' ORDER BY n.nspname,p.proname,pg_get_function_identity_arguments(p.oid)
  )
  INTO public_execute_functions
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname IN ('public','private')
    AND p.prosecdef
    AND EXISTS (
      SELECT 1 FROM aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) a
      WHERE a.grantee=0 AND a.privilege_type='EXECUTE'
    );

  IF public_execute_functions IS NOT NULL THEN
    RAISE EXCEPTION 'SECURITY DEFINER function(s) grant EXECUTE to PUBLIC: %',
      public_execute_functions;
  END IF;

  -- Schema USAGE is a separate reachability dimension from function EXECUTE.
  WITH expected(schema_name, role_name, can_use) AS (
    VALUES
      ('public','anon',true),
      ('public','authenticated',true),
      ('public','service_role',true),
      ('private','anon',false),
      ('private','authenticated',true),
      ('private','service_role',false)
  )
  SELECT string_agg(
    schema_name || '/' || role_name || ': expected=' || can_use ||
    ', actual=' || has_schema_privilege(role_name,schema_name,'USAGE'),
    '; ' ORDER BY schema_name,role_name
  )
  INTO schema_usage_drift
  FROM expected
  WHERE has_schema_privilege(role_name,schema_name,'USAGE') IS DISTINCT FROM can_use;

  IF schema_usage_drift IS NOT NULL THEN
    RAISE EXCEPTION 'Schema USAGE contract drift: %', schema_usage_drift;
  END IF;

  RAISE NOTICE 'PASS: exact SECURITY DEFINER signatures, effective role ACLs, constrained search_path, PUBLIC EXECUTE, and schema USAGE match the reviewed current-state snapshot';
END
$catalog_test$;

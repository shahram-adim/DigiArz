-- DigiArz SECURITY DEFINER catalog contract test
-- Read-only: this script inspects PostgreSQL catalogs and raises on drift.
-- Expected baseline: Production catalog audit 2026-11-25.
-- Run only against a dedicated test database whose grants/schema usage mirror Production.

DO $catalog_test$
DECLARE
  unexpected_functions text;
  overloaded_functions text;
  unsafe_search_paths text;
  public_execute_functions text;
  unexpected_anon text;
  unexpected_authenticated text;
  missing_anon text;
  missing_authenticated text;
  schema_usage_drift text;
  unexpected_service_role text;
  missing_service_role text;
BEGIN
  SELECT string_agg(format('%I.%I(%s)', n.nspname, p.proname,
                           pg_get_function_identity_arguments(p.oid)), ', ')
    INTO unexpected_functions
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname IN ('public','private')
    AND p.prosecdef
    AND NOT (
      (n.nspname = 'private' AND p.proname IN (
        'admin_adjust_wallet','admin_list_users','auto_activate_verified_exchange_pairs',
        'auto_list_verified_exchange_asset','enforce_unique_admin_market_listing_symbol',
        'guard_active_account_writes','is_current_user_super_admin','is_super_admin',
        'request_market_price_overflow'
      ))
      OR
      (n.nspname = 'public' AND p.proname IN (
        'admin_add_market_listing','admin_disable_market_pair','admin_enable_market_pair',
        'admin_exchange_asset_sync_report','admin_remove_market_listing',
        'admin_request_exchange_asset_sync','admin_review_market_listings',
        'admin_search_market_assets','cancel_conditional_exit_order','cancel_limit_order',
        'cancel_stop_limit_order','claim_admin_asset_refresh','current_account_is_active',
        'deactivate_my_account','execute_demo_trade','get_admin_market_listings',
        'get_demo_trading_fee_rate','get_exchange_discovered_market_assets',
        'get_my_order_reservations','new_user_setup','place_conditional_exit_order',
        'place_limit_order','place_stop_limit_order','process_bit24_exchange_sync',
        'process_conditional_orders','process_iran_exchange_asset_sync',
        'process_limit_orders','process_stop_limit_orders','reactivate_my_account',
        'recover_stale_crypto_assets_sync','refresh_crypto_assets',
        'refresh_crypto_assets_toman','refresh_market_fx_rate','refresh_market_prices',
        'request_bit24_exchange_sync','request_iran_exchange_asset_sync',
        'request_market_price_refresh'
      ))
    );

  IF unexpected_functions IS NOT NULL THEN
    RAISE EXCEPTION 'Unreviewed SECURITY DEFINER function(s): %', unexpected_functions;
  END IF;

  SELECT string_agg(format('%I.%I has %s overloads',
                                overloads.nspname, overloads.proname,
                                overloads.overload_count), ', ')
    INTO overloaded_functions
  FROM (
    SELECT n.nspname, p.proname, count(*) AS overload_count
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('public','private') AND p.prosecdef
    GROUP BY n.nspname, p.proname
    HAVING count(*) > 1
  ) AS overloads;

  IF overloaded_functions IS NOT NULL THEN
    RAISE EXCEPTION 'SECURITY DEFINER overloads require explicit signature review: %', overloaded_functions;
  END IF;

  SELECT string_agg(format('%I.%I(%s)', n.nspname, p.proname,
                           pg_get_function_identity_arguments(p.oid)), ', ')
    INTO unsafe_search_paths
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname IN ('public','private')
    AND p.prosecdef
    AND NOT (
      COALESCE(p.proconfig, ARRAY[]::text[]) @> ARRAY['search_path=""']
      OR COALESCE(p.proconfig, ARRAY[]::text[]) @> ARRAY['search_path=pg_catalog']
    );

  IF unsafe_search_paths IS NOT NULL THEN
    RAISE EXCEPTION 'SECURITY DEFINER function(s) missing empty search_path: %', unsafe_search_paths;
  END IF;

  SELECT string_agg(format('%I.%I(%s)', n.nspname, p.proname,
                           pg_get_function_identity_arguments(p.oid)), ', ')
    INTO public_execute_functions
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname IN ('public','private')
    AND p.prosecdef
    AND EXISTS (
      SELECT 1
      FROM aclexplode(COALESCE(p.proacl, acldefault('f', p.proowner))) a
      WHERE a.grantee = 0 AND a.privilege_type = 'EXECUTE'
    );

  IF public_execute_functions IS NOT NULL THEN
    RAISE EXCEPTION 'SECURITY DEFINER function(s) grant EXECUTE to PUBLIC: %', public_execute_functions;
  END IF;

  -- Exact anon EXECUTE allowlist: public market metadata only.
  WITH expected(schema_name, function_name) AS (
    VALUES ('public','get_admin_market_listings'),
           ('public','get_exchange_discovered_market_assets')
  ),
  actual AS (
    SELECT n.nspname, p.proname
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('public','private')
      AND p.prosecdef
      AND has_function_privilege('anon', p.oid, 'EXECUTE')
  )
  SELECT
    (SELECT string_agg(schema_name || '.' || function_name, ', ')
       FROM (SELECT * FROM actual EXCEPT SELECT * FROM expected) x),
    (SELECT string_agg(schema_name || '.' || function_name, ', ')
       FROM (SELECT * FROM expected EXCEPT SELECT * FROM actual) x)
  INTO unexpected_anon, missing_anon;

  IF unexpected_anon IS NOT NULL OR missing_anon IS NOT NULL THEN
    RAISE EXCEPTION 'anon SECURITY DEFINER allowlist drift; unexpected=[%], missing=[%]',
      COALESCE(unexpected_anon,''), COALESCE(missing_anon,'');
  END IF;

  -- Exact authenticated EXECUTE allowlist from the reviewed Production baseline.
  WITH expected(schema_name, function_name) AS (
    VALUES
      ('private','admin_adjust_wallet'),('private','admin_list_users'),
      ('private','is_current_user_super_admin'),
      ('public','admin_add_market_listing'),('public','admin_disable_market_pair'),
      ('public','admin_enable_market_pair'),('public','admin_exchange_asset_sync_report'),
      ('public','admin_remove_market_listing'),('public','admin_request_exchange_asset_sync'),
      ('public','admin_review_market_listings'),('public','admin_search_market_assets'),
      ('public','cancel_conditional_exit_order'),('public','cancel_limit_order'),
      ('public','cancel_stop_limit_order'),('public','current_account_is_active'),
      ('public','deactivate_my_account'),('public','execute_demo_trade'),
      ('public','get_admin_market_listings'),('public','get_demo_trading_fee_rate'),
      ('public','get_exchange_discovered_market_assets'),('public','get_my_order_reservations'),
      ('public','place_conditional_exit_order'),('public','place_limit_order'),
      ('public','place_stop_limit_order'),('public','reactivate_my_account'),
      ('public','request_market_price_refresh')
  ),
  actual AS (
    SELECT n.nspname, p.proname
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('public','private')
      AND p.prosecdef
      AND has_function_privilege('authenticated', p.oid, 'EXECUTE')
  )
  SELECT
    (SELECT string_agg(schema_name || '.' || function_name, ', ')
       FROM (SELECT * FROM actual EXCEPT SELECT * FROM expected) x),
    (SELECT string_agg(schema_name || '.' || function_name, ', ')
       FROM (SELECT * FROM expected EXCEPT SELECT * FROM actual) x)
  INTO unexpected_authenticated, missing_authenticated;

  IF unexpected_authenticated IS NOT NULL OR missing_authenticated IS NOT NULL THEN
    RAISE EXCEPTION 'authenticated SECURITY DEFINER allowlist drift; unexpected=[%], missing=[%]',
      COALESCE(unexpected_authenticated,''), COALESCE(missing_authenticated,'');
  END IF;

  -- Exact schema USAGE contract is part of effective API reachability.
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
           ', actual=' || has_schema_privilege(role_name, schema_name, 'USAGE'),
           '; ' ORDER BY schema_name, role_name
         )
    INTO schema_usage_drift
  FROM expected
  WHERE has_schema_privilege(role_name, schema_name, 'USAGE') IS DISTINCT FROM can_use;

  IF schema_usage_drift IS NOT NULL THEN
    RAISE EXCEPTION 'Schema USAGE contract drift: %', schema_usage_drift;
  END IF;

  -- service_role is a trusted backend identity, but its function ACL must
  -- still be explicit and reviewed; it is not interchangeable with PUBLIC.
  WITH expected(schema_name, function_name) AS (
    VALUES
      ('public','admin_add_market_listing'),
      ('public','admin_disable_market_pair'),
      ('public','admin_enable_market_pair'),
      ('public','admin_exchange_asset_sync_report'),
      ('public','admin_remove_market_listing'),
      ('public','admin_request_exchange_asset_sync'),
      ('public','admin_review_market_listings'),
      ('public','admin_search_market_assets'),
      ('public','cancel_conditional_exit_order'),
      ('public','cancel_limit_order'),
      ('public','cancel_stop_limit_order'),
      ('public','claim_admin_asset_refresh'),
      ('public','current_account_is_active'),
      ('public','deactivate_my_account'),
      ('public','execute_demo_trade'),
      ('public','get_admin_market_listings'),
      ('public','get_demo_trading_fee_rate'),
      ('public','get_exchange_discovered_market_assets'),
      ('public','get_my_order_reservations'),
      ('public','new_user_setup'),
      ('public','place_conditional_exit_order'),
      ('public','place_limit_order'),
      ('public','place_stop_limit_order'),
      ('public','process_bit24_exchange_sync'),
      ('public','process_conditional_orders'),
      ('public','process_iran_exchange_asset_sync'),
      ('public','process_limit_orders'),
      ('public','process_stop_limit_orders'),
      ('public','reactivate_my_account'),
      ('public','recover_stale_crypto_assets_sync'),
      ('public','refresh_crypto_assets'),
      ('public','refresh_crypto_assets_toman'),
      ('public','refresh_market_fx_rate'),
      ('public','request_bit24_exchange_sync'),
      ('public','request_iran_exchange_asset_sync'),
      ('public','request_market_price_refresh')
  ),
  actual AS (
    SELECT n.nspname, p.proname
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('public','private')
      AND p.prosecdef
      AND has_function_privilege('service_role', p.oid, 'EXECUTE')
  )
  SELECT
    (SELECT string_agg(schema_name || '.' || function_name, ', ')
       FROM (SELECT * FROM actual EXCEPT SELECT * FROM expected) x),
    (SELECT string_agg(schema_name || '.' || function_name, ', ')
       FROM (SELECT * FROM expected EXCEPT SELECT * FROM actual) x)
  INTO unexpected_service_role, missing_service_role;

  IF unexpected_service_role IS NOT NULL OR missing_service_role IS NOT NULL THEN
    RAISE EXCEPTION 'service_role SECURITY DEFINER allowlist drift; unexpected=[%], missing=[%]',
      COALESCE(unexpected_service_role,''), COALESCE(missing_service_role,'');
  END IF;

  RAISE NOTICE 'PASS: SECURITY DEFINER inventory, search_path, PUBLIC revoke, schema USAGE, and anon/authenticated/service_role allowlists match reviewed baseline';
END
$catalog_test$;

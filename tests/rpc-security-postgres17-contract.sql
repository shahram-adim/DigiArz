-- Contract checks for the disposable PostgreSQL 17 RPC fixture only.
-- This is not the 46-signature Production catalog regression test.
\set ON_ERROR_STOP on

DO $contract$
DECLARE
  fn oid;
  cfg text[];
BEGIN
  SELECT p.oid, p.proconfig
    INTO fn, cfg
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'admin_exchange_asset_sync_report'
    AND pg_get_function_identity_arguments(p.oid) = '';

  IF fn IS NULL THEN
    RAISE EXCEPTION 'Expected exact function public.admin_exchange_asset_sync_report() is missing';
  END IF;

  IF NOT (SELECT prosecdef FROM pg_proc WHERE oid = fn) THEN
    RAISE EXCEPTION 'Expected SECURITY DEFINER function';
  END IF;

  IF NOT COALESCE(cfg @> ARRAY['search_path=""'], false) THEN
    RAISE EXCEPTION 'Expected constrained empty search_path; actual proconfig=%', cfg;
  END IF;

  IF has_function_privilege('anon', fn, 'EXECUTE') THEN
    RAISE EXCEPTION 'anon must not have EXECUTE in the fixture ACL';
  END IF;

  IF NOT has_function_privilege('authenticated', fn, 'EXECUTE') THEN
    RAISE EXCEPTION 'authenticated must have EXECUTE so function-body authorization can be tested';
  END IF;

  IF NOT has_function_privilege('service_role', fn, 'EXECUTE') THEN
    RAISE EXCEPTION 'service_role current-state fixture grant is missing';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM aclexplode(COALESCE((SELECT proacl FROM pg_proc WHERE oid=fn),
                             acldefault('f', (SELECT proowner FROM pg_proc WHERE oid=fn)))) a
    WHERE a.grantee = 0 AND a.privilege_type = 'EXECUTE'
  ) THEN
    RAISE EXCEPTION 'PUBLIC must not have direct EXECUTE on the fixture function';
  END IF;

  RAISE NOTICE 'PASS: PostgreSQL 17 fixture exact signature, SECURITY DEFINER, search_path and role ACL contract';
END
$contract$;

 
DO $claim_contract$
DECLARE
  fn oid;
BEGIN
  SELECT p.oid INTO fn
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.proname='claim_admin_asset_refresh'
    AND pg_get_function_identity_arguments(p.oid)='p_coingecko_id text, p_admin_user_id uuid';

  IF fn IS NULL THEN
    RAISE EXCEPTION 'Exact claim_admin_asset_refresh(text, uuid) is missing';
  END IF;
  IF pg_get_function_result(fn) <> 'boolean' THEN
    RAISE EXCEPTION 'claim_admin_asset_refresh must return boolean; got %', pg_get_function_result(fn);
  END IF;
  IF NOT (SELECT prosecdef FROM pg_proc WHERE oid=fn) THEN
    RAISE EXCEPTION 'claim_admin_asset_refresh must be SECURITY DEFINER';
  END IF;
  IF NOT COALESCE((SELECT proconfig @> ARRAY['search_path=""'] FROM pg_proc WHERE oid=fn),false) THEN
    RAISE EXCEPTION 'claim_admin_asset_refresh must have empty search_path';
  END IF;
  IF has_function_privilege('anon',fn,'EXECUTE')
     OR has_function_privilege('authenticated',fn,'EXECUTE') THEN
    RAISE EXCEPTION 'claim_admin_asset_refresh must not be executable by anon/authenticated';
  END IF;
  IF NOT has_function_privilege('service_role',fn,'EXECUTE') THEN
    RAISE EXCEPTION 'claim_admin_asset_refresh service_role grant is required for the verified Edge Function caller';
  END IF;
  RAISE NOTICE 'PASS: claim_admin_asset_refresh exact return type, SECURITY DEFINER, search_path and function-specific service_role ACL';
END
$claim_contract$;


DO $market_listings_contract$
DECLARE
  fn oid;
  result_type text;
BEGIN
  SELECT p.oid INTO fn
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='get_admin_market_listings'
    AND pg_get_function_identity_arguments(p.oid)='';
  IF fn IS NULL THEN RAISE EXCEPTION 'get_admin_market_listings() missing'; END IF;
  SELECT pg_get_function_result(fn) INTO result_type;
  IF result_type <> 'TABLE(coingecko_id text, symbol text, name text, image_url text, market_cap_rank integer, current_price_usd numeric, price_toman numeric, price_change_percentage_24h numeric, total_volume_usd numeric, last_updated timestamp with time zone, added_at timestamp with time zone)' THEN
    RAISE EXCEPTION 'Unexpected get_admin_market_listings return shape: %', result_type;
  END IF;
  IF NOT (SELECT prosecdef AND provolatile='s' FROM pg_proc WHERE oid=fn) THEN
    RAISE EXCEPTION 'get_admin_market_listings must be STABLE SECURITY DEFINER';
  END IF;
  IF NOT COALESCE((SELECT proconfig @> ARRAY['search_path=""'] FROM pg_proc WHERE oid=fn),false) THEN
    RAISE EXCEPTION 'get_admin_market_listings must have empty search_path';
  END IF;
  IF has_function_privilege('anon',fn,'EXECUTE') IS NOT TRUE
     OR has_function_privilege('authenticated',fn,'EXECUTE') IS NOT TRUE
     OR has_function_privilege('service_role',fn,'EXECUTE') IS NOT TRUE THEN
    RAISE EXCEPTION 'get_admin_market_listings current API-role ACL mismatch';
  END IF;
  RAISE NOTICE 'PASS: get_admin_market_listings exact TABLE return shape, STABLE, SECURITY DEFINER, empty search_path and current effective API ACL';
END
$market_listings_contract$;


DO $admin_search_contract$
DECLARE
  fn oid;
  result_type text;
BEGIN
  fn := 'public.admin_search_market_assets(text,integer)'::regprocedure;
  SELECT pg_get_function_result(fn) INTO result_type;
  IF result_type <> 'TABLE(coingecko_id text, symbol text, name text, image_url text, market_cap_rank integer, current_price_usd numeric, last_updated timestamp with time zone)' THEN
    RAISE EXCEPTION 'Unexpected admin_search_market_assets return shape: %', result_type;
  END IF;
  IF NOT (SELECT prosecdef AND provolatile='s' AND proowner='postgres'::regrole FROM pg_proc WHERE oid=fn) THEN
    RAISE EXCEPTION 'admin_search_market_assets owner/volatility/SECURITY DEFINER mismatch';
  END IF;
  IF NOT COALESCE((SELECT proconfig @> ARRAY['search_path=""'] FROM pg_proc WHERE oid=fn),false) THEN
    RAISE EXCEPTION 'admin_search_market_assets must have empty search_path';
  END IF;
  IF has_function_privilege('anon',fn,'EXECUTE')
     OR NOT has_function_privilege('authenticated',fn,'EXECUTE')
     OR NOT has_function_privilege('service_role',fn,'EXECUTE') THEN
    RAISE EXCEPTION 'admin_search_market_assets effective API ACL mismatch';
  END IF;
  IF EXISTS (
    SELECT 1 FROM aclexplode(COALESCE((SELECT proacl FROM pg_proc WHERE oid=fn),
                                    acldefault('f',(SELECT proowner FROM pg_proc WHERE oid=fn)))) a
    WHERE a.grantee=0 AND a.privilege_type='EXECUTE'
  ) THEN
    RAISE EXCEPTION 'PUBLIC must not execute admin_search_market_assets';
  END IF;
  IF NOT (SELECT relrowsecurity AND NOT relforcerowsecurity
          FROM pg_class WHERE oid='public.crypto_assets'::regclass) THEN
    RAISE EXCEPTION 'crypto_assets RLS flags mismatch';
  END IF;
  IF NOT (SELECT relrowsecurity AND NOT relforcerowsecurity
          FROM pg_class WHERE oid='private.admin_users'::regclass) THEN
    RAISE EXCEPTION 'private.admin_users RLS flags mismatch';
  END IF;
  IF has_table_privilege('anon','private.admin_users','SELECT')
     OR has_table_privilege('authenticated','private.admin_users','SELECT')
     OR has_table_privilege('service_role','private.admin_users','SELECT') THEN
    RAISE EXCEPTION 'private.admin_users must not be directly readable by API roles';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='crypto_assets'
      AND policyname='crypto_assets_public_read' AND cmd='SELECT'
      AND roles @> ARRAY['anon','authenticated']::name[] AND qual='true'
  ) THEN
    RAISE EXCEPTION 'crypto_assets_public_read policy does not match Production';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='private' AND tablename='admin_users'
  ) THEN
    RAISE EXCEPTION 'private.admin_users unexpectedly has an RLS policy';
  END IF;
  RAISE NOTICE 'PASS: admin_search_market_assets live return shape, owner, volatility, path, ACL and dependency RLS';
END
$admin_search_contract$;


DO $exchange_discovery_shared_contract$
DECLARE
  fn oid;
  result_type text;
BEGIN
  SELECT p.oid INTO fn
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='get_exchange_discovered_market_assets'
    AND pg_get_function_identity_arguments(p.oid)='';
  IF fn IS NULL THEN RAISE EXCEPTION 'get_exchange_discovered_market_assets() missing'; END IF;
  SELECT pg_get_function_result(fn) INTO result_type;
  IF result_type <> 'TABLE(symbol text, name text, current_price_usd numeric, last_updated timestamp with time zone, exchange_sources text, exchange_count integer, observed_at timestamp with time zone, match_status text)' THEN
    RAISE EXCEPTION 'Unexpected exchange discovery return shape: %',result_type;
  END IF;
  IF NOT (SELECT prosecdef AND provolatile='s' FROM pg_proc WHERE oid=fn) THEN
    RAISE EXCEPTION 'Exchange discovery must be STABLE SECURITY DEFINER';
  END IF;
  IF NOT COALESCE((SELECT proconfig @> ARRAY['search_path=""'] FROM pg_proc WHERE oid=fn),false) THEN
    RAISE EXCEPTION 'Exchange discovery must have empty search_path';
  END IF;
  IF (SELECT rolname FROM pg_roles WHERE oid=(SELECT proowner FROM pg_proc WHERE oid=fn)) <> 'postgres' THEN
    RAISE EXCEPTION 'Expected postgres owner in disposable fixture';
  END IF;
  IF NOT has_function_privilege('anon',fn,'EXECUTE')
     OR NOT has_function_privilege('authenticated',fn,'EXECUTE')
     OR NOT has_function_privilege('service_role',fn,'EXECUTE') THEN
    RAISE EXCEPTION 'Shared fixture API-role ACL does not match reviewed current catalog snapshot';
  END IF;
  IF EXISTS (
    SELECT 1 FROM aclexplode(COALESCE((SELECT proacl FROM pg_proc WHERE oid=fn),
                                     acldefault('f',(SELECT proowner FROM pg_proc WHERE oid=fn)))) a
    WHERE a.grantee=0 AND a.privilege_type='EXECUTE'
  ) THEN
    RAISE EXCEPTION 'PUBLIC must not have EXECUTE on exchange discovery';
  END IF;
  IF EXISTS (
    SELECT 1 FROM unnest(ARRAY[
      'public.exchange_asset_observations'::regclass,
      'public.admin_market_listings'::regclass,
      'public.crypto_assets'::regclass,
      'public.demo_trading_pairs'::regclass,
      'public.market_prices'::regclass
    ]) AS t(relid)
    WHERE NOT (SELECT relrowsecurity FROM pg_class WHERE oid=t.relid)
  ) THEN
    RAISE EXCEPTION 'All exchange discovery dependencies must have RLS enabled in the disposable fixture';
  END IF;
  RAISE NOTICE 'PASS: exact exchange discovery return shape, volatility, definer, path, owner, ACL and dependency RLS';
END
$exchange_discovery_shared_contract$;

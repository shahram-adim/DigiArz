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

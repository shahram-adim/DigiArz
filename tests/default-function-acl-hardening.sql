-- DigiArz future-function EXECUTE default hardening contract
-- READ-ONLY catalog assertion; no DDL, GRANT, REVOKE, or object creation.
-- This test is expected to FAIL on the current Production baseline until an
-- approved hardening migration has been separately reviewed and applied to an
-- isolated clone. Do not enable in the current CI job before that point.
--
-- Target contract:
--   * postgres-created functions do not inherit EXECUTE from PUBLIC globally.
--   * postgres-created public functions do not inherit direct EXECUTE for
--     anon/authenticated from schema-specific defaults.
--   * service_role retains its explicit schema-specific default EXECUTE grant.
--   * supabase_admin is deliberately not altered by this contract.

DO $default_function_acl$
DECLARE
  postgres_oid oid;
  anon_oid oid;
  authenticated_oid oid;
  service_role_oid oid;
  public_oid oid;
  global_acl aclitem[];
  schema_acl aclitem[];
BEGIN
  SELECT oid INTO postgres_oid FROM pg_roles WHERE rolname='postgres';
  SELECT oid INTO anon_oid FROM pg_roles WHERE rolname='anon';
  SELECT oid INTO authenticated_oid FROM pg_roles WHERE rolname='authenticated';
  SELECT oid INTO service_role_oid FROM pg_roles WHERE rolname='service_role';
  SELECT oid INTO public_oid FROM pg_namespace WHERE nspname='public';

  IF postgres_oid IS NULL OR anon_oid IS NULL OR authenticated_oid IS NULL
     OR service_role_oid IS NULL OR public_oid IS NULL THEN
    RAISE EXCEPTION 'Required Supabase roles/schema are missing';
  END IF;

  -- Global default ACL row (defaclnamespace=0) overrides PostgreSQL's
  -- built-in PUBLIC EXECUTE default for functions created by postgres.
  SELECT d.defaclacl INTO global_acl
  FROM pg_default_acl d
  WHERE d.defaclrole=postgres_oid
    AND d.defaclnamespace=0
    AND d.defaclobjtype='f';

  IF global_acl IS NULL THEN
    global_acl := acldefault('f',postgres_oid);
  END IF;

  IF EXISTS (
    SELECT 1
    FROM aclexplode(global_acl) a
    WHERE a.grantee=0 AND a.privilege_type='EXECUTE'
  ) THEN
    RAISE EXCEPTION 'postgres global function default still grants EXECUTE to PUBLIC';
  END IF;

  -- Schema-specific default ACL is additive to the global default.
  SELECT d.defaclacl INTO schema_acl
  FROM pg_default_acl d
  WHERE d.defaclrole=postgres_oid
    AND d.defaclnamespace=public_oid
    AND d.defaclobjtype='f';

  IF schema_acl IS NOT NULL AND EXISTS (
    SELECT 1
    FROM aclexplode(schema_acl) a
    WHERE a.grantee IN (anon_oid,authenticated_oid)
      AND a.privilege_type='EXECUTE'
  ) THEN
    RAISE EXCEPTION 'postgres public-schema function defaults still grant EXECUTE directly to anon/authenticated';
  END IF;

  IF schema_acl IS NULL OR NOT EXISTS (
    SELECT 1
    FROM aclexplode(schema_acl) a
    WHERE a.grantee=service_role_oid
      AND a.privilege_type='EXECUTE'
  ) THEN
    RAISE EXCEPTION 'postgres public-schema function default no longer grants EXECUTE to service_role';
  END IF;

  RAISE NOTICE 'PASS: postgres future-function defaults deny PUBLIC/anon/authenticated and preserve service_role';
END
$default_function_acl$;

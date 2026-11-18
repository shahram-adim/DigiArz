DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='service_role') THEN
    CREATE ROLE service_role NOLOGIN BYPASSRLS;
  END IF;
END;
$roles$;

CREATE SCHEMA IF NOT EXISTS auth;
CREATE TABLE IF NOT EXISTS auth.users (id uuid PRIMARY KEY);

CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path TO ''
AS $function$
  SELECT nullif(current_setting('request.jwt.claim.sub',true),'')::uuid;
$function$;

GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated;

-- A pre-existing role may have been created without BYPASSRLS by a test
-- helper. Normalize the disposable trusted-worker role explicitly.
ALTER ROLE service_role NOLOGIN BYPASSRLS;

DO $trusted_role$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_roles
    WHERE rolname='service_role' AND rolbypassrls AND NOT rolcanlogin
  ) THEN
    RAISE EXCEPTION 'Disposable service_role must be NOLOGIN BYPASSRLS';
  END IF;
END;
$trusted_role$;

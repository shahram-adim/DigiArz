-- DigiArz isolated RPC authorization test
-- READ-ONLY FUNCTION UNDER TEST: public.admin_exchange_asset_sync_report()
-- All grants are transaction-scoped and rolled back at the end.
-- No user, wallet, order, queue, Cron, or migration rows are written.

BEGIN;

-- The current isolated test project does not grant public-schema USAGE to API roles.
-- Add only the minimum temporary access needed to exercise the function-body guard.
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_exchange_asset_sync_report() TO anon, authenticated;

-- 1) Anonymous caller must be rejected by the server-side super-admin guard.
SELECT set_config('request.jwt.claim.sub', '', true);
SELECT set_config('request.jwt.claim.role', 'anon', true);
SELECT set_config('request.jwt.claims', '{"role":"anon"}', true);
SET LOCAL ROLE anon;

DO $anon_test$
BEGIN
  PERFORM public.admin_exchange_asset_sync_report();
  RAISE EXCEPTION 'FAIL: anon unexpectedly passed the admin RPC guard';
EXCEPTION
  WHEN SQLSTATE '42501' THEN
    RAISE NOTICE 'PASS: anon rejected with insufficient_privilege (42501)';
END
$anon_test$;

RESET ROLE;

-- 2) An ordinary authenticated identity must also be rejected.
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SELECT set_config(
  'request.jwt.claims',
  '{"role":"authenticated","sub":"11111111-1111-4111-8111-111111111111"}',
  true
);
SET LOCAL ROLE authenticated;

DO $user_test$
BEGIN
  PERFORM public.admin_exchange_asset_sync_report();
  RAISE EXCEPTION 'FAIL: ordinary authenticated user unexpectedly passed the admin RPC guard';
EXCEPTION
  WHEN SQLSTATE '42501' THEN
    RAISE NOTICE 'PASS: ordinary authenticated user rejected with insufficient_privilege (42501)';
END
$user_test$;

RESET ROLE;

-- 3) A seeded super-admin identity must be accepted by the same read-only RPC.
-- The test database must contain exactly one designated test super-admin.
DO $seed_test$
BEGIN
  IF (SELECT count(*) FROM private.admin_users WHERE role = 'super_admin') <> 1 THEN
    RAISE EXCEPTION 'Test fixture error: expected exactly one private.admin_users super_admin row';
  END IF;
END
$seed_test$;

SELECT set_config(
  'request.jwt.claim.sub',
  (SELECT user_id::text FROM private.admin_users WHERE role = 'super_admin' LIMIT 1),
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SELECT set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'role', 'authenticated',
    'sub', (SELECT user_id::text FROM private.admin_users WHERE role = 'super_admin' LIMIT 1)
  )::text,
  true
);
SET LOCAL ROLE authenticated;

DO $admin_test$
DECLARE
  report jsonb;
BEGIN
  report := public.admin_exchange_asset_sync_report();
  IF jsonb_typeof(report) <> 'object' THEN
    RAISE EXCEPTION 'FAIL: super-admin RPC returned an unexpected result type';
  END IF;
  RAISE NOTICE 'PASS: designated super-admin accepted by read-only admin RPC';
END
$admin_test$;

ROLLBACK;

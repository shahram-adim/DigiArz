-- Source-faithful behavior test for public.claim_admin_asset_refresh(text, uuid).
-- Uses only the synthetic super-admin identity and synthetic asset key.
-- No external API, Edge Function, market refresh, or persistent database is used.
\set ON_ERROR_STOP on

BEGIN;
SET LOCAL ROLE service_role;

DO $claim_test$
DECLARE
  v_result boolean;
BEGIN
  -- Positive path: the verified synthetic super-admin may claim a synthetic asset.
  v_result := public.claim_admin_asset_refresh(
    'ci-synthetic-asset-claim',
    '22222222-2222-4222-8222-222222222222'::uuid
  );
  IF v_result IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'FAIL: expected claim function to return true';
  END IF;
  RAISE NOTICE 'PASS: service_role claim accepted for synthetic super-admin';

  -- Negative path: the function itself rejects a non-admin subject.
  BEGIN
    PERFORM public.claim_admin_asset_refresh(
      'ci-synthetic-nonadmin-asset',
      '11111111-1111-4111-8111-111111111111'::uuid
    );
    RAISE EXCEPTION 'FAIL: non-admin subject unexpectedly claimed an asset';
  EXCEPTION WHEN SQLSTATE '42501' THEN
    RAISE NOTICE 'PASS: non-admin subject rejected with 42501';
  END;

  -- Negative path: invalid asset identifier is rejected before any claim.
  BEGIN
    PERFORM public.claim_admin_asset_refresh(
      '   ',
      '22222222-2222-4222-8222-222222222222'::uuid
    );
    RAISE EXCEPTION 'FAIL: blank asset identifier unexpectedly accepted';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    RAISE NOTICE 'PASS: invalid asset identifier rejected with 22023';
  END;

  -- Negative path: the same asset cannot be claimed twice inside the 30-second window.
  BEGIN
    PERFORM public.claim_admin_asset_refresh(
      'ci-synthetic-asset-claim',
      '22222222-2222-4222-8222-222222222222'::uuid
    );
    RAISE EXCEPTION 'FAIL: cooldown did not reject a duplicate claim';
  EXCEPTION WHEN SQLSTATE '55000' THEN
    RAISE NOTICE 'PASS: duplicate claim rejected by 30-second cooldown with 55000';
  END;
END
$claim_test$;

ROLLBACK;

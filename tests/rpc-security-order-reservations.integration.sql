-- TEST-ONLY: read-only owner-scoped reservation RPC.
-- Only synthetic reservation rows are inserted; all changes are rolled back.
\set ON_ERROR_STOP on
BEGIN;

INSERT INTO public.order_reservations
  (order_id,user_id,asset,reserved_amount,consumed_amount,released_amount,status)
VALUES
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1','11111111-1111-4111-8111-111111111111','USDT',100,20,10,'reserved'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2','11111111-1111-4111-8111-111111111111','BTC',0.5,0,0,'reserved'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1','22222222-2222-4222-8222-222222222222','USDT',900,0,0,'reserved');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $owner$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM public.get_my_order_reservations(ARRAY[
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'::uuid,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2'::uuid,
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1'::uuid
  ]);
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'Owner-scoped reservation RPC returned % rows; expected 2',v_count;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.get_my_order_reservations(ARRAY[
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'::uuid,
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1'::uuid
    ]) WHERE order_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1'::uuid
  ) THEN
    RAISE EXCEPTION 'Reservation RPC leaked another user reservation';
  END IF;

  IF (SELECT count(*) FROM public.get_my_order_reservations(NULL::uuid[])) <> 0
     OR (SELECT count(*) FROM public.get_my_order_reservations(ARRAY[]::uuid[])) <> 0
     OR (SELECT count(*) FROM public.get_my_order_reservations(array_fill(
       'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'::uuid,ARRAY[101]
     ))) <> 0 THEN
    RAISE EXCEPTION 'Reservation RPC did not enforce null/empty/100-ID bounds';
  END IF;

  IF has_table_privilege('authenticated','public.order_reservations','SELECT') THEN
    RAISE EXCEPTION 'authenticated unexpectedly has direct reservation table SELECT';
  END IF;
END
$owner$;
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','',true);
DO $no_user$
BEGIN
  IF (SELECT count(*) FROM public.get_my_order_reservations(
       ARRAY['aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'::uuid]
     )) <> 0 THEN
    RAISE EXCEPTION 'Reservation RPC returned rows without auth.uid()';
  END IF;
END
$no_user$;
RESET ROLE;

SET LOCAL ROLE anon;
DO $anon$
BEGIN
  IF has_function_privilege('anon','public.get_my_order_reservations(uuid[])','EXECUTE') THEN
    RAISE EXCEPTION 'anon unexpectedly has reservation RPC EXECUTE';
  END IF;
  BEGIN
    PERFORM public.get_my_order_reservations(ARRAY['aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'::uuid]);
    RAISE EXCEPTION 'Expected anon reservation RPC denial';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$anon$;
RESET ROLE;

SET LOCAL ROLE service_role;
SELECT set_config('request.jwt.claim.sub','',true);
DO $service$
BEGIN
  IF NOT has_function_privilege('service_role','public.get_my_order_reservations(uuid[])','EXECUTE')
     OR NOT has_table_privilege('service_role','public.order_reservations','SELECT')
     OR (SELECT count(*) FROM public.get_my_order_reservations(
       ARRAY['aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'::uuid]
     )) <> 0 THEN
    RAISE EXCEPTION 'service_role reservation ACL or no-user scoping mismatch';
  END IF;
END
$service$;
RESET ROLE;

DO $catalog$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    WHERE p.oid='public.get_my_order_reservations(uuid[])'::regprocedure
      AND p.prorettype='record'::regtype
      AND p.provolatile='s'
      AND p.prosecdef IS TRUE
      AND p.proowner='postgres'::regrole
      AND 'search_path=""'=ANY(p.proconfig)
  ) THEN
    RAISE EXCEPTION 'Reservation RPC metadata differs from Production';
  END IF;

  IF NOT (SELECT relrowsecurity AND NOT relforcerowsecurity
          FROM pg_catalog.pg_class WHERE oid='public.order_reservations'::regclass) THEN
    RAISE EXCEPTION 'order_reservations RLS flags differ from Production';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_policy p
    WHERE p.polrelid='public.order_reservations'::regclass
      AND p.polname='Users can view own order reservations'
      AND p.polcmd='r'
  ) THEN
    RAISE EXCEPTION 'order_reservations owner-read policy missing';
  END IF;
END
$catalog$;

ROLLBACK;

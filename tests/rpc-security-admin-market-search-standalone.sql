-- Isolated PostgreSQL 17 source-migration test for admin_search_market_assets.
-- The exact migration file is loaded from /tmp; no copied function body is used.
\set ON_ERROR_STOP on

DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN CREATE ROLE anon NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='service_role') THEN CREATE ROLE service_role NOLOGIN BYPASSRLS; END IF;
END
$roles$;

CREATE SCHEMA auth;
CREATE SCHEMA private;
CREATE TABLE private.admin_users(user_id uuid PRIMARY KEY);
INSERT INTO private.admin_users VALUES ('11111111-1111-4111-8111-111111111111');

CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid
LANGUAGE sql STABLE
SET search_path = ''
AS $uid$
  SELECT NULLIF(pg_catalog.current_setting('request.jwt.claim.sub', true), '')::uuid;
$uid$;

CREATE OR REPLACE FUNCTION private.is_super_admin()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $admin$
  SELECT EXISTS (
    SELECT 1 FROM private.admin_users AS a
    WHERE a.user_id = auth.uid()
  );
$admin$;

CREATE TABLE public.crypto_assets (
  coingecko_id text PRIMARY KEY,
  symbol text NOT NULL,
  name text NOT NULL,
  image_url text,
  market_cap_rank integer,
  current_price_usd numeric,
  price_toman numeric,
  price_change_percentage_24h numeric,
  total_volume_usd numeric,
  last_updated timestamptz,
  is_active boolean NOT NULL DEFAULT true
);
CREATE TABLE public.admin_market_listings (
  coingecko_id text PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT pg_catalog.now()
);
ALTER TABLE public.crypto_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_market_listings ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.crypto_assets, public.admin_market_listings
  FROM PUBLIC, anon, authenticated, service_role;

-- Exact source migration creates get_admin_market_listings and admin_search_market_assets.
\ir /tmp/harden_admin_market_listing_access.sql

INSERT INTO public.crypto_assets
  (coingecko_id,symbol,name,image_url,market_cap_rank,current_price_usd,price_toman,
   price_change_percentage_24h,total_volume_usd,last_updated,is_active)
SELECT
  'ci-asset-' || lpad(g::text,2,'0'),
  'C' || g::text,
  'CI Synthetic Asset ' || g::text,
  NULL,
  g,
  100 + g,
  100000 + g,
  0,
  1000000,
  pg_catalog.now() - interval '30 minutes',
  true
FROM generate_series(1,60) AS g;

INSERT INTO public.crypto_assets
  (coingecko_id,symbol,name,market_cap_rank,current_price_usd,last_updated,is_active)
VALUES
  ('ci-stale','STALE','CI Stale Asset',61,10,pg_catalog.now()-interval '25 hours',true),
  ('ci-inactive','INACT','CI Inactive Asset',62,10,pg_catalog.now()-interval '1 minute',false),
  ('ci-zero','ZERO','CI Zero Asset',63,0,pg_catalog.now()-interval '1 minute',true);

DO $acl$
DECLARE fn regprocedure := 'public.admin_search_market_assets(text,integer)'::regprocedure;
BEGIN
  IF has_function_privilege('anon',fn,'EXECUTE') THEN RAISE EXCEPTION 'anon must not execute admin search'; END IF;
  IF NOT has_function_privilege('authenticated',fn,'EXECUTE') THEN RAISE EXCEPTION 'authenticated must execute admin search'; END IF;
  IF has_function_privilege('service_role',fn,'EXECUTE') THEN RAISE EXCEPTION 'source migration unexpectedly grants service_role'; END IF;
  IF EXISTS (
    SELECT 1 FROM aclexplode(COALESCE((SELECT proacl FROM pg_proc WHERE oid=fn),
      acldefault('f',(SELECT proowner FROM pg_proc WHERE oid=fn)))) a
    WHERE a.grantee=0 AND a.privilege_type='EXECUTE'
  ) THEN RAISE EXCEPTION 'PUBLIC must not execute admin search'; END IF;
  IF has_table_privilege('anon','public.admin_market_listings','SELECT')
     OR has_table_privilege('authenticated','public.admin_market_listings','SELECT') THEN
    RAISE EXCEPTION 'source migration must revoke direct listing table SELECT';
  END IF;
END
$acl$;

BEGIN;
SET LOCAL ROLE authenticated;
SELECT pg_catalog.set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
DO $ordinary_user$
BEGIN
  BEGIN
    PERFORM * FROM public.admin_search_market_assets('ci',20);
    RAISE EXCEPTION 'ordinary authenticated user unexpectedly searched admin assets';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$ordinary_user$;
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT pg_catalog.set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $super_admin$
DECLARE n integer; n_one integer;
BEGIN
  SELECT count(*) INTO n FROM public.admin_search_market_assets('ci',500);
  IF n <> 50 THEN RAISE EXCEPTION 'limit must clamp to 50; got %',n; END IF;
  SELECT count(*) INTO n_one FROM public.admin_search_market_assets('ci',0);
  IF n_one <> 1 THEN RAISE EXCEPTION 'limit zero must clamp to 1; got %',n_one; END IF;
  IF EXISTS (SELECT 1 FROM public.admin_search_market_assets('ci',50)
             WHERE coingecko_id IN ('ci-stale','ci-inactive','ci-zero')) THEN
    RAISE EXCEPTION 'stale, inactive or zero-price asset leaked into results';
  END IF;
  BEGIN
    PERFORM * FROM public.admin_search_market_assets('c',20);
    RAISE EXCEPTION 'one-character search unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE 'Search query must contain at least two characters%' THEN RAISE; END IF;
  END;
END
$super_admin$;
RESET ROLE;
ROLLBACK;

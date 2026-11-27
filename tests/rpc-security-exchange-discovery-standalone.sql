-- Isolated PostgreSQL 17 reproduction for the source migration.
-- This file runs in a dedicated disposable database, never in the shared RPC fixture.
\set ON_ERROR_STOP on

DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN CREATE ROLE anon NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='service_role') THEN CREATE ROLE service_role NOLOGIN BYPASSRLS; END IF;
END
$roles$;

BEGIN;

CREATE TABLE public.exchange_asset_observations (
  exchange text NOT NULL,
  base_symbol text NOT NULL,
  asset_name text,
  last_seen_at timestamptz NOT NULL,
  match_status text NOT NULL,
  is_active boolean NOT NULL DEFAULT true
);
CREATE TABLE public.admin_market_listings (
  coingecko_id text PRIMARY KEY
);
CREATE TABLE public.crypto_assets (
  coingecko_id text PRIMARY KEY,
  symbol text NOT NULL
);
CREATE TABLE public.demo_trading_pairs (
  base_coingecko_id text NOT NULL,
  is_enabled boolean NOT NULL DEFAULT false
);
CREATE TABLE public.market_prices (
  symbol text PRIMARY KEY,
  price numeric,
  updated_at timestamptz
);

ALTER TABLE public.exchange_asset_observations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_market_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crypto_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demo_trading_pairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_prices ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.exchange_asset_observations, public.admin_market_listings,
  public.crypto_assets, public.demo_trading_pairs, public.market_prices
  FROM PUBLIC, anon, authenticated, service_role;

-- Load the exact migration source; do not copy/paste or reserialize its function body.
\ir /tmp/get_exchange_discovered_market_assets.sql

INSERT INTO public.crypto_assets(coingecko_id,symbol) VALUES
  ('ci-curated','LIST'), ('ci-enabled','PAIR');
INSERT INTO public.admin_market_listings(coingecko_id) VALUES ('ci-curated');
INSERT INTO public.demo_trading_pairs(base_coingecko_id,is_enabled) VALUES ('ci-enabled',true);
INSERT INTO public.market_prices(symbol,price,updated_at) VALUES
  ('BTCUSDT',65000,pg_catalog.now()-interval '30 seconds'),
  ('STLUSDT',12,pg_catalog.now()-interval '5 minutes');
INSERT INTO public.exchange_asset_observations
  (exchange,base_symbol,asset_name,last_seen_at,match_status,is_active)
VALUES
  ('nobitex','BTC','Bitcoin Synthetic',pg_catalog.now()-interval '2 minutes','pending',true),
  ('wallex','BTC','Bitcoin Synthetic',pg_catalog.now()-interval '1 minute','ambiguous',true),
  ('nobitex','STL','Stale Synthetic',pg_catalog.now()-interval '3 minutes','unmatched',true),
  ('nobitex','OLD','Old Synthetic',pg_catalog.now()-interval '49 hours','unmatched',true),
  ('nobitex','STOCK','Example XStock',pg_catalog.now()-interval '1 minute','unmatched',true),
  ('nobitex','MATCH','Matched Synthetic',pg_catalog.now()-interval '1 minute','matched',true),
  ('nobitex','PAIR','Enabled Pair Synthetic',pg_catalog.now()-interval '1 minute','unmatched',true),
  ('nobitex','LIST','Curated Listing Synthetic',pg_catalog.now()-interval '1 minute','unmatched',true);

SET LOCAL ROLE anon;
DO $anon$
DECLARE
  n integer;
  src text;
  cnt integer;
  status text;
  fresh numeric;
  stale numeric;
BEGIN
  SELECT count(*) INTO n FROM public.get_exchange_discovered_market_assets();
  IF n <> 2 THEN RAISE EXCEPTION 'expected 2 discovery rows, got %',n; END IF;
  SELECT exchange_sources,exchange_count,match_status,current_price_usd
    INTO src,cnt,status,fresh
  FROM public.get_exchange_discovered_market_assets() WHERE symbol='BTC';
  IF src IS DISTINCT FROM 'nobitex, wallex' OR cnt <> 2 OR status <> 'ambiguous' OR fresh IS DISTINCT FROM 65000 THEN
    RAISE EXCEPTION 'BTC aggregation mismatch: %, %, %, %',src,cnt,status,fresh;
  END IF;
  SELECT current_price_usd INTO stale
  FROM public.get_exchange_discovered_market_assets() WHERE symbol='STL';
  IF stale IS NOT NULL THEN RAISE EXCEPTION 'stale price must be NULL, got %',stale; END IF;
  IF has_table_privilege(current_user,'public.exchange_asset_observations','SELECT')
     OR has_table_privilege(current_user,'public.crypto_assets','SELECT')
     OR has_table_privilege(current_user,'public.market_prices','SELECT') THEN
    RAISE EXCEPTION 'anon unexpectedly has direct SELECT on dependency tables';
  END IF;
END
$anon$;
RESET ROLE;

SET LOCAL ROLE authenticated;
DO $authenticated$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM public.get_exchange_discovered_market_assets();
  IF n <> 2 THEN RAISE EXCEPTION 'authenticated expected 2 rows, got %',n; END IF;
END
$authenticated$;
RESET ROLE;

DO $acl$
DECLARE fn regprocedure := 'public.get_exchange_discovered_market_assets()'::regprocedure;
BEGIN
  IF NOT has_function_privilege('anon',fn,'EXECUTE')
     OR NOT has_function_privilege('authenticated',fn,'EXECUTE') THEN
    RAISE EXCEPTION 'source migration must grant anon and authenticated';
  END IF;
  IF has_function_privilege('service_role',fn,'EXECUTE') THEN
    RAISE EXCEPTION 'source migration unexpectedly grants service_role; review source ACL discrepancy';
  END IF;
  IF EXISTS (
    SELECT 1 FROM aclexplode(COALESCE(
      (SELECT proacl FROM pg_proc WHERE oid=fn),
      acldefault('f',(SELECT proowner FROM pg_proc WHERE oid=fn))
    )) AS a
    WHERE a.grantee=0 AND a.privilege_type='EXECUTE'
  ) THEN
    RAISE EXCEPTION 'PUBLIC must not have EXECUTE';
  END IF;
END
$acl$;

ROLLBACK;

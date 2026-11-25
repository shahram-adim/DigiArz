-- Exact source-migration function behavior in the shared disposable PostgreSQL 17 fixture.
-- Only synthetic market metadata is inserted; all rows are rolled back.
\set ON_ERROR_STOP on
BEGIN;

INSERT INTO public.crypto_assets(coingecko_id,symbol,name,is_active) VALUES
  ('ci-discovery-curated','LIST','Synthetic Curated Listing',true),
  ('ci-discovery-enabled','PAIR','Synthetic Enabled Pair',true);
INSERT INTO public.admin_market_listings(coingecko_id,added_by)
VALUES ('ci-discovery-curated',NULL);
INSERT INTO public.demo_trading_pairs(base_coingecko_id,is_enabled)
VALUES ('ci-discovery-enabled',true);
INSERT INTO public.market_prices(symbol,price,updated_at,source) VALUES
  ('BTCUSDT',65000,pg_catalog.now()-interval '30 seconds','CoinGecko'),
  ('STLUSDT',12,pg_catalog.now()-interval '5 minutes','CoinGecko');
INSERT INTO public.exchange_asset_observations
  (exchange,market_symbol,base_symbol,quote_symbol,asset_name,coingecko_id,
   match_status,source_url,source_payload,is_active,last_seen_at)
VALUES
  ('nobitex','BTCIRT','BTC','IRT','Bitcoin Synthetic',NULL,'pending','https://fixture.invalid/nobitex','{}',true,pg_catalog.now()-interval '2 minutes'),
  ('wallex','BTCUSDT','BTC','USDT','Bitcoin Synthetic',NULL,'ambiguous','https://fixture.invalid/wallex','{}',true,pg_catalog.now()-interval '1 minute'),
  ('nobitex','STLIRT','STL','IRT','Stale Synthetic',NULL,'unmatched','https://fixture.invalid/nobitex','{}',true,pg_catalog.now()-interval '3 minutes'),
  ('nobitex','OLDIRT','OLD','IRT','Old Synthetic',NULL,'unmatched','https://fixture.invalid/nobitex','{}',true,pg_catalog.now()-interval '49 hours'),
  ('nobitex','STOCKIRT','STOCK','IRT','Example XStock',NULL,'unmatched','https://fixture.invalid/nobitex','{}',true,pg_catalog.now()-interval '1 minute'),
  ('nobitex','MATCHIRT','MATCH','IRT','Matched Synthetic','ci-matched','matched','https://fixture.invalid/nobitex','{}',true,pg_catalog.now()-interval '1 minute'),
  ('nobitex','PAIRIRT','PAIR','IRT','Enabled Pair Synthetic',NULL,'unmatched','https://fixture.invalid/nobitex','{}',true,pg_catalog.now()-interval '1 minute'),
  ('nobitex','LISTIRT','LIST','IRT','Curated Listing Synthetic',NULL,'unmatched','https://fixture.invalid/nobitex','{}',true,pg_catalog.now()-interval '1 minute');

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
  IF n <> 2 THEN RAISE EXCEPTION 'anon expected 2 discovery rows, got %',n; END IF;
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
     OR has_table_privilege(current_user,'public.demo_trading_pairs','SELECT')
     OR has_table_privilege(current_user,'public.market_prices','SELECT') THEN
    RAISE EXCEPTION 'anon unexpectedly has direct SELECT on protected dependency tables';
  END IF;
END
$anon$;
RESET ROLE;

SET LOCAL ROLE authenticated;
DO $authenticated$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM public.get_exchange_discovered_market_assets();
  IF n <> 2 THEN RAISE EXCEPTION 'authenticated expected 2 discovery rows, got %',n; END IF;
END
$authenticated$;
RESET ROLE;

SET LOCAL ROLE service_role;
DO $service_role$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM public.get_exchange_discovered_market_assets();
  IF n <> 2 THEN RAISE EXCEPTION 'service_role expected 2 discovery rows, got %',n; END IF;
END
$service_role$;
RESET ROLE;

ROLLBACK;

-- Source-faithful, read-only exchange-discovery RPC test.
-- Only synthetic non-financial market metadata is inserted; transaction rolls back.
\set ON_ERROR_STOP on
BEGIN;

INSERT INTO public.crypto_assets
  (coingecko_id,symbol,name,image_url,market_cap_rank,price_toman,price_change_percentage_24h,total_volume_usd,is_active)
VALUES
  ('ci-discovery-pair','PAIR','Synthetic Enabled Pair',NULL,10,1000,0,100000,true),
  ('ci-discovery-listed','LIST','Synthetic Curated Listing',NULL,11,1000,0,100000,true);

INSERT INTO public.admin_market_listings(coingecko_id,added_by)
VALUES ('ci-discovery-listed',NULL);

INSERT INTO public.demo_trading_pairs(pair_symbol,base_coingecko_id,is_enabled)
VALUES ('PAIRUSDT','ci-discovery-pair',true);

INSERT INTO public.market_prices(symbol,price,updated_at,source)
VALUES
  ('BTCUSDT',65000,pg_catalog.now()-interval '30 seconds','CoinGecko'),
  ('STLUSDT',12,pg_catalog.now()-interval '5 minutes','CoinGecko');

INSERT INTO public.exchange_asset_observations
  (exchange,market_symbol,base_symbol,quote_symbol,asset_name,coingecko_id,match_status,source_url,source_payload,is_active,last_seen_at)
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
DO $anon_discovery_test$
DECLARE
  v_count integer;
  v_sources text;
  v_exchange_count integer;
  v_status text;
  v_fresh numeric;
  v_stale numeric;
BEGIN
  SELECT count(*) INTO v_count FROM public.get_exchange_discovered_market_assets();
  IF v_count <> 2 THEN RAISE EXCEPTION 'anon expected two synthetic discovery rows, got %',v_count; END IF;
  SELECT exchange_sources,exchange_count,match_status,current_price_usd
    INTO v_sources,v_exchange_count,v_status,v_fresh
  FROM public.get_exchange_discovered_market_assets() WHERE symbol='BTC';
  IF v_sources IS DISTINCT FROM 'nobitex, wallex' OR v_exchange_count <> 2 OR v_status <> 'ambiguous' OR v_fresh IS DISTINCT FROM 65000 THEN
    RAISE EXCEPTION 'BTC aggregation mismatch: sources %, count %, status %, price %',v_sources,v_exchange_count,v_status,v_fresh;
  END IF;
  SELECT current_price_usd INTO v_stale FROM public.get_exchange_discovered_market_assets() WHERE symbol='STL';
  IF v_stale IS NOT NULL THEN RAISE EXCEPTION 'stale market price must be absent, got %',v_stale; END IF;
END
$anon_discovery_test$;
RESET ROLE;

SET LOCAL ROLE authenticated;
DO $authenticated_discovery_test$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.get_exchange_discovered_market_assets();
  IF v_count <> 2 THEN RAISE EXCEPTION 'authenticated expected two synthetic discovery rows, got %',v_count; END IF;
END
$authenticated_discovery_test$;
RESET ROLE;

SET LOCAL ROLE service_role;
DO $service_discovery_test$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.get_exchange_discovered_market_assets();
  IF v_count <> 2 THEN RAISE EXCEPTION 'service_role expected two synthetic discovery rows, got %',v_count; END IF;
END
$service_discovery_test$;
RESET ROLE;

DO $discovery_table_acl_test$
BEGIN
  IF has_table_privilege('anon','public.exchange_asset_observations','SELECT')
     OR has_table_privilege('anon','public.admin_market_listings','SELECT')
     OR has_table_privilege('anon','public.crypto_assets','SELECT')
     OR has_table_privilege('anon','public.demo_trading_pairs','SELECT')
     OR has_table_privilege('anon','public.market_prices','SELECT') THEN
    RAISE EXCEPTION 'anon unexpectedly has direct SELECT on an underlying discovery dependency';
  END IF;
  RAISE NOTICE 'PASS: discovery RPC aggregates recent exchange metadata, filters unsafe/known assets, and suppresses stale prices';
END
$discovery_table_acl_test$;

ROLLBACK;

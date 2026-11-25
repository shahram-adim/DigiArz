-- Source-faithful, read-only market metadata RPC test.
-- Only synthetic non-financial market rows are inserted; transaction rolls back.
\set ON_ERROR_STOP on
BEGIN;

INSERT INTO public.crypto_assets
  (coingecko_id,symbol,name,image_url,market_cap_rank,price_toman,price_change_percentage_24h,total_volume_usd,is_active)
VALUES
  ('ci-market-fresh','btc','Synthetic Fresh Asset',NULL,1,1000000,2.5,900000,true),
  ('ci-market-stale','stl','Synthetic Stale Asset',NULL,2,2000000,-1.5,800000,true),
  ('ci-market-inactive','off','Synthetic Inactive Asset',NULL,3,3000000,0,700000,false);

INSERT INTO public.admin_market_listings(coingecko_id,added_by,created_at)
VALUES
  ('ci-market-fresh',NULL,pg_catalog.now()-interval '3 minutes'),
  ('ci-market-stale',NULL,pg_catalog.now()-interval '2 minutes'),
  ('ci-market-inactive',NULL,pg_catalog.now()-interval '1 minute');

INSERT INTO public.market_prices(symbol,price,updated_at,source)
VALUES
  ('BTCUSDT',65000,pg_catalog.now()-interval '30 seconds','CoinGecko'),
  ('STLUSDT',12,pg_catalog.now()-interval '5 minutes','CoinGecko');

SET LOCAL ROLE anon;
DO $anon_market_test$
DECLARE
  v_count integer;
  v_fresh numeric;
  v_stale numeric;
BEGIN
  SELECT count(*) INTO v_count FROM public.get_admin_market_listings();
  IF v_count <> 2 THEN RAISE EXCEPTION 'anon expected two active synthetic listings, got %',v_count; END IF;
  SELECT current_price_usd INTO v_fresh FROM public.get_admin_market_listings() WHERE coingecko_id='ci-market-fresh';
  SELECT current_price_usd INTO v_stale FROM public.get_admin_market_listings() WHERE coingecko_id='ci-market-stale';
  IF v_fresh IS DISTINCT FROM 65000 THEN RAISE EXCEPTION 'fresh CoinGecko price should be visible, got %',v_fresh; END IF;
  IF v_stale IS NOT NULL THEN RAISE EXCEPTION 'stale price must be redacted, got %',v_stale; END IF;
END
$anon_market_test$;
RESET ROLE;

SET LOCAL ROLE authenticated;
DO $authenticated_market_test$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.get_admin_market_listings();
  IF v_count <> 2 THEN RAISE EXCEPTION 'authenticated expected two synthetic listings, got %',v_count; END IF;
END
$authenticated_market_test$;
RESET ROLE;

SET LOCAL ROLE service_role;
DO $service_market_test$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.get_admin_market_listings();
  IF v_count <> 2 THEN RAISE EXCEPTION 'service_role expected two synthetic listings, got %',v_count; END IF;
END
$service_market_test$;
RESET ROLE;

DO $market_table_acl_test$
BEGIN
  IF has_table_privilege('anon','public.crypto_assets','SELECT')
     OR has_table_privilege('anon','public.market_prices','SELECT') THEN
    RAISE EXCEPTION 'anon unexpectedly has direct SELECT on underlying tables';
  END IF;
  RAISE NOTICE 'PASS: public market RPC exposes only active listings and redacts stale USD prices; base tables remain non-readable directly';
END
$market_table_acl_test$;

ROLLBACK;

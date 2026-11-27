-- TEST-ONLY: exact live Production admin_enable_market_pair body.
-- Synthetic market assets, pair rows, prices and audit records only.
-- No real orders, wallets, or Production rows are accessed.
\set ON_ERROR_STOP on
BEGIN;

INSERT INTO public.crypto_assets
  (coingecko_id,symbol,name,market_cap_rank,current_price_usd,total_volume_usd,last_updated,is_active)
VALUES
  ('ci-enable-good','ENAB','CI Enable Good',100,100,2000000,now(),true),
  ('ci-enable-stale-meta','STAM','CI Enable Stale Metadata',101,100,2000000,now()-interval '25 hours',true),
  ('ci-enable-low-volume','LOWV','CI Enable Low Volume',102,100,999999,now(),true),
  ('ci-enable-bad-rank','RANK','CI Enable Bad Rank',2001,100,2000000,now(),true),
  ('ci-enable-bad-symbol','BAD_SYMBOL','CI Enable Bad Symbol',103,100,2000000,now(),true),
  ('ci-enable-usdt','USDT','CI Enable USDT',104,100,2000000,now(),true),
  ('ci-enable-conflict','COLL','CI Enable Conflict',105,100,2000000,now(),true),
  ('ci-enable-price-stale','PSTA','CI Enable Stale Price',106,100,2000000,now(),true),
  ('ci-enable-price-source','PSRC','CI Enable Wrong Source',107,100,2000000,now(),true),
  ('ci-enable-existing','EXST','CI Enable Existing Pair',108,100,2000000,now(),true),
  ('ci-enable-no-list','NOLI','CI Enable Not Curated',109,100,2000000,now(),true),
  ('ci-enable-other','OTHR','CI Enable Conflict Owner',110,100,2000000,now(),true);

INSERT INTO public.admin_market_listings(coingecko_id,added_by)
SELECT coingecko_id,'22222222-2222-4222-8222-222222222222'::uuid
FROM public.crypto_assets
WHERE coingecko_id LIKE 'ci-enable-%'
  AND coingecko_id <> 'ci-enable-no-list';

INSERT INTO public.market_prices(symbol,price,source,updated_at)
VALUES
 ('ENABUSDT',100,'CoinGecko',now()),
 ('STAMUSDT',100,'CoinGecko',now()),
 ('LOWVUSDT',100,'CoinGecko',now()),
 ('RANKUSDT',100,'CoinGecko',now()),
 ('BAD_SYMBOLUSDT',100,'CoinGecko',now()),
 ('USDTUSDT',100,'CoinGecko',now()),
 ('COLLUSDT',100,'CoinGecko',now()),
 ('PSTAUSDT',100,'CoinGecko',now()-interval '3 minutes'),
 ('PSRCUSDT',100,'Manual',now()),
 ('EXSTUSDT',100,'CoinGecko',now()),
 ('NOLIUSDT',100,'CoinGecko',now());

INSERT INTO public.demo_trading_pairs(pair_symbol,base_coingecko_id,quote_asset,is_enabled)
VALUES
 ('COLLUSDT','ci-enable-other','USDT',true),
 ('EXSTUSDT','ci-enable-existing','USDT',false);

SET LOCAL ROLE anon;
DO $anon$
BEGIN
  IF has_function_privilege('anon','public.admin_enable_market_pair(text)','EXECUTE') THEN
    RAISE EXCEPTION 'anon unexpectedly has admin-enable EXECUTE';
  END IF;
  BEGIN
    PERFORM public.admin_enable_market_pair('ci-enable-good');
    RAISE EXCEPTION 'anon unexpectedly invoked admin-enable';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$anon$;
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
DO $ordinary$
BEGIN
  BEGIN
    PERFORM public.admin_enable_market_pair('ci-enable-good');
    RAISE EXCEPTION 'ordinary authenticated user unexpectedly enabled a pair';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$ordinary$;
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
DO $super_admin$
DECLARE
  result jsonb;
BEGIN
  result := public.admin_enable_market_pair('ci-enable-good');
  IF result->>'success' <> 'true'
     OR result->>'pair_symbol' <> 'ENABUSDT'
     OR result->>'status' <> 'enabled'
     OR result->>'coingecko_id' <> 'ci-enable-good' THEN
    RAISE EXCEPTION 'Unexpected successful activation response: %',result;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.demo_trading_pairs
                 WHERE pair_symbol='ENABUSDT' AND is_enabled IS TRUE) THEN
    RAISE EXCEPTION 'Eligible pair was not enabled';
  END IF;
  -- Existing same-asset pair is re-enabled idempotently.
  result := public.admin_enable_market_pair('ci-enable-existing');
  IF result->>'status' <> 'enabled'
     OR NOT EXISTS (SELECT 1 FROM public.demo_trading_pairs
                    WHERE pair_symbol='EXSTUSDT' AND is_enabled IS TRUE) THEN
    RAISE EXCEPTION 'Existing same-asset pair was not re-enabled';
  END IF;

  BEGIN
    PERFORM public.admin_enable_market_pair('ci-enable-no-list');
    RAISE EXCEPTION 'non-curated asset unexpectedly enabled';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Asset must first be added to the admin-curated market list' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.admin_enable_market_pair('ci-enable-stale-meta');
    RAISE EXCEPTION 'stale metadata unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Asset does not meet the current market-data and liquidity requirements' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.admin_enable_market_pair('ci-enable-low-volume');
    RAISE EXCEPTION 'low-volume asset unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Asset does not meet the current market-data and liquidity requirements' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.admin_enable_market_pair('ci-enable-bad-rank');
    RAISE EXCEPTION 'out-of-range rank unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Asset does not meet the current market-data and liquidity requirements' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.admin_enable_market_pair('ci-enable-bad-symbol');
    RAISE EXCEPTION 'malformed symbol unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Asset symbol is not valid for a USDT trading pair' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.admin_enable_market_pair('ci-enable-usdt');
    RAISE EXCEPTION 'USDT base asset unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Asset symbol is not valid for a USDT trading pair' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.admin_enable_market_pair('ci-enable-conflict');
    RAISE EXCEPTION 'conflicting pair symbol unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Trading-pair symbol conflicts with another asset' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.admin_enable_market_pair('ci-enable-price-stale');
    RAISE EXCEPTION 'stale market price unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'A fresh CoinGecko price is required before enabling this pair' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.admin_enable_market_pair('ci-enable-price-source');
    RAISE EXCEPTION 'non-CoinGecko price unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'A fresh CoinGecko price is required before enabling this pair' THEN RAISE; END IF;
  END;
END
$super_admin$;
RESET ROLE;

SET LOCAL ROLE service_role;
DO $service$
BEGIN
  IF NOT has_function_privilege('service_role','public.admin_enable_market_pair(text)','EXECUTE') THEN
    RAISE EXCEPTION 'service_role effective EXECUTE bit is missing';
  END IF;
END
$service$;
RESET ROLE;
SET LOCAL ROLE postgres;

DO $audit_assert$
BEGIN
  IF (SELECT count(*) FROM private.market_pair_admin_audit
      WHERE pair_symbol='ENABUSDT' AND action='enabled'
        AND admin_user_id='22222222-2222-4222-8222-222222222222') <> 1 THEN
    RAISE EXCEPTION 'Expected one admin audit row for enabled pair';
  END IF;
END
$audit_assert$;

ROLLBACK;

DO $rollback_assert$
BEGIN
  IF EXISTS (SELECT 1 FROM public.demo_trading_pairs WHERE base_coingecko_id LIKE 'ci-enable-%')
     OR EXISTS (SELECT 1 FROM private.market_pair_admin_audit WHERE coingecko_id LIKE 'ci-enable-%') THEN
    RAISE EXCEPTION 'Synthetic pair or audit rows survived rollback';
  END IF;
END
$rollback_assert$;

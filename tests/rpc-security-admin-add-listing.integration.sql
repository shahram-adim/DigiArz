-- TEST-ONLY: exact live Production admin_add_market_listing body.
-- Synthetic market metadata and curated-listing rows only; all changes rollback.
\set ON_ERROR_STOP on
BEGIN;

DROP TRIGGER IF EXISTS admin_market_listing_unique_ticker ON public.admin_market_listings;
CREATE TRIGGER admin_market_listing_unique_ticker
BEFORE INSERT OR UPDATE OF coingecko_id ON public.admin_market_listings
FOR EACH ROW EXECUTE FUNCTION private.enforce_unique_admin_market_listing_symbol();

INSERT INTO public.crypto_assets
  (coingecko_id,symbol,name,market_cap_rank,current_price_usd,last_updated,is_active)
VALUES
  ('ci-add-good','GOOD','CI Add Good',1,100,now(),true),
  ('ci-add-stale','STALE','CI Add Stale',2,100,now()-interval '25 hours',true),
  ('ci-add-inactive','INACT','CI Add Inactive',3,100,now(),false),
  ('ci-add-zero','ZERO','CI Add Zero',4,0,now(),true),
  ('ci-add-bad-symbol','BAD_SYMBOL','CI Add Bad Symbol',5,100,now(),true),
  ('ci-add-usdt','USDT','CI Add USDT',6,100,now(),true),
  ('ci-add-pair-conflict','COLL','CI Add Pair Conflict',7,100,now(),true),
  ('ci-add-same-pair','PAIR','CI Add Same Pair',8,100,now(),true),
  ('ci-add-curated-a','DUP','CI Add Duplicate A',9,100,now(),true),
  ('ci-add-curated-b','dup','CI Add Duplicate B',10,100,now(),true),
  ('different-asset','OTHR','CI Existing Pair Owner',11,100,now(),true);

INSERT INTO public.demo_trading_pairs(pair_symbol,base_coingecko_id,quote_asset,is_enabled)
VALUES
  ('PAIRUSDT','ci-add-same-pair','USDT',true),
  ('COLLUSDT','different-asset','USDT',true);

SET LOCAL ROLE anon;
DO $anon$
BEGIN
  IF has_function_privilege('anon','public.admin_add_market_listing(text)','EXECUTE') THEN
    RAISE EXCEPTION 'anon unexpectedly has admin-add EXECUTE';
  END IF;
  BEGIN
    PERFORM public.admin_add_market_listing('ci-add-good');
    RAISE EXCEPTION 'anon unexpectedly invoked admin-add';
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
    PERFORM public.admin_add_market_listing('ci-add-good');
    RAISE EXCEPTION 'ordinary authenticated user unexpectedly added a listing';
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
  result := public.admin_add_market_listing('ci-add-good');
  IF result->>'success' <> 'true'
     OR result->>'coingecko_id' <> 'ci-add-good'
     OR result->>'pair_symbol' <> 'GOODUSDT'
     OR result->>'pair_already_exists' <> 'false' THEN
    RAISE EXCEPTION 'Unexpected success response: %',result;
  END IF;

  -- Existing same-asset pair is valid; adding a curated listing does not
  -- create or reactivate a trading pair.
  result := public.admin_add_market_listing('ci-add-same-pair');
  IF result->>'pair_already_exists' <> 'true' THEN
    RAISE EXCEPTION 'Existing same-asset pair was not recognized: %',result;
  END IF;

  -- Repeated add is idempotent.
  result := public.admin_add_market_listing('ci-add-good');
  IF result->>'success' <> 'true' THEN
    RAISE EXCEPTION 'Repeated listing should be idempotent: %',result;
  END IF;

  BEGIN
    PERFORM public.admin_add_market_listing('ci-add-stale');
    RAISE EXCEPTION 'stale asset unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Asset not found, inactive, or market data is stale' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.admin_add_market_listing('ci-add-inactive');
    RAISE EXCEPTION 'inactive asset unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Asset not found, inactive, or market data is stale' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.admin_add_market_listing('ci-add-zero');
    RAISE EXCEPTION 'zero-price asset unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Asset not found, inactive, or market data is stale' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.admin_add_market_listing('ci-add-bad-symbol');
    RAISE EXCEPTION 'malformed symbol unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Asset symbol is not valid for a USDT trading pair' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.admin_add_market_listing('ci-add-usdt');
    RAISE EXCEPTION 'USDT base asset unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Asset symbol is not valid for a USDT trading pair' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.admin_add_market_listing('ci-add-pair-conflict');
    RAISE EXCEPTION 'conflicting demo pair unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Trading-pair symbol conflicts with another asset' THEN RAISE; END IF;
  END;

  PERFORM public.admin_add_market_listing('ci-add-curated-a');
  BEGIN
    PERFORM public.admin_add_market_listing('ci-add-curated-b');
    RAISE EXCEPTION 'duplicate curated ticker unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Another curated asset already uses this ticker' THEN RAISE; END IF;
  END;
END
$super_admin$;
RESET ROLE;

SET LOCAL ROLE service_role;
DO $service$
BEGIN
  IF NOT has_function_privilege('service_role','public.admin_add_market_listing(text)','EXECUTE') THEN
    RAISE EXCEPTION 'service_role effective EXECUTE bit is missing';
  END IF;
END
$service$;
RESET ROLE;

ROLLBACK;

DO $rollback_assert$
BEGIN
  IF EXISTS (SELECT 1 FROM public.admin_market_listings
             WHERE coingecko_id LIKE 'ci-add-%') THEN
    RAISE EXCEPTION 'Synthetic admin listings survived transaction rollback';
  END IF;
END
$rollback_assert$;

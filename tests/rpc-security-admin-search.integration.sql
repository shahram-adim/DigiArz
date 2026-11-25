-- TEST-ONLY: exact live Production admin_search_market_assets body.
-- Synthetic market metadata only; no financial/order/user data is touched.
-- All inserted rows are rolled back.
\\set ON_ERROR_STOP on
BEGIN;

INSERT INTO public.crypto_assets
  (coingecko_id,symbol,name,image_url,market_cap_rank,current_price_usd,last_updated,is_active)
SELECT
  'ci-search-' || lpad(g::text,2,'0'),
  'CS' || g::text,
  'CI Search Synthetic Asset ' || g::text,
  NULL,
  g,
  100 + g,
  now() - interval '30 minutes',
  true
FROM generate_series(1,60) AS g;

INSERT INTO public.crypto_assets
  (coingecko_id,symbol,name,market_cap_rank,current_price_usd,last_updated,is_active)
VALUES
  ('ci-search-stale','CSTALE','CI Search Stale Active',61,10,now()-interval '25 hours',true),
  ('ci-search-zero','CZERO','CI Search Zero Price Active',62,0,now()-interval '1 minute',true),
  ('ci-search-inactive','CINACT','CI Search Inactive',63,10,now()-interval '1 minute',false);

SET LOCAL ROLE anon;
DO $anon$
BEGIN
  IF has_function_privilege('anon','public.admin_search_market_assets(text,integer)','EXECUTE') THEN
    RAISE EXCEPTION 'anon unexpectedly has admin-search EXECUTE';
  END IF;
  BEGIN
    PERFORM * FROM public.admin_search_market_assets('ci',20);
    RAISE EXCEPTION 'anon unexpectedly invoked admin search';
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
    PERFORM * FROM public.admin_search_market_assets('ci',20);
    RAISE EXCEPTION 'ordinary authenticated user unexpectedly searched admin assets';
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
  n integer;
  n_one integer;
BEGIN
  SELECT count(*) INTO n FROM public.admin_search_market_assets('ci',500);
  IF n <> 50 THEN RAISE EXCEPTION 'limit must clamp to 50; got %',n; END IF;

  SELECT count(*) INTO n_one FROM public.admin_search_market_assets('ci',0);
  IF n_one <> 1 THEN RAISE EXCEPTION 'limit zero must clamp to 1; got %',n_one; END IF;

  IF NOT EXISTS (SELECT 1 FROM public.admin_search_market_assets('stale',20)
                 WHERE coingecko_id='ci-search-stale') THEN
    RAISE EXCEPTION 'active stale asset should remain visible under the current Production body';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.admin_search_market_assets('zero',20)
                 WHERE coingecko_id='ci-search-zero') THEN
    RAISE EXCEPTION 'active zero-price asset should remain visible under the current Production body';
  END IF;
  IF EXISTS (SELECT 1 FROM public.admin_search_market_assets('inactive',20)
             WHERE coingecko_id='ci-search-inactive') THEN
    RAISE EXCEPTION 'inactive asset leaked into results';
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

SET LOCAL ROLE service_role;
DO $service$
BEGIN
  IF NOT has_function_privilege('service_role','public.admin_search_market_assets(text,integer)','EXECUTE') THEN
    RAISE EXCEPTION 'service_role effective EXECUTE bit is missing';
  END IF;
END
$service$;
RESET ROLE;

ROLLBACK;

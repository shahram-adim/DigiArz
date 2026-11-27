-- TEST-ONLY: exercises the exact current Production trigger body with synthetic rows.
-- All DML and trigger DDL are transaction-scoped and rolled back at the end.
\set ON_ERROR_STOP on
BEGIN;

DROP TRIGGER IF EXISTS admin_market_listing_unique_ticker
  ON public.admin_market_listings;
CREATE TRIGGER admin_market_listing_unique_ticker
BEFORE INSERT OR UPDATE OF coingecko_id
ON public.admin_market_listings
FOR EACH ROW
EXECUTE FUNCTION private.enforce_unique_admin_market_listing_symbol();

INSERT INTO public.crypto_assets (coingecko_id, symbol, name)
VALUES
  ('fixture-asset-a', 'AAA', 'Fixture Asset A'),
  ('fixture-asset-b', 'aaa', 'Fixture Asset B'),
  ('fixture-asset-c', 'CCC', 'Fixture Asset C'),
  ('fixture-asset-d', 'DDD', 'Fixture Asset D');

INSERT INTO public.demo_trading_pairs (pair_symbol, base_coingecko_id, quote_asset, is_enabled)
VALUES ('DDDUSDT', 'different-fixture-asset', 'USDT', true);

-- A unique, source-backed asset is accepted.
INSERT INTO public.admin_market_listings (coingecko_id)
VALUES ('fixture-asset-a');

-- Case-insensitive ticker collision must be rejected.
DO $test$
BEGIN
  BEGIN
    INSERT INTO public.admin_market_listings (coingecko_id)
    VALUES ('fixture-asset-b');
    RAISE EXCEPTION 'Expected duplicate ticker rejection';
  EXCEPTION WHEN SQLSTATE 'P0001' THEN
    IF SQLERRM <> 'Another curated asset already uses this ticker' THEN
      RAISE;
    END IF;
  END;
END
$test$;

-- A ticker already assigned to another demo pair must be rejected.
DO $test$
BEGIN
  BEGIN
    INSERT INTO public.admin_market_listings (coingecko_id)
    VALUES ('fixture-asset-d');
    RAISE EXCEPTION 'Expected demo-pair ticker rejection';
  EXCEPTION WHEN SQLSTATE 'P0001' THEN
    IF SQLERRM <> 'Ticker conflicts with an existing demo trading pair' THEN
      RAISE;
    END IF;
  END;
END
$test$;

-- A listing cannot reference a missing crypto asset.
DO $test$
BEGIN
  BEGIN
    INSERT INTO public.admin_market_listings (coingecko_id)
    VALUES ('missing-fixture-asset');
    RAISE EXCEPTION 'Expected missing-asset rejection';
  EXCEPTION WHEN SQLSTATE 'P0001' THEN
    IF SQLERRM <> 'Curated asset does not exist' THEN
      RAISE;
    END IF;
  END;
END
$test$;

-- The trigger also validates changes to coingecko_id.
UPDATE public.admin_market_listings
SET coingecko_id = 'fixture-asset-c'
WHERE coingecko_id = 'fixture-asset-a';

DO $assert$
DECLARE
  v_result_type text;
  v_config text[];
BEGIN
  IF (SELECT count(*) FROM public.admin_market_listings) <> 1
     OR NOT EXISTS (
       SELECT 1 FROM public.admin_market_listings
       WHERE coingecko_id = 'fixture-asset-c'
     ) THEN
    RAISE EXCEPTION 'Ticker guard accepted/rejected an unexpected listing state';
  END IF;

  SELECT pg_catalog.format_type(p.prorettype, NULL), p.proconfig
  INTO v_result_type, v_config
  FROM pg_catalog.pg_proc p
  WHERE p.oid = 'private.enforce_unique_admin_market_listing_symbol()'::regprocedure;

  IF v_result_type <> 'trigger'
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
       WHERE p.oid = 'private.enforce_unique_admin_market_listing_symbol()'::regprocedure
         AND p.prosecdef IS TRUE
         AND 'search_path=""' = ANY(p.proconfig)
     ) THEN
    RAISE EXCEPTION 'Ticker guard signature/security/search_path differs from Production';
  END IF;

  IF has_function_privilege('anon', 'private.enforce_unique_admin_market_listing_symbol()', 'EXECUTE')
     OR has_function_privilege('authenticated', 'private.enforce_unique_admin_market_listing_symbol()', 'EXECUTE')
     OR has_function_privilege('service_role', 'private.enforce_unique_admin_market_listing_symbol()', 'EXECUTE') THEN
    RAISE EXCEPTION 'Ticker guard unexpectedly grants EXECUTE to an API role';
  END IF;

  IF NOT (SELECT relrowsecurity AND NOT relforcerowsecurity
          FROM pg_catalog.pg_class
          WHERE oid='public.demo_trading_pairs'::regclass) THEN
    RAISE EXCEPTION 'demo_trading_pairs RLS flags differ from Production';
  END IF;
END
$assert$;

ROLLBACK;

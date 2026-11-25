-- TEST-ONLY: exercises the exact current Production auto-list trigger.
-- Uses synthetic market metadata only; all trigger DDL and DML are rolled back.
\set ON_ERROR_STOP on
BEGIN;

DROP TRIGGER IF EXISTS admin_market_listing_unique_ticker
  ON public.admin_market_listings;
CREATE TRIGGER admin_market_listing_unique_ticker
BEFORE INSERT OR UPDATE OF coingecko_id
ON public.admin_market_listings
FOR EACH ROW
EXECUTE FUNCTION private.enforce_unique_admin_market_listing_symbol();

DROP TRIGGER IF EXISTS trg_auto_list_verified_exchange_asset
  ON public.exchange_asset_observations;
CREATE TRIGGER trg_auto_list_verified_exchange_asset
AFTER INSERT OR UPDATE OF match_status, coingecko_id, is_active
ON public.exchange_asset_observations
FOR EACH ROW
EXECUTE FUNCTION private.auto_list_verified_exchange_asset();

INSERT INTO public.crypto_assets
  (coingecko_id,symbol,name,current_price_usd,last_updated,is_active)
VALUES
  ('fixture-auto-good','GOOD','Fixture Auto Good',10,pg_catalog.now(),true),
  ('fixture-auto-stale','STALE','Fixture Auto Stale',10,pg_catalog.now()-interval '48 hours',true),
  ('fixture-auto-dup-1','DUP','Fixture Duplicate One',10,pg_catalog.now(),true),
  ('fixture-auto-dup-2','dup','Fixture Duplicate Two',10,pg_catalog.now(),true),
  ('fixture-auto-pair','PAIR','Fixture Pair Conflict',10,pg_catalog.now(),true),
  ('fixture-auto-update','UPD','Fixture Auto Update',10,pg_catalog.now(),true);

INSERT INTO public.demo_trading_pairs(pair_symbol,base_coingecko_id,quote_asset,is_enabled)
VALUES ('PAIRUSDT','different-fixture-asset','USDT',true);

INSERT INTO public.exchange_asset_observations
  (exchange,market_symbol,base_symbol,quote_symbol,asset_name,coingecko_id,
   match_status,source_url,source_payload,is_active)
VALUES
  ('fixture','GOODUSDT','GOOD','USDT','Fixture Auto Good','fixture-auto-good','matched','https://fixture.invalid/good','{}',true),
  ('fixture','STALEUSDT','STALE','USDT','Fixture Auto Stale','fixture-auto-stale','matched','https://fixture.invalid/stale','{}',true),
  ('fixture','DUPUSDT','DUP','USDT','Fixture Duplicate One','fixture-auto-dup-1','matched','https://fixture.invalid/dup-one','{}',true),
  ('fixture','dupUSDT','dup','USDT','Fixture Duplicate Two','fixture-auto-dup-2','matched','https://fixture.invalid/dup-two','{}',true),
  ('fixture','PAIRUSDT','PAIR','USDT','Fixture Pair Conflict','fixture-auto-pair','matched','https://fixture.invalid/pair','{}',true),
  ('fixture','UPDUSDT','UPD','USDT','Fixture Auto Update','fixture-auto-update','pending','https://fixture.invalid/update','{}',true);

-- The transition from pending to matched must invoke the same trigger.
UPDATE public.exchange_asset_observations
SET match_status='matched'
WHERE coingecko_id='fixture-auto-update';

DO $assert$
DECLARE
  v_result_type text;
BEGIN
  IF (SELECT count(*) FROM public.admin_market_listings) <> 2
     OR NOT EXISTS (SELECT 1 FROM public.admin_market_listings WHERE coingecko_id='fixture-auto-good')
     OR NOT EXISTS (SELECT 1 FROM public.admin_market_listings WHERE coingecko_id='fixture-auto-update')
     OR EXISTS (SELECT 1 FROM public.admin_market_listings WHERE coingecko_id IN (
       'fixture-auto-stale','fixture-auto-dup-1','fixture-auto-dup-2','fixture-auto-pair'
     )) THEN
    RAISE EXCEPTION 'Auto-list trigger accepted or withheld an unexpected synthetic asset';
  END IF;

  SELECT pg_catalog.format_type(p.prorettype,NULL)
  INTO v_result_type
  FROM pg_catalog.pg_proc p
  WHERE p.oid='private.auto_list_verified_exchange_asset()'::regprocedure;

  IF v_result_type <> 'trigger'
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
       WHERE p.oid='private.auto_list_verified_exchange_asset()'::regprocedure
         AND p.prosecdef IS TRUE
         AND 'search_path=""'=ANY(p.proconfig)
     ) THEN
    RAISE EXCEPTION 'Auto-list trigger signature/security/search_path differs from Production';
  END IF;

  IF has_function_privilege('anon','private.auto_list_verified_exchange_asset()','EXECUTE')
     OR has_function_privilege('authenticated','private.auto_list_verified_exchange_asset()','EXECUTE')
     OR has_function_privilege('service_role','private.auto_list_verified_exchange_asset()','EXECUTE') THEN
    RAISE EXCEPTION 'Auto-list trigger unexpectedly grants EXECUTE to an API role';
  END IF;
END
$assert$;

ROLLBACK;

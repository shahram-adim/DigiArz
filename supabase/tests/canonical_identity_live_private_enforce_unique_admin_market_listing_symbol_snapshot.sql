-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: private.enforce_unique_admin_market_listing_symbol()
-- PostgreSQL md5(pg_get_functiondef(...)): 6e9a7e9f7d8cd5f0ac20f3216ee5f0b3
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=false, service_role=false.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION private.enforce_unique_admin_market_listing_symbol()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_symbol text;
BEGIN
  SELECT ca.symbol INTO v_symbol
  FROM public.crypto_assets ca
  WHERE ca.coingecko_id = NEW.coingecko_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Curated asset does not exist';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.admin_market_listings l
    JOIN public.crypto_assets other ON other.coingecko_id = l.coingecko_id
    WHERE l.coingecko_id <> NEW.coingecko_id
      AND pg_catalog.upper(other.symbol) = pg_catalog.upper(v_symbol)
  ) THEN
    RAISE EXCEPTION 'Another curated asset already uses this ticker';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.demo_trading_pairs dp
    WHERE dp.pair_symbol = pg_catalog.upper(v_symbol) || 'USDT'
      AND dp.base_coingecko_id <> NEW.coingecko_id
  ) THEN
    RAISE EXCEPTION 'Ticker conflicts with an existing demo trading pair';
  END IF;

  RETURN NEW;
END;
$function$
;

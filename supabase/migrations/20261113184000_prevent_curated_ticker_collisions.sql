CREATE OR REPLACE FUNCTION private.enforce_unique_admin_market_listing_symbol()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
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
$function$;

DROP TRIGGER IF EXISTS admin_market_listing_unique_ticker
  ON public.admin_market_listings;
CREATE TRIGGER admin_market_listing_unique_ticker
BEFORE INSERT OR UPDATE OF coingecko_id
ON public.admin_market_listings
FOR EACH ROW
EXECUTE FUNCTION private.enforce_unique_admin_market_listing_symbol();

REVOKE ALL ON FUNCTION private.enforce_unique_admin_market_listing_symbol()
  FROM PUBLIC, anon, authenticated, service_role;
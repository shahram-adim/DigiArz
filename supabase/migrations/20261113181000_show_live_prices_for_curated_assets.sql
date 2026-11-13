CREATE OR REPLACE FUNCTION public.get_admin_market_listings()
RETURNS TABLE (
  coingecko_id text,
  symbol text,
  name text,
  image_url text,
  market_cap_rank integer,
  current_price_usd numeric,
  price_toman numeric,
  price_change_percentage_24h numeric,
  total_volume_usd numeric,
  last_updated timestamptz,
  added_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT
    ca.coingecko_id,
    ca.symbol,
    ca.name,
    ca.image_url,
    ca.market_cap_rank,
    CASE
      WHEN mp.updated_at >= pg_catalog.now() - interval '2 minutes'
       AND mp.source = 'CoinGecko'
       AND mp.price > 0
      THEN mp.price
      ELSE NULL
    END AS current_price_usd,
    ca.price_toman,
    ca.price_change_percentage_24h,
    ca.total_volume_usd,
    mp.updated_at AS last_updated,
    l.created_at AS added_at
  FROM public.admin_market_listings AS l
  JOIN public.crypto_assets AS ca ON ca.coingecko_id = l.coingecko_id
  LEFT JOIN public.market_prices AS mp
    ON mp.symbol = pg_catalog.upper(ca.symbol) || 'USDT'
  WHERE ca.is_active IS TRUE
  ORDER BY l.created_at DESC, ca.market_cap_rank ASC NULLS LAST;
$function$;

REVOKE ALL ON FUNCTION public.get_admin_market_listings() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_admin_market_listings() TO anon, authenticated;
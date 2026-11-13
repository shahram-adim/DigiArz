-- Keep internal curator identity private; expose only the safe listing projection.
REVOKE ALL ON public.admin_market_listings FROM anon, authenticated;

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
  SELECT ca.coingecko_id, ca.symbol, ca.name, ca.image_url,
         ca.market_cap_rank, ca.current_price_usd, ca.price_toman,
         ca.price_change_percentage_24h, ca.total_volume_usd,
         ca.last_updated, l.created_at
  FROM public.admin_market_listings AS l
  JOIN public.crypto_assets AS ca ON ca.coingecko_id = l.coingecko_id
  WHERE ca.is_active IS TRUE
  ORDER BY l.created_at DESC, ca.market_cap_rank ASC NULLS LAST;
$function$;

CREATE OR REPLACE FUNCTION public.admin_search_market_assets(
  p_search text,
  p_limit integer DEFAULT 20
)
RETURNS TABLE (
  coingecko_id text,
  symbol text,
  name text,
  image_url text,
  market_cap_rank integer,
  current_price_usd numeric,
  last_updated timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_search text := btrim(COALESCE(p_search, ''));
BEGIN
  IF auth.uid() IS NULL OR NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'Super administrator access required' USING errcode = '42501';
  END IF;
  IF length(v_search) < 2 THEN
    RAISE EXCEPTION 'Search query must contain at least two characters';
  END IF;

  RETURN QUERY
  SELECT ca.coingecko_id, ca.symbol, ca.name, ca.image_url,
         ca.market_cap_rank, ca.current_price_usd, ca.last_updated
  FROM public.crypto_assets AS ca
  WHERE ca.is_active IS TRUE
    AND ca.current_price_usd > 0
    AND ca.last_updated >= now() - interval '24 hours'
    AND (
      ca.symbol ILIKE '%' || v_search || '%'
      OR ca.name ILIKE '%' || v_search || '%'
      OR ca.coingecko_id ILIKE '%' || v_search || '%'
    )
  ORDER BY ca.market_cap_rank ASC NULLS LAST
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 20), 1), 50);
END;
$function$;

REVOKE ALL ON FUNCTION public.get_admin_market_listings() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_admin_market_listings() TO anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_search_market_assets(text, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_search_market_assets(text, integer) TO authenticated;

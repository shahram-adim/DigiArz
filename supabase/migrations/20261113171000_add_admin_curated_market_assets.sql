-- Admin-curated market listings. These are visible in the market but remain
-- view-only until a separate, server-approved demo trading pair is enabled.
CREATE TABLE IF NOT EXISTS public.admin_market_listings (
  coingecko_id text PRIMARY KEY REFERENCES public.crypto_assets(coingecko_id) ON DELETE RESTRICT,
  added_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.admin_market_listings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_market_listings_public_read ON public.admin_market_listings;
CREATE POLICY admin_market_listings_public_read
  ON public.admin_market_listings
  FOR SELECT TO anon, authenticated
  USING (true);

REVOKE ALL ON public.admin_market_listings FROM anon, authenticated;
GRANT SELECT ON public.admin_market_listings TO anon, authenticated;

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

CREATE OR REPLACE FUNCTION public.admin_add_market_listing(p_coingecko_id text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_admin uuid := auth.uid();
  v_asset public.crypto_assets%ROWTYPE;
BEGIN
  IF v_admin IS NULL OR NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'Super administrator access required' USING errcode = '42501';
  END IF;
  IF p_coingecko_id IS NULL OR length(btrim(p_coingecko_id)) NOT BETWEEN 1 AND 128 THEN
    RAISE EXCEPTION 'Invalid CoinGecko asset id';
  END IF;

  SELECT * INTO v_asset
  FROM public.crypto_assets
  WHERE coingecko_id = btrim(p_coingecko_id)
    AND is_active IS TRUE
    AND current_price_usd > 0
    AND last_updated >= now() - interval '24 hours';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Asset not found, inactive, or market data is stale';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.demo_trading_pairs
    WHERE base_coingecko_id = v_asset.coingecko_id
  ) THEN
    RAISE EXCEPTION 'Asset already exists in the demo trading-pair list';
  END IF;

  INSERT INTO public.admin_market_listings(coingecko_id, added_by)
  VALUES (v_asset.coingecko_id, v_admin)
  ON CONFLICT (coingecko_id) DO NOTHING;

  RETURN jsonb_build_object(
    'success', true,
    'coingecko_id', v_asset.coingecko_id,
    'symbol', v_asset.symbol,
    'name', v_asset.name
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_remove_market_listing(p_coingecko_id text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_admin uuid := auth.uid();
  v_deleted integer;
BEGIN
  IF v_admin IS NULL OR NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'Super administrator access required' USING errcode = '42501';
  END IF;
  DELETE FROM public.admin_market_listings
  WHERE coingecko_id = btrim(p_coingecko_id);
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN jsonb_build_object('success', true, 'removed', v_deleted > 0);
END;
$function$;

REVOKE ALL ON FUNCTION public.get_admin_market_listings() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_admin_market_listings() TO anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_add_market_listing(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_remove_market_listing(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_add_market_listing(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_remove_market_listing(text) TO authenticated;

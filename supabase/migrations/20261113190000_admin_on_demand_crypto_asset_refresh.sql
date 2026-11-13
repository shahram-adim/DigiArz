CREATE TABLE IF NOT EXISTS private.admin_asset_refresh_limits (
  coingecko_id text PRIMARY KEY,
  last_requested_at timestamptz NOT NULL,
  requested_by uuid NOT NULL
);
ALTER TABLE private.admin_asset_refresh_limits ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.admin_asset_refresh_limits FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.claim_admin_asset_refresh(
  p_coingecko_id text,
  p_admin_user_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_claimed boolean := false;
BEGIN
  IF p_admin_user_id IS NULL
     OR p_coingecko_id IS NULL
     OR pg_catalog.length(pg_catalog.btrim(p_coingecko_id)) NOT BETWEEN 1 AND 128 THEN
    RAISE EXCEPTION 'Invalid refresh request' USING errcode = '22023';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM private.admin_users a
    WHERE a.user_id = p_admin_user_id
      AND a.role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Super administrator access required' USING errcode = '42501';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    742021,
    pg_catalog.hashtext(pg_catalog.btrim(p_coingecko_id))
  );

  INSERT INTO private.admin_asset_refresh_limits(
    coingecko_id, last_requested_at, requested_by
  )
  VALUES (pg_catalog.btrim(p_coingecko_id), pg_catalog.now(), p_admin_user_id)
  ON CONFLICT (coingecko_id) DO UPDATE
    SET last_requested_at = EXCLUDED.last_requested_at,
        requested_by = EXCLUDED.requested_by
    WHERE private.admin_asset_refresh_limits.last_requested_at
          <= pg_catalog.now() - interval '30 seconds'
  RETURNING true INTO v_claimed;

  IF NOT COALESCE(v_claimed, false) THEN
    RAISE EXCEPTION 'This asset was refreshed recently; wait 30 seconds'
      USING errcode = '55000';
  END IF;

  RETURN true;
END;
$function$;

REVOKE ALL ON FUNCTION public.claim_admin_asset_refresh(text, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.claim_admin_asset_refresh(text, uuid) TO service_role;

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
  v_search text := pg_catalog.btrim(COALESCE(p_search, ''));
BEGIN
  IF auth.uid() IS NULL OR NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'Super administrator access required' USING errcode = '42501';
  END IF;
  IF pg_catalog.length(v_search) < 2 THEN
    RAISE EXCEPTION 'Search query must contain at least two characters';
  END IF;

  RETURN QUERY
  SELECT ca.coingecko_id, ca.symbol, ca.name, ca.image_url,
         ca.market_cap_rank, ca.current_price_usd, ca.last_updated
  FROM public.crypto_assets AS ca
  WHERE ca.is_active IS TRUE
    AND (
      ca.symbol ILIKE '%' || v_search || '%'
      OR ca.name ILIKE '%' || v_search || '%'
      OR ca.coingecko_id ILIKE '%' || v_search || '%'
    )
  ORDER BY ca.market_cap_rank ASC NULLS LAST
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 20), 1), 50);
END;
$function$;

REVOKE ALL ON FUNCTION public.admin_search_market_assets(text, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_search_market_assets(text, integer) TO authenticated;

-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: admin_search_market_assets(text,integer)
-- PostgreSQL md5(pg_get_functiondef(...)): f5dfc59bd5c47065692601c46590cffc
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.admin_search_market_assets(p_search text, p_limit integer DEFAULT 20)
 RETURNS TABLE(coingecko_id text, symbol text, name text, image_url text, market_cap_rank integer, current_price_usd numeric, last_updated timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
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
$function$
;

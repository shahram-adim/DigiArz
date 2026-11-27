-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: get_crypto_assets(text,integer,integer,text)
-- PostgreSQL md5(pg_get_functiondef(...)): b85d4a1073e425c2ac29899152168cf2
-- Verified metadata: owner=postgres; SECURITY DEFINER=false; config=search_path=""; EXECUTE anon=true, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.get_crypto_assets(p_search text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0, p_sort text DEFAULT 'rank'::text)
 RETURNS TABLE(coingecko_id text, symbol text, name text, image_url text, market_cap_rank integer, current_price_usd numeric, price_toman numeric, price_change_percentage_24h numeric, market_cap_usd numeric, total_volume_usd numeric, last_updated timestamp with time zone, total_count bigint)
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
    SELECT
        ca.coingecko_id,
        ca.symbol,
        ca.name,
        ca.image_url,
        ca.market_cap_rank,
        ca.current_price_usd,
        ca.price_toman,
        ca.price_change_percentage_24h,
        ca.market_cap_usd,
        ca.total_volume_usd,
        ca.last_updated,
        COUNT(*) OVER() AS total_count
    FROM public.crypto_assets ca
    WHERE ca.is_active = TRUE
      AND (
          NULLIF(BTRIM(p_search), '') IS NULL
          OR ca.name ILIKE '%' || BTRIM(p_search) || '%'
          OR ca.symbol ILIKE '%' || BTRIM(p_search) || '%'
          OR ca.coingecko_id ILIKE '%' || BTRIM(p_search) || '%'
      )
    ORDER BY
        CASE WHEN p_sort = 'rank'
             THEN ca.market_cap_rank END ASC NULLS LAST,
        CASE WHEN p_sort = 'price'
             THEN ca.current_price_usd END DESC NULLS LAST,
        CASE WHEN p_sort = 'market_cap'
             THEN ca.market_cap_usd END DESC NULLS LAST,
        CASE WHEN p_sort = 'volume'
             THEN ca.total_volume_usd END DESC NULLS LAST,
        ca.market_cap_rank ASC NULLS LAST
    LIMIT LEAST(GREATEST(COALESCE(p_limit, 50), 1), 100)
    OFFSET GREATEST(COALESCE(p_offset, 0), 0);
$function$
;

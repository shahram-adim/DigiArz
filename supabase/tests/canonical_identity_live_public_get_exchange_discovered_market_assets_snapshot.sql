-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: get_exchange_discovered_market_assets()
-- PostgreSQL md5(pg_get_functiondef(...)): 87f9f56829abb50b2ff1fb878684e89c
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=true, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.get_exchange_discovered_market_assets()
 RETURNS TABLE(symbol text, name text, current_price_usd numeric, last_updated timestamp with time zone, exchange_sources text, exchange_count integer, observed_at timestamp with time zone, match_status text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  WITH active_observations AS (
    SELECT upper(o.base_symbol) AS symbol,
           nullif(btrim(o.asset_name), '') AS asset_name,
           o.exchange, o.last_seen_at, o.match_status
    FROM public.exchange_asset_observations AS o
    WHERE o.is_active IS TRUE
      AND o.base_symbol ~ '^[A-Z0-9]{2,20}$'
      AND o.last_seen_at >= pg_catalog.now() - interval '48 hours'
      AND o.match_status IN ('pending', 'ambiguous', 'unmatched')
      AND coalesce(o.asset_name, '') !~* '(stock|equity|shares|xstock|tokenized)'
      AND NOT EXISTS (
        SELECT 1
        FROM public.admin_market_listings AS l
        JOIN public.crypto_assets AS ca ON ca.coingecko_id = l.coingecko_id
        WHERE upper(ca.symbol) = upper(o.base_symbol)
      )
      AND NOT EXISTS (
        SELECT 1
        FROM public.demo_trading_pairs AS dp
        JOIN public.crypto_assets AS ca ON ca.coingecko_id = dp.base_coingecko_id
        WHERE upper(ca.symbol) = upper(o.base_symbol)
          AND dp.is_enabled IS TRUE
      )
  ),
  grouped AS (
    SELECT symbol,
           (array_agg(asset_name ORDER BY last_seen_at DESC)
             FILTER (WHERE asset_name IS NOT NULL))[1] AS name,
           array_to_string(array_agg(DISTINCT exchange ORDER BY exchange), ', ') AS exchange_sources,
           count(DISTINCT exchange)::integer AS exchange_count,
           max(last_seen_at) AS observed_at,
           CASE WHEN bool_or(match_status = 'ambiguous') THEN 'ambiguous' ELSE 'unmatched' END AS match_status
    FROM active_observations
    GROUP BY symbol
  )
  SELECT g.symbol,
         coalesce(g.name, g.symbol) AS name,
         mp.price AS current_price_usd,
         mp.updated_at AS last_updated,
         g.exchange_sources,
         g.exchange_count,
         g.observed_at,
         g.match_status
  FROM grouped AS g
  LEFT JOIN public.market_prices AS mp
    ON mp.symbol = g.symbol || 'USDT'
   AND mp.price > 0
   AND mp.updated_at >= pg_catalog.now() - interval '2 minutes'
  ORDER BY g.observed_at DESC, g.symbol;
$function$
;

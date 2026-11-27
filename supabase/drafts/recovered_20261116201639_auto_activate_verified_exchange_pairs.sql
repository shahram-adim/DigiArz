-- RECOVERED HISTORICAL PRODUCTION MIGRATION SOURCE
-- Migration version: 20261116201639
-- Name: auto_activate_verified_exchange_pairs
-- Source: Production supabase_migrations.schema_migrations.statements (read-only retrieval, 2026-11-25).
-- STATUS: REVIEW-ONLY / HISTORICAL REFERENCE. NOT AN EXECUTABLE MIGRATION.
-- This file is intentionally under supabase/drafts/, not supabase/migrations/.
-- Do NOT run, replay, or copy into a migration directory without separate review
-- and explicit owner approval. This migration is already recorded as applied in Production.

CREATE OR REPLACE FUNCTION private.auto_activate_verified_exchange_pairs()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_inserted integer := 0;
BEGIN
  WITH eligible AS (
    SELECT
      ca.coingecko_id,
      pg_catalog.upper(ca.symbol) || 'USDT' AS pair_symbol
    FROM public.crypto_assets AS ca
    JOIN public.admin_market_listings AS l
      ON l.coingecko_id = ca.coingecko_id
    JOIN public.market_prices AS mp
      ON mp.symbol = pg_catalog.upper(ca.symbol) || 'USDT'
    WHERE ca.is_active IS TRUE
      AND ca.symbol ~ '^[A-Za-z0-9]{2,15}$'
      AND pg_catalog.upper(ca.symbol) <> 'USDT'
      AND ca.current_price_usd > 0
      AND ca.last_updated >= pg_catalog.now() - interval '24 hours'
      AND ca.total_volume_usd >= 1000000
      AND (ca.market_cap_rank IS NULL OR ca.market_cap_rank <= 2000)
      AND mp.price > 0
      AND mp.source = 'CoinGecko'
      AND mp.updated_at >= pg_catalog.now() - interval '2 minutes'
      AND EXISTS (
        SELECT 1
        FROM public.exchange_asset_observations AS o
        WHERE o.coingecko_id = ca.coingecko_id
          AND o.match_status = 'matched'
          AND o.is_active IS TRUE
          AND o.last_seen_at >= pg_catalog.now() - interval '48 hours'
      )
      AND (
        SELECT pg_catalog.count(*)
        FROM public.crypto_assets AS other
        WHERE other.is_active IS TRUE
          AND pg_catalog.upper(other.symbol) = pg_catalog.upper(ca.symbol)
      ) = 1
      AND NOT EXISTS (
        SELECT 1
        FROM public.demo_trading_pairs AS conflict
        WHERE conflict.pair_symbol = pg_catalog.upper(ca.symbol) || 'USDT'
          AND conflict.base_coingecko_id <> ca.coingecko_id
      )
  )
  INSERT INTO public.demo_trading_pairs(
    pair_symbol, base_coingecko_id, quote_asset, is_enabled, created_at, updated_at
  )
  SELECT pair_symbol, coingecko_id, 'USDT', true, pg_catalog.now(), pg_catalog.now()
  FROM eligible
  ON CONFLICT (pair_symbol) DO NOTHING;

  GET DIAGNOSTICS v_inserted = ROW_COUNT;

  RETURN pg_catalog.jsonb_build_object(
    'success', true,
    'activated_pairs', v_inserted,
    'checked_at', pg_catalog.now(),
    'policy', 'automatic_verified_exchange_listing'
  );
END;
$function$;

REVOKE ALL ON FUNCTION private.auto_activate_verified_exchange_pairs() FROM PUBLIC, anon, authenticated;

SELECT cron.schedule(
  'digiarz-auto-activate-verified-exchange-pairs',
  '* * * * *',
  'SELECT private.auto_activate_verified_exchange_pairs();'
);
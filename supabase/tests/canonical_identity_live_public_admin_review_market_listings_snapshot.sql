-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: admin_review_market_listings()
-- PostgreSQL md5(pg_get_functiondef(...)): 93e96328ff9b8d8f3739b57ce49eb397
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.admin_review_market_listings()
 RETURNS TABLE(coingecko_id text, symbol text, name text, pair_symbol text, current_price_usd numeric, total_volume_usd numeric, market_cap_rank integer, metadata_updated_at timestamp with time zone, market_price numeric, price_source text, price_updated_at timestamp with time zone, price_age_seconds numeric, is_enabled boolean, is_eligible boolean, eligibility_reason text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  WITH rows AS (
    SELECT
      ca.coingecko_id,
      ca.symbol,
      ca.name,
      pg_catalog.upper(ca.symbol) || 'USDT' AS pair_symbol,
      ca.current_price_usd,
      ca.total_volume_usd,
      ca.market_cap_rank,
      ca.last_updated AS metadata_updated_at,
      mp.price AS market_price,
      mp.source AS price_source,
      mp.updated_at AS price_updated_at,
      CASE WHEN mp.updated_at IS NULL THEN NULL
           ELSE EXTRACT(EPOCH FROM (pg_catalog.now() - mp.updated_at)) END AS price_age_seconds,
      COALESCE(dp.is_enabled, false) AS is_enabled,
      ca.is_active,
      EXISTS (
        SELECT 1 FROM public.demo_trading_pairs AS other
        WHERE other.pair_symbol = pg_catalog.upper(ca.symbol) || 'USDT'
          AND other.base_coingecko_id <> ca.coingecko_id
      ) AS symbol_conflict
    FROM public.admin_market_listings AS l
    JOIN public.crypto_assets AS ca ON ca.coingecko_id = l.coingecko_id
    LEFT JOIN public.market_prices AS mp
      ON mp.symbol = pg_catalog.upper(ca.symbol) || 'USDT'
    LEFT JOIN public.demo_trading_pairs AS dp
      ON dp.base_coingecko_id = ca.coingecko_id
  )
  SELECT
    x.coingecko_id, x.symbol, x.name, x.pair_symbol,
    x.current_price_usd, x.total_volume_usd, x.market_cap_rank,
    x.metadata_updated_at, x.market_price, x.price_source,
    x.price_updated_at, x.price_age_seconds, x.is_enabled,
    (
      x.is_active IS TRUE
      AND x.symbol ~ '^[A-Za-z0-9]{2,15}$'
      AND pg_catalog.upper(x.symbol) <> 'USDT'
      AND x.current_price_usd > 0
      AND x.metadata_updated_at >= pg_catalog.now() - interval '24 hours'
      AND x.total_volume_usd >= 1000000
      AND (x.market_cap_rank IS NULL OR x.market_cap_rank <= 2000)
      AND x.market_price > 0
      AND x.price_source = 'CoinGecko'
      AND x.price_updated_at >= pg_catalog.now() - interval '2 minutes'
      AND NOT x.symbol_conflict
    ) AS is_eligible,
    CASE
      WHEN x.is_active IS NOT TRUE THEN 'ارز در کاتالوگ غیرفعال است'
      WHEN x.symbol !~ '^[A-Za-z0-9]{2,15}$' OR pg_catalog.upper(x.symbol) = 'USDT' THEN 'نماد ارز برای جفت USDT معتبر نیست'
      WHEN x.current_price_usd IS NULL OR x.current_price_usd <= 0 THEN 'قیمت مرجع معتبر نیست'
      WHEN x.metadata_updated_at IS NULL OR x.metadata_updated_at < pg_catalog.now() - interval '24 hours' THEN 'اطلاعات بازار ارز قدیمی‌تر از ۲۴ ساعت است'
      WHEN x.total_volume_usd IS NULL OR x.total_volume_usd < 1000000 THEN 'حجم معاملات ۲۴ساعته کمتر از یک میلیون دلار است'
      WHEN x.market_cap_rank IS NOT NULL AND x.market_cap_rank > 2000 THEN 'رتبه ارزش بازار خارج از محدوده مجاز است'
      WHEN x.market_price IS NULL OR x.market_price <= 0 THEN 'هنوز قیمت زنده برای این جفت‌ارز دریافت نشده است'
      WHEN x.price_source <> 'CoinGecko' THEN 'منبع قیمت تأیید نشده است'
      WHEN x.price_updated_at IS NULL OR x.price_updated_at < pg_catalog.now() - interval '2 minutes' THEN 'قیمت زنده قدیمی‌تر از دو دقیقه است'
      WHEN x.symbol_conflict THEN 'نماد این جفت‌ارز با دارایی دیگری تداخل دارد'
      ELSE 'آماده فعال‌سازی'
    END AS eligibility_reason
  FROM rows AS x
  WHERE auth.uid() IS NOT NULL
    AND private.is_super_admin()
  ORDER BY x.metadata_updated_at DESC NULLS LAST, x.symbol;
$function$
;

-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: refresh_crypto_assets_toman()
-- PostgreSQL md5(pg_get_functiondef(...)): bc9daf5e57307e82fd5188798624b116
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=false, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.refresh_crypto_assets_toman()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
    UPDATE public.crypto_assets AS ca
    SET price_toman = ROUND(
        ca.current_price_usd * fx.price_toman,
        2
    )
    FROM public.market_fx_rates AS fx
    WHERE fx.symbol = 'USD_IRT'
      AND fx.is_stale = FALSE
      AND fx.updated_at >= NOW() - INTERVAL '30 minutes'
      AND ca.current_price_usd IS NOT NULL
      AND ca.price_toman IS DISTINCT FROM ROUND(
          ca.current_price_usd * fx.price_toman,
          2
      );
END;
$function$
;

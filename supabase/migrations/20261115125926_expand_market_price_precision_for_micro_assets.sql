-- Preserve micro-asset prices that are smaller than 1e-8 USD.
-- numeric(28,8) rounded Baby Doge Coin and Vita Inu prices to zero,
-- violating market_prices_price_check and aborting the entire refresh batch.
DROP VIEW IF EXISTS public.market_prices_with_toman;

ALTER TABLE public.market_prices
  ALTER COLUMN price TYPE numeric(38,18);

CREATE VIEW public.market_prices_with_toman
WITH (security_invoker = true)
AS
SELECT
  p.symbol,
  p.price AS price_usd,
  round((p.price * fx.price_toman), 0) AS price_toman,
  fx.price_toman AS usd_rate_toman,
  p.source,
  p.updated_at,
  fx.updated_at AS fx_updated_at,
  fx.is_stale AS fx_is_stale
FROM public.market_prices p
CROSS JOIN public.market_fx_rates fx
WHERE fx.symbol = 'USD_IRT'::text;

GRANT ALL ON public.market_prices_with_toman TO service_role;
GRANT SELECT ON public.market_prices_with_toman TO anon, authenticated;

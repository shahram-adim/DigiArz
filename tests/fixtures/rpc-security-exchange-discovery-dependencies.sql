-- Additional synthetic dependencies for the exact exchange-discovery migration.
-- The observations table is already created by the base PostgreSQL 17 bootstrap.
\set ON_ERROR_STOP on

CREATE TABLE public.demo_trading_pairs (
  pair_symbol text NOT NULL,
  base_coingecko_id text NOT NULL,
  quote_asset text NOT NULL DEFAULT 'USDT',
  is_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.exchange_asset_observations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demo_trading_pairs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS demo_trading_pairs_public_read ON public.demo_trading_pairs;
CREATE POLICY demo_trading_pairs_public_read
  ON public.demo_trading_pairs
  FOR SELECT TO anon, authenticated
  USING (true);

REVOKE ALL ON public.exchange_asset_observations, public.demo_trading_pairs
  FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON public.demo_trading_pairs TO anon, authenticated;
GRANT ALL ON public.demo_trading_pairs TO service_role;

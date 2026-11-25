-- Additional synthetic dependencies for the exact exchange-discovery migration.
-- The observations table is already created by the base PostgreSQL 17 bootstrap.
\set ON_ERROR_STOP on

CREATE TABLE public.demo_trading_pairs (
  base_coingecko_id text NOT NULL,
  is_enabled boolean NOT NULL DEFAULT false
);

ALTER TABLE public.exchange_asset_observations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demo_trading_pairs ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.exchange_asset_observations, public.demo_trading_pairs
  FROM PUBLIC, anon, authenticated, service_role;

-- Additional synthetic dependencies for the exact exchange-discovery migration.
-- The observations table is already created by the base PostgreSQL 17 bootstrap.
\set ON_ERROR_STOP on

CREATE TABLE auth.users (
  id uuid PRIMARY KEY
);
INSERT INTO auth.users(id)
VALUES ('22222222-2222-4222-8222-222222222222');

-- Shared synthetic FK target used by existing ticker-conflict integration fixtures.
INSERT INTO public.crypto_assets
  (coingecko_id,symbol,name,market_cap_rank,current_price_usd,total_volume_usd,last_updated,is_active)
VALUES ('different-fixture-asset','DIFF','Fixture Pair Owner',1,1,1000000,now(),true);

CREATE TABLE public.demo_trading_pairs (
  pair_symbol text PRIMARY KEY,
  base_coingecko_id text NOT NULL UNIQUE REFERENCES public.crypto_assets(coingecko_id),
  quote_asset text NOT NULL DEFAULT 'USDT' CHECK (quote_asset = 'USDT'),
  is_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (pair_symbol ~ '^[A-Z0-9]{2,15}USDT$')
);

CREATE TABLE private.market_pair_admin_audit (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pair_symbol text NOT NULL,
  coingecko_id text NOT NULL,
  action text NOT NULL CHECK (action IN ('enabled','disabled')),
  admin_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  reason text,
  validation_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE private.market_pair_admin_audit ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.market_pair_admin_audit FROM PUBLIC, anon, authenticated, service_role;
CREATE INDEX market_pair_admin_audit_pair_created_idx
  ON private.market_pair_admin_audit(pair_symbol, created_at DESC);

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

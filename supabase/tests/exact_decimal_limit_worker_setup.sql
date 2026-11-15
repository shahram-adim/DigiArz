-- Isolated PostgreSQL 17 fixture for the exact-decimal Limit worker.
-- This file is used only by the disposable GitHub Actions PostgreSQL service.
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY,
  is_active boolean NOT NULL
);
CREATE TABLE public.orders (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL,
  symbol text NOT NULL,
  side text NOT NULL,
  order_type text NOT NULL,
  amount numeric(34,18) NOT NULL,
  price numeric(34,18) NOT NULL,
  filled_amount numeric(34,18) NOT NULL,
  remaining_amount numeric(34,18) NOT NULL,
  status text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.demo_trading_pairs (
  pair_symbol text PRIMARY KEY,
  quote_asset text NOT NULL,
  is_enabled boolean NOT NULL
);
CREATE TABLE public.market_prices (
  symbol text PRIMARY KEY,
  price numeric(38,18) NOT NULL,
  updated_at timestamptz NOT NULL
);
CREATE TABLE public.order_reservations (
  id uuid PRIMARY KEY,
  order_id uuid NOT NULL UNIQUE,
  user_id uuid NOT NULL,
  asset text NOT NULL,
  reserved_amount numeric(38,18) NOT NULL,
  consumed_amount numeric(38,18) NOT NULL,
  released_amount numeric(38,18) NOT NULL,
  status text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.wallets (
  user_id uuid PRIMARY KEY,
  balance_usdt numeric(24,8) NOT NULL
);
CREATE TABLE public.asset_balances (
  user_id uuid NOT NULL,
  asset text NOT NULL,
  balance numeric(38,18) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, asset)
);
CREATE TABLE public.trades (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id uuid NOT NULL,
  user_id uuid NOT NULL,
  symbol text NOT NULL,
  side text NOT NULL,
  amount numeric(34,18) NOT NULL,
  price numeric(34,18) NOT NULL
);
CREATE TABLE public.transactions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id uuid NOT NULL,
  currency text NOT NULL,
  amount numeric(24,8) NOT NULL,
  transaction_type text NOT NULL,
  description text NOT NULL
);
CREATE FUNCTION public.get_demo_trading_fee_rate(p_quote text, p_kind text)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
SET search_path TO ''
AS $fee$
  SELECT 0.001::numeric
$fee$;

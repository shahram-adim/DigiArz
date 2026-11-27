-- Disposable PostgreSQL 17 only. Applies the authoritative Market/Limit migration
-- in CI; never run this setup or its migration against Production.
CREATE SCHEMA IF NOT EXISTS auth;
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN CREATE ROLE anon NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='service_role') THEN CREATE ROLE service_role NOLOGIN; END IF;
END
$roles$;
CREATE FUNCTION auth.uid() RETURNS uuid
LANGUAGE sql STABLE SET search_path TO ''
AS $f$ SELECT nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $f$;
CREATE TABLE public.profiles(id uuid PRIMARY KEY,is_active boolean NOT NULL);
CREATE FUNCTION public.current_account_is_active() RETURNS boolean
LANGUAGE sql STABLE SET search_path TO ''
AS $f$ SELECT EXISTS(SELECT 1 FROM public.profiles WHERE id=auth.uid() AND is_active IS TRUE) $f$;
CREATE TABLE public.orders(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL,
 symbol text NOT NULL,side text NOT NULL,order_type text NOT NULL,
 amount numeric(34,18) NOT NULL,price numeric(34,18) NOT NULL,
 filled_amount numeric(34,18) NOT NULL DEFAULT 0,
 remaining_amount numeric(34,18) NOT NULL DEFAULT 0,
 status text NOT NULL DEFAULT 'pending',created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.demo_trading_pairs(pair_symbol text PRIMARY KEY,quote_asset text NOT NULL,is_enabled boolean NOT NULL);
CREATE TABLE public.market_prices(symbol text PRIMARY KEY,price numeric(38,18) NOT NULL,updated_at timestamptz NOT NULL);
CREATE TABLE public.order_reservations(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),order_id uuid NOT NULL UNIQUE,
 user_id uuid NOT NULL,asset text NOT NULL,reserved_amount numeric(38,18) NOT NULL,
 consumed_amount numeric(38,18) NOT NULL DEFAULT 0,released_amount numeric(38,18) NOT NULL DEFAULT 0,
 status text NOT NULL,updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.wallets(user_id uuid PRIMARY KEY,balance_usdt numeric(24,8) NOT NULL DEFAULT 0);
CREATE TABLE public.asset_balances(
 user_id uuid NOT NULL,asset text NOT NULL,balance numeric(38,18) NOT NULL,
 updated_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(user_id,asset)
);
CREATE TABLE public.trades(
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,order_id uuid NOT NULL,user_id uuid NOT NULL,
 symbol text NOT NULL,side text NOT NULL,amount numeric(34,18) NOT NULL,price numeric(34,18) NOT NULL
);
CREATE TABLE public.transactions(
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,user_id uuid NOT NULL,currency text NOT NULL,
 amount numeric(24,8) NOT NULL,transaction_type text NOT NULL,description text NOT NULL
);
CREATE FUNCTION public.get_demo_trading_fee_rate(p_quote text,p_kind text) RETURNS numeric
LANGUAGE sql IMMUTABLE SET search_path TO ''
AS $f$ SELECT 0.001::numeric $f$;

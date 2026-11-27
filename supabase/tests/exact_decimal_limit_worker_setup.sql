-- Isolated PostgreSQL 17 fixture for the exact-decimal Limit worker.
-- This file is used only by the disposable GitHub Actions PostgreSQL service.
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY,
  is_active boolean NOT NULL
);

CREATE SCHEMA private;
CREATE FUNCTION private.guard_active_account_writes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_active boolean;
BEGIN
  SELECT p.is_active INTO v_active
  FROM public.profiles p
  WHERE p.id = NEW.user_id
  FOR SHARE;

  IF COALESCE(v_active, false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Account is inactive; reactivate the account before trading';
  END IF;

  RETURN NEW;
END;
$function$;
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

-- Match Production's active-account INSERT guards on all three ledger tables.
CREATE TRIGGER guard_active_account_orders
BEFORE INSERT ON public.orders
FOR EACH ROW EXECUTE FUNCTION private.guard_active_account_writes();

CREATE TRIGGER guard_active_account_trades
BEFORE INSERT ON public.trades
FOR EACH ROW EXECUTE FUNCTION private.guard_active_account_writes();

CREATE TRIGGER guard_active_account_transactions
BEFORE INSERT ON public.transactions
FOR EACH ROW EXECUTE FUNCTION private.guard_active_account_writes();

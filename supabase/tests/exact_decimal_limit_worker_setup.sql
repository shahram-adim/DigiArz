-- Isolated PostgreSQL 17 fixture for the exact-decimal Limit worker.
-- Mirrors the live Production catalog for the worker's dependency tables,
-- with only the numeric widening proposal applied to the five target ledgers.
-- This file is used only by the disposable GitHub Actions PostgreSQL service.

DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN EXECUTE 'CREATE ROLE anon NOLOGIN'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN EXECUTE 'CREATE ROLE authenticated NOLOGIN'; END IF;
END
$roles$;

CREATE SCHEMA auth;
CREATE TABLE auth.users (id uuid PRIMARY KEY);
CREATE FUNCTION auth.uid() RETURNS uuid
LANGUAGE sql STABLE
AS $uid$ SELECT NULL::uuid $uid$;

CREATE SCHEMA private;
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  created_at timestamptz DEFAULT now(),
  is_active boolean NOT NULL DEFAULT true,
  deactivated_at timestamptz
);

CREATE FUNCTION public.current_account_is_active()
RETURNS boolean LANGUAGE sql STABLE
AS $active$ SELECT true $active$;

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

CREATE TABLE public.crypto_assets (
  coingecko_id text PRIMARY KEY
);

CREATE TABLE public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  symbol text NOT NULL,
  side text NOT NULL,
  order_type text NOT NULL DEFAULT 'market',
  amount numeric(34,18) NOT NULL,
  price numeric(34,18),
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  filled_amount numeric(34,18) NOT NULL DEFAULT 0,
  remaining_amount numeric(34,18) NOT NULL,
  CONSTRAINT orders_amount_accounting_chk CHECK (filled_amount + remaining_amount = amount),
  CONSTRAINT orders_amount_positive CHECK (amount > 0),
  CONSTRAINT orders_filled_amount_range_chk CHECK (filled_amount >= 0 AND filled_amount <= amount),
  CONSTRAINT orders_id_user_id_unique UNIQUE (id,user_id),
  CONSTRAINT orders_limit_price_required_chk CHECK (order_type <> 'limit' OR price IS NOT NULL),
  CONSTRAINT orders_price_positive CHECK (price IS NULL OR price > 0),
  CONSTRAINT orders_remaining_amount_range_chk CHECK (remaining_amount >= 0 AND remaining_amount <= amount),
  CONSTRAINT orders_side_check CHECK (side = ANY (ARRAY['buy','sell'])),
  CONSTRAINT orders_status_valid CHECK (status = ANY (ARRAY['pending','partially_filled','triggered','filled','cancelled','rejected'])),
  CONSTRAINT orders_type_valid CHECK (order_type = ANY (ARRAY['market','limit','conditional']))
);
CREATE INDEX orders_limit_active_created_at_idx
  ON public.orders(created_at)
  WHERE order_type='limit' AND status IN ('pending','partially_filled');

CREATE TABLE public.demo_trading_pairs (
  pair_symbol text PRIMARY KEY,
  base_coingecko_id text NOT NULL REFERENCES public.crypto_assets(coingecko_id),
  quote_asset text NOT NULL DEFAULT 'USDT',
  is_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT demo_trading_pairs_quote_check CHECK (quote_asset='USDT'),
  CONSTRAINT demo_trading_pairs_symbol_format CHECK (pair_symbol ~ '^[A-Z0-9]{2,15}USDT$'),
  CONSTRAINT demo_trading_pairs_unique_base UNIQUE (base_coingecko_id)
);

CREATE TABLE public.market_prices (
  symbol text PRIMARY KEY,
  price numeric(38,18) NOT NULL,
  source text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT market_prices_price_check CHECK (price > 0)
);

CREATE TABLE public.order_reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL,
  user_id uuid NOT NULL,
  asset text NOT NULL,
  reserved_amount numeric(38,18) NOT NULL,
  released_amount numeric(38,18) NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'reserved',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  consumed_amount numeric(38,18) NOT NULL DEFAULT 0,
  CONSTRAINT order_reservations_accounting_check CHECK (consumed_amount >= 0 AND consumed_amount + released_amount <= reserved_amount),
  CONSTRAINT order_reservations_amount_check CHECK (released_amount <= reserved_amount),
  CONSTRAINT order_reservations_order_user_fk FOREIGN KEY (order_id,user_id)
    REFERENCES public.orders(id,user_id) ON DELETE CASCADE,
  CONSTRAINT order_reservations_released_amount_check CHECK (released_amount >= 0),
  CONSTRAINT order_reservations_reserved_amount_check CHECK (reserved_amount > 0),
  CONSTRAINT order_reservations_status_check CHECK (status = ANY (ARRAY['reserved','released','consumed']))
);
CREATE UNIQUE INDEX order_reservations_order_unique ON public.order_reservations(order_id);
CREATE INDEX order_reservations_user_status_idx ON public.order_reservations(user_id,status);

CREATE TABLE public.wallets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  balance_usdt numeric(24,8) NOT NULL DEFAULT 200,
  balance_irr numeric(24,0) NOT NULL DEFAULT 1000000000,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT wallets_nonnegative_balance CHECK (balance_usdt >= 0 AND balance_irr >= 0)
);

CREATE TABLE public.asset_balances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  asset text NOT NULL,
  balance numeric(38,18) NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT asset_balances_asset_upper CHECK (asset=upper(asset)),
  CONSTRAINT asset_balances_nonnegative CHECK (balance >= 0),
  CONSTRAINT asset_balances_user_asset_unique UNIQUE (user_id,asset)
);

CREATE TABLE public.trades (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  symbol text NOT NULL,
  side text NOT NULL,
  amount numeric(34,18) NOT NULL,
  price numeric(34,18) NOT NULL,
  created_at timestamptz DEFAULT now(),
  order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  CONSTRAINT trades_amount_positive CHECK (amount > 0),
  CONSTRAINT trades_price_positive CHECK (price > 0),
  CONSTRAINT trades_side_valid CHECK (side = ANY (ARRAY['buy','sell']))
);
CREATE INDEX trades_order_id_created_at_idx ON public.trades(order_id,created_at);

CREATE TABLE public.transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  currency text NOT NULL,
  amount numeric(24,8) NOT NULL,
  transaction_type text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT transactions_amount_nonzero CHECK (amount <> 0)
);

CREATE FUNCTION public.get_demo_trading_fee_rate(p_quote text, p_kind text)
RETURNS numeric LANGUAGE sql IMMUTABLE SET search_path TO ''
AS $fee$ SELECT 0.001::numeric $fee$;

-- Production RLS metadata; the postgres CI owner bypasses RLS just as the
-- SECURITY DEFINER worker owner does, while catalog parity remains testable.
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demo_trading_pairs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View own profile" ON public.profiles FOR SELECT USING (auth.uid()=id);
CREATE POLICY "View own orders" ON public.orders FOR SELECT TO authenticated
  USING (auth.uid()=user_id AND current_account_is_active());
CREATE POLICY "View own trades" ON public.trades FOR SELECT TO authenticated
  USING (auth.uid()=user_id AND current_account_is_active());
CREATE POLICY "View own transactions" ON public.transactions FOR SELECT TO authenticated
  USING (auth.uid()=user_id AND current_account_is_active());
CREATE POLICY "View own wallet" ON public.wallets FOR SELECT TO authenticated
  USING (auth.uid()=user_id AND current_account_is_active());
CREATE POLICY "Users can view own asset balances" ON public.asset_balances FOR SELECT TO authenticated
  USING (auth.uid()=user_id AND current_account_is_active());
CREATE POLICY "Users can view own order reservations" ON public.order_reservations FOR SELECT TO authenticated
  USING (auth.uid()=user_id);
CREATE POLICY "Authenticated users can view market prices" ON public.market_prices FOR SELECT TO authenticated
  USING (true);
CREATE POLICY "market_prices_anon_public_read" ON public.market_prices FOR SELECT TO anon
  USING (true);
CREATE POLICY "demo_trading_pairs_public_read" ON public.demo_trading_pairs FOR SELECT TO anon,authenticated
  USING (true);

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

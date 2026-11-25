-- DigiArz Production-snapshot RLS isolation test (PostgreSQL 17).
-- TEST-ONLY: synthetic identities and rows in a disposable CI service container.
-- Policy predicates, table RLS flags and effective table grants are copied from
-- the read-only Production catalog snapshot dated 2026-11-25.
--
-- This is deliberately NOT a full schema/trigger parity test:
-- public.current_account_is_active() uses the captured Production body and
-- auth.uid() remains a test shim backed by a transaction-local claim, not
-- Supabase JWT verification. Triggers, RPC bodies and non-SELECT write paths
-- remain outside this test. order_reservations has no authenticated SELECT
-- grant in Production; its policy is exercised only after a transaction-scoped
-- grant, and the grant is rolled back with all fixture objects/data.
--
-- Never point this file at a persistent database. The workflow invokes it
-- only against the job-local postgres:17 service container.
\set ON_ERROR_STOP on

DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='service_role') THEN
    CREATE ROLE service_role NOLOGIN BYPASSRLS;
  END IF;
END
$roles$;

BEGIN;

CREATE SCHEMA auth;
CREATE SCHEMA private;

CREATE TABLE auth.users (
  id uuid PRIMARY KEY,
  email text
);

-- Test shim only; this is not Supabase JWT verification.
CREATE FUNCTION auth.uid()
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path=''
AS $fn$
  SELECT NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid;
$fn$;

-- Body copied from the captured Production definition (MD5 d932cd1d0da21bb96bdc0a381f7dcbc3).
-- auth.uid() remains a test shim backed by request.jwt.claim.sub; no real JWT is verified.
CREATE FUNCTION public.current_account_is_active()
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $fn$
  SELECT coalesce((
    SELECT p.is_active
    FROM public.profiles p
    WHERE p.id = auth.uid()
  ), false);
$fn$;

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  created_at timestamptz DEFAULT now(),
  is_active boolean NOT NULL DEFAULT true,
  deactivated_at timestamptz
);
CREATE TABLE public.wallets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  balance_usdt numeric(24,8) NOT NULL DEFAULT 200,
  balance_irr numeric(24,0) NOT NULL DEFAULT 1000000000,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT wallets_nonnegative_balance
    CHECK (balance_usdt >= 0 AND balance_irr >= 0)
);
CREATE TABLE public.asset_balances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  asset text NOT NULL,
  balance numeric(28,8) NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT asset_balances_asset_upper CHECK (asset=upper(asset)),
  CONSTRAINT asset_balances_nonnegative CHECK (balance>=0),
  CONSTRAINT asset_balances_user_asset_unique UNIQUE(user_id,asset)
);
CREATE TABLE public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  symbol text NOT NULL,
  side text NOT NULL CHECK (side IN ('buy','sell')),
  order_type text NOT NULL DEFAULT 'market'
    CHECK (order_type IN ('market','limit','conditional')),
  amount numeric(24,8) NOT NULL CHECK (amount>0),
  price numeric(24,8),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','partially_filled','triggered','filled','cancelled','rejected')),
  created_at timestamptz DEFAULT now(),
  filled_amount numeric NOT NULL DEFAULT 0,
  remaining_amount numeric NOT NULL,
  CONSTRAINT orders_amount_accounting_chk CHECK (filled_amount+remaining_amount=amount),
  CONSTRAINT orders_filled_amount_range_chk CHECK (filled_amount>=0 AND filled_amount<=amount),
  CONSTRAINT orders_remaining_amount_range_chk CHECK (remaining_amount>=0 AND remaining_amount<=amount),
  CONSTRAINT orders_price_positive CHECK (price IS NULL OR price>0),
  CONSTRAINT orders_limit_price_required_chk CHECK (order_type<>'limit' OR price IS NOT NULL),
  CONSTRAINT orders_id_user_id_unique UNIQUE(id,user_id)
);
CREATE TABLE public.trades (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  symbol text NOT NULL,
  side text NOT NULL CHECK (side IN ('buy','sell')),
  amount numeric(24,8) NOT NULL CHECK (amount>0),
  price numeric(24,8) NOT NULL CHECK (price>0),
  created_at timestamptz DEFAULT now(),
  order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL
);
CREATE TABLE public.transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  currency text NOT NULL,
  amount numeric(24,8) NOT NULL CHECK (amount<>0),
  transaction_type text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now()
);
CREATE TABLE public.order_reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL,
  user_id uuid NOT NULL,
  asset text NOT NULL,
  reserved_amount numeric NOT NULL CHECK (reserved_amount>0),
  released_amount numeric NOT NULL DEFAULT 0 CHECK (released_amount>=0 AND released_amount<=reserved_amount),
  status text NOT NULL DEFAULT 'reserved' CHECK (status IN ('reserved','released','consumed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  consumed_amount numeric NOT NULL DEFAULT 0,
  CONSTRAINT order_reservations_accounting_check
    CHECK (consumed_amount>=0 AND consumed_amount+released_amount<=reserved_amount),
  CONSTRAINT order_reservations_order_user_fk
    FOREIGN KEY(order_id,user_id) REFERENCES public.orders(id,user_id) ON DELETE CASCADE
);
CREATE TABLE public.conditional_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL UNIQUE REFERENCES public.orders(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  symbol text NOT NULL CHECK (symbol ~ '^[A-Z0-9]{2,15}USDT$'),
  side text NOT NULL DEFAULT 'sell' CHECK (side IN ('buy','sell')),
  order_kind text NOT NULL CHECK (order_kind IN ('take_profit','stop_loss','stop_limit')),
  trigger_price numeric NOT NULL CHECK (trigger_price>0),
  amount numeric NOT NULL CHECK (amount>0),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','triggered','filled','cancelled','rejected')),
  execution_order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  executed_price numeric CHECK (executed_price IS NULL OR executed_price>0),
  attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count>=0),
  last_error text,
  triggered_at timestamptz,
  executed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  limit_price numeric,
  CONSTRAINT conditional_orders_stop_limit_fields_chk CHECK (
    (order_kind='stop_limit' AND limit_price IS NOT NULL AND limit_price>0)
    OR (order_kind IN ('take_profit','stop_loss') AND limit_price IS NULL)
  )
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conditional_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View own profile" ON public.profiles
  FOR SELECT TO PUBLIC USING (auth.uid()=id);
CREATE POLICY "View own wallet" ON public.wallets
  FOR SELECT TO authenticated
  USING (auth.uid()=user_id AND public.current_account_is_active());
CREATE POLICY "Users can view own asset balances" ON public.asset_balances
  FOR SELECT TO authenticated
  USING (auth.uid()=user_id AND public.current_account_is_active());
CREATE POLICY "View own orders" ON public.orders
  FOR SELECT TO authenticated
  USING (auth.uid()=user_id AND public.current_account_is_active());
CREATE POLICY "View own trades" ON public.trades
  FOR SELECT TO authenticated
  USING (auth.uid()=user_id AND public.current_account_is_active());
CREATE POLICY "View own transactions" ON public.transactions
  FOR SELECT TO authenticated
  USING (auth.uid()=user_id AND public.current_account_is_active());
CREATE POLICY "Users can view own order reservations" ON public.order_reservations
  FOR SELECT TO authenticated USING (auth.uid()=user_id);
CREATE POLICY conditional_orders_select_own ON public.conditional_orders
  FOR SELECT TO authenticated USING ((SELECT auth.uid())=user_id);

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION auth.uid() TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.current_account_is_active() TO authenticated;

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON public.profiles, public.wallets, public.asset_balances,
  public.orders, public.trades, public.transactions, public.conditional_orders
  TO authenticated;
-- Production has an anon SELECT grant on conditional_orders but no anon policy.
GRANT SELECT ON public.conditional_orders TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;

INSERT INTO auth.users(id,email) VALUES
 ('11111111-1111-4111-8111-111111111111','user-a@test.invalid'),
 ('22222222-2222-4222-8222-222222222222','user-b@test.invalid');
INSERT INTO public.profiles(id,email) VALUES
 ('11111111-1111-4111-8111-111111111111','user-a@test.invalid'),
 ('22222222-2222-4222-8222-222222222222','user-b@test.invalid');
INSERT INTO public.wallets(user_id,balance_usdt,balance_irr) VALUES
 ('11111111-1111-4111-8111-111111111111',200,1000000000),
 ('22222222-2222-4222-8222-222222222222',300,2000000000);
INSERT INTO public.asset_balances(user_id,asset,balance) VALUES
 ('11111111-1111-4111-8111-111111111111','BTC',1),
 ('22222222-2222-4222-8222-222222222222','BTC',9);
INSERT INTO public.orders(id,user_id,symbol,side,amount,remaining_amount) VALUES
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1','11111111-1111-4111-8111-111111111111','BTCUSDT','buy',1,1),
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1','22222222-2222-4222-8222-222222222222','BTCUSDT','sell',2,2);
INSERT INTO public.trades(user_id,symbol,side,amount,price,order_id) VALUES
 ('11111111-1111-4111-8111-111111111111','BTCUSDT','buy',1,100,'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'),
 ('22222222-2222-4222-8222-222222222222','BTCUSDT','sell',2,100,'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1');
INSERT INTO public.transactions(user_id,currency,amount,transaction_type) VALUES
 ('11111111-1111-4111-8111-111111111111','USDT',10,'test'),
 ('22222222-2222-4222-8222-222222222222','USDT',20,'test');
INSERT INTO public.order_reservations(order_id,user_id,asset,reserved_amount) VALUES
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1','11111111-1111-4111-8111-111111111111','USDT',100),
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1','22222222-2222-4222-8222-222222222222','USDT',200);
INSERT INTO public.conditional_orders(order_id,user_id,symbol,side,order_kind,trigger_price,amount) VALUES
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1','11111111-1111-4111-8111-111111111111','BTCUSDT','sell','take_profit',120,1),
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1','22222222-2222-4222-8222-222222222222','BTCUSDT','sell','stop_loss',80,2);

-- Assert the captured RLS flags, policy presence and table ACL boundary.
DO $catalog$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['profiles','wallets','asset_balances','orders','trades',
    'transactions','order_reservations','conditional_orders'] LOOP
    IF NOT (SELECT relrowsecurity AND NOT relforcerowsecurity
            FROM pg_class WHERE oid=to_regclass('public.'||t)) THEN
      RAISE EXCEPTION 'RLS flags differ for public.%',t;
    END IF;
  END LOOP;
  IF has_table_privilege('anon','public.wallets','SELECT')
     OR has_table_privilege('anon','public.asset_balances','SELECT')
     OR has_table_privilege('anon','public.orders','SELECT')
     OR has_table_privilege('anon','public.trades','SELECT')
     OR has_table_privilege('anon','public.transactions','SELECT')
     OR has_table_privilege('anon','public.profiles','SELECT') THEN
    RAISE EXCEPTION 'anon unexpectedly has SELECT on a protected user-owned table';
  END IF;
  IF NOT has_table_privilege('anon','public.conditional_orders','SELECT') THEN
    RAISE EXCEPTION 'Captured conditional_orders anon SELECT grant is missing';
  END IF;
  IF has_table_privilege('authenticated','public.order_reservations','SELECT') THEN
    RAISE EXCEPTION 'Production authenticated order_reservations SELECT grant unexpectedly present';
  END IF;
  IF has_table_privilege('authenticated','public.wallets','UPDATE')
     OR has_table_privilege('authenticated','public.orders','INSERT')
     OR has_table_privilege('authenticated','public.trades','DELETE')
     OR has_table_privilege('authenticated','public.transactions','UPDATE') THEN
    RAISE EXCEPTION 'authenticated has unexpected direct financial DML privilege';
  END IF;
  IF (SELECT count(*) FROM pg_policy WHERE polrelid='public.order_reservations'::regclass
      AND polname='Users can view own order reservations' AND polcmd='r') <> 1 THEN
    RAISE EXCEPTION 'order_reservations owner SELECT policy missing';
  END IF;
  IF (SELECT count(*) FROM pg_policy WHERE polrelid='public.conditional_orders'::regclass
      AND polname='conditional_orders_select_own' AND polcmd='r') <> 1 THEN
    RAISE EXCEPTION 'conditional_orders owner SELECT policy missing';
  END IF;
END
$catalog$;

-- The Production grant is absent on order_reservations. Add a transaction-local
-- SELECT grant solely to exercise its captured RLS predicate; rollback removes it.
GRANT SELECT ON public.order_reservations TO authenticated;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $user_a$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM public.profiles;
  IF n<>1 OR EXISTS(SELECT 1 FROM public.profiles WHERE id<>'11111111-1111-4111-8111-111111111111') THEN RAISE EXCEPTION 'user A profile isolation failed'; END IF;
  SELECT count(*) INTO n FROM public.wallets; IF n<>1 OR EXISTS(SELECT 1 FROM public.wallets WHERE user_id<>'11111111-1111-4111-8111-111111111111') THEN RAISE EXCEPTION 'user A wallet isolation failed'; END IF;
  SELECT count(*) INTO n FROM public.asset_balances; IF n<>1 OR EXISTS(SELECT 1 FROM public.asset_balances WHERE user_id<>'11111111-1111-4111-8111-111111111111') THEN RAISE EXCEPTION 'user A asset balance isolation failed'; END IF;
  SELECT count(*) INTO n FROM public.orders; IF n<>1 OR EXISTS(SELECT 1 FROM public.orders WHERE user_id<>'11111111-1111-4111-8111-111111111111') THEN RAISE EXCEPTION 'user A order isolation failed'; END IF;
  SELECT count(*) INTO n FROM public.trades; IF n<>1 OR EXISTS(SELECT 1 FROM public.trades WHERE user_id<>'11111111-1111-4111-8111-111111111111') THEN RAISE EXCEPTION 'user A trade isolation failed'; END IF;
  SELECT count(*) INTO n FROM public.transactions; IF n<>1 OR EXISTS(SELECT 1 FROM public.transactions WHERE user_id<>'11111111-1111-4111-8111-111111111111') THEN RAISE EXCEPTION 'user A transaction isolation failed'; END IF;
  SELECT count(*) INTO n FROM public.order_reservations; IF n<>1 OR EXISTS(SELECT 1 FROM public.order_reservations WHERE user_id<>'11111111-1111-4111-8111-111111111111') THEN RAISE EXCEPTION 'user A reservation policy isolation failed'; END IF;
  SELECT count(*) INTO n FROM public.conditional_orders; IF n<>1 OR EXISTS(SELECT 1 FROM public.conditional_orders WHERE user_id<>'11111111-1111-4111-8111-111111111111') THEN RAISE EXCEPTION 'user A conditional order isolation failed'; END IF;
END
$user_a$;
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
DO $user_b$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM public.profiles; IF n<>1 OR EXISTS(SELECT 1 FROM public.profiles WHERE id<>'22222222-2222-4222-8222-222222222222') THEN RAISE EXCEPTION 'user B profile isolation failed'; END IF;
  SELECT count(*) INTO n FROM public.wallets; IF n<>1 OR EXISTS(SELECT 1 FROM public.wallets WHERE user_id<>'22222222-2222-4222-8222-222222222222') THEN RAISE EXCEPTION 'user B wallet isolation failed'; END IF;
  SELECT count(*) INTO n FROM public.asset_balances; IF n<>1 OR EXISTS(SELECT 1 FROM public.asset_balances WHERE user_id<>'22222222-2222-4222-8222-222222222222') THEN RAISE EXCEPTION 'user B asset balance isolation failed'; END IF;
  SELECT count(*) INTO n FROM public.orders; IF n<>1 OR EXISTS(SELECT 1 FROM public.orders WHERE user_id<>'22222222-2222-4222-8222-222222222222') THEN RAISE EXCEPTION 'user B order isolation failed'; END IF;
  SELECT count(*) INTO n FROM public.trades; IF n<>1 OR EXISTS(SELECT 1 FROM public.trades WHERE user_id<>'22222222-2222-4222-8222-222222222222') THEN RAISE EXCEPTION 'user B trade isolation failed'; END IF;
  SELECT count(*) INTO n FROM public.transactions; IF n<>1 OR EXISTS(SELECT 1 FROM public.transactions WHERE user_id<>'22222222-2222-4222-8222-222222222222') THEN RAISE EXCEPTION 'user B transaction isolation failed'; END IF;
  SELECT count(*) INTO n FROM public.order_reservations; IF n<>1 OR EXISTS(SELECT 1 FROM public.order_reservations WHERE user_id<>'22222222-2222-4222-8222-222222222222') THEN RAISE EXCEPTION 'user B reservation policy isolation failed'; END IF;
  SELECT count(*) INTO n FROM public.conditional_orders; IF n<>1 OR EXISTS(SELECT 1 FROM public.conditional_orders WHERE user_id<>'22222222-2222-4222-8222-222222222222') THEN RAISE EXCEPTION 'user B conditional order isolation failed'; END IF;
END
$user_b$;
RESET ROLE;

-- Exercise the captured Production helper body with an inactive synthetic account.
-- Policies that call the helper must hide rows; policies without it are recorded separately.
UPDATE public.profiles
SET is_active = false, deactivated_at = now()
WHERE id = '22222222-2222-4222-8222-222222222222';

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
DO $inactive_account$
DECLARE n integer;
BEGIN
  IF public.current_account_is_active() IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'captured active-account helper did not reject inactive user B';
  END IF;
  IF (SELECT count(*) FROM public.wallets) <> 0
     OR (SELECT count(*) FROM public.asset_balances) <> 0
     OR (SELECT count(*) FROM public.orders) <> 0
     OR (SELECT count(*) FROM public.trades) <> 0
     OR (SELECT count(*) FROM public.transactions) <> 0 THEN
    RAISE EXCEPTION 'active-account RLS predicate exposed rows to inactive user B';
  END IF;
  SELECT count(*) INTO n FROM public.profiles;
  IF n <> 1 THEN
    RAISE EXCEPTION 'profile self-read policy behavior changed for inactive user B';
  END IF;
  SELECT count(*) INTO n FROM public.order_reservations;
  IF n <> 1 THEN
    RAISE EXCEPTION 'order_reservations policy no longer matches captured owner-only predicate';
  END IF;
  SELECT count(*) INTO n FROM public.conditional_orders;
  IF n <> 1 THEN
    RAISE EXCEPTION 'conditional_orders policy no longer matches captured owner-only predicate';
  END IF;
END
$inactive_account$;
RESET ROLE;

-- No authenticated subject: all owner-scoped rows must be hidden.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','',true);
DO $no_subject$
BEGIN
  IF (SELECT count(*) FROM public.wallets)<>0
     OR (SELECT count(*) FROM public.asset_balances)<>0
     OR (SELECT count(*) FROM public.orders)<>0
     OR (SELECT count(*) FROM public.trades)<>0
     OR (SELECT count(*) FROM public.transactions)<>0
     OR (SELECT count(*) FROM public.conditional_orders)<>0
     OR (SELECT count(*) FROM public.profiles)<>0
     OR (SELECT count(*) FROM public.order_reservations)<>0 THEN
    RAISE EXCEPTION 'Rows visible without auth.uid()';
  END IF;
END
$no_subject$;
RESET ROLE;

-- anon can SELECT conditional_orders at the table ACL layer, but no anon RLS
-- policy exists, so zero rows must be visible.
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claim.sub','',true);
DO $anonymous$
BEGIN
  IF (SELECT count(*) FROM public.conditional_orders)<>0 THEN
    RAISE EXCEPTION 'anon unexpectedly sees conditional_orders rows';
  END IF;
END
$anonymous$;
RESET ROLE;

-- service_role is intentionally BYPASSRLS and has table grants in Production.
SET LOCAL ROLE service_role;
SELECT set_config('request.jwt.claim.sub','',true);
DO $service$
BEGIN
  IF (SELECT count(*) FROM public.wallets)<>2
     OR (SELECT count(*) FROM public.asset_balances)<>2
     OR (SELECT count(*) FROM public.orders)<>2
     OR (SELECT count(*) FROM public.trades)<>2
     OR (SELECT count(*) FROM public.transactions)<>2
     OR (SELECT count(*) FROM public.order_reservations)<>2
     OR (SELECT count(*) FROM public.conditional_orders)<>2
     OR (SELECT count(*) FROM public.profiles)<>2 THEN
    RAISE EXCEPTION 'service_role BYPASSRLS/table grant behavior mismatch';
  END IF;
END
$service$;
RESET ROLE;

-- postgres is the table owner/superuser in the disposable service and sees both.
DO $postgres$
BEGIN
  IF (SELECT count(*) FROM public.wallets)<>2
     OR (SELECT count(*) FROM public.orders)<>2
     OR (SELECT count(*) FROM public.order_reservations)<>2 THEN
    RAISE EXCEPTION 'postgres owner/superuser visibility mismatch';
  END IF;
END
$postgres$;

ROLLBACK;

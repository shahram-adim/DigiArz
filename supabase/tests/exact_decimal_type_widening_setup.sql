-- Disposable PostgreSQL CI fixture mirroring the relevant Production catalog.
-- Never run against Supabase Production. Types targeted for widening intentionally
-- retain their current Production definitions until the draft migration runs.
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN CREATE ROLE authenticated; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN CREATE ROLE anon; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='service_role') THEN CREATE ROLE service_role; END IF;
END
$roles$;

CREATE SCHEMA auth;
CREATE SCHEMA private;
CREATE TABLE auth.users (id uuid PRIMARY KEY);
INSERT INTO auth.users(id) VALUES ('20000000-0000-4000-8000-000000000001');
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS
$$ SELECT NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
CREATE FUNCTION public.current_account_is_active() RETURNS boolean
LANGUAGE sql STABLE AS $$ SELECT true $$;
CREATE FUNCTION private.guard_active_account_writes() RETURNS trigger
LANGUAGE plpgsql AS $$ BEGIN RETURN NEW; END $$;

CREATE TABLE public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  symbol text NOT NULL,
  side text NOT NULL,
  order_type text NOT NULL DEFAULT 'market',
  amount numeric(24,8) NOT NULL,
  price numeric(24,8),
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  filled_amount numeric NOT NULL DEFAULT 0,
  remaining_amount numeric NOT NULL,
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
CREATE TABLE public.trades (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  symbol text NOT NULL,
  side text NOT NULL,
  amount numeric(24,8) NOT NULL,
  price numeric(24,8) NOT NULL,
  created_at timestamptz DEFAULT now(),
  order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  CONSTRAINT trades_amount_positive CHECK (amount > 0),
  CONSTRAINT trades_price_positive CHECK (price > 0),
  CONSTRAINT trades_side_valid CHECK (side = ANY (ARRAY['buy','sell']))
);
CREATE TABLE public.asset_balances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  asset text NOT NULL,
  balance numeric(28,8) NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT asset_balances_asset_upper CHECK (asset = upper(asset)),
  CONSTRAINT asset_balances_nonnegative CHECK (balance >= 0),
  CONSTRAINT asset_balances_user_asset_unique UNIQUE (user_id,asset)
);
CREATE TABLE public.order_reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL,
  user_id uuid NOT NULL,
  asset text NOT NULL,
  reserved_amount numeric NOT NULL,
  released_amount numeric NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'reserved',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  consumed_amount numeric NOT NULL DEFAULT 0,
  CONSTRAINT order_reservations_accounting_check CHECK (consumed_amount >= 0 AND consumed_amount + released_amount <= reserved_amount),
  CONSTRAINT order_reservations_amount_check CHECK (released_amount <= reserved_amount),
  CONSTRAINT order_reservations_order_user_fk FOREIGN KEY (order_id,user_id) REFERENCES public.orders(id,user_id) ON DELETE CASCADE,
  CONSTRAINT order_reservations_released_amount_check CHECK (released_amount >= 0),
  CONSTRAINT order_reservations_reserved_amount_check CHECK (reserved_amount > 0),
  CONSTRAINT order_reservations_status_check CHECK (status = ANY (ARRAY['reserved','released','consumed']))
);
CREATE UNIQUE INDEX order_reservations_order_unique ON public.order_reservations(order_id);
CREATE TABLE public.wallets (balance_usdt numeric(24,8) NOT NULL);
CREATE TABLE public.transactions (amount numeric(24,8) NOT NULL);

CREATE TABLE public.conditional_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL UNIQUE REFERENCES public.orders(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  symbol text NOT NULL,
  side text NOT NULL DEFAULT 'sell',
  order_kind text NOT NULL,
  trigger_price numeric NOT NULL,
  amount numeric NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  execution_order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  executed_price numeric,
  attempt_count integer NOT NULL DEFAULT 0,
  last_error text,
  triggered_at timestamptz,
  executed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  limit_price numeric,
  CONSTRAINT conditional_orders_amount_check CHECK (amount > 0),
  CONSTRAINT conditional_orders_attempt_count_check CHECK (attempt_count >= 0),
  CONSTRAINT conditional_orders_executed_price_check CHECK (executed_price IS NULL OR executed_price > 0),
  CONSTRAINT conditional_orders_order_kind_check CHECK (order_kind = ANY (ARRAY['take_profit','stop_loss','stop_limit'])),
  CONSTRAINT conditional_orders_side_check CHECK (side = ANY (ARRAY['buy','sell'])),
  CONSTRAINT conditional_orders_status_check CHECK (status = ANY (ARRAY['pending','triggered','filled','cancelled','rejected'])),
  CONSTRAINT conditional_orders_stop_limit_fields_chk CHECK (
    (order_kind='stop_limit' AND limit_price IS NOT NULL AND limit_price > 0)
    OR (order_kind IN ('take_profit','stop_loss') AND limit_price IS NULL)
  ),
  CONSTRAINT conditional_orders_symbol_check CHECK (symbol ~ '^[A-Z0-9]{2,15}USDT$'),
  CONSTRAINT conditional_orders_trigger_price_check CHECK (trigger_price > 0)
);

-- Match Production's secondary indexes on the five financial tables.
CREATE INDEX conditional_orders_execution_order_id_idx ON public.conditional_orders(execution_order_id);
CREATE INDEX conditional_orders_pending_created_idx ON public.conditional_orders(created_at) WHERE status='pending';
CREATE INDEX conditional_orders_stop_limit_pending_idx ON public.conditional_orders(created_at) WHERE order_kind='stop_limit' AND status='pending';
CREATE INDEX conditional_orders_user_status_created_idx ON public.conditional_orders(user_id,status,created_at DESC);
CREATE INDEX order_reservations_user_status_idx ON public.order_reservations(user_id,status);
CREATE INDEX orders_limit_active_created_at_idx ON public.orders(created_at) WHERE order_type='limit' AND status IN ('pending','partially_filled');
CREATE INDEX trades_order_id_created_at_idx ON public.trades(order_id,created_at);

CREATE TRIGGER guard_active_account_orders BEFORE INSERT ON public.orders
FOR EACH ROW EXECUTE FUNCTION private.guard_active_account_writes();
CREATE TRIGGER guard_active_account_trades BEFORE INSERT ON public.trades
FOR EACH ROW EXECUTE FUNCTION private.guard_active_account_writes();

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conditional_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View own orders" ON public.orders FOR SELECT TO authenticated
USING (auth.uid() = user_id AND current_account_is_active());
CREATE POLICY "View own trades" ON public.trades FOR SELECT TO authenticated
USING (auth.uid() = user_id AND current_account_is_active());
CREATE POLICY "Users can view own asset balances" ON public.asset_balances FOR SELECT TO authenticated
USING (auth.uid() = user_id AND current_account_is_active());
CREATE POLICY "Users can view own order reservations" ON public.order_reservations FOR SELECT TO authenticated
USING (auth.uid() = user_id);
CREATE POLICY conditional_orders_select_own ON public.conditional_orders FOR SELECT TO authenticated
USING (( SELECT auth.uid() AS uid) = user_id);

GRANT SELECT ON public.orders,public.trades,public.asset_balances TO authenticated;
GRANT SELECT ON public.conditional_orders TO anon,authenticated;
GRANT ALL PRIVILEGES ON public.orders,public.trades,public.asset_balances,public.order_reservations,public.conditional_orders TO service_role;

INSERT INTO public.orders(id,user_id,symbol,side,order_type,amount,price,status,filled_amount,remaining_amount)
VALUES
('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','BTCUSDT','buy','limit',1.25,10.5,'pending',0.25,1.00),
('10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000001','ETHUSDT','sell','conditional',0.5,NULL,'pending',0,0.5);
INSERT INTO public.trades(user_id,symbol,side,amount,price,order_id)
VALUES ('20000000-0000-4000-8000-000000000001','BTCUSDT','buy',0.25,10.5,'10000000-0000-4000-8000-000000000001');
INSERT INTO public.asset_balances(user_id,asset,balance)
VALUES ('20000000-0000-4000-8000-000000000001','BTC',1.25);
INSERT INTO public.order_reservations(order_id,user_id,asset,reserved_amount,released_amount,consumed_amount)
VALUES ('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','USDT',10.5,1.25,2.5);
INSERT INTO public.order_reservations(order_id,user_id,asset,reserved_amount,released_amount,consumed_amount)
VALUES ('10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000001','ETH',0.5,0,0);
INSERT INTO public.conditional_orders(order_id,user_id,symbol,side,order_kind,trigger_price,amount,status)
VALUES ('10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000001','ETHUSDT','sell','take_profit',12.25,0.5,'pending');

-- Snapshot constraints, indexes, triggers, defaults, grants, RLS policies and
-- non-type column attributes before the type-widening rehearsal.
CREATE TABLE public.widening_schema_snapshot (
  object_kind text NOT NULL,
  object_name text NOT NULL,
  definition text NOT NULL,
  PRIMARY KEY (object_kind,object_name)
);
INSERT INTO public.widening_schema_snapshot
SELECT 'constraint',c.relname||'.'||con.conname,pg_get_constraintdef(con.oid)
FROM pg_constraint con JOIN pg_class c ON c.oid=con.conrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
UNION ALL
SELECT 'index',t.relname||'.'||i.relname,pg_get_indexdef(i.oid)
FROM pg_index x JOIN pg_class t ON t.oid=x.indrelid JOIN pg_class i ON i.oid=x.indexrelid
JOIN pg_namespace n ON n.oid=t.relnamespace
WHERE n.nspname='public' AND t.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
UNION ALL
SELECT 'trigger',c.relname||'.'||tr.tgname,pg_get_triggerdef(tr.oid,true)
FROM pg_trigger tr JOIN pg_class c ON c.oid=tr.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders') AND NOT tr.tgisinternal
UNION ALL
SELECT 'default',c.relname||'.'||a.attname,pg_get_expr(d.adbin,d.adrelid)
FROM pg_attrdef d JOIN pg_class c ON c.oid=d.adrelid JOIN pg_namespace n ON n.oid=c.relnamespace
JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum=d.adnum
WHERE n.nspname='public' AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
UNION ALL
SELECT 'column',c.relname||'.'||a.attname,'not_null='||a.attnotnull
FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
AND a.attnum>0 AND NOT a.attisdropped
UNION ALL
SELECT 'grant',table_name||'.'||grantee||'.'||privilege_type,is_grantable
FROM information_schema.role_table_grants
WHERE table_schema='public' AND table_name IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
UNION ALL
SELECT 'policy',c.relname||'.'||p.polname,
  p.polcmd::text||'|'||p.polpermissive::text||'|'||p.polroles::text||'|'||
  COALESCE(pg_get_expr(p.polqual,p.polrelid),'')||'|'||
  COALESCE(pg_get_expr(p.polwithcheck,p.polrelid),'')
FROM pg_policy p JOIN pg_class c ON c.oid=p.polrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
UNION ALL
SELECT 'rls',c.relname,c.relrowsecurity::text||'|'||c.relforcerowsecurity::text
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders');

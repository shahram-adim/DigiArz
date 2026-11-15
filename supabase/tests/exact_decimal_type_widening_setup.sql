-- Disposable PostgreSQL CI fixture mirroring production constraints on widened columns.
-- Never run against Supabase Production.
DO $roles$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN CREATE ROLE authenticated; END IF; IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='service_role') THEN CREATE ROLE service_role; END IF; END $roles$;

CREATE TABLE public.orders (
  order_type text NOT NULL,
  amount numeric(24,8) NOT NULL,
  price numeric(24,8),
  filled_amount numeric NOT NULL DEFAULT 0,
  remaining_amount numeric NOT NULL,
  CONSTRAINT orders_amount_accounting_chk CHECK (filled_amount + remaining_amount = amount),
  CONSTRAINT orders_amount_positive CHECK (amount > 0),
  CONSTRAINT orders_filled_amount_range_chk CHECK (filled_amount >= 0 AND filled_amount <= amount),
  CONSTRAINT orders_limit_price_required_chk CHECK (order_type <> 'limit' OR price IS NOT NULL),
  CONSTRAINT orders_price_positive CHECK (price IS NULL OR price > 0),
  CONSTRAINT orders_remaining_amount_range_chk CHECK (remaining_amount >= 0 AND remaining_amount <= amount)
);
CREATE TABLE public.trades (
  amount numeric(24,8) NOT NULL CHECK (amount > 0),
  price numeric(24,8) NOT NULL CHECK (price > 0)
);
CREATE TABLE public.asset_balances (
  balance numeric(28,8) NOT NULL DEFAULT 0 CHECK (balance >= 0)
);
CREATE TABLE public.order_reservations (
  reserved_amount numeric NOT NULL CHECK (reserved_amount > 0),
  released_amount numeric NOT NULL DEFAULT 0 CHECK (released_amount >= 0 AND released_amount <= reserved_amount),
  consumed_amount numeric NOT NULL DEFAULT 0 CHECK (consumed_amount >= 0 AND consumed_amount + released_amount <= reserved_amount)
);
CREATE TABLE public.conditional_orders (
  order_kind text NOT NULL,
  amount numeric NOT NULL CHECK (amount > 0),
  trigger_price numeric NOT NULL CHECK (trigger_price > 0),
  limit_price numeric,
  executed_price numeric,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT conditional_orders_executed_price_check CHECK (executed_price IS NULL OR executed_price > 0),
  CONSTRAINT conditional_orders_stop_limit_fields_chk CHECK (
    (order_kind='stop_limit' AND limit_price IS NOT NULL AND limit_price > 0)
    OR (order_kind IN ('take_profit','stop_loss') AND limit_price IS NULL)
  )
);
CREATE TABLE public.wallets (balance_usdt numeric(24,8) NOT NULL);
CREATE TABLE public.transactions (amount numeric(24,8) NOT NULL);

INSERT INTO public.orders(order_type,amount,price,filled_amount,remaining_amount)
VALUES ('limit',1.25,10.5,0.25,1.00),('market',0.5,NULL,0,0.5);
INSERT INTO public.trades VALUES (0.25,10.5);
INSERT INTO public.asset_balances VALUES (1.25);
INSERT INTO public.order_reservations VALUES (10.5,1.25,2.5);
INSERT INTO public.conditional_orders(order_kind,amount,trigger_price,limit_price,executed_price)
VALUES ('take_profit',0.5,12.25,NULL,NULL);
INSERT INTO public.wallets VALUES (200);
INSERT INTO public.transactions VALUES (10.5);

-- Representative production-like indexes, trigger, defaults, and grants.
CREATE UNIQUE INDEX orders_widening_fixture_idx ON public.orders(order_type, amount);
CREATE INDEX trades_widening_fixture_idx ON public.trades(amount, price);
CREATE INDEX asset_balances_widening_fixture_idx ON public.asset_balances(balance);
CREATE INDEX order_reservations_widening_fixture_idx ON public.order_reservations(reserved_amount);
CREATE INDEX conditional_orders_widening_fixture_idx ON public.conditional_orders(created_at);

CREATE FUNCTION public.widening_fixture_guard() RETURNS trigger
LANGUAGE plpgsql AS $fn$ BEGIN RETURN NEW; END $fn$;
CREATE TRIGGER orders_widening_fixture_trigger BEFORE INSERT ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.widening_fixture_guard();

GRANT SELECT ON public.orders, public.trades, public.asset_balances, public.conditional_orders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders, public.trades, public.asset_balances,
  public.order_reservations, public.conditional_orders TO service_role;

-- Catalog snapshot used to prove the type changes preserve all fixture schema objects.
CREATE TABLE public.widening_schema_snapshot (
  object_kind text NOT NULL,
  object_name text NOT NULL,
  definition text NOT NULL,
  PRIMARY KEY (object_kind, object_name)
);
INSERT INTO public.widening_schema_snapshot
SELECT 'constraint', c.relname || '.' || con.conname, pg_get_constraintdef(con.oid)
FROM pg_constraint con
JOIN pg_class c ON c.oid=con.conrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public'
  AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
UNION ALL
SELECT 'index', t.relname || '.' || i.relname, pg_get_indexdef(i.oid)
FROM pg_index x
JOIN pg_class t ON t.oid=x.indrelid
JOIN pg_class i ON i.oid=x.indexrelid
JOIN pg_namespace n ON n.oid=t.relnamespace
WHERE n.nspname='public'
  AND t.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
UNION ALL
SELECT 'trigger', c.relname || '.' || tr.tgname, pg_get_triggerdef(tr.oid,true)
FROM pg_trigger tr
JOIN pg_class c ON c.oid=tr.tgrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public'
  AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
  AND NOT tr.tgisinternal
UNION ALL
SELECT 'default', c.relname || '.' || a.attname, pg_get_expr(d.adbin,d.adrelid)
FROM pg_attrdef d
JOIN pg_class c ON c.oid=d.adrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum=d.adnum
WHERE n.nspname='public'
  AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
UNION ALL
SELECT 'grant', table_name || '.' || grantee || '.' || privilege_type,
       is_grantable
FROM information_schema.role_table_grants
WHERE table_schema='public'
  AND table_name IN ('orders','trades','asset_balances','order_reservations','conditional_orders');

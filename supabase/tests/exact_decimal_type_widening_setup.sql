-- Disposable PostgreSQL CI fixture mirroring production constraints on widened columns.
-- Never run against Supabase Production.
CREATE TABLE public.orders (
  order_type text NOT NULL,
  amount numeric(24,8) NOT NULL,
  price numeric(24,8),
  filled_amount numeric NOT NULL,
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
  balance numeric(28,8) NOT NULL CHECK (balance >= 0)
);
CREATE TABLE public.order_reservations (
  reserved_amount numeric NOT NULL CHECK (reserved_amount > 0),
  released_amount numeric NOT NULL CHECK (released_amount >= 0 AND released_amount <= reserved_amount),
  consumed_amount numeric NOT NULL CHECK (consumed_amount >= 0 AND consumed_amount + released_amount <= reserved_amount)
);
CREATE TABLE public.conditional_orders (
  order_kind text NOT NULL,
  amount numeric(24,8) NOT NULL CHECK (amount > 0),
  trigger_price numeric(24,8) NOT NULL CHECK (trigger_price > 0),
  limit_price numeric(24,8),
  executed_price numeric(24,8),
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

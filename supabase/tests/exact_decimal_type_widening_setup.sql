-- Disposable PostgreSQL CI fixture for the exact-decimal type-widening rehearsal.
-- Never run against Supabase Production.
CREATE TABLE public.orders (
  amount numeric(24,8) NOT NULL,
  price numeric(24,8) NOT NULL,
  filled_amount numeric NOT NULL,
  remaining_amount numeric NOT NULL
);
CREATE TABLE public.trades (amount numeric(24,8) NOT NULL, price numeric(24,8) NOT NULL);
CREATE TABLE public.asset_balances (balance numeric(28,8) NOT NULL);
CREATE TABLE public.order_reservations (
  reserved_amount numeric NOT NULL,
  released_amount numeric NOT NULL,
  consumed_amount numeric NOT NULL
);
CREATE TABLE public.conditional_orders (
  amount numeric(24,8) NOT NULL,
  trigger_price numeric(24,8) NOT NULL,
  limit_price numeric(24,8),
  executed_price numeric(24,8)
);
CREATE TABLE public.wallets (balance_usdt numeric(24,8) NOT NULL);
CREATE TABLE public.transactions (amount numeric(24,8) NOT NULL);

INSERT INTO public.orders VALUES (1.25, 10.5, 0.25, 1.00);
INSERT INTO public.trades VALUES (0.25, 10.5);
INSERT INTO public.asset_balances VALUES (1.25);
INSERT INTO public.order_reservations VALUES (10.5, 1.25, 2.5);
INSERT INTO public.conditional_orders VALUES (0.5, 12.25, NULL, NULL);
INSERT INTO public.wallets VALUES (200);
INSERT INTO public.transactions VALUES (10.5);

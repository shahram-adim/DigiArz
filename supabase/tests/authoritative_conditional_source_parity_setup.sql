-- Disposable source-parity harness for the authoritative 2026-11-13 TP/SL and Stop-Limit migrations.
-- CI only. Never run this file or the migration files against Production.
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS cron;
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN CREATE ROLE anon NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='service_role') THEN CREATE ROLE service_role NOLOGIN; END IF;
END
$roles$;
CREATE TABLE auth.users(id uuid PRIMARY KEY);
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE SET search_path TO ''
AS $f$ SELECT nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $f$;
CREATE TABLE cron.job(jobid bigserial PRIMARY KEY,jobname text UNIQUE);
CREATE FUNCTION cron.schedule(text,text,text) RETURNS bigint LANGUAGE plpgsql
AS $f$ DECLARE v_id bigint; BEGIN INSERT INTO cron.job(jobname) VALUES($1) ON CONFLICT(jobname) DO UPDATE SET jobname=EXCLUDED.jobname RETURNING jobid INTO v_id; RETURN v_id; END $f$;
CREATE FUNCTION cron.unschedule(bigint) RETURNS boolean LANGUAGE sql AS $f$ SELECT true $f$;
CREATE TABLE public.profiles(id uuid PRIMARY KEY REFERENCES auth.users(id),is_active boolean NOT NULL,deactivated_at timestamptz);
CREATE FUNCTION public.current_account_is_active() RETURNS boolean LANGUAGE sql STABLE SET search_path TO ''
AS $f$ SELECT EXISTS(SELECT 1 FROM public.profiles WHERE id=auth.uid() AND is_active IS TRUE) $f$;
CREATE TABLE public.orders(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES auth.users(id),
  symbol text NOT NULL,side text NOT NULL,order_type text NOT NULL,
  amount numeric(34,18) NOT NULL,price numeric(34,18) NOT NULL,
  filled_amount numeric(34,18) NOT NULL DEFAULT 0,remaining_amount numeric(34,18) NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending',created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.demo_trading_pairs(pair_symbol text PRIMARY KEY,quote_asset text NOT NULL,is_enabled boolean NOT NULL);
CREATE TABLE public.market_prices(symbol text PRIMARY KEY,price numeric(38,18) NOT NULL,updated_at timestamptz NOT NULL);
CREATE TABLE public.order_reservations(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),order_id uuid NOT NULL UNIQUE REFERENCES public.orders(id),
  user_id uuid NOT NULL REFERENCES auth.users(id),asset text NOT NULL,
  reserved_amount numeric(38,18) NOT NULL,consumed_amount numeric(38,18) NOT NULL DEFAULT 0,
  released_amount numeric(38,18) NOT NULL DEFAULT 0,status text NOT NULL,updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.wallets(user_id uuid PRIMARY KEY REFERENCES auth.users(id),balance_usdt numeric(24,8) NOT NULL);
CREATE TABLE public.asset_balances(
  user_id uuid NOT NULL REFERENCES auth.users(id),asset text NOT NULL,balance numeric(38,18) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(user_id,asset)
);
CREATE TABLE public.trades(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,order_id uuid NOT NULL,user_id uuid NOT NULL,symbol text NOT NULL,side text NOT NULL,amount numeric(34,18) NOT NULL,price numeric(34,18) NOT NULL);
CREATE TABLE public.transactions(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,user_id uuid NOT NULL,currency text NOT NULL,amount numeric(24,8) NOT NULL,transaction_type text NOT NULL,description text NOT NULL);
CREATE FUNCTION public.get_demo_trading_fee_rate(text,text) RETURNS numeric LANGUAGE sql IMMUTABLE SET search_path TO ''
AS $f$ SELECT 0.001::numeric $f$;

-- Explicit downstream adapters: the harness tests the exact authoritative
-- conditional/Stop-Limit RPC and worker bodies, while isolating the separate
-- Market/Limit matching engines from this source-parity check.
CREATE FUNCTION public.execute_demo_trade(p_symbol text,p_side text,p_amount numeric,p_price numeric)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $f$
DECLARE v_id uuid;
BEGIN
  INSERT INTO public.orders(user_id,symbol,side,order_type,amount,price,status,filled_amount,remaining_amount)
  VALUES(auth.uid(),p_symbol,p_side,'market',p_amount,p_price,'filled',p_amount,0)
  RETURNING id INTO v_id;
  RETURN jsonb_build_object('success',true,'order_id',v_id,'price',p_price);
END $f$;
CREATE FUNCTION public.place_limit_order(p_symbol text,p_side text,p_amount numeric,p_limit_price numeric)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $f$
DECLARE v_id uuid;
BEGIN
  INSERT INTO public.orders(user_id,symbol,side,order_type,amount,price,status,filled_amount,remaining_amount)
  VALUES(auth.uid(),p_symbol,p_side,'limit',p_amount,p_limit_price,'pending',0,p_amount)
  RETURNING id INTO v_id;
  RETURN jsonb_build_object('success',true,'order_id',v_id);
END $f$;
CREATE FUNCTION public.cancel_limit_order(p_order_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $f$
BEGIN
  UPDATE public.orders SET status='cancelled',remaining_amount=amount-filled_amount
  WHERE id=p_order_id AND user_id=auth.uid() AND order_type='limit'
    AND status IN ('pending','partially_filled');
  RETURN jsonb_build_object('success',true);
END $f$;

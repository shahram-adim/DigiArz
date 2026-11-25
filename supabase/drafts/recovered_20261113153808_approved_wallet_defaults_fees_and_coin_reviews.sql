-- RECOVERED HISTORICAL PRODUCTION MIGRATION SOURCE
-- Migration version: 20261113153808
-- Name: approved_wallet_defaults_fees_and_coin_reviews
-- Source: Production supabase_migrations.schema_migrations.statements (read-only retrieval, 2026-11-25).
-- STATUS: REVIEW-ONLY / HISTORICAL REFERENCE. NOT AN EXECUTABLE MIGRATION.
-- This file is intentionally under supabase/drafts/, not supabase/migrations/.
-- Do NOT run, replay, or copy into a migration directory without separate review
-- and explicit owner approval. This migration is already recorded as applied in Production.


-- DigiArz: approved demo wallet defaults, configurable fees, and instant coin reviews.
ALTER TABLE public.wallets
  ALTER COLUMN balance_usdt SET DEFAULT 200,
  ALTER COLUMN balance_irr SET DEFAULT 1000000000;

CREATE OR REPLACE FUNCTION public.new_user_setup()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
    INSERT INTO public.profiles (id, email)
    VALUES (NEW.id, NEW.email);

    INSERT INTO public.wallets (user_id, balance_usdt, balance_irr)
    VALUES (NEW.id, 200, 1000000000);

    RETURN NEW;
END;
$function$;

CREATE TABLE IF NOT EXISTS public.demo_trading_fees (
    quote_asset text PRIMARY KEY,
    maker_fee_rate numeric(10,8) NOT NULL CHECK (maker_fee_rate >= 0 AND maker_fee_rate <= 0.05),
    taker_fee_rate numeric(10,8) NOT NULL CHECK (taker_fee_rate >= 0 AND taker_fee_rate <= 0.05),
    is_enabled boolean NOT NULL DEFAULT true,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (quote_asset ~ '^[A-Z0-9]{2,12}$')
);

INSERT INTO public.demo_trading_fees (quote_asset, maker_fee_rate, taker_fee_rate)
VALUES ('USDT', 0.001, 0.0013), ('IRR', 0.0025, 0.0025)
ON CONFLICT (quote_asset) DO NOTHING;

ALTER TABLE public.demo_trading_fees ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.demo_trading_fees FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.get_demo_trading_fee_rate(p_quote_asset text, p_liquidity_type text)
RETURNS numeric
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
    v_rate numeric;
BEGIN
    IF p_liquidity_type NOT IN ('maker', 'taker') THEN
        RAISE EXCEPTION 'Invalid liquidity type';
    END IF;

    SELECT CASE WHEN p_liquidity_type = 'maker'
                THEN f.maker_fee_rate ELSE f.taker_fee_rate END
      INTO v_rate
      FROM public.demo_trading_fees AS f
     WHERE f.quote_asset = upper(btrim(p_quote_asset))
       AND f.is_enabled IS TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Trading fee is not configured for quote asset %', p_quote_asset;
    END IF;

    RETURN v_rate;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_demo_trading_fee_rate(text,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_demo_trading_fee_rate(text,text) TO authenticated;

-- Market orders are taker orders.
DO $migration$
DECLARE v_def text;
BEGIN
  v_def := pg_get_functiondef('public.execute_demo_trade(text,text,numeric,numeric)'::regprocedure);
  IF position('v_fee_rate numeric := 0.001;' in v_def) = 0 THEN
    RAISE EXCEPTION 'Unexpected execute_demo_trade definition; aborting fee migration';
  END IF;
  v_def := replace(v_def, 'v_fee_rate numeric := 0.001;', 'v_fee_rate numeric;');
  v_def := replace(v_def, 'v_gross := round(p_amount * v_price, 8);',
    'v_fee_rate := public.get_demo_trading_fee_rate(''USDT'', ''taker'');' || chr(10) ||
    '    v_gross := round(p_amount * v_price, 8);');
  EXECUTE v_def;
END;
$migration$;

-- Limit orders reserve maker fees; their fills are processed as maker liquidity.
DO $migration$
DECLARE v_def text;
BEGIN
  v_def := pg_get_functiondef('public.place_limit_order(text,text,numeric,numeric)'::regprocedure);
  IF position('v_required_amount := p_amount * p_limit_price * 1.001;' in v_def) = 0 THEN
    RAISE EXCEPTION 'Unexpected place_limit_order definition; aborting fee migration';
  END IF;
  v_def := replace(v_def, 'v_order_id uuid;', 'v_order_id uuid;' || chr(10) || '    v_fee_rate numeric;');
  v_def := replace(v_def, 'IF v_side = ''buy'' THEN',
    'v_fee_rate := public.get_demo_trading_fee_rate(''USDT'', ''maker'');' || chr(10) ||
    '    IF v_side = ''buy'' THEN');
  v_def := replace(v_def, 'v_required_amount := p_amount * p_limit_price * 1.001;',
    'v_required_amount := p_amount * p_limit_price * (1 + v_fee_rate);');
  v_def := replace(v_def, '''fee_rate'', 0.001,', '''fee_rate'', v_fee_rate,');
  EXECUTE v_def;
END;
$migration$;

-- Limit-order matching applies the maker fee consistently to fills and remaining reservations.
DO $migration$
DECLARE v_def text;
BEGIN
  v_def := pg_get_functiondef('public.process_limit_orders()'::regprocedure);
  IF position('v_fee := v_gross * 0.001;' in v_def) = 0 THEN
    RAISE EXCEPTION 'Unexpected process_limit_orders definition; aborting fee migration';
  END IF;
  v_def := replace(v_def, 'v_fee numeric;', 'v_fee numeric;' || chr(10) || '    v_fee_rate numeric;');
  v_def := replace(v_def, 'v_fee := v_gross * 0.001;',
    'v_fee_rate := public.get_demo_trading_fee_rate(''USDT'', ''maker'');' || chr(10) ||
    '        v_fee := v_gross * v_fee_rate;');
  v_def := replace(v_def, 'v_new_remaining * v_order.price * 1.001;',
    'v_new_remaining * v_order.price * (1 + v_fee_rate);');
  v_def := replace(v_def, '''fee_rate'', 0.001', '''fee_rate'', v_fee_rate');
  EXECUTE v_def;
END;
$migration$;

CREATE TABLE IF NOT EXISTS public.coin_reviews (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    symbol text NOT NULL CHECK (symbol ~ '^[A-Z0-9]{2,20}$'),
    rating smallint NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment text NOT NULL CHECK (char_length(btrim(comment)) BETWEEN 5 AND 1000),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, symbol)
);

CREATE INDEX IF NOT EXISTS coin_reviews_symbol_created_idx
ON public.coin_reviews(symbol, created_at DESC);

ALTER TABLE public.coin_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can read coin reviews" ON public.coin_reviews;
CREATE POLICY "Public can read coin reviews"
ON public.coin_reviews FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "Users can create own coin reviews" ON public.coin_reviews;
CREATE POLICY "Users can create own coin reviews"
ON public.coin_reviews FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id AND public.current_account_is_active());
DROP POLICY IF EXISTS "Users can update own coin reviews" ON public.coin_reviews;
CREATE POLICY "Users can update own coin reviews"
ON public.coin_reviews FOR UPDATE TO authenticated
USING (auth.uid() = user_id AND public.current_account_is_active())
WITH CHECK (auth.uid() = user_id AND public.current_account_is_active());
DROP POLICY IF EXISTS "Users can delete own coin reviews" ON public.coin_reviews;
CREATE POLICY "Users can delete own coin reviews"
ON public.coin_reviews FOR DELETE TO authenticated
USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.coin_review_reports (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id uuid NOT NULL REFERENCES public.coin_reviews(id) ON DELETE CASCADE,
    reporter_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reason text NOT NULL CHECK (char_length(btrim(reason)) BETWEEN 5 AND 500),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (review_id, reporter_user_id)
);
ALTER TABLE public.coin_review_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can report coin reviews" ON public.coin_review_reports;
CREATE POLICY "Users can report coin reviews"
ON public.coin_review_reports FOR INSERT TO authenticated
WITH CHECK (auth.uid() = reporter_user_id AND public.current_account_is_active());
REVOKE ALL ON public.coin_review_reports FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.coin_reviews TO authenticated;
GRANT SELECT ON public.coin_reviews TO anon;
GRANT INSERT ON public.coin_review_reports TO authenticated;

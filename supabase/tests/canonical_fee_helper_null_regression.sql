-- Disposable PostgreSQL 17 only.
-- Run after authoritative_market_limit_source_parity_setup.sql and the captured
-- Production fee-helper snapshot. This characterizes the captured helper defect
-- and tests a fail-closed candidate; it does not alter Production.
CREATE SCHEMA IF NOT EXISTS canonical_fee_candidate;

-- Distinct configured rates make the NULL-to-taker fall-through observable.
UPDATE public.demo_trading_fees
   SET maker_fee_rate = 0.002, taker_fee_rate = 0.001
 WHERE quote_asset = 'USDT' AND is_enabled IS TRUE;

DO $captured_source$
DECLARE
  v_maker numeric;
  v_taker numeric;
  v_null_liquidity numeric;
BEGIN
  v_maker := public.get_demo_trading_fee_rate('USDT', 'maker');
  v_taker := public.get_demo_trading_fee_rate('USDT', 'taker');
  v_null_liquidity := public.get_demo_trading_fee_rate('USDT', NULL);

  IF v_maker IS DISTINCT FROM 0.002::numeric
     OR v_taker IS DISTINCT FROM 0.001::numeric
     OR v_null_liquidity IS DISTINCT FROM v_taker
     OR v_null_liquidity IS NOT DISTINCT FROM v_maker THEN
    RAISE EXCEPTION
      'Captured source characterization changed: NULL liquidity no longer follows the taker ELSE branch';
  END IF;
END
$captured_source$;

CREATE OR REPLACE FUNCTION canonical_fee_candidate.get_demo_trading_fee_rate(
  p_quote_asset text,
  p_liquidity_type text
)
RETURNS numeric
LANGUAGE plpgsql
STABLE
SET search_path TO ''
AS $candidate$
DECLARE
  v_rate numeric;
BEGIN
  IF p_liquidity_type IS NULL
     OR p_liquidity_type NOT IN ('maker', 'taker') THEN
    RAISE EXCEPTION 'Invalid liquidity type' USING ERRCODE = '22023';
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
END
$candidate$;

DO $candidate_regression$
DECLARE
  v_maker numeric;
  v_taker numeric;
BEGIN
  v_maker := canonical_fee_candidate.get_demo_trading_fee_rate(' usdt ', 'maker');
  v_taker := canonical_fee_candidate.get_demo_trading_fee_rate('USDT', 'taker');

  IF v_maker IS DISTINCT FROM 0.002::numeric
     OR v_taker IS DISTINCT FROM 0.001::numeric THEN
    RAISE EXCEPTION 'Candidate must preserve configured maker/taker rates and quote normalization';
  END IF;

  BEGIN
    PERFORM canonical_fee_candidate.get_demo_trading_fee_rate('USDT', NULL);
    RAISE EXCEPTION 'Candidate unexpectedly accepted NULL liquidity type';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    NULL;
  END;

  BEGIN
    PERFORM canonical_fee_candidate.get_demo_trading_fee_rate('USDT', 'unknown');
    RAISE EXCEPTION 'Candidate unexpectedly accepted an invalid liquidity type';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    NULL;
  END;

  BEGIN
    PERFORM canonical_fee_candidate.get_demo_trading_fee_rate('NO_SUCH_QUOTE', 'taker');
    RAISE EXCEPTION 'Candidate unexpectedly accepted an unconfigured quote asset';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'Candidate unexpectedly accepted an unconfigured quote asset' THEN
      RAISE;
    END IF;
  END;
END
$candidate_regression$;

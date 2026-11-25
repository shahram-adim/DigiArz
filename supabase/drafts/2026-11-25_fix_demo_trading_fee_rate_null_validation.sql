-- PROPOSAL ONLY — do not execute against Production.
-- Reviewed target: public.get_demo_trading_fee_rate(text,text)
-- Purpose: reject NULL liquidity type rather than silently treating it as taker.
-- This is a reviewable SQL draft, NOT a timestamped Supabase migration.

CREATE OR REPLACE FUNCTION public.get_demo_trading_fee_rate(
    p_quote_asset text,
    p_liquidity_type text
)
RETURNS numeric
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
    v_rate numeric;
BEGIN
    IF p_liquidity_type IS NULL
       OR p_liquidity_type NOT IN ('maker', 'taker') THEN
        RAISE EXCEPTION 'Invalid liquidity type';
    END IF;

    SELECT CASE
             WHEN p_liquidity_type = 'maker' THEN f.maker_fee_rate
             ELSE f.taker_fee_rate
           END
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

-- Review notes:
-- * Preserves exact signature, return type, STABLE, SECURITY DEFINER and empty search_path.
-- * Adds explicit NULL rejection; valid maker/taker behavior is unchanged.
-- * No ownership, grants, default ACLs, or caller permissions are altered.
-- * Apply only through a separately approved migration after isolated tests pass.

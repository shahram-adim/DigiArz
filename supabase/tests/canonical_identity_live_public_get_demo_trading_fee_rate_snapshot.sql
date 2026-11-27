-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: get_demo_trading_fee_rate(text,text)
-- PostgreSQL md5(pg_get_functiondef(...)): 546d80d7105228ed97da26c5ed0c7b7f
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.get_demo_trading_fee_rate(p_quote_asset text, p_liquidity_type text)
 RETURNS numeric
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
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
$function$
;

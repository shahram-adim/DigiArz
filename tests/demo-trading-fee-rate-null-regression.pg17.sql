-- Disposable PostgreSQL 17 regression for NULL liquidity-type validation.
-- Uses only the synthetic fee table from the local CI bootstrap. Rolls back.
-- Never execute against Production.
\set ON_ERROR_STOP on
BEGIN;
INSERT INTO public.demo_trading_fees(quote_asset,maker_fee_rate,taker_fee_rate,is_enabled)
VALUES ('NULLCASE',0.0017,0.0031,true),('NULLDISABLED',0.0021,0.0042,false);

-- Reproduce the current guard's NULL fall-through.
CREATE OR REPLACE FUNCTION public.get_demo_trading_fee_rate(p_quote_asset text,p_liquidity_type text)
RETURNS numeric LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE v_rate numeric;
BEGIN
 IF p_liquidity_type NOT IN ('maker','taker') THEN RAISE EXCEPTION 'Invalid liquidity type'; END IF;
 SELECT CASE WHEN p_liquidity_type='maker' THEN f.maker_fee_rate ELSE f.taker_fee_rate END
 INTO v_rate FROM public.demo_trading_fees f
 WHERE f.quote_asset=upper(btrim(p_quote_asset)) AND f.is_enabled IS TRUE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Trading fee is not configured for quote asset %',p_quote_asset; END IF;
 RETURN v_rate;
END;
$function$;
DO $baseline$
BEGIN
 IF public.get_demo_trading_fee_rate('NULLCASE',NULL) IS DISTINCT FROM 0.0031 THEN
  RAISE EXCEPTION 'Expected baseline NULL fall-through to taker rate';
 END IF;
END $baseline$;

-- Apply the reviewed guard only inside this disposable transaction.
CREATE OR REPLACE FUNCTION public.get_demo_trading_fee_rate(p_quote_asset text,p_liquidity_type text)
RETURNS numeric LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE v_rate numeric;
BEGIN
 IF p_liquidity_type IS NULL OR p_liquidity_type NOT IN ('maker','taker') THEN
  RAISE EXCEPTION 'Invalid liquidity type';
 END IF;
 SELECT CASE WHEN p_liquidity_type='maker' THEN f.maker_fee_rate ELSE f.taker_fee_rate END
 INTO v_rate FROM public.demo_trading_fees f
 WHERE f.quote_asset=upper(btrim(p_quote_asset)) AND f.is_enabled IS TRUE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Trading fee is not configured for quote asset %',p_quote_asset; END IF;
 RETURN v_rate;
END;
$function$;
DO $assertions$
DECLARE v_message text;
BEGIN
 IF public.get_demo_trading_fee_rate('NULLCASE','maker') IS DISTINCT FROM 0.0017
 OR public.get_demo_trading_fee_rate('nullcase','taker') IS DISTINCT FROM 0.0031 THEN
  RAISE EXCEPTION 'Maker/taker rates changed after NULL guard';
 END IF;
 BEGIN
  PERFORM public.get_demo_trading_fee_rate('NULLCASE',NULL);
  RAISE EXCEPTION 'FAIL: NULL accepted';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_message=MESSAGE_TEXT;
  IF v_message<>'Invalid liquidity type' THEN RAISE; END IF;
 END;
 BEGIN
  PERFORM public.get_demo_trading_fee_rate('NULLCASE','provider');
  RAISE EXCEPTION 'FAIL: unsupported liquidity type accepted';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_message=MESSAGE_TEXT;
  IF v_message<>'Invalid liquidity type' THEN RAISE; END IF;
 END;
 BEGIN
  PERFORM public.get_demo_trading_fee_rate('NULLDISABLED','maker');
  RAISE EXCEPTION 'FAIL: disabled quote accepted';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_message=MESSAGE_TEXT;
  IF v_message NOT LIKE 'Trading fee is not configured for quote asset %' THEN RAISE; END IF;
 END;
END $assertions$;
ROLLBACK;

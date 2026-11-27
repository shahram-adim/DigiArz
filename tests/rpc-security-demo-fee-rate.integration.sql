-- TEST-ONLY: source-backed, read-only demo fee-rate RPC.
-- Only synthetic fee rows are inserted; all data is rolled back.
\set ON_ERROR_STOP on
BEGIN;

INSERT INTO public.demo_trading_fees
  (quote_asset,maker_fee_rate,taker_fee_rate,is_enabled)
VALUES
  ('USDT',0.001,0.0013,true),
  ('IRR',0.0025,0.0025,true),
  ('OFF',0.004,0.005,false);

SET LOCAL ROLE anon;
DO $anon$
BEGIN
  IF has_function_privilege('anon','public.get_demo_trading_fee_rate(text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'anon unexpectedly has fee-rate RPC EXECUTE';
  END IF;
  IF has_table_privilege('anon','public.demo_trading_fees','SELECT') THEN
    RAISE EXCEPTION 'anon unexpectedly has direct fee-table SELECT';
  END IF;
  BEGIN
    PERFORM public.get_demo_trading_fee_rate('USDT','maker');
    RAISE EXCEPTION 'Expected anon fee-rate RPC denial';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$anon$;
RESET ROLE;

SET LOCAL ROLE authenticated;
DO $authenticated$
BEGIN
  IF public.get_demo_trading_fee_rate(' usdt ','maker') <> 0.001
     OR public.get_demo_trading_fee_rate('USDT','taker') <> 0.0013
     OR public.get_demo_trading_fee_rate('irr','maker') <> 0.0025 THEN
    RAISE EXCEPTION 'Fee-rate lookup or normalization mismatch';
  END IF;

  IF has_table_privilege('authenticated','public.demo_trading_fees','SELECT') THEN
    RAISE EXCEPTION 'authenticated unexpectedly has direct fee-table SELECT';
  END IF;

  BEGIN
    PERFORM public.get_demo_trading_fee_rate('USDT','invalid');
    RAISE EXCEPTION 'Expected invalid-liquidity rejection';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Invalid liquidity type' THEN RAISE; END IF;
  END;

  BEGIN
    PERFORM public.get_demo_trading_fee_rate('MISSING','maker');
    RAISE EXCEPTION 'Expected missing-quote rejection';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Trading fee is not configured for quote asset MISSING' THEN RAISE; END IF;
  END;

  BEGIN
    PERFORM public.get_demo_trading_fee_rate('OFF','maker');
    RAISE EXCEPTION 'Expected disabled-quote rejection';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Trading fee is not configured for quote asset OFF' THEN RAISE; END IF;
  END;
END
$authenticated$;
RESET ROLE;

SET LOCAL ROLE service_role;
DO $service$
BEGIN
  IF public.get_demo_trading_fee_rate('USDT','maker') <> 0.001
     OR NOT has_table_privilege('service_role','public.demo_trading_fees','SELECT') THEN
    RAISE EXCEPTION 'service_role fee-rate ACL or lookup mismatch';
  END IF;
END
$service$;
RESET ROLE;

DO $catalog$
DECLARE
  v_result_type text;
BEGIN
  SELECT pg_catalog.format_type(p.prorettype,NULL)
  INTO v_result_type
  FROM pg_catalog.pg_proc p
  WHERE p.oid='public.get_demo_trading_fee_rate(text,text)'::regprocedure;

  IF v_result_type <> 'numeric'
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
       WHERE p.oid='public.get_demo_trading_fee_rate(text,text)'::regprocedure
         AND p.provolatile='s'
         AND p.prosecdef IS TRUE
         AND p.proowner='postgres'::regrole
         AND 'search_path=""'=ANY(p.proconfig)
     ) THEN
    RAISE EXCEPTION 'Fee-rate function metadata differs from Production';
  END IF;

  IF has_function_privilege('anon','public.get_demo_trading_fee_rate(text,text)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.get_demo_trading_fee_rate(text,text)','EXECUTE')
     OR NOT has_function_privilege('service_role','public.get_demo_trading_fee_rate(text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'Fee-rate function effective ACL differs from observed Production';
  END IF;

  IF NOT (SELECT relrowsecurity AND NOT relforcerowsecurity
          FROM pg_catalog.pg_class WHERE oid='public.demo_trading_fees'::regclass) THEN
    RAISE EXCEPTION 'demo_trading_fees RLS flags differ from Production';
  END IF;
END
$catalog$;

ROLLBACK;

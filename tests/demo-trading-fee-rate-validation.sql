-- Behavioral regression test for public.get_demo_trading_fee_rate(text,text)
-- Run only on a disposable test database with a configured enabled fee row.
-- This script performs function calls and catalog/table reads only; it does not
-- insert/update/delete data or alter schema/ACLs. Do NOT run against Production.

DO $fee_rate_test$
DECLARE
    v_quote_asset text;
    v_expected_maker numeric;
    v_expected_taker numeric;
    v_actual numeric;
    v_message text;
BEGIN
    SELECT f.quote_asset, f.maker_fee_rate, f.taker_fee_rate
      INTO v_quote_asset, v_expected_maker, v_expected_taker
      FROM public.demo_trading_fees AS f
     WHERE f.is_enabled IS TRUE
       AND f.quote_asset IS NOT NULL
     ORDER BY f.quote_asset
     LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Fixture error: at least one enabled quote-asset fee row is required';
    END IF;

    v_actual := public.get_demo_trading_fee_rate(v_quote_asset, 'maker');
    IF v_actual IS DISTINCT FROM v_expected_maker THEN
        RAISE EXCEPTION 'FAIL: maker rate mismatch for quote asset %', v_quote_asset;
    END IF;

    v_actual := public.get_demo_trading_fee_rate(v_quote_asset, 'taker');
    IF v_actual IS DISTINCT FROM v_expected_taker THEN
        RAISE EXCEPTION 'FAIL: taker rate mismatch for quote asset %', v_quote_asset;
    END IF;

    -- NULL and unsupported liquidity types must raise the exact validation error.
    BEGIN
        PERFORM public.get_demo_trading_fee_rate(v_quote_asset, NULL);
        RAISE EXCEPTION 'FAIL: NULL liquidity type was accepted';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_message = MESSAGE_TEXT;
        IF v_message <> 'Invalid liquidity type' THEN
            RAISE;
        END IF;
    END;

    BEGIN
        PERFORM public.get_demo_trading_fee_rate(v_quote_asset, 'provider');
        RAISE EXCEPTION 'FAIL: unsupported liquidity type was accepted';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_message = MESSAGE_TEXT;
        IF v_message <> 'Invalid liquidity type' THEN
            RAISE;
        END IF;
    END;

    -- An unknown quote asset must remain a configuration error, not return NULL.
    BEGIN
        PERFORM public.get_demo_trading_fee_rate('__DIGIARZ_TEST_UNKNOWN_QUOTE__', 'maker');
        RAISE EXCEPTION 'FAIL: unknown quote asset was accepted';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_message = MESSAGE_TEXT;
        IF v_message NOT LIKE 'Trading fee is not configured for quote asset %' THEN
            RAISE;
        END IF;
    END;

    RAISE NOTICE 'PASS: maker/taker rates preserved; NULL/invalid liquidity types and unknown quote asset rejected';
END
$fee_rate_test$;

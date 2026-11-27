-- Disposable PostgreSQL 17 integration for Stop-Limit and TP/SL placement RPCs.
-- Never run against Supabase Production.
DO $test$
DECLARE
  v_uid uuid := '61000000-0000-0000-0000-000000000006';
  v_result jsonb;
  v_order_id uuid;
  v_conditional_id uuid;
  v_amount numeric;
  v_trigger numeric;
  v_limit numeric;
  v_reserved numeric;
  v_asset text;
  v_count integer;
BEGIN
  INSERT INTO public.profiles(id,is_active) VALUES(v_uid,true);
  INSERT INTO public.demo_trading_pairs(pair_symbol,quote_asset,is_enabled)
  VALUES('BTCUSDT','USDT',true);
  INSERT INTO public.wallets(user_id,balance_usdt) VALUES(v_uid,200);
  INSERT INTO public.asset_balances(user_id,asset,balance)
  VALUES(v_uid,'BTC',2);

  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);

  -- Stop-Limit buy preserves 18-place amount and trigger/limit prices.
  v_result := public.place_stop_limit_order(
    'BTCUSDT','buy',
    0.123456789012345678,
    10.000000000000000001,
    11.000000000000000001
  );
  v_order_id := (v_result->>'order_id')::uuid;
  v_conditional_id := (v_result->>'conditional_order_id')::uuid;
  SELECT amount,price INTO v_amount,v_limit FROM public.orders WHERE id=v_order_id;
  SELECT amount,trigger_price,limit_price
    INTO v_amount,v_trigger,v_limit
  FROM public.conditional_orders WHERE id=v_conditional_id;
  IF v_amount <> 0.123456789012345678
     OR v_trigger <> 10.000000000000000001
     OR v_limit <> 11.000000000000000001 THEN
    RAISE EXCEPTION 'Stop-Limit buy precision mismatch: amount %, trigger %, limit %',
      v_amount,v_trigger,v_limit;
  END IF;
  SELECT reserved_amount,asset INTO v_reserved,v_asset
  FROM public.order_reservations WHERE order_id=v_order_id;
  IF v_asset <> 'USDT'
     OR v_reserved <> round(0.123456789012345678 * 11.000000000000000001,8)
       + round(round(0.123456789012345678 * 11.000000000000000001,8) * 0.001,8)
       + 0.0000001 THEN
    RAISE EXCEPTION 'Stop-Limit buy reservation mismatch: asset %, amount %',v_asset,v_reserved;
  END IF;

  -- Stop-Limit sell reserves the exact base quantity.
  v_result := public.place_stop_limit_order(
    'BTCUSDT','sell',
    0.250000000000000001,
    10.000000000000000001,
    9.000000000000000001
  );
  v_order_id := (v_result->>'order_id')::uuid;
  SELECT reserved_amount,asset INTO v_reserved,v_asset
  FROM public.order_reservations WHERE order_id=v_order_id;
  IF v_asset <> 'BTC' OR v_reserved <> 0.250000000000000001 THEN
    RAISE EXCEPTION 'Stop-Limit sell reservation mismatch: asset %, amount %',v_asset,v_reserved;
  END IF;

  -- TP/SL exit stores exact quantity/trigger and reserves exact base quantity.
  v_result := public.place_conditional_exit_order(
    'BTCUSDT','take_profit',
    0.333333333333333333,
    12.500000000000000001
  );
  v_order_id := (v_result->>'order_id')::uuid;
  v_conditional_id := (v_result->>'conditional_order_id')::uuid;
  SELECT amount,trigger_price INTO v_amount,v_trigger
  FROM public.conditional_orders WHERE id=v_conditional_id;
  IF v_amount <> 0.333333333333333333
     OR v_trigger <> 12.500000000000000001 THEN
    RAISE EXCEPTION 'TP/SL precision mismatch: amount %, trigger %',v_amount,v_trigger;
  END IF;
  SELECT reserved_amount,asset INTO v_reserved,v_asset
  FROM public.order_reservations WHERE order_id=v_order_id;
  IF v_asset <> 'BTC' OR v_reserved <> 0.333333333333333333 THEN
    RAISE EXCEPTION 'TP/SL reservation mismatch: asset %, amount %',v_asset,v_reserved;
  END IF;

  -- Over-cap sell notionals must be rejected before creating parent/reservation rows.
  UPDATE public.asset_balances SET balance=10 WHERE user_id=v_uid AND asset='BTC';
  BEGIN
    PERFORM public.place_stop_limit_order(
      'BTCUSDT','sell',2,9999999999999999,9999999999999998
    );
    RAISE EXCEPTION 'Expected oversized Stop-Limit sell settlement to be rejected';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Expected oversized Stop-Limit sell settlement to be rejected' THEN RAISE; END IF;
    IF SQLERRM NOT LIKE '%Stop-Limit sell settlement exceeds numeric(24,8) USDT capacity%' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.place_conditional_exit_order(
      'BTCUSDT','take_profit',2,9999999999999999
    );
    RAISE EXCEPTION 'Expected oversized TP/SL sell settlement to be rejected';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Expected oversized TP/SL sell settlement to be rejected' THEN RAISE; END IF;
    IF SQLERRM NOT LIKE '%Conditional exit settlement exceeds numeric(24,8) USDT capacity%' THEN RAISE; END IF;
  END;
  SELECT count(*) INTO v_count FROM public.orders WHERE user_id=v_uid;
  IF v_count <> 3 THEN
    RAISE EXCEPTION 'Rejected over-cap sell entrypoint persisted an order: %',v_count;
  END IF;

  -- Reject quantities that would settle to zero USDT.
  BEGIN
    PERFORM public.place_stop_limit_order(
      'BTCUSDT','buy',0.000000000000000001,1,1
    );
    RAISE EXCEPTION 'Expected zero-notional Stop-Limit to be rejected';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Expected zero-notional Stop-Limit to be rejected' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.place_conditional_exit_order(
      'BTCUSDT','stop_loss',0.000000000000000001,1
    );
    RAISE EXCEPTION 'Expected zero-notional TP/SL to be rejected';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Expected zero-notional TP/SL to be rejected' THEN RAISE; END IF;
  END;

  -- Reject more than 18 fractional digits rather than silently rounding.
  BEGIN
    PERFORM public.place_stop_limit_order(
      'BTCUSDT','buy',0.0000000000000000001,1,1
    );
    RAISE EXCEPTION 'Expected >18-place Stop-Limit amount to be rejected';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Expected >18-place Stop-Limit amount to be rejected' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.place_conditional_exit_order(
      'BTCUSDT','take_profit',0.0000000000000000001,1
    );
    RAISE EXCEPTION 'Expected >18-place TP/SL amount to be rejected';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Expected >18-place TP/SL amount to be rejected' THEN RAISE; END IF;
  END;


  -- Reject zero/negative Stop-Limit quantities and >18-place trigger/limit prices.
  FOREACH v_amount IN ARRAY ARRAY[0::numeric, -0.1::numeric] LOOP
    BEGIN
      PERFORM public.place_stop_limit_order('BTCUSDT','buy',v_amount,10,11);
      RAISE EXCEPTION 'Expected invalid Stop-Limit quantity to be rejected: %',v_amount;
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM LIKE 'Expected invalid Stop-Limit quantity%' THEN RAISE; END IF;
    END;
  END LOOP;
  BEGIN
    PERFORM public.place_stop_limit_order(
      'BTCUSDT','buy',0.1,10.0000000000000000001,11
    );
    RAISE EXCEPTION 'Expected >18-place Stop-Limit trigger to be rejected';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Expected >18-place Stop-Limit trigger to be rejected' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.place_stop_limit_order(
      'BTCUSDT','buy',0.1,10,11.0000000000000000001
    );
    RAISE EXCEPTION 'Expected >18-place Stop-Limit limit price to be rejected';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Expected >18-place Stop-Limit limit price to be rejected' THEN RAISE; END IF;
  END;

  -- Reject invalid TP/SL quantities and >18-place/negative trigger prices.
  FOREACH v_amount IN ARRAY ARRAY[0::numeric, -0.1::numeric] LOOP
    BEGIN
      PERFORM public.place_conditional_exit_order('BTCUSDT','take_profit',v_amount,12);
      RAISE EXCEPTION 'Expected invalid TP/SL quantity to be rejected: %',v_amount;
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM LIKE 'Expected invalid TP/SL quantity%' THEN RAISE; END IF;
    END;
  END LOOP;
  BEGIN
    PERFORM public.place_conditional_exit_order(
      'BTCUSDT','take_profit',0.1,12.0000000000000000001
    );
    RAISE EXCEPTION 'Expected >18-place TP/SL trigger to be rejected';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Expected >18-place TP/SL trigger to be rejected' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.place_conditional_exit_order(
      'BTCUSDT','take_profit',0.1,-12
    );
    RAISE EXCEPTION 'Expected negative TP/SL trigger to be rejected';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Expected negative TP/SL trigger to be rejected' THEN RAISE; END IF;
  END;

  RAISE NOTICE 'Stop-Limit and TP/SL placement entrypoint integration: PASS';
END
$test$;

-- Disposable PostgreSQL 17 CI integration for Market execution and Limit placement.
ALTER TABLE public.wallets ALTER COLUMN balance_usdt SET DEFAULT 200;
-- Never run against Supabase Production.
DO $test$
DECLARE
  v_uid uuid := '60000000-0000-0000-0000-000000000006';
  v_result jsonb;
  v_wallet numeric;
  v_asset numeric;
  v_order_id uuid;
  v_amount numeric;
  v_reserved numeric;
  v_count integer;
BEGIN
  INSERT INTO public.profiles(id,is_active) VALUES(v_uid,true);
  INSERT INTO public.demo_trading_pairs(pair_symbol,quote_asset,is_enabled)
  VALUES('BTCUSDT','USDT',true);
  INSERT INTO public.market_prices(symbol,price,updated_at)
  VALUES('BTCUSDT',10,now());
  INSERT INTO public.wallets(user_id,balance_usdt) VALUES(v_uid,200);
  INSERT INTO public.asset_balances(user_id,asset,balance)
  VALUES(v_uid,'BTC',0);

  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);

  -- Market buy: base quantity remains exact to 18 places; quote ledger rounds to 8.
  v_result := public.execute_demo_trade(
    'BTCUSDT','buy',1.000000000000000001,0
  );
  SELECT balance_usdt INTO v_wallet FROM public.wallets WHERE user_id=v_uid;
  SELECT balance INTO v_asset FROM public.asset_balances
  WHERE user_id=v_uid AND asset='BTC';
  IF v_wallet <> 189.99 OR v_asset <> 1.000000000000000001 THEN
    RAISE EXCEPTION 'Market buy balance mismatch: wallet %, BTC %',v_wallet,v_asset;
  END IF;
  SELECT count(*) INTO v_count FROM public.trades
  WHERE user_id=v_uid AND side='buy'
    AND amount=1.000000000000000001 AND price=10;
  IF v_count <> 1 THEN RAISE EXCEPTION 'Market buy trade precision mismatch'; END IF;

  -- Market sell: exact base debit and 8-place net credit.
  UPDATE public.market_prices SET price=12,updated_at=now() WHERE symbol='BTCUSDT';
  PERFORM public.execute_demo_trade(
    'BTCUSDT','sell',0.250000000000000001,0
  );
  SELECT balance_usdt INTO v_wallet FROM public.wallets WHERE user_id=v_uid;
  SELECT balance INTO v_asset FROM public.asset_balances
  WHERE user_id=v_uid AND asset='BTC';
  IF v_wallet <> 192.987 OR v_asset <> 0.750000000000000000 THEN
    RAISE EXCEPTION 'Market sell balance mismatch: wallet %, BTC %',v_wallet,v_asset;
  END IF;

  -- Limit buy reserves a quote amount rounded once to 8 places.
  v_result := public.place_limit_order(
    'BTCUSDT','buy',0.125000000000000001,8
  );
  v_order_id := (v_result->>'order_id')::uuid;
  SELECT amount INTO v_amount FROM public.orders WHERE id=v_order_id;
  SELECT reserved_amount INTO v_reserved FROM public.order_reservations
  WHERE order_id=v_order_id;
  IF v_amount <> 0.125000000000000001 OR v_reserved <> 1.0010001 THEN
    RAISE EXCEPTION 'Limit buy precision/reservation mismatch: amount %, reserve %',v_amount,v_reserved;
  END IF;

  -- Limit sell reserves the exact base quantity.
  v_result := public.place_limit_order(
    'BTCUSDT','sell',0.250000000000000001,8
  );
  v_order_id := (v_result->>'order_id')::uuid;
  SELECT reserved_amount INTO v_reserved FROM public.order_reservations
  WHERE order_id=v_order_id;
  IF v_reserved <> 0.250000000000000001 THEN
    RAISE EXCEPTION 'Limit sell reservation precision mismatch: %',v_reserved;
  END IF;

  -- Reject more than 18 fractional digits rather than silently rounding.
  BEGIN
    PERFORM public.place_limit_order(
      'BTCUSDT','buy',0.0000000000000000001,8
    );
    RAISE EXCEPTION 'Expected >18-place Limit amount to be rejected';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Expected >18-place Limit amount to be rejected' THEN RAISE; END IF;
  END;

  -- Reject Market buy settlement above numeric(24,8) capacity before any ledger write.
  UPDATE public.market_prices SET price=9999999999999999,updated_at=now()
  WHERE symbol='BTCUSDT';
  BEGIN
    PERFORM public.execute_demo_trade('BTCUSDT','buy',1000000,0);
    RAISE EXCEPTION 'Expected oversized Market settlement to be rejected';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Expected oversized Market settlement to be rejected' THEN RAISE; END IF;
    IF SQLERRM NOT LIKE '%numeric(24,8) USDT capacity%' THEN RAISE; END IF;
  END;
  SELECT balance_usdt INTO v_wallet FROM public.wallets WHERE user_id=v_uid;
  IF v_wallet <> 192.987 THEN
    RAISE EXCEPTION 'Rejected oversized Market trade changed wallet: %',v_wallet;
  END IF;

  -- Reject Limit buy reservation above numeric(24,8) capacity.
  BEGIN
    PERFORM public.place_limit_order(
      'BTCUSDT','buy',1000000,9999999999999999
    );
    RAISE EXCEPTION 'Expected oversized Limit reservation to be rejected';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Expected oversized Limit reservation to be rejected' THEN RAISE; END IF;
    IF SQLERRM NOT LIKE '%numeric(24,8) USDT capacity%' THEN RAISE; END IF;
  END;
  SELECT count(*) INTO v_count FROM public.orders
  WHERE user_id=v_uid AND order_type='limit';
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'Rejected oversized Limit order was persisted';
  END IF;

  RAISE NOTICE 'Market execution and Limit placement integration: PASS';
END
$test$;

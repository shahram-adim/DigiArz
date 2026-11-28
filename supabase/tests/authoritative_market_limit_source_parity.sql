-- Runs only after the exact authoritative Market/Limit migration has been applied
-- to the disposable PostgreSQL 17 database by the CI workflow.
DO $test$
DECLARE
  v_user uuid := '21000000-0000-0000-0000-000000000001';
  v_inactive uuid := '21000000-0000-0000-0000-000000000002';
  v_result jsonb;
  v_order uuid;
  v_wallet_before numeric;
  v_wallet_after numeric;
  v_filled numeric;
  v_reserved numeric;
  v_consumed numeric;
  v_released numeric;
  v_status text;
  i integer;
BEGIN
  INSERT INTO public.profiles(id,is_active) VALUES(v_user,true),(v_inactive,false);
  INSERT INTO public.wallets(user_id,balance_usdt) VALUES(v_user,1000),(v_inactive,1000);
  INSERT INTO public.asset_balances(user_id,asset,balance) VALUES(v_user,'DOT',10);
  INSERT INTO public.demo_trading_pairs(pair_symbol,quote_asset,is_enabled) VALUES('DOTUSDT','USDT',true);

  -- Exact captured Production helpers: fee configuration and active-account lookup.
  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
  IF public.current_account_is_active() IS NOT TRUE THEN
    RAISE EXCEPTION 'active-account helper rejected an active user';
  END IF;
  PERFORM set_config('request.jwt.claim.sub',v_inactive::text,true);
  IF public.current_account_is_active() IS NOT FALSE THEN
    RAISE EXCEPTION 'active-account helper accepted an inactive user';
  END IF;
  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
  IF public.get_demo_trading_fee_rate('USDT','maker')<>0.001
     OR public.get_demo_trading_fee_rate('USDT','taker')<>0.001 THEN
    RAISE EXCEPTION 'captured fee helper did not return configured maker/taker rates';
  END IF;
  BEGIN
    PERFORM public.get_demo_trading_fee_rate('MISSING','taker');
    RAISE EXCEPTION 'fee helper accepted an unconfigured quote asset';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='fee helper accepted an unconfigured quote asset' THEN RAISE; END IF;
    IF SQLERRM NOT LIKE '%Trading fee is not configured%' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.get_demo_trading_fee_rate('USDT','provider');
    RAISE EXCEPTION 'fee helper accepted an invalid liquidity type';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='fee helper accepted an invalid liquidity type' THEN RAISE; END IF;
    IF SQLERRM NOT LIKE '%Invalid liquidity type%' THEN RAISE; END IF;
  END;
  UPDATE public.demo_trading_fees SET is_enabled=false WHERE quote_asset='USDT';
  BEGIN
    PERFORM public.get_demo_trading_fee_rate('USDT','maker');
    RAISE EXCEPTION 'fee helper accepted a disabled fee configuration';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='fee helper accepted a disabled fee configuration' THEN RAISE; END IF;
    IF SQLERRM NOT LIKE '%Trading fee is not configured%' THEN RAISE; END IF;
  END;
  UPDATE public.demo_trading_fees SET is_enabled=true WHERE quote_asset='USDT';
  INSERT INTO public.market_prices(symbol,price,updated_at) VALUES('DOTUSDT',10,clock_timestamp());
  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);

  -- Actual Market buy entrypoint: fresh price, fee, wallet, balance, order, trade, transaction.
  v_wallet_before := (SELECT balance_usdt FROM public.wallets WHERE user_id=v_user);
  v_result := public.execute_demo_trade('DOTUSDT','buy',1,999999);
  IF COALESCE((v_result->>'success')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'authoritative Market buy failed: %',v_result;
  END IF;
  IF (SELECT balance FROM public.asset_balances WHERE user_id=v_user AND asset='DOT') <> 11 THEN
    RAISE EXCEPTION 'Market buy did not credit exact base quantity';
  END IF;
  IF (SELECT count(*) FROM public.trades WHERE user_id=v_user AND side='buy') <> 1 THEN
    RAISE EXCEPTION 'Market buy trade ledger missing';
  END IF;
  v_wallet_after := (SELECT balance_usdt FROM public.wallets WHERE user_id=v_user);
  IF v_wallet_before-v_wallet_after <> 10.01 THEN
    RAISE EXCEPTION 'Market buy wallet settlement mismatch: %',v_wallet_before-v_wallet_after;
  END IF;

  -- Actual Market sell entrypoint and base-asset debit.
  v_result := public.execute_demo_trade('DOTUSDT','sell',0.5,1);
  IF (SELECT balance FROM public.asset_balances WHERE user_id=v_user AND asset='DOT') <> 10.5 THEN
    RAISE EXCEPTION 'Market sell did not debit exact base quantity';
  END IF;
  IF (SELECT count(*) FROM public.trades WHERE user_id=v_user AND side='sell') <> 1 THEN
    RAISE EXCEPTION 'Market sell trade ledger missing';
  END IF;

  -- Existing USDT reservations must reduce available Market-buy funds.
  INSERT INTO public.order_reservations(
    order_id,user_id,asset,reserved_amount,consumed_amount,released_amount,status
  ) VALUES (
    '21000000-0000-0000-0000-000000000101',v_user,'USDT',
    (SELECT balance_usdt FROM public.wallets WHERE user_id=v_user),0,0,'reserved'
  );
  v_wallet_before := (SELECT balance_usdt FROM public.wallets WHERE user_id=v_user);
  BEGIN
    PERFORM public.execute_demo_trade('DOTUSDT','buy',0.1,10);
    RAISE EXCEPTION 'Market buy spent funds already reserved by a Limit order';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='Market buy spent funds already reserved by a Limit order' THEN RAISE; END IF;
    IF SQLERRM NOT LIKE '%Insufficient available USDT balance%' THEN RAISE; END IF;
  END;
  IF (SELECT balance_usdt FROM public.wallets WHERE user_id=v_user)<>v_wallet_before THEN
    RAISE EXCEPTION 'failed reserved-funds Market buy changed wallet balance';
  END IF;
  DELETE FROM public.order_reservations
  WHERE order_id='21000000-0000-0000-0000-000000000101';

  -- Existing base-asset reservations must reduce available Market-sell funds.
  INSERT INTO public.order_reservations(
    order_id,user_id,asset,reserved_amount,consumed_amount,released_amount,status
  ) VALUES (
    '21000000-0000-0000-0000-000000000102',v_user,'DOT',
    (SELECT balance FROM public.asset_balances WHERE user_id=v_user AND asset='DOT'),0,0,'reserved'
  );
  v_filled := (SELECT balance FROM public.asset_balances WHERE user_id=v_user AND asset='DOT');
  BEGIN
    PERFORM public.execute_demo_trade('DOTUSDT','sell',0.1,10);
    RAISE EXCEPTION 'Market sell spent base assets already reserved by a Limit order';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='Market sell spent base assets already reserved by a Limit order' THEN RAISE; END IF;
    IF SQLERRM NOT LIKE '%Insufficient available asset balance%' THEN RAISE; END IF;
  END;
  IF (SELECT balance FROM public.asset_balances WHERE user_id=v_user AND asset='DOT')<>v_filled THEN
    RAISE EXCEPTION 'failed reserved-funds Market sell changed base balance';
  END IF;
  DELETE FROM public.order_reservations
  WHERE order_id='21000000-0000-0000-0000-000000000102';

  -- Caller-supplied p_price is not authoritative; stale market data must fail closed.
  UPDATE public.market_prices SET updated_at=clock_timestamp()-interval '2 minutes' WHERE symbol='DOTUSDT';
  BEGIN
    PERFORM public.execute_demo_trade('DOTUSDT','buy',0.1,10);
    RAISE EXCEPTION 'stale Market quote unexpectedly executed';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='stale Market quote unexpectedly executed' THEN RAISE; END IF;
    IF SQLERRM NOT LIKE '%Market price unavailable or outdated%' THEN RAISE; END IF;
  END;
  UPDATE public.market_prices SET updated_at=clock_timestamp(),price=10 WHERE symbol='DOTUSDT';

  -- Inactive accounts must not place Market orders.
  PERFORM set_config('request.jwt.claim.sub',v_inactive::text,true);
  BEGIN
    PERFORM public.execute_demo_trade('DOTUSDT','buy',0.1,10);
    RAISE EXCEPTION 'inactive Market account unexpectedly executed';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='inactive Market account unexpectedly executed' THEN RAISE; END IF;
    IF SQLERRM NOT LIKE '%Account is inactive%' THEN RAISE; END IF;
  END;
  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);

  -- Actual Limit buy placement and worker partial fills: 4 cycles at 25% of original amount.
  v_result := public.place_limit_order('DOTUSDT','buy',1,11);
  v_order := (v_result->>'order_id')::uuid;
  IF v_order IS NULL THEN RAISE EXCEPTION 'Limit buy did not return order ID'; END IF;
  v_reserved := (SELECT reserved_amount FROM public.order_reservations WHERE order_id=v_order);
  IF v_reserved <> 11.011 THEN RAISE EXCEPTION 'Limit buy reserve mismatch: %',v_reserved; END IF;
  FOR i IN 1..4 LOOP
    PERFORM public.process_limit_orders();
  END LOOP;
  SELECT filled_amount,status INTO v_filled,v_status FROM public.orders WHERE id=v_order;
  SELECT consumed_amount,released_amount INTO v_consumed,v_released FROM public.order_reservations WHERE order_id=v_order;
  IF v_filled<>1 OR v_status<>'filled' THEN RAISE EXCEPTION 'Limit buy did not fully fill: %, %',v_filled,v_status; END IF;
  IF v_consumed<>10.01 OR v_released<>1.001 THEN
    RAISE EXCEPTION 'Limit buy reserve settlement mismatch: consumed %, released %',v_consumed,v_released;
  END IF;
  IF (SELECT count(*) FROM public.trades WHERE order_id=v_order)<>4 THEN
    RAISE EXCEPTION 'Limit buy expected four partial-fill trade rows';
  END IF;

  -- Actual Limit sell placement and four worker fills.
  v_result := public.place_limit_order('DOTUSDT','sell',1,9);
  v_order := (v_result->>'order_id')::uuid;
  IF (SELECT asset FROM public.order_reservations WHERE order_id=v_order)<>'DOT' THEN
    RAISE EXCEPTION 'Limit sell did not reserve the base asset';
  END IF;
  FOR i IN 1..4 LOOP
    PERFORM public.process_limit_orders();
  END LOOP;
  SELECT filled_amount,status INTO v_filled,v_status FROM public.orders WHERE id=v_order;
  SELECT consumed_amount,released_amount INTO v_consumed,v_released FROM public.order_reservations WHERE order_id=v_order;
  IF v_filled<>1 OR v_status<>'filled' THEN RAISE EXCEPTION 'Limit sell did not fully fill: %, %',v_filled,v_status; END IF;
  IF v_consumed<>1 OR v_released<>0 THEN
    RAISE EXCEPTION 'Limit sell reserve settlement mismatch: consumed %, released %',v_consumed,v_released;
  END IF;
  IF (SELECT count(*) FROM public.trades WHERE order_id=v_order)<>4 THEN
    RAISE EXCEPTION 'Limit sell expected four partial-fill trade rows';
  END IF;

  -- Stale quote must not consume the pending order or its reservation.
  v_result := public.place_limit_order('DOTUSDT','buy',1,11);
  v_order := (v_result->>'order_id')::uuid;
  UPDATE public.market_prices SET updated_at=clock_timestamp()-interval '2 minutes' WHERE symbol='DOTUSDT';
  v_result := public.process_limit_orders();
  IF (SELECT status FROM public.orders WHERE id=v_order)<>'pending'
     OR (SELECT status FROM public.order_reservations WHERE order_id=v_order)<>'reserved' THEN
    RAISE EXCEPTION 'stale Limit quote changed pending order/reservation';
  END IF;
  UPDATE public.market_prices SET updated_at=clock_timestamp(),price=10 WHERE symbol='DOTUSDT';

  -- Unauthenticated entrypoint must fail closed.
  PERFORM set_config('request.jwt.claim.sub','',true);
  BEGIN
    PERFORM public.place_limit_order('DOTUSDT','buy',0.1,10);
    RAISE EXCEPTION 'unauthenticated Limit placement unexpectedly succeeded';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='unauthenticated Limit placement unexpectedly succeeded' THEN RAISE; END IF;
    IF SQLERRM NOT LIKE '%Authentication required%' THEN RAISE; END IF;
  END;
END
$test$;

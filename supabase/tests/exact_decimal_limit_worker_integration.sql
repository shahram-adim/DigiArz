-- End-to-end accounting checks for the candidate Limit worker.
-- Runs only against the disposable PostgreSQL 17 CI database.
INSERT INTO public.profiles (id, is_active) VALUES
('10000000-0000-0000-0000-000000000001', true),
('20000000-0000-0000-0000-000000000002', true),
('30000000-0000-0000-0000-000000000003', true);

INSERT INTO public.demo_trading_pairs (pair_symbol, quote_asset, is_enabled)
VALUES ('BTCUSDT', 'USDT', true);
INSERT INTO public.market_prices (symbol, price, updated_at)
VALUES ('BTCUSDT', 10.000000000000000001, now());

INSERT INTO public.wallets (user_id, balance_usdt) VALUES
('10000000-0000-0000-0000-000000000001', 1000),
('20000000-0000-0000-0000-000000000002', 0),
('30000000-0000-0000-0000-000000000003', 100);

INSERT INTO public.asset_balances (user_id, asset, balance) VALUES
('10000000-0000-0000-0000-000000000001', 'BTC', 0),
('20000000-0000-0000-0000-000000000002', 'BTC', 2),
('30000000-0000-0000-0000-000000000003', 'BTC', 0);

INSERT INTO public.orders (
  id, user_id, symbol, side, order_type, amount, price,
  filled_amount, remaining_amount, status
) VALUES
('a1000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000001',
 'BTCUSDT', 'buy', 'limit', 1.000000000000000001, 10.000000000000000001, 0,
 1.000000000000000001, 'pending'),
('b2000000-0000-0000-0000-000000000002',
 '20000000-0000-0000-0000-000000000002',
 'BTCUSDT', 'sell', 'limit', 1.000000000000000001, 10.000000000000000001, 0,
 1.000000000000000001, 'pending'),
('c3000000-0000-0000-0000-000000000003',
 '30000000-0000-0000-0000-000000000003',
 'BTCUSDT', 'buy', 'limit', 0.000000000000000001, 10, 0,
 0.000000000000000001, 'pending');

INSERT INTO public.order_reservations (
  id, order_id, user_id, asset, reserved_amount, consumed_amount,
  released_amount, status
) VALUES
('a1000000-0000-0000-0000-000000000011',
 'a1000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000001',
 'USDT', 10.01, 0, 0, 'reserved'),
('b2000000-0000-0000-0000-000000000022',
 'b2000000-0000-0000-0000-000000000002',
 '20000000-0000-0000-0000-000000000002',
 'BTC', 1.000000000000000001, 0, 0, 'reserved'),
('c3000000-0000-0000-0000-000000000033',
 'c3000000-0000-0000-0000-000000000003',
 '30000000-0000-0000-0000-000000000003',
 'USDT', 0.00000001, 0, 0, 'reserved');

DO $test$
DECLARE
  v_cycle integer;
  v_result jsonb;
  v_value numeric;
BEGIN
  FOR v_cycle IN 1..4 LOOP
    v_result := public.process_limit_orders();
  END LOOP;

  IF (SELECT status FROM public.orders
      WHERE id='a1000000-0000-0000-0000-000000000001') <> 'filled' THEN
    RAISE EXCEPTION '18-place buy order did not finish in four cycles';
  END IF;
  SELECT sum(amount) INTO v_value FROM public.trades
  WHERE order_id='a1000000-0000-0000-0000-000000000001';
  IF v_value <> 1.000000000000000001::numeric THEN
    RAISE EXCEPTION 'Buy trade quantities lost precision: %', v_value;
  END IF;
  SELECT balance INTO v_value FROM public.asset_balances
  WHERE user_id='10000000-0000-0000-0000-000000000001' AND asset='BTC';
  IF v_value <> 1.000000000000000001::numeric THEN
    RAISE EXCEPTION 'Buy base balance mismatch: %', v_value;
  END IF;
  SELECT balance_usdt INTO v_value FROM public.wallets
  WHERE user_id='10000000-0000-0000-0000-000000000001';
  IF v_value <> 989.99::numeric THEN
    RAISE EXCEPTION 'Buy quote settlement mismatch: %', v_value;
  END IF;
  SELECT consumed_amount INTO v_value FROM public.order_reservations
  WHERE order_id='a1000000-0000-0000-0000-000000000001';
  IF v_value <> 10.01::numeric THEN
    RAISE EXCEPTION 'Buy reservation consumption mismatch: %', v_value;
  END IF;

  -- Quote transactions must reconcile to the 8-place USDT settlement,
  -- while the individual trade rows retain the 18-place market price.
  SELECT sum(amount) INTO v_value FROM public.transactions
  WHERE user_id='10000000-0000-0000-0000-000000000001'
    AND currency='USDT' AND transaction_type='limit_buy';
  IF v_value <> 10.01::numeric THEN
    RAISE EXCEPTION 'Buy transaction ledger mismatch: %', v_value;
  END IF;
  IF (SELECT count(*) FROM public.trades
      WHERE order_id='a1000000-0000-0000-0000-000000000001') <> 4
     OR EXISTS (
       SELECT 1 FROM public.trades
       WHERE order_id='a1000000-0000-0000-0000-000000000001'
         AND price <> 10.000000000000000001::numeric
     ) THEN
    RAISE EXCEPTION 'Buy trade price did not retain 18-place precision';
  END IF;

  IF (SELECT status FROM public.orders
      WHERE id='b2000000-0000-0000-0000-000000000002') <> 'filled' THEN
    RAISE EXCEPTION '18-place sell order did not finish in four cycles';
  END IF;
  SELECT sum(amount) INTO v_value FROM public.trades
  WHERE order_id='b2000000-0000-0000-0000-000000000002';
  IF v_value <> 1.000000000000000001::numeric THEN
    RAISE EXCEPTION 'Sell trade quantities lost precision: %', v_value;
  END IF;
  SELECT balance INTO v_value FROM public.asset_balances
  WHERE user_id='20000000-0000-0000-0000-000000000002' AND asset='BTC';
  IF v_value <> 0.999999999999999999::numeric THEN
    RAISE EXCEPTION 'Sell base balance mismatch: %', v_value;
  END IF;
  SELECT balance_usdt INTO v_value FROM public.wallets
  WHERE user_id='20000000-0000-0000-0000-000000000002';
  IF v_value <> 9.99::numeric THEN
    RAISE EXCEPTION 'Sell quote settlement mismatch: %', v_value;
  END IF;
  SELECT consumed_amount INTO v_value FROM public.order_reservations
  WHERE order_id='b2000000-0000-0000-0000-000000000002';
  IF v_value <> 1.000000000000000001::numeric THEN
    RAISE EXCEPTION 'Sell reservation consumption mismatch: %', v_value;
  END IF;

  SELECT sum(amount) INTO v_value FROM public.transactions
  WHERE user_id='20000000-0000-0000-0000-000000000002'
    AND currency='USDT' AND transaction_type='limit_sell';
  IF v_value <> 9.99::numeric THEN
    RAISE EXCEPTION 'Sell transaction ledger mismatch: %', v_value;
  END IF;
  IF (SELECT count(*) FROM public.trades
      WHERE order_id='b2000000-0000-0000-0000-000000000002') <> 4
     OR EXISTS (
       SELECT 1 FROM public.trades
       WHERE order_id='b2000000-0000-0000-0000-000000000002'
         AND price <> 10.000000000000000001::numeric
     ) THEN
    RAISE EXCEPTION 'Sell trade price did not retain 18-place precision';
  END IF;

  IF (SELECT status FROM public.orders
      WHERE id='c3000000-0000-0000-0000-000000000003') <> 'pending' THEN
    RAISE EXCEPTION 'Zero-notional order should remain pending and untouched';
  END IF;
  IF EXISTS (SELECT 1 FROM public.trades
             WHERE order_id='c3000000-0000-0000-0000-000000000003') THEN
    RAISE EXCEPTION 'Zero-notional order unexpectedly created a trade';
  END IF;
  IF (SELECT balance_usdt FROM public.wallets
      WHERE user_id='30000000-0000-0000-0000-000000000003') <> 100 THEN
    RAISE EXCEPTION 'Zero-notional order changed wallet balance';
  END IF;

  -- Oversized quote settlements must be skipped before touching either ledger.
  INSERT INTO public.profiles (id, is_active) VALUES
    ('40000000-0000-0000-0000-000000000004', true),
    ('50000000-0000-0000-0000-000000000005', true);
  INSERT INTO public.wallets (user_id, balance_usdt) VALUES
    ('40000000-0000-0000-0000-000000000004', 200),
    ('50000000-0000-0000-0000-000000000005', 100);
  INSERT INTO public.asset_balances (user_id, asset, balance) VALUES
    ('40000000-0000-0000-0000-000000000004', 'BTC', 0),
    ('50000000-0000-0000-0000-000000000005', 'BTC', 1000000);

  UPDATE public.market_prices
  SET price = 9999999999999999, updated_at = now()
  WHERE symbol = 'BTCUSDT';

  INSERT INTO public.orders (
    id, user_id, symbol, side, order_type, amount, price,
    filled_amount, remaining_amount, status
  ) VALUES
  ('64000000-0000-0000-0000-000000000064',
   '40000000-0000-0000-0000-000000000004',
   'BTCUSDT', 'buy', 'limit', 1000000, 9999999999999999,
   0, 1000000, 'pending'),
  ('65000000-0000-0000-0000-000000000065',
   '50000000-0000-0000-0000-000000000005',
   'BTCUSDT', 'sell', 'limit', 1000000, 9999999999999999,
   0, 1000000, 'pending');

  INSERT INTO public.order_reservations (
    id, order_id, user_id, asset, reserved_amount, consumed_amount,
    released_amount, status
  ) VALUES
  ('64000000-0000-0000-0000-000000000644',
   '64000000-0000-0000-0000-000000000064',
   '40000000-0000-0000-0000-000000000004',
   'USDT', 90000000000000000000, 0, 0, 'reserved'),
  ('65000000-0000-0000-0000-000000000655',
   '65000000-0000-0000-0000-000000000065',
   '50000000-0000-0000-0000-000000000005',
   'BTC', 1000000, 0, 0, 'reserved');

  v_result := public.process_limit_orders();

  IF (SELECT status FROM public.orders
      WHERE id='64000000-0000-0000-0000-000000000064') <> 'pending'
     OR (SELECT status FROM public.orders
         WHERE id='65000000-0000-0000-0000-000000000065') <> 'pending' THEN
    RAISE EXCEPTION 'Oversized settlement orders must remain pending';
  END IF;
  IF EXISTS (SELECT 1 FROM public.trades
             WHERE order_id IN (
               '64000000-0000-0000-0000-000000000064',
               '65000000-0000-0000-0000-000000000065'
             )) THEN
    RAISE EXCEPTION 'Oversized settlement unexpectedly created a trade';
  END IF;
  IF (SELECT balance_usdt FROM public.wallets
      WHERE user_id='40000000-0000-0000-0000-000000000004') <> 200
     OR (SELECT balance_usdt FROM public.wallets
         WHERE user_id='50000000-0000-0000-0000-000000000005') <> 100 THEN
    RAISE EXCEPTION 'Oversized settlement changed a USDT wallet';
  END IF;
  IF (SELECT balance FROM public.asset_balances
      WHERE user_id='40000000-0000-0000-0000-000000000004' AND asset='BTC') <> 0
     OR (SELECT balance FROM public.asset_balances
         WHERE user_id='50000000-0000-0000-0000-000000000005' AND asset='BTC') <> 1000000 THEN
    RAISE EXCEPTION 'Oversized settlement changed a base-asset balance';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.order_reservations
    WHERE order_id IN (
      '64000000-0000-0000-0000-000000000064',
      '65000000-0000-0000-0000-000000000065'
    )
    AND (consumed_amount <> 0 OR released_amount <> 0 OR status <> 'reserved')
  ) THEN
    RAISE EXCEPTION 'Oversized settlement changed reservation accounting';
  END IF;
END
$test$;

SELECT 'exact-decimal Limit worker integration: PASS' AS result;

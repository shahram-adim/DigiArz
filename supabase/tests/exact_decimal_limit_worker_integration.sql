-- End-to-end accounting checks for the candidate Limit worker.
-- Runs only against the disposable PostgreSQL 17 CI database.

-- Match the live function owner and EXECUTE ACL in the isolated rehearsal.
REVOKE ALL ON FUNCTION public.process_limit_orders() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.process_limit_orders() FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_limit_orders() TO service_role;

DO $acl_test$
DECLARE
  v_owner text;
  v_security_definer boolean;
  v_search_path text[];
BEGIN
  SELECT pg_get_userbyid(p.proowner), p.prosecdef, p.proconfig
  INTO v_owner, v_security_definer, v_search_path
  FROM pg_proc p
  WHERE p.oid='public.process_limit_orders()'::regprocedure;

  IF v_owner <> 'postgres' OR NOT v_security_definer
     OR NOT (v_search_path @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'Limit worker owner/SECURITY DEFINER/search_path mismatch: %, %, %',
      v_owner, v_security_definer, v_search_path;
  END IF;
  IF has_function_privilege('anon','public.process_limit_orders()','EXECUTE')
     OR has_function_privilege('authenticated','public.process_limit_orders()','EXECUTE')
     OR NOT has_function_privilege('service_role','public.process_limit_orders()','EXECUTE') THEN
    RAISE EXCEPTION 'Limit worker EXECUTE ACL differs from Production';
  END IF;
END
$acl_test$;
INSERT INTO auth.users (id) VALUES
('10000000-0000-0000-0000-000000000001'),
('20000000-0000-0000-0000-000000000002'),
('30000000-0000-0000-0000-000000000003');
INSERT INTO public.profiles (id, is_active) VALUES
('10000000-0000-0000-0000-000000000001', true),
('20000000-0000-0000-0000-000000000002', true),
('30000000-0000-0000-0000-000000000003', true);

INSERT INTO public.crypto_assets (coingecko_id) VALUES ('bitcoin');
INSERT INTO public.demo_trading_pairs (pair_symbol, base_coingecko_id, quote_asset, is_enabled)
VALUES ('BTCUSDT', 'bitcoin', 'USDT', true);
INSERT INTO public.market_prices (symbol, price, source, updated_at)
VALUES ('BTCUSDT', 10.000000000000000001, 'fixture', now());

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
  INSERT INTO auth.users (id) VALUES
    ('40000000-0000-0000-0000-000000000004'),
    ('50000000-0000-0000-0000-000000000005');
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


-- Production also guards INSERTs into orders, trades, and transactions.
-- Prove the disposable worker fixture rejects a ledger write for an inactive account.
INSERT INTO auth.users (id)
VALUES ('90000000-0000-0000-0000-000000000009');
INSERT INTO public.profiles (id, is_active)
VALUES ('90000000-0000-0000-0000-000000000009', false);

DO $guard_test$
DECLARE
  v_rejected boolean := false;
BEGIN
  BEGIN
    INSERT INTO public.transactions (
      user_id, currency, amount, transaction_type, description
    ) VALUES (
      '90000000-0000-0000-0000-000000000009',
      'USDT', 0.01, 'limit_buy', 'inactive-account trigger regression'
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'Account is inactive; reactivate the account before trading' THEN
      v_rejected := true;
    ELSE
      RAISE;
    END IF;
  END;

  IF NOT v_rejected THEN
    RAISE EXCEPTION 'Production active-account trigger accepted an inactive transaction';
  END IF;
END
$guard_test$;



-- Minimum fee half-quantum boundary: gross=0.00000500 USDT makes
-- the 0.1% fee exactly 0.000000005, which must round to one 8-place unit.
INSERT INTO auth.users (id)
VALUES ('60000000-0000-0000-0000-000000000006');
INSERT INTO public.profiles (id, is_active)
VALUES ('60000000-0000-0000-0000-000000000006', true);
INSERT INTO public.wallets (user_id, balance_usdt)
VALUES ('60000000-0000-0000-0000-000000000006', 1);
INSERT INTO public.asset_balances (user_id, asset, balance)
VALUES ('60000000-0000-0000-0000-000000000006', 'BTC', 0);

UPDATE public.orders
SET status='cancelled'
WHERE id IN (
  '64000000-0000-0000-0000-000000000064',
  '65000000-0000-0000-0000-000000000065'
);

UPDATE public.market_prices
SET price = 0.000005, updated_at = now()
WHERE symbol = 'BTCUSDT';

INSERT INTO public.orders (
  id, user_id, symbol, side, order_type, amount, price,
  filled_amount, remaining_amount, status
) VALUES (
  '66000000-0000-0000-0000-000000000066',
  '60000000-0000-0000-0000-000000000006',
  'BTCUSDT', 'buy', 'limit', 4, 0.000005,
  0, 4, 'pending'
);

INSERT INTO public.order_reservations (
  id, order_id, user_id, asset, reserved_amount,
  consumed_amount, released_amount, status
) VALUES (
  '66000000-0000-0000-0000-000000000666',
  '66000000-0000-0000-0000-000000000066',
  '60000000-0000-0000-0000-000000000006',
  'USDT', 0.00002020, 0, 0, 'reserved'
);

DO $fee_boundary$
DECLARE
  v_value numeric;
BEGIN
  PERFORM public.process_limit_orders();

  SELECT balance_usdt INTO v_value
  FROM public.wallets
  WHERE user_id='60000000-0000-0000-0000-000000000006';
  IF v_value <> 0.99999499::numeric THEN
    RAISE EXCEPTION 'Half-quantum fee was not rounded consistently in wallet: %', v_value;
  END IF;

  SELECT sum(amount) INTO v_value
  FROM public.transactions
  WHERE user_id='60000000-0000-0000-0000-000000000006'
    AND currency='USDT' AND transaction_type='limit_buy';
  IF v_value <> 0.00000501::numeric THEN
    RAISE EXCEPTION 'Half-quantum fee ledger mismatch: %', v_value;
  END IF;

  SELECT consumed_amount INTO v_value
  FROM public.order_reservations
  WHERE order_id='66000000-0000-0000-0000-000000000066';
  IF v_value <> 0.00000501::numeric THEN
    RAISE EXCEPTION 'Half-quantum fee reservation mismatch: %', v_value;
  END IF;

  SELECT amount INTO v_value
  FROM public.trades
  WHERE order_id='66000000-0000-0000-0000-000000000066';
  IF v_value <> 1::numeric THEN
    RAISE EXCEPTION 'Half-quantum fee boundary fill quantity mismatch: %', v_value;
  END IF;
END
$fee_boundary$;

-- Repeated partial fills must preserve the exact remaining reserve at every cycle.
INSERT INTO auth.users (id)
VALUES ('77000000-0000-0000-0000-000000000007');
INSERT INTO public.profiles (id, is_active)
VALUES ('77000000-0000-0000-0000-000000000007', true);
INSERT INTO public.wallets (user_id, balance_usdt)
VALUES ('77000000-0000-0000-0000-000000000007', 10);
INSERT INTO public.asset_balances (user_id, asset, balance)
VALUES ('77000000-0000-0000-0000-000000000007', 'BTC', 0);
UPDATE public.market_prices SET price=1, updated_at=now()
WHERE symbol='BTCUSDT';
INSERT INTO public.orders (
  id, user_id, symbol, side, order_type, amount, price,
  filled_amount, remaining_amount, status
) VALUES (
  '77000000-0000-0000-0000-000000000077',
  '77000000-0000-0000-0000-000000000007',
  'BTCUSDT', 'buy', 'limit', 4, 1, 0, 4, 'pending'
);
INSERT INTO public.order_reservations (
  id, order_id, user_id, asset, reserved_amount,
  consumed_amount, released_amount, status
) VALUES (
  '77000000-0000-0000-0000-000000000777',
  '77000000-0000-0000-0000-000000000077',
  '77000000-0000-0000-0000-000000000007',
  'USDT', 4.0040001, 0, 0, 'reserved'
);

DO $partial_reserve$
DECLARE
  v_cycle integer;
  v_consumed numeric;
  v_released numeric;
  v_expected numeric[] := ARRAY[1.001, 2.002, 3.003, 4.004]::numeric[];
  v_expected_release numeric[] := ARRAY[0, 0, 0, 0.0000001]::numeric[];
BEGIN
  FOR v_cycle IN 1..4 LOOP
    PERFORM public.process_limit_orders();
    SELECT consumed_amount, released_amount
    INTO v_consumed, v_released
    FROM public.order_reservations
    WHERE order_id='77000000-0000-0000-0000-000000000077';

    IF v_consumed <> v_expected[v_cycle]
       OR v_released <> v_expected_release[v_cycle] THEN
      RAISE EXCEPTION
        'Partial-fill reserve mismatch at cycle %: consumed %, released %',
        v_cycle, v_consumed, v_released;
    END IF;

    IF v_cycle < 4 AND (
      SELECT status FROM public.order_reservations
      WHERE order_id='77000000-0000-0000-0000-000000000077'
    ) <> 'reserved' THEN
      RAISE EXCEPTION 'Reservation left reserved state before final fill at cycle %', v_cycle;
    END IF;
  END LOOP;

  IF (SELECT status FROM public.orders
      WHERE id='77000000-0000-0000-0000-000000000077') <> 'filled' THEN
    RAISE EXCEPTION 'Repeated partial-fill order did not complete';
  END IF;
  IF (SELECT status FROM public.order_reservations
      WHERE order_id='77000000-0000-0000-0000-000000000077') <> 'released' THEN
    RAISE EXCEPTION 'Final reserve dust was not released';
  END IF;
  IF (SELECT balance_usdt FROM public.wallets
      WHERE user_id='77000000-0000-0000-0000-000000000007') <> 5.996 THEN
    RAISE EXCEPTION 'Repeated partial-fill wallet settlement mismatch';
  END IF;
END
$partial_reserve$;

-- If the remaining quarter cannot produce one 8-place quote unit, the worker
-- must absorb it into the current fill rather than leave unfillable base dust.
INSERT INTO auth.users (id)
VALUES ('88000000-0000-0000-0000-000000000008');
INSERT INTO public.profiles (id, is_active)
VALUES ('88000000-0000-0000-0000-000000000008', true);
INSERT INTO public.wallets (user_id, balance_usdt)
VALUES ('88000000-0000-0000-0000-000000000008', 1);
INSERT INTO public.asset_balances (user_id, asset, balance)
VALUES ('88000000-0000-0000-0000-000000000008', 'BTC', 0);
UPDATE public.market_prices SET price=0.06, updated_at=now()
WHERE symbol='BTCUSDT';
INSERT INTO public.orders (
  id, user_id, symbol, side, order_type, amount, price,
  filled_amount, remaining_amount, status
) VALUES (
  '88000000-0000-0000-0000-000000000088',
  '88000000-0000-0000-0000-000000000008',
  'BTCUSDT', 'buy', 'limit', 0.0000001, 0.06,
  0, 0.0000001, 'pending'
);
INSERT INTO public.order_reservations (
  id, order_id, user_id, asset, reserved_amount,
  consumed_amount, released_amount, status
) VALUES (
  '88000000-0000-0000-0000-000000000888',
  '88000000-0000-0000-0000-000000000088',
  '88000000-0000-0000-0000-000000000008',
  'USDT', 0.00000002, 0, 0, 'reserved'
);

DO $dust_remainder$
DECLARE
  v_value numeric;
BEGIN
  PERFORM public.process_limit_orders();

  IF (SELECT status FROM public.orders
      WHERE id='88000000-0000-0000-0000-000000000088') <> 'filled' THEN
    RAISE EXCEPTION 'Unsettleable remainder was not absorbed into the fill';
  END IF;
  SELECT filled_amount INTO v_value FROM public.orders
  WHERE id='88000000-0000-0000-0000-000000000088';
  IF v_value <> 0.0000001::numeric THEN
    RAISE EXCEPTION 'Dust-remainder fill quantity mismatch: %', v_value;
  END IF;
  SELECT sum(amount) INTO v_value FROM public.trades
  WHERE order_id='88000000-0000-0000-0000-000000000088';
  IF v_value <> 0.0000001::numeric THEN
    RAISE EXCEPTION 'Dust-remainder trade quantity mismatch: %', v_value;
  END IF;
  SELECT balance_usdt INTO v_value FROM public.wallets
  WHERE user_id='88000000-0000-0000-0000-000000000008';
  IF v_value <> 0.99999999::numeric THEN
    RAISE EXCEPTION 'Dust-remainder wallet debit mismatch: %', v_value;
  END IF;
  SELECT consumed_amount INTO v_value FROM public.order_reservations
  WHERE order_id='88000000-0000-0000-0000-000000000088';
  IF v_value <> 0.00000001::numeric THEN
    RAISE EXCEPTION 'Dust-remainder reservation consumption mismatch: %', v_value;
  END IF;
  SELECT released_amount INTO v_value FROM public.order_reservations
  WHERE order_id='88000000-0000-0000-0000-000000000088';
  IF v_value <> 0.00000001::numeric THEN
    RAISE EXCEPTION 'Dust-remainder reservation release mismatch: %', v_value;
  END IF;
END
$dust_remainder$;

SELECT 'exact-decimal Limit worker integration, fee boundary, partial-reserve lifecycle, dust remainder, and account guards: PASS' AS result;

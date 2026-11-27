-- Disposable proof of canonical asset IDs through duplicate-ticker demo trading.
-- This fixture creates only an isolated schema and never touches Production tables.
DROP SCHEMA IF EXISTS canonical_asset_candidate CASCADE;
CREATE SCHEMA canonical_asset_candidate;

CREATE TABLE canonical_asset_candidate.assets (
  asset_id uuid PRIMARY KEY,
  coingecko_id text NOT NULL UNIQUE,
  display_symbol text NOT NULL,
  display_name text NOT NULL,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE canonical_asset_candidate.provider_mappings (
  provider text NOT NULL,
  provider_asset_id text NOT NULL,
  asset_id uuid NOT NULL REFERENCES canonical_asset_candidate.assets(asset_id),
  PRIMARY KEY(provider,provider_asset_id),
  UNIQUE(provider,asset_id)
);

CREATE TABLE canonical_asset_candidate.pairs (
  pair_id uuid PRIMARY KEY,
  base_asset_id uuid NOT NULL REFERENCES canonical_asset_candidate.assets(asset_id),
  quote_asset_id uuid NOT NULL REFERENCES canonical_asset_candidate.assets(asset_id),
  display_pair text NOT NULL,
  is_enabled boolean NOT NULL DEFAULT true,
  UNIQUE(base_asset_id,quote_asset_id),
  UNIQUE(pair_id,base_asset_id,quote_asset_id)
);

CREATE TABLE canonical_asset_candidate.prices (
  pair_id uuid PRIMARY KEY REFERENCES canonical_asset_candidate.pairs(pair_id),
  price numeric NOT NULL CHECK(price>0 AND price::text NOT IN ('NaN','Infinity','-Infinity')),
  source text NOT NULL,
  observed_at timestamptz NOT NULL,
  received_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE canonical_asset_candidate.balances (
  user_id uuid NOT NULL,
  asset_id uuid NOT NULL REFERENCES canonical_asset_candidate.assets(asset_id),
  balance numeric NOT NULL DEFAULT 0 CHECK(balance>=0 AND balance::text NOT IN ('NaN','Infinity','-Infinity')),
  PRIMARY KEY(user_id,asset_id)
);

CREATE TABLE canonical_asset_candidate.orders (
  order_id uuid PRIMARY KEY,
  user_id uuid NOT NULL,
  pair_id uuid NOT NULL REFERENCES canonical_asset_candidate.pairs(pair_id),
  base_asset_id uuid NOT NULL REFERENCES canonical_asset_candidate.assets(asset_id),
  quote_asset_id uuid NOT NULL REFERENCES canonical_asset_candidate.assets(asset_id),
  side text NOT NULL CHECK(side IN ('buy','sell')),
  order_type text NOT NULL DEFAULT 'market' CHECK(order_type IN ('market','limit','conditional')),
  amount numeric NOT NULL CHECK(amount>0),
  price numeric NOT NULL CHECK(price>0),
  limit_price numeric,
  filled_amount numeric NOT NULL DEFAULT 0,
  remaining_amount numeric NOT NULL DEFAULT 0,
  status text NOT NULL CHECK(status IN ('pending','filled','cancelled')),
  UNIQUE(order_id,user_id),
  UNIQUE(order_id,user_id,pair_id,base_asset_id,quote_asset_id),
  FOREIGN KEY(pair_id,base_asset_id,quote_asset_id)
    REFERENCES canonical_asset_candidate.pairs(pair_id,base_asset_id,quote_asset_id),
  CHECK(filled_amount>=0 AND remaining_amount>=0 AND filled_amount+remaining_amount=amount)
);

CREATE TABLE canonical_asset_candidate.trades (
  trade_id uuid PRIMARY KEY,
  order_id uuid NOT NULL REFERENCES canonical_asset_candidate.orders(order_id),
  user_id uuid NOT NULL,
  pair_id uuid NOT NULL REFERENCES canonical_asset_candidate.pairs(pair_id),
  base_asset_id uuid NOT NULL REFERENCES canonical_asset_candidate.assets(asset_id),
  quote_asset_id uuid NOT NULL REFERENCES canonical_asset_candidate.assets(asset_id),
  side text NOT NULL CHECK(side IN ('buy','sell')),
  amount numeric NOT NULL CHECK(amount>0),
  price numeric NOT NULL CHECK(price>0),
  fee_quote numeric NOT NULL CHECK(fee_quote>=0),
  FOREIGN KEY(order_id,user_id,pair_id,base_asset_id,quote_asset_id)
    REFERENCES canonical_asset_candidate.orders(order_id,user_id,pair_id,base_asset_id,quote_asset_id)
);

CREATE TABLE canonical_asset_candidate.reservations (
  reservation_id uuid PRIMARY KEY,
  order_id uuid NOT NULL REFERENCES canonical_asset_candidate.orders(order_id),
  user_id uuid NOT NULL,
  asset_id uuid NOT NULL REFERENCES canonical_asset_candidate.assets(asset_id),
  amount numeric NOT NULL CHECK(amount>0),
  UNIQUE(order_id),
  FOREIGN KEY(order_id,user_id)
    REFERENCES canonical_asset_candidate.orders(order_id,user_id)
);

CREATE TABLE canonical_asset_candidate.conditional_orders (
  conditional_id uuid PRIMARY KEY,
  order_id uuid NOT NULL UNIQUE,
  user_id uuid NOT NULL,
  pair_id uuid NOT NULL,
  base_asset_id uuid NOT NULL,
  quote_asset_id uuid NOT NULL,
  display_pair text NOT NULL,
  order_kind text NOT NULL CHECK(order_kind IN ('take_profit','stop_loss','stop_limit')),
  trigger_price numeric NOT NULL CHECK(trigger_price>0),
  limit_price numeric,
  status text NOT NULL CHECK(status IN ('pending','triggered','filled','cancelled','rejected')),
  execution_order_id uuid UNIQUE,
  FOREIGN KEY(order_id,user_id,pair_id,base_asset_id,quote_asset_id)
    REFERENCES canonical_asset_candidate.orders(order_id,user_id,pair_id,base_asset_id,quote_asset_id),
  FOREIGN KEY(execution_order_id,user_id,pair_id,base_asset_id,quote_asset_id)
    REFERENCES canonical_asset_candidate.orders(order_id,user_id,pair_id,base_asset_id,quote_asset_id),
  CHECK((order_kind='stop_limit' AND limit_price IS NOT NULL AND limit_price>0)
     OR (order_kind IN ('take_profit','stop_loss') AND limit_price IS NULL))
);

CREATE OR REPLACE FUNCTION canonical_asset_candidate.execute_market_trade(
  p_user_id uuid,
  p_pair_id uuid,
  p_side text,
  p_amount numeric
) RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
  v_pair canonical_asset_candidate.pairs%ROWTYPE;
  v_price canonical_asset_candidate.prices%ROWTYPE;
  v_base_balance numeric;
  v_quote_balance numeric;
  v_quote_value numeric;
  v_fee numeric;
  v_order_id uuid := gen_random_uuid();
  v_trade_id uuid := gen_random_uuid();
BEGIN
  IF p_user_id IS NULL OR p_amount IS NULL OR p_amount<=0
     OR p_amount::text IN ('NaN','Infinity','-Infinity')
     OR p_side IS NULL OR p_side NOT IN ('buy','sell') THEN
    RAISE EXCEPTION 'invalid trade request' USING ERRCODE='22023';
  END IF;

  SELECT * INTO v_pair
  FROM canonical_asset_candidate.pairs
  WHERE pair_id=p_pair_id AND is_enabled
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'pair unavailable' USING ERRCODE='23514'; END IF;

  SELECT * INTO v_price
  FROM canonical_asset_candidate.prices
  WHERE pair_id=p_pair_id
    AND observed_at>=clock_timestamp()-interval '2 minutes'
    AND observed_at<=clock_timestamp()+interval '30 seconds';
  IF NOT FOUND THEN RAISE EXCEPTION 'price missing or stale' USING ERRCODE='23514'; END IF;

  IF NOT EXISTS (SELECT 1 FROM canonical_asset_candidate.assets WHERE asset_id=v_pair.base_asset_id AND is_active)
     OR NOT EXISTS (SELECT 1 FROM canonical_asset_candidate.assets WHERE asset_id=v_pair.quote_asset_id AND is_active) THEN
    RAISE EXCEPTION 'asset inactive' USING ERRCODE='23514';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM canonical_asset_candidate.assets WHERE asset_id=v_pair.quote_asset_id AND display_symbol='USDT') THEN
    RAISE EXCEPTION 'unsupported quote asset' USING ERRCODE='23514';
  END IF;

  INSERT INTO canonical_asset_candidate.balances(user_id,asset_id,balance)
  VALUES (p_user_id,v_pair.base_asset_id,0),(p_user_id,v_pair.quote_asset_id,0)
  ON CONFLICT(user_id,asset_id) DO NOTHING;

  PERFORM 1 FROM canonical_asset_candidate.balances
  WHERE user_id=p_user_id AND asset_id IN (v_pair.base_asset_id,v_pair.quote_asset_id)
  ORDER BY asset_id FOR UPDATE;

  SELECT balance INTO v_base_balance FROM canonical_asset_candidate.balances
  WHERE user_id=p_user_id AND asset_id=v_pair.base_asset_id;
  SELECT balance INTO v_quote_balance FROM canonical_asset_candidate.balances
  WHERE user_id=p_user_id AND asset_id=v_pair.quote_asset_id;

  v_quote_value := p_amount*v_price.price;
  v_fee := v_quote_value*0.001;

  IF p_side='buy' THEN
    IF v_quote_balance < v_quote_value+v_fee THEN
      RAISE EXCEPTION 'insufficient quote balance' USING ERRCODE='23514';
    END IF;
    UPDATE canonical_asset_candidate.balances
      SET balance=balance-v_quote_value-v_fee
      WHERE user_id=p_user_id AND asset_id=v_pair.quote_asset_id;
    UPDATE canonical_asset_candidate.balances
      SET balance=balance+p_amount
      WHERE user_id=p_user_id AND asset_id=v_pair.base_asset_id;
  ELSE
    IF v_base_balance < p_amount THEN
      RAISE EXCEPTION 'insufficient base balance' USING ERRCODE='23514';
    END IF;
    UPDATE canonical_asset_candidate.balances
      SET balance=balance-p_amount
      WHERE user_id=p_user_id AND asset_id=v_pair.base_asset_id;
    UPDATE canonical_asset_candidate.balances
      SET balance=balance+v_quote_value-v_fee
      WHERE user_id=p_user_id AND asset_id=v_pair.quote_asset_id;
  END IF;

  INSERT INTO canonical_asset_candidate.orders(
    order_id,user_id,pair_id,base_asset_id,quote_asset_id,side,order_type,
    amount,price,filled_amount,remaining_amount,status
  ) VALUES (
    v_order_id,p_user_id,v_pair.pair_id,v_pair.base_asset_id,v_pair.quote_asset_id,
    p_side,'market',p_amount,v_price.price,p_amount,0,'filled'
  );

  INSERT INTO canonical_asset_candidate.trades(
    trade_id,order_id,user_id,pair_id,base_asset_id,quote_asset_id,side,amount,price,fee_quote
  ) VALUES (
    v_trade_id,v_order_id,p_user_id,v_pair.pair_id,v_pair.base_asset_id,v_pair.quote_asset_id,
    p_side,p_amount,v_price.price,v_fee
  );

  RETURN v_order_id;
END;
$$;

CREATE OR REPLACE FUNCTION canonical_asset_candidate.place_limit_order(
  p_user_id uuid,p_pair_id uuid,p_side text,p_amount numeric,p_limit_price numeric
) RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
  v_pair canonical_asset_candidate.pairs%ROWTYPE;
  v_price canonical_asset_candidate.prices%ROWTYPE;
  v_base numeric;
  v_quote numeric;
  v_reserve_asset uuid;
  v_reserve_amount numeric;
  v_order uuid := gen_random_uuid();
BEGIN
  IF p_user_id IS NULL OR p_side IS NULL OR p_side NOT IN ('buy','sell')
     OR p_amount IS NULL OR p_amount<=0 OR p_amount::text IN ('NaN','Infinity','-Infinity')
     OR p_limit_price IS NULL OR p_limit_price<=0
     OR p_limit_price::text IN ('NaN','Infinity','-Infinity') THEN
    RAISE EXCEPTION 'invalid limit request' USING ERRCODE='22023';
  END IF;

  SELECT * INTO v_pair FROM canonical_asset_candidate.pairs
  WHERE pair_id=p_pair_id AND is_enabled FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'pair unavailable' USING ERRCODE='23514'; END IF;

  SELECT * INTO v_price FROM canonical_asset_candidate.prices
  WHERE pair_id=p_pair_id
    AND observed_at>=clock_timestamp()-interval '2 minutes'
    AND observed_at<=clock_timestamp()+interval '30 seconds';
  IF NOT FOUND THEN RAISE EXCEPTION 'price missing or stale' USING ERRCODE='23514'; END IF;

  IF NOT EXISTS (SELECT 1 FROM canonical_asset_candidate.assets WHERE asset_id=v_pair.base_asset_id AND is_active)
     OR NOT EXISTS (SELECT 1 FROM canonical_asset_candidate.assets WHERE asset_id=v_pair.quote_asset_id AND is_active)
     OR NOT EXISTS (SELECT 1 FROM canonical_asset_candidate.assets WHERE asset_id=v_pair.quote_asset_id AND display_symbol='USDT') THEN
    RAISE EXCEPTION 'asset inactive or unsupported quote' USING ERRCODE='23514';
  END IF;

  INSERT INTO canonical_asset_candidate.balances(user_id,asset_id,balance)
  VALUES (p_user_id,v_pair.base_asset_id,0),(p_user_id,v_pair.quote_asset_id,0)
  ON CONFLICT(user_id,asset_id) DO NOTHING;
  PERFORM 1 FROM canonical_asset_candidate.balances
  WHERE user_id=p_user_id AND asset_id IN (v_pair.base_asset_id,v_pair.quote_asset_id)
  ORDER BY asset_id FOR UPDATE;
  SELECT balance INTO v_base FROM canonical_asset_candidate.balances
  WHERE user_id=p_user_id AND asset_id=v_pair.base_asset_id;
  SELECT balance INTO v_quote FROM canonical_asset_candidate.balances
  WHERE user_id=p_user_id AND asset_id=v_pair.quote_asset_id;

  IF p_side='buy' THEN
    v_reserve_asset := v_pair.quote_asset_id;
    v_reserve_amount := p_amount*p_limit_price*1.001;
    IF v_quote<v_reserve_amount THEN RAISE EXCEPTION 'insufficient quote balance' USING ERRCODE='23514'; END IF;
    UPDATE canonical_asset_candidate.balances SET balance=balance-v_reserve_amount
    WHERE user_id=p_user_id AND asset_id=v_pair.quote_asset_id;
  ELSE
    v_reserve_asset := v_pair.base_asset_id;
    v_reserve_amount := p_amount;
    IF v_base<v_reserve_amount THEN RAISE EXCEPTION 'insufficient base balance' USING ERRCODE='23514'; END IF;
    UPDATE canonical_asset_candidate.balances SET balance=balance-v_reserve_amount
    WHERE user_id=p_user_id AND asset_id=v_pair.base_asset_id;
  END IF;

  INSERT INTO canonical_asset_candidate.orders(
    order_id,user_id,pair_id,base_asset_id,quote_asset_id,side,order_type,
    amount,price,limit_price,filled_amount,remaining_amount,status
  ) VALUES (
    v_order,p_user_id,v_pair.pair_id,v_pair.base_asset_id,v_pair.quote_asset_id,
    p_side,'limit',p_amount,p_limit_price,p_limit_price,0,p_amount,'pending'
  );

  INSERT INTO canonical_asset_candidate.reservations(
    reservation_id,order_id,user_id,asset_id,amount
  ) VALUES (gen_random_uuid(),v_order,p_user_id,v_reserve_asset,v_reserve_amount);

  RETURN v_order;
END;
$$;

CREATE OR REPLACE FUNCTION canonical_asset_candidate.process_limit_orders()
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  v_order canonical_asset_candidate.orders%ROWTYPE;
  v_pair canonical_asset_candidate.pairs%ROWTYPE;
  v_price numeric;
  v_reservation canonical_asset_candidate.reservations%ROWTYPE;
  v_fee numeric;
  v_value numeric;
  v_processed integer := 0;
BEGIN
  FOR v_order IN
    SELECT * FROM canonical_asset_candidate.orders
    WHERE order_type='limit' AND status='pending'
    ORDER BY order_id
    FOR UPDATE SKIP LOCKED
  LOOP
    SELECT * INTO v_pair FROM canonical_asset_candidate.pairs
    WHERE pair_id=v_order.pair_id AND is_enabled FOR UPDATE;
    IF NOT FOUND THEN CONTINUE; END IF;
    IF v_order.base_asset_id<>v_pair.base_asset_id
       OR v_order.quote_asset_id<>v_pair.quote_asset_id THEN
      CONTINUE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM canonical_asset_candidate.assets WHERE asset_id=v_pair.base_asset_id AND is_active)
       OR NOT EXISTS (SELECT 1 FROM canonical_asset_candidate.assets WHERE asset_id=v_pair.quote_asset_id AND is_active AND display_symbol='USDT') THEN
      CONTINUE;
    END IF;

    SELECT price INTO v_price FROM canonical_asset_candidate.prices
    WHERE pair_id=v_order.pair_id
      AND observed_at>=clock_timestamp()-interval '2 minutes'
      AND observed_at<=clock_timestamp()+interval '30 seconds';
    IF NOT FOUND THEN CONTINUE; END IF;

    IF (v_order.side='buy' AND v_price>v_order.limit_price)
       OR (v_order.side='sell' AND v_price<v_order.limit_price) THEN
      CONTINUE;
    END IF;

    SELECT * INTO v_reservation FROM canonical_asset_candidate.reservations
    WHERE order_id=v_order.order_id FOR UPDATE;
    IF NOT FOUND OR v_reservation.user_id<>v_order.user_id THEN
      RAISE EXCEPTION 'limit reservation missing or owner mismatch' USING ERRCODE='23514';
    END IF;

    PERFORM 1 FROM canonical_asset_candidate.balances
    WHERE user_id=v_order.user_id AND asset_id IN (v_order.base_asset_id,v_order.quote_asset_id)
    ORDER BY asset_id FOR UPDATE;

    v_value := v_order.amount*v_price;
    v_fee := v_value*0.001;

    IF v_order.side='buy' THEN
      IF v_reservation.asset_id<>v_order.quote_asset_id OR v_reservation.amount<v_value+v_fee THEN
        RAISE EXCEPTION 'limit quote reservation mismatch' USING ERRCODE='23514';
      END IF;
      UPDATE canonical_asset_candidate.balances
      SET balance=balance+v_reservation.amount-v_value-v_fee
      WHERE user_id=v_order.user_id AND asset_id=v_order.quote_asset_id;
      UPDATE canonical_asset_candidate.balances
      SET balance=balance+v_order.amount
      WHERE user_id=v_order.user_id AND asset_id=v_order.base_asset_id;
    ELSE
      IF v_reservation.asset_id<>v_order.base_asset_id OR v_reservation.amount<v_order.amount THEN
        RAISE EXCEPTION 'limit base reservation mismatch' USING ERRCODE='23514';
      END IF;
      UPDATE canonical_asset_candidate.balances
      SET balance=balance+v_value-v_fee
      WHERE user_id=v_order.user_id AND asset_id=v_order.quote_asset_id;
    END IF;

    INSERT INTO canonical_asset_candidate.trades(
      trade_id,order_id,user_id,pair_id,base_asset_id,quote_asset_id,side,amount,price,fee_quote
    ) VALUES (
      gen_random_uuid(),v_order.order_id,v_order.user_id,v_order.pair_id,
      v_order.base_asset_id,v_order.quote_asset_id,v_order.side,v_order.amount,v_price,v_fee
    );

    UPDATE canonical_asset_candidate.orders
    SET status='filled',price=v_price,filled_amount=amount,remaining_amount=0
    WHERE order_id=v_order.order_id;
    DELETE FROM canonical_asset_candidate.reservations WHERE order_id=v_order.order_id;
    v_processed := v_processed+1;
  END LOOP;
  RETURN v_processed;
END;
$$;


-- Pair administration is scoped exclusively by immutable pair_id, never display_pair.
CREATE OR REPLACE FUNCTION canonical_asset_candidate.disable_pair(p_pair_id uuid)
RETURNS integer
LANGUAGE plpgsql
AS $disable_pair$
DECLARE
  v_cancelled integer;
BEGIN
  UPDATE canonical_asset_candidate.pairs
  SET is_enabled=false
  WHERE pair_id=p_pair_id AND is_enabled;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'pair unavailable' USING ERRCODE='23514';
  END IF;

  UPDATE canonical_asset_candidate.orders
  SET status='cancelled'
  WHERE pair_id=p_pair_id AND status='pending';
  GET DIAGNOSTICS v_cancelled = ROW_COUNT;

  UPDATE canonical_asset_candidate.conditional_orders
  SET status='cancelled'
  WHERE pair_id=p_pair_id AND status IN ('pending','triggered');

  DELETE FROM canonical_asset_candidate.reservations r
  USING canonical_asset_candidate.orders o
  WHERE r.order_id=o.order_id AND o.pair_id=p_pair_id AND o.status='cancelled';

  RETURN v_cancelled;
END;
$disable_pair$;

DO $candidate_test$
DECLARE
  v_user uuid := '10000000-0000-0000-0000-000000000001';
  v_dot_a uuid := '20000000-0000-0000-0000-000000000001';
  v_dot_b uuid := '20000000-0000-0000-0000-000000000002';
  v_usdt uuid := '20000000-0000-0000-0000-000000000003';
  v_pair_a uuid := '30000000-0000-0000-0000-000000000001';
  v_pair_b uuid := '30000000-0000-0000-0000-000000000002';
  v_order uuid;
  v_limit_buy uuid;
  v_limit_sell uuid;
  v_limit_stale uuid;
  v_limit_bad_reservation uuid;
  v_reserve_amount numeric;
  v_disable_a uuid;
  v_disable_b uuid;
  v_cond_parent_a uuid;
  v_cond_parent_b uuid;
  v_cond_child_a uuid;
  v_cond_child_b uuid;
  v_processed integer;
  v_a numeric;
  v_b numeric;
  v_usdt_balance numeric;
  v_trade_count integer;
BEGIN
  INSERT INTO canonical_asset_candidate.assets(asset_id,coingecko_id,display_symbol,display_name) VALUES
    (v_dot_a,'polkadot','DOT','Polkadot'),
    (v_dot_b,'dot','DOT','Dot'),
    (v_usdt,'tether','USDT','Tether');
  INSERT INTO canonical_asset_candidate.provider_mappings(provider,provider_asset_id,asset_id) VALUES
    ('coingecko','polkadot',v_dot_a),
    ('coingecko','dot',v_dot_b),
    ('coingecko','tether',v_usdt);

  INSERT INTO canonical_asset_candidate.pairs(pair_id,base_asset_id,quote_asset_id,display_pair) VALUES
    (v_pair_a,v_dot_a,v_usdt,'DOT/USDT'),
    (v_pair_b,v_dot_b,v_usdt,'DOT/USDT');
  INSERT INTO canonical_asset_candidate.prices(pair_id,price,source,observed_at) VALUES
    (v_pair_a,10,'CoinGecko',clock_timestamp()),
    (v_pair_b,20,'CoinGecko',clock_timestamp());
  INSERT INTO canonical_asset_candidate.balances(user_id,asset_id,balance) VALUES
    (v_user,v_usdt,10000);

  -- Database constraints prevent an order from combining one pair ID with another asset ID.
  BEGIN
    INSERT INTO canonical_asset_candidate.orders(
      order_id,user_id,pair_id,base_asset_id,quote_asset_id,side,order_type,
      amount,price,filled_amount,remaining_amount,status
    ) VALUES (
      gen_random_uuid(),v_user,v_pair_a,v_dot_b,v_usdt,'buy','market',1,10,0,1,'pending'
    );
    RAISE EXCEPTION 'mismatched pair/base identity was accepted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;

  IF (SELECT count(*) FROM canonical_asset_candidate.pairs WHERE display_pair='DOT/USDT')<>2 THEN
    RAISE EXCEPTION 'duplicate display tickers were not represented as separate pairs';
  END IF;

  v_order := canonical_asset_candidate.execute_market_trade(v_user,v_pair_a,'buy',1);
  PERFORM canonical_asset_candidate.execute_market_trade(v_user,v_pair_b,'buy',1);
  PERFORM canonical_asset_candidate.execute_market_trade(v_user,v_pair_a,'sell',0.5);

  SELECT balance INTO v_a FROM canonical_asset_candidate.balances
  WHERE user_id=v_user AND asset_id=v_dot_a;
  SELECT balance INTO v_b FROM canonical_asset_candidate.balances
  WHERE user_id=v_user AND asset_id=v_dot_b;
  SELECT balance INTO v_usdt_balance FROM canonical_asset_candidate.balances
  WHERE user_id=v_user AND asset_id=v_usdt;

  IF v_a<>0.5 OR v_b<>1 THEN
    RAISE EXCEPTION 'same-ticker assets contaminated each other: asset A %, asset B %',v_a,v_b;
  END IF;
  IF v_usdt_balance<>9974.965 THEN
    RAISE EXCEPTION 'unexpected quote balance after fee-aware trades: %',v_usdt_balance;
  END IF;

  SELECT count(*) INTO v_trade_count FROM canonical_asset_candidate.trades
  WHERE user_id=v_user AND (
    (pair_id=v_pair_a AND base_asset_id=v_dot_a) OR
    (pair_id=v_pair_b AND base_asset_id=v_dot_b)
  );
  IF v_trade_count<>3 THEN RAISE EXCEPTION 'canonical trade identity was not preserved'; END IF;

  IF EXISTS (
    SELECT 1 FROM canonical_asset_candidate.trades
    WHERE (pair_id=v_pair_a AND base_asset_id<>v_dot_a)
       OR (pair_id=v_pair_b AND base_asset_id<>v_dot_b)
  ) THEN RAISE EXCEPTION 'pair/base canonical identity mismatch'; END IF;

  -- Provider IDs remain unique even when the display ticker is duplicated.
  BEGIN
    INSERT INTO canonical_asset_candidate.provider_mappings(provider,provider_asset_id,asset_id)
    VALUES ('coingecko','polkadot',v_dot_b);
    RAISE EXCEPTION 'provider ID was mapped to two canonical assets';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;

  -- Limit reservations and worker fills retain canonical asset identity.
  v_limit_buy := canonical_asset_candidate.place_limit_order(v_user,v_pair_a,'buy',1,9);
  v_limit_sell := canonical_asset_candidate.place_limit_order(v_user,v_pair_b,'sell',0.25,21);
  IF (SELECT asset_id FROM canonical_asset_candidate.reservations WHERE order_id=v_limit_buy)<>v_usdt
     OR (SELECT asset_id FROM canonical_asset_candidate.reservations WHERE order_id=v_limit_sell)<>v_dot_b THEN
    RAISE EXCEPTION 'limit reservations do not reference the canonical quote/base asset';
  END IF;

  UPDATE canonical_asset_candidate.prices SET price=8,observed_at=clock_timestamp() WHERE pair_id=v_pair_a;
  UPDATE canonical_asset_candidate.prices SET price=22,observed_at=clock_timestamp() WHERE pair_id=v_pair_b;
  v_processed := canonical_asset_candidate.process_limit_orders();
  IF v_processed<>2 THEN RAISE EXCEPTION 'expected two canonical limit fills, got %',v_processed; END IF;

  SELECT balance INTO v_a FROM canonical_asset_candidate.balances
  WHERE user_id=v_user AND asset_id=v_dot_a;
  SELECT balance INTO v_b FROM canonical_asset_candidate.balances
  WHERE user_id=v_user AND asset_id=v_dot_b;
  SELECT balance INTO v_usdt_balance FROM canonical_asset_candidate.balances
  WHERE user_id=v_user AND asset_id=v_usdt;
  IF v_a<>1.5 OR v_b<>0.75 OR v_usdt_balance<>9972.4515 THEN
    RAISE EXCEPTION 'limit worker changed wrong canonical balance: A %, B %, USDT %',v_a,v_b,v_usdt_balance;
  END IF;
  IF EXISTS (SELECT 1 FROM canonical_asset_candidate.reservations WHERE order_id IN (v_limit_buy,v_limit_sell)) THEN
    RAISE EXCEPTION 'filled limit orders retained reservations';
  END IF;
  IF (SELECT count(*) FROM canonical_asset_candidate.orders
      WHERE order_id IN (v_limit_buy,v_limit_sell) AND status='filled'
        AND ((order_id=v_limit_buy AND base_asset_id=v_dot_a)
          OR (order_id=v_limit_sell AND base_asset_id=v_dot_b)))<>2 THEN
    RAISE EXCEPTION 'limit order worker lost canonical pair identity';
  END IF;

  -- A stale market observation cannot trigger a pending limit order.
  v_limit_stale := canonical_asset_candidate.place_limit_order(v_user,v_pair_a,'sell',0.1,19);
  UPDATE canonical_asset_candidate.prices
  SET price=20,observed_at=clock_timestamp()-interval '3 minutes'
  WHERE pair_id=v_pair_a;
  v_processed := canonical_asset_candidate.process_limit_orders();
  IF v_processed<>0 OR (SELECT status FROM canonical_asset_candidate.orders WHERE order_id=v_limit_stale)<>'pending' THEN
    RAISE EXCEPTION 'stale provider price triggered a limit fill';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM canonical_asset_candidate.reservations
                 WHERE order_id=v_limit_stale AND asset_id=v_dot_a) THEN
    RAISE EXCEPTION 'stale limit order lost its canonical base reservation';
  END IF;

  -- Verify reservation ownership using a direct insert against an existing order.
  SELECT amount INTO v_reserve_amount
  FROM canonical_asset_candidate.reservations WHERE order_id=v_limit_stale;
  IF v_reserve_amount IS NULL THEN
    RAISE EXCEPTION 'pending limit reservation unexpectedly missing before ownership test';
  END IF;
  DELETE FROM canonical_asset_candidate.reservations WHERE order_id=v_limit_stale;
  BEGIN
    INSERT INTO canonical_asset_candidate.reservations(
      reservation_id,order_id,user_id,asset_id,amount
    ) VALUES (
      gen_random_uuid(),v_limit_stale,
      '10000000-0000-0000-0000-000000000099',v_dot_a,v_reserve_amount
    );
    RAISE EXCEPTION 'reservation owner mismatch was accepted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;
  INSERT INTO canonical_asset_candidate.reservations(
    reservation_id,order_id,user_id,asset_id,amount
  ) VALUES (gen_random_uuid(),v_limit_stale,v_user,v_dot_a,v_reserve_amount);
  UPDATE canonical_asset_candidate.prices
  SET price=20,observed_at=clock_timestamp()
  WHERE pair_id=v_pair_a;
  v_processed := canonical_asset_candidate.process_limit_orders();
  IF v_processed<>1 OR (SELECT status FROM canonical_asset_candidate.orders WHERE order_id=v_limit_stale)<>'filled' THEN
    RAISE EXCEPTION 'fresh canonical price did not trigger pending limit order';
  END IF;

  -- A malformed reservation asset must fail closed; the order and reservation remain retryable.
  v_limit_bad_reservation := canonical_asset_candidate.place_limit_order(v_user,v_pair_a,'sell',0.05,19);
  UPDATE canonical_asset_candidate.reservations
  SET asset_id=v_dot_b
  WHERE order_id=v_limit_bad_reservation;
  BEGIN
    PERFORM canonical_asset_candidate.process_limit_orders();
    RAISE EXCEPTION 'worker accepted reservation for the other same-ticker asset';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
  IF (SELECT status FROM canonical_asset_candidate.orders WHERE order_id=v_limit_bad_reservation)<>'pending'
     OR NOT EXISTS (SELECT 1 FROM canonical_asset_candidate.reservations
                    WHERE order_id=v_limit_bad_reservation AND asset_id=v_dot_b) THEN
    RAISE EXCEPTION 'invalid reservation was not preserved for safe retry';
  END IF;
  UPDATE canonical_asset_candidate.reservations
  SET asset_id=v_dot_a
  WHERE order_id=v_limit_bad_reservation;
  v_processed := canonical_asset_candidate.process_limit_orders();
  IF v_processed<>1 OR (SELECT status FROM canonical_asset_candidate.orders WHERE order_id=v_limit_bad_reservation)<>'filled' THEN
    RAISE EXCEPTION 'corrected canonical reservation did not retry successfully';
  END IF;

  SELECT balance INTO v_a FROM canonical_asset_candidate.balances
  WHERE user_id=v_user AND asset_id=v_dot_a;
  SELECT balance INTO v_usdt_balance FROM canonical_asset_candidate.balances
  WHERE user_id=v_user AND asset_id=v_usdt;
  IF v_a<>1.35 OR v_usdt_balance<>9975.4485 THEN
    RAISE EXCEPTION 'stale/fresh limit worker changed wrong balance: A %, USDT %',v_a,v_usdt_balance;
  END IF;

  -- A stale quote fails closed; local receive time cannot refresh it.
  UPDATE canonical_asset_candidate.prices
  SET observed_at=clock_timestamp()-interval '3 minutes'
  WHERE pair_id=v_pair_b;
  BEGIN
    PERFORM canonical_asset_candidate.execute_market_trade(v_user,v_pair_b,'buy',0.1);
    RAISE EXCEPTION 'stale canonical pair price was accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  -- Refresh both disposable pair observations before the subsequent placement/cancel assertions.
  UPDATE canonical_asset_candidate.prices
  SET observed_at=clock_timestamp()
  WHERE pair_id IN (v_pair_a,v_pair_b);

  -- Conditional parent and execution child must retain the exact same canonical pair.
  v_cond_parent_a := gen_random_uuid();
  v_cond_parent_b := gen_random_uuid();
  v_cond_child_a := gen_random_uuid();
  v_cond_child_b := gen_random_uuid();
  INSERT INTO canonical_asset_candidate.orders(
    order_id,user_id,pair_id,base_asset_id,quote_asset_id,side,order_type,
    amount,price,filled_amount,remaining_amount,status
  ) VALUES
    (v_cond_parent_a,v_user,v_pair_a,v_dot_a,v_usdt,'sell','conditional',0.1,20,0,0.1,'pending'),
    (v_cond_parent_b,v_user,v_pair_b,v_dot_b,v_usdt,'sell','conditional',0.1,20,0,0.1,'pending'),
    (v_cond_child_a,v_user,v_pair_a,v_dot_a,v_usdt,'sell','limit',0.1,19,0,0.1,'pending'),
    (v_cond_child_b,v_user,v_pair_b,v_dot_b,v_usdt,'sell','limit',0.1,19,0,0.1,'pending');
  INSERT INTO canonical_asset_candidate.reservations(
    reservation_id,order_id,user_id,asset_id,amount
  ) VALUES
    (gen_random_uuid(),v_cond_parent_a,v_user,v_dot_a,0.1),
    (gen_random_uuid(),v_cond_parent_b,v_user,v_dot_b,0.1);
  INSERT INTO canonical_asset_candidate.conditional_orders(
    conditional_id,order_id,user_id,pair_id,base_asset_id,quote_asset_id,
    display_pair,order_kind,trigger_price,limit_price,status
  ) VALUES
    (gen_random_uuid(),v_cond_parent_a,v_user,v_pair_a,v_dot_a,v_usdt,'DOT/USDT','stop_limit',20,19,'pending'),
    (gen_random_uuid(),v_cond_parent_b,v_user,v_pair_b,v_dot_b,v_usdt,'DOT/USDT','stop_limit',20,19,'pending');

  -- A child order from the other same-label pair must never attach to this parent.
  BEGIN
    UPDATE canonical_asset_candidate.conditional_orders
    SET status='triggered',execution_order_id=v_cond_child_b
    WHERE order_id=v_cond_parent_a;
    RAISE EXCEPTION 'cross-pair conditional child was accepted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;
  UPDATE canonical_asset_candidate.conditional_orders
  SET status='triggered',execution_order_id=v_cond_child_a
  WHERE order_id=v_cond_parent_a;
  UPDATE canonical_asset_candidate.conditional_orders
  SET status='triggered',execution_order_id=v_cond_child_b
  WHERE order_id=v_cond_parent_b;

  -- Disabling one same-label pair must cancel only its parent, child and reservation.
  v_disable_a := canonical_asset_candidate.place_limit_order(v_user,v_pair_a,'sell',0.1,30);
  v_disable_b := canonical_asset_candidate.place_limit_order(v_user,v_pair_b,'sell',0.1,30);
  IF canonical_asset_candidate.disable_pair(v_pair_a)<>3 THEN
    RAISE EXCEPTION 'pair disable did not cancel exactly three pending pair-A orders';
  END IF;
  IF (SELECT status FROM canonical_asset_candidate.orders WHERE order_id=v_disable_a)<>'cancelled'
     OR EXISTS (SELECT 1 FROM canonical_asset_candidate.reservations WHERE order_id=v_disable_a)
     OR (SELECT status FROM canonical_asset_candidate.orders WHERE order_id=v_cond_parent_a)<>'cancelled'
     OR (SELECT status FROM canonical_asset_candidate.orders WHERE order_id=v_cond_child_a)<>'cancelled'
     OR EXISTS (SELECT 1 FROM canonical_asset_candidate.reservations WHERE order_id=v_cond_parent_a)
     OR (SELECT status FROM canonical_asset_candidate.conditional_orders WHERE order_id=v_cond_parent_a)<>'cancelled' THEN
    RAISE EXCEPTION 'disabled pair retained conditional parent/child/reservation';
  END IF;
  IF (SELECT status FROM canonical_asset_candidate.orders WHERE order_id=v_disable_b)<>'pending'
     OR NOT EXISTS (SELECT 1 FROM canonical_asset_candidate.reservations WHERE order_id=v_disable_b)
     OR (SELECT status FROM canonical_asset_candidate.orders WHERE order_id=v_cond_parent_b)<>'pending'
     OR (SELECT status FROM canonical_asset_candidate.orders WHERE order_id=v_cond_child_b)<>'pending'
     OR NOT EXISTS (SELECT 1 FROM canonical_asset_candidate.reservations WHERE order_id=v_cond_parent_b)
     OR (SELECT status FROM canonical_asset_candidate.conditional_orders WHERE order_id=v_cond_parent_b)<>'triggered' THEN
    RAISE EXCEPTION 'pair disable crossed into another same-display-symbol conditional lifecycle';
  END IF;
  IF NOT (SELECT is_enabled FROM canonical_asset_candidate.pairs WHERE pair_id=v_pair_b) THEN
    RAISE EXCEPTION 'unrelated same-label pair was disabled';
  END IF;

  RAISE NOTICE 'Canonical asset identity / duplicate ticker Market and Limit lifecycle: PASS';
END $candidate_test$;

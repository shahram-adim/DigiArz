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
  UNIQUE(base_asset_id,quote_asset_id)
);

CREATE TABLE canonical_asset_candidate.prices (
  pair_id uuid PRIMARY KEY REFERENCES canonical_asset_candidate.pairs(pair_id),
  price numeric NOT NULL CHECK(price>0),
  source text NOT NULL,
  observed_at timestamptz NOT NULL,
  received_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE canonical_asset_candidate.balances (
  user_id uuid NOT NULL,
  asset_id uuid NOT NULL REFERENCES canonical_asset_candidate.assets(asset_id),
  balance numeric NOT NULL DEFAULT 0 CHECK(balance>=0),
  PRIMARY KEY(user_id,asset_id)
);

CREATE TABLE canonical_asset_candidate.orders (
  order_id uuid PRIMARY KEY,
  user_id uuid NOT NULL,
  pair_id uuid NOT NULL REFERENCES canonical_asset_candidate.pairs(pair_id),
  base_asset_id uuid NOT NULL REFERENCES canonical_asset_candidate.assets(asset_id),
  quote_asset_id uuid NOT NULL REFERENCES canonical_asset_candidate.assets(asset_id),
  side text NOT NULL CHECK(side IN ('buy','sell')),
  amount numeric NOT NULL CHECK(amount>0),
  price numeric NOT NULL CHECK(price>0),
  status text NOT NULL CHECK(status IN ('filled'))
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
  fee_quote numeric NOT NULL CHECK(fee_quote>=0)
);

CREATE TABLE canonical_asset_candidate.reservations (
  reservation_id uuid PRIMARY KEY,
  order_id uuid NOT NULL REFERENCES canonical_asset_candidate.orders(order_id),
  user_id uuid NOT NULL,
  asset_id uuid NOT NULL REFERENCES canonical_asset_candidate.assets(asset_id),
  amount numeric NOT NULL CHECK(amount>0)
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
  IF p_user_id IS NULL OR p_amount IS NULL OR p_amount<=0 OR p_side NOT IN ('buy','sell') THEN
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
    order_id,user_id,pair_id,base_asset_id,quote_asset_id,side,amount,price,status
  ) VALUES (
    v_order_id,p_user_id,v_pair.pair_id,v_pair.base_asset_id,v_pair.quote_asset_id,
    p_side,p_amount,v_price.price,'filled'
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

DO $$
DECLARE
  v_user uuid := '10000000-0000-0000-0000-000000000001';
  v_dot_a uuid := '20000000-0000-0000-0000-000000000001';
  v_dot_b uuid := '20000000-0000-0000-0000-000000000002';
  v_usdt uuid := '20000000-0000-0000-0000-000000000003';
  v_pair_a uuid := '30000000-0000-0000-0000-000000000001';
  v_pair_b uuid := '30000000-0000-0000-0000-000000000002';
  v_order uuid;
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

  RAISE NOTICE 'Canonical asset identity / duplicate ticker market buy-sell isolation: PASS';
END $$;

-- PostgreSQL 17 contract fixture for safe market-price bulk upserts.
-- This tests PostgreSQL mechanics and an explicit caller-supplied rank only.
-- It does NOT assert Production provider precedence or replace the live function.
BEGIN;

CREATE TEMP TABLE market_price_fixture (
  symbol text PRIMARY KEY,
  price numeric NOT NULL,
  source text NOT NULL
) ON COMMIT DROP;

-- PostgreSQL rejects one multi-row ON CONFLICT statement when two input rows
-- target the same unique key. Catch the expected cardinality_violation and
-- verify the failed statement made no partial write.
DO $test$
BEGIN
  BEGIN
    INSERT INTO market_price_fixture(symbol, price, source)
    VALUES ('BTC', 100, 'provider-a'), ('BTC', 101, 'provider-b')
    ON CONFLICT (symbol) DO UPDATE
      SET price = EXCLUDED.price, source = EXCLUDED.source;
    RAISE EXCEPTION 'duplicate conflict keys unexpectedly succeeded';
  EXCEPTION
    WHEN cardinality_violation THEN NULL;
  END;

  IF EXISTS (SELECT 1 FROM market_price_fixture) THEN
    RAISE EXCEPTION 'failed multi-row upsert left partial rows behind';
  END IF;
END
$test$;

CREATE TEMP TABLE market_price_input (
  symbol text NOT NULL,
  price numeric,
  source text NOT NULL,
  explicit_rank integer NOT NULL,
  received_order integer NOT NULL
) ON COMMIT DROP;

INSERT INTO market_price_input(symbol, price, source, explicit_rank, received_order)
VALUES
  ('BTC', 100, 'first-ranked', 1, 1),
  ('BTC', 101, 'second-ranked', 2, 2),
  ('ETH', 10, 'valid-eth', 1, 3),
  ('ZERO', 0, 'zero', 1, 4),
  ('NEG', -1, 'negative', 1, 5),
  ('NULL', NULL, 'null', 1, 6),
  ('NAN', 'NaN'::numeric, 'nan', 1, 7),
  ('INF', 'Infinity'::numeric, 'infinity', 1, 8);

-- Deduplicate by target key before the bulk statement. The rank is supplied
-- by the caller; this fixture deliberately does not define real provider rank.
WITH ranked AS (
  SELECT symbol, price, source,
         row_number() OVER (
           PARTITION BY symbol
           ORDER BY explicit_rank, received_order
         ) AS rn
  FROM market_price_input
  WHERE price IS NOT NULL
    AND price > 0
    AND price <> 'NaN'::numeric
    AND price <> 'Infinity'::numeric
),
chosen AS (
  SELECT symbol, price, source
  FROM ranked
  WHERE rn = 1
)
INSERT INTO market_price_fixture(symbol, price, source)
SELECT symbol, price, source
FROM chosen
ON CONFLICT (symbol) DO UPDATE
  SET price = EXCLUDED.price, source = EXCLUDED.source;

DO $test$
BEGIN
  IF (SELECT count(*) FROM market_price_fixture) <> 2 THEN
    RAISE EXCEPTION 'expected exactly BTC and ETH after filtering';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM market_price_fixture
    WHERE symbol = 'BTC' AND price = 100 AND source = 'first-ranked'
  ) THEN
    RAISE EXCEPTION 'explicit rank was not preserved for duplicate BTC';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM market_price_fixture
    WHERE symbol = 'ETH' AND price = 10 AND source = 'valid-eth'
  ) THEN
    RAISE EXCEPTION 'valid ETH price was not written';
  END IF;
  IF EXISTS (
    SELECT 1 FROM market_price_fixture
    WHERE price <= 0 OR price = 'NaN'::numeric OR price = 'Infinity'::numeric
  ) THEN
    RAISE EXCEPTION 'invalid price entered target table';
  END IF;
END
$test$;



-- Cross-provider duplicate-key scenario: two upstream CoinGecko IDs and
-- two exchange providers can all produce the same target symbol. This fixture
-- intentionally does not choose a winner or encode Production precedence.
CREATE TEMP TABLE provider_price_candidates (
  symbol text NOT NULL,
  price numeric NOT NULL,
  source text NOT NULL,
  upstream_key text NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE provider_price_target (
  symbol text PRIMARY KEY,
  price numeric NOT NULL,
  source text NOT NULL
) ON COMMIT DROP;

INSERT INTO provider_price_candidates(symbol, price, source, upstream_key)
VALUES
  ('SOL', 150, 'coingecko', 'coingecko-id-sol-a'),
  ('SOL', 151, 'coingecko', 'coingecko-id-sol-b'),
  ('SOL', 149, 'kucoin', 'SOL-USDT'),
  ('SOL', 152, 'gateio', 'SOL_USDT');

DO $test$
BEGIN
  IF (SELECT count(*) FROM provider_price_candidates WHERE symbol = 'SOL') <> 4 THEN
    RAISE EXCEPTION 'expected four independent SOL provider candidates';
  END IF;

  -- A direct set-based upsert cannot consume all four candidates for one
  -- unique target key. The failed statement must leave the target untouched.
  BEGIN
    INSERT INTO provider_price_target(symbol, price, source)
    SELECT symbol, price, source
    FROM provider_price_candidates
    WHERE symbol = 'SOL'
    ON CONFLICT (symbol) DO UPDATE
      SET price = EXCLUDED.price, source = EXCLUDED.source;
    RAISE EXCEPTION 'cross-provider duplicate target keys unexpectedly succeeded';
  EXCEPTION
    WHEN cardinality_violation THEN NULL;
  END;

  IF EXISTS (SELECT 1 FROM provider_price_target) THEN
    RAISE EXCEPTION 'failed cross-provider upsert left a partial SOL row';
  END IF;
END
$test$;


-- Response-level exception scope: earlier valid writes in the same response
-- roll back when a later numeric cast fails. Queue deletion is deliberately
-- outside that exception block, matching the repository migration structure.
CREATE TEMP TABLE response_price_target (
  symbol text PRIMARY KEY,
  price numeric NOT NULL,
  source text NOT NULL
) ON COMMIT DROP;
CREATE TEMP TABLE response_queue (
  response_id integer PRIMARY KEY,
  payload text NOT NULL
) ON COMMIT DROP;

INSERT INTO response_queue VALUES (1, 'valid-then-malformed');

DO $test$
DECLARE
  caught boolean := false;
BEGIN
  BEGIN
    INSERT INTO response_price_target(symbol, price, source)
    VALUES ('BTC', 100, 'response-1');

    -- Mirrors NULLIF(text, '')::numeric on a malformed non-empty ticker.
    PERFORM NULLIF('not-a-number', '')::numeric;
  EXCEPTION
    WHEN OTHERS THEN
      caught := true;
  END;

  IF NOT caught THEN
    RAISE EXCEPTION 'malformed ticker did not raise inside response block';
  END IF;

  -- This statement is outside the nested exception block and must persist.
  DELETE FROM response_queue WHERE response_id = 1;

  IF EXISTS (SELECT 1 FROM response_price_target WHERE symbol = 'BTC') THEN
    RAISE EXCEPTION 'valid write survived response-level exception rollback';
  END IF;
  IF EXISTS (SELECT 1 FROM response_queue WHERE response_id = 1) THEN
    RAISE EXCEPTION 'queue row was not deleted after caught response error';
  END IF;
END
$test$;

-- A failed response must not prevent a later queued response from processing.
TRUNCATE response_queue;
TRUNCATE response_price_target;
INSERT INTO response_queue VALUES
  (10, 'bad-response'),
  (11, 'good-response');

DO $test$
DECLARE
  item record;
BEGIN
  FOR item IN SELECT response_id, payload FROM response_queue ORDER BY response_id
  LOOP
    BEGIN
      IF item.response_id = 10 THEN
        INSERT INTO response_price_target(symbol, price, source)
        VALUES ('BAD_PARTIAL', 1, 'response-10');
        PERFORM NULLIF('malformed', '')::numeric;
      ELSE
        INSERT INTO response_price_target(symbol, price, source)
        VALUES ('ETH', 10, 'response-11');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        -- Match the production source's per-response catch boundary.
        NULL;
    END;

    DELETE FROM response_queue WHERE response_id = item.response_id;
  END LOOP;

  IF EXISTS (SELECT 1 FROM response_price_target WHERE symbol = 'BAD_PARTIAL') THEN
    RAISE EXCEPTION 'failed response retained a partial write';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM response_price_target
    WHERE symbol = 'ETH' AND price = 10 AND source = 'response-11'
  ) THEN
    RAISE EXCEPTION 'good response was not processed after prior response failure';
  END IF;
  IF EXISTS (SELECT 1 FROM response_queue) THEN
    RAISE EXCEPTION 'processed response queue rows were not deleted';
  END IF;
END
$test$;

-- Provider response gates: rejected HTTP/status/code/shape responses must
-- not write prices. These checks model the source predicates, not HTTP calls.
CREATE TEMP TABLE gated_response_target (
  symbol text PRIMARY KEY,
  price numeric NOT NULL
) ON COMMIT DROP;

DO $test$
DECLARE
  gate record;
  provider_code text;
  gate_payload jsonb;
BEGIN
  -- CoinGecko/KuCoin/Gate.io shared HTTP acceptance gate.
  FOR gate IN
    SELECT * FROM (VALUES
      (500, false, true),
      (200, true, true),
      (200, false, false)
    ) AS rejected(status, timeout_flag, has_content)
  LOOP
    IF gate.status = 200 AND NOT gate.timeout_flag AND gate.has_content THEN
      INSERT INTO gated_response_target VALUES ('SHOULD_NOT_APPEAR', 1);
    END IF;
  END LOOP;

  -- KuCoin requires provider code 200000.
  provider_code := '500000';
  IF provider_code = '200000' THEN
    INSERT INTO gated_response_target VALUES ('KUCOIN_BAD', 1);
  END IF;

  -- Gate.io expects an array; an object is rejected by the response handler.
  gate_payload := '{"currency_pair":"BTC_USDT","last":"100"}'::jsonb;
  IF jsonb_typeof(gate_payload) = 'array' THEN
    INSERT INTO gated_response_target VALUES ('GATE_BAD', 1);
  END IF;

  IF EXISTS (SELECT 1 FROM gated_response_target) THEN
    RAISE EXCEPTION 'a provider response that failed its acceptance gate wrote a price';
  END IF;
END
$test$;

-- Accepted positive-price updates carry the matching provider source; invalid
-- or rejected prices do not update source/price fields.
CREATE TEMP TABLE source_timestamp_target (
  symbol text PRIMARY KEY,
  price numeric NOT NULL,
  source text NOT NULL,
  updated_at timestamptz NOT NULL
) ON COMMIT DROP;

INSERT INTO source_timestamp_target
VALUES ('BTC', 90, 'old-source', '2026-01-01 00:00:00+00');

DO $test$
DECLARE
  before_updated_at timestamptz;
BEGIN
  SELECT updated_at INTO before_updated_at
  FROM source_timestamp_target WHERE symbol = 'BTC';

  -- Simulate the source's positive-price acceptance condition.
  IF 0::numeric > 0 THEN
    UPDATE source_timestamp_target
    SET price = 0, source = 'invalid-source', updated_at = now()
    WHERE symbol = 'BTC';
  END IF;

  IF (SELECT price FROM source_timestamp_target WHERE symbol = 'BTC') <> 90
     OR (SELECT source FROM source_timestamp_target WHERE symbol = 'BTC') <> 'old-source'
     OR (SELECT updated_at FROM source_timestamp_target WHERE symbol = 'BTC') <> before_updated_at THEN
    RAISE EXCEPTION 'rejected price changed existing price/source/timestamp';
  END IF;

  UPDATE source_timestamp_target
  SET price = 100, source = 'accepted-source', updated_at = now()
  WHERE symbol = 'BTC' AND 100::numeric > 0;

  IF (SELECT price FROM source_timestamp_target WHERE symbol = 'BTC') <> 100
     OR (SELECT source FROM source_timestamp_target WHERE symbol = 'BTC') <> 'accepted-source'
     OR (SELECT updated_at FROM source_timestamp_target WHERE symbol = 'BTC') <= before_updated_at THEN
    RAISE EXCEPTION 'accepted positive price did not update price/source/timestamp';
  END IF;
END
$test$;


-- Malformed JSON and missing provider keys are isolated to their response.
-- The malformed text cast is caught at the response exception boundary;
-- absent nested keys produce no ticker rows and therefore no price write.
CREATE TEMP TABLE malformed_payload_target (
  symbol text PRIMARY KEY,
  price numeric NOT NULL
) ON COMMIT DROP;

DO $test$
DECLARE
  caught boolean := false;
  parsed jsonb;
  missing_payload jsonb := '{"data":{}}'::jsonb;
BEGIN
  BEGIN
    parsed := '{"data":'::jsonb;
    INSERT INTO malformed_payload_target VALUES ('MALFORMED', 1);
  EXCEPTION
    WHEN OTHERS THEN
      caught := true;
  END;

  IF NOT caught THEN
    RAISE EXCEPTION 'malformed JSON did not raise inside response boundary';
  END IF;

  -- Missing KuCoin ticker key behaves as an empty result, not a price update.
  IF jsonb_typeof(missing_payload -> 'data' -> 'ticker') = 'array' THEN
    INSERT INTO malformed_payload_target VALUES ('MISSING_KEY', 1);
  END IF;

  IF EXISTS (SELECT 1 FROM malformed_payload_target) THEN
    RAISE EXCEPTION 'malformed or missing-key payload wrote a market price';
  END IF;
END
$test$;

ROLLBACK;

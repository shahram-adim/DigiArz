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

ROLLBACK;

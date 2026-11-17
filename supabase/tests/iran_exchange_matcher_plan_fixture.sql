\set ON_ERROR_STOP on

-- Disposable PostgreSQL 17 plan/scale experiment only.
-- Cardinalities mirror the current read-only Production snapshot:
-- 18,874 crypto assets and 4,960 exchange observations.
-- No Production schema, data, or indexes are touched.

CREATE TEMP TABLE plan_crypto_assets (
  id integer PRIMARY KEY,
  symbol text NOT NULL,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TEMP TABLE plan_exchange_observations (
  id integer PRIMARY KEY,
  base_symbol text NOT NULL,
  asset_name text NOT NULL,
  is_active boolean NOT NULL DEFAULT true
);

INSERT INTO plan_crypto_assets(id, symbol)
SELECT n, 'SYM' || lpad(n::text, 5, '0')
FROM generate_series(1, 18874) AS n;

INSERT INTO plan_exchange_observations(id, base_symbol, asset_name)
SELECT n, 'SYM' || lpad(n::text, 5, '0'), 'Synthetic asset ' || n
FROM generate_series(1, 4960) AS n;

-- Reproduce the relevant current index shape: lower(symbol) on the catalog
-- and upper(base_symbol) on observations.
CREATE INDEX plan_crypto_assets_lower_symbol_idx
  ON plan_crypto_assets (lower(symbol));
CREATE INDEX plan_observations_upper_base_symbol_idx
  ON plan_exchange_observations (upper(base_symbol));

ANALYZE plan_crypto_assets;
ANALYZE plan_exchange_observations;

CREATE TEMP TABLE plan_experiment_results (
  scenario text PRIMARY KEY,
  plan jsonb NOT NULL
);

DO $$
DECLARE
  v_plan jsonb;
BEGIN
  -- A small dirty batch is the intended access pattern for incremental matching.
  EXECUTE $plan$
    EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
    SELECT o.id, ca.id
    FROM plan_exchange_observations o
    JOIN plan_crypto_assets ca
      ON upper(ca.symbol) = upper(o.base_symbol)
     AND ca.is_active IS TRUE
    WHERE o.is_active IS TRUE
      AND o.asset_name IS NOT NULL
      AND o.id <= 100
  $plan$ INTO v_plan;
  INSERT INTO plan_experiment_results VALUES ('dirty_batch_lower_index_only', v_plan);

  -- Full-scan baseline under the same lower(symbol)-only catalog index.
  EXECUTE $plan$
    EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
    SELECT o.id, ca.id
    FROM plan_exchange_observations o
    JOIN plan_crypto_assets ca
      ON upper(ca.symbol) = upper(o.base_symbol)
     AND ca.is_active IS TRUE
    WHERE o.is_active IS TRUE
      AND o.asset_name IS NOT NULL
  $plan$ INTO v_plan;
  INSERT INTO plan_experiment_results VALUES ('full_scan_lower_index_only', v_plan);

  -- Candidate index exists only on this disposable fixture.
  CREATE INDEX plan_crypto_assets_upper_symbol_idx
    ON plan_crypto_assets (upper(symbol));
  ANALYZE plan_crypto_assets;

  EXECUTE $plan$
    EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
    SELECT o.id, ca.id
    FROM plan_exchange_observations o
    JOIN plan_crypto_assets ca
      ON upper(ca.symbol) = upper(o.base_symbol)
     AND ca.is_active IS TRUE
    WHERE o.is_active IS TRUE
      AND o.asset_name IS NOT NULL
      AND o.id <= 100
  $plan$ INTO v_plan;
  INSERT INTO plan_experiment_results VALUES ('dirty_batch_with_upper_index', v_plan);

  EXECUTE $plan$
    EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
    SELECT o.id, ca.id
    FROM plan_exchange_observations o
    JOIN plan_crypto_assets ca
      ON upper(ca.symbol) = upper(o.base_symbol)
     AND ca.is_active IS TRUE
    WHERE o.is_active IS TRUE
      AND o.asset_name IS NOT NULL
  $plan$ INTO v_plan;
  INSERT INTO plan_experiment_results VALUES ('full_scan_with_upper_index', v_plan);
END $$;

-- Emit actual execution time, buffer counts, and chosen plan for each scenario.
SELECT scenario,
       plan->0->>'Planning Time' AS planning_time_ms,
       plan->0->>'Execution Time' AS execution_time_ms,
       plan->0->'Plan' AS plan
FROM plan_experiment_results
ORDER BY scenario;

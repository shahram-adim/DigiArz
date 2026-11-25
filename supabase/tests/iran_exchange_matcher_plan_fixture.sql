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
SELECT n, 'SYM' || lpad(n::text, 5, '0') FROM generate_series(1, 18874) AS n;
INSERT INTO plan_exchange_observations(id, base_symbol, asset_name)
SELECT n, 'SYM' || lpad(n::text, 5, '0'), 'Synthetic asset ' || n
FROM generate_series(1, 4960) AS n;

CREATE INDEX plan_crypto_assets_lower_symbol_idx ON plan_crypto_assets (lower(symbol));
CREATE INDEX plan_observations_upper_base_symbol_idx ON plan_exchange_observations (upper(base_symbol));
ANALYZE plan_crypto_assets;
ANALYZE plan_exchange_observations;

CREATE TEMP TABLE plan_experiment_results (
  scenario text NOT NULL, iteration integer NOT NULL, plan jsonb NOT NULL,
  PRIMARY KEY (scenario, iteration)
);

DO $$
DECLARE v_plan jsonb; i integer;
BEGIN
  -- Warm each case once, then collect five warm-cache measurements.
  EXECUTE $q$EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
    SELECT o.id, ca.id FROM plan_exchange_observations o
    JOIN plan_crypto_assets ca ON upper(ca.symbol)=upper(o.base_symbol) AND ca.is_active IS TRUE
    WHERE o.is_active IS TRUE AND o.asset_name IS NOT NULL AND o.id<=100$q$ INTO v_plan;
  FOR i IN 1..5 LOOP
    EXECUTE $q$EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT o.id, ca.id FROM plan_exchange_observations o
      JOIN plan_crypto_assets ca ON upper(ca.symbol)=upper(o.base_symbol) AND ca.is_active IS TRUE
      WHERE o.is_active IS TRUE AND o.asset_name IS NOT NULL AND o.id<=100$q$ INTO v_plan;
    INSERT INTO plan_experiment_results VALUES ('dirty_batch_lower_index_only',i,v_plan);
  END LOOP;

  EXECUTE $q$EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
    SELECT o.id, ca.id FROM plan_exchange_observations o
    JOIN plan_crypto_assets ca ON upper(ca.symbol)=upper(o.base_symbol) AND ca.is_active IS TRUE
    WHERE o.is_active IS TRUE AND o.asset_name IS NOT NULL$q$ INTO v_plan;
  FOR i IN 1..5 LOOP
    EXECUTE $q$EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT o.id, ca.id FROM plan_exchange_observations o
      JOIN plan_crypto_assets ca ON upper(ca.symbol)=upper(o.base_symbol) AND ca.is_active IS TRUE
      WHERE o.is_active IS TRUE AND o.asset_name IS NOT NULL$q$ INTO v_plan;
    INSERT INTO plan_experiment_results VALUES ('full_scan_lower_index_only',i,v_plan);
  END LOOP;

  CREATE INDEX plan_crypto_assets_upper_symbol_idx ON plan_crypto_assets (upper(symbol));
  ANALYZE plan_crypto_assets;

  EXECUTE $q$EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
    SELECT o.id, ca.id FROM plan_exchange_observations o
    JOIN plan_crypto_assets ca ON upper(ca.symbol)=upper(o.base_symbol) AND ca.is_active IS TRUE
    WHERE o.is_active IS TRUE AND o.asset_name IS NOT NULL AND o.id<=100$q$ INTO v_plan;
  FOR i IN 1..5 LOOP
    EXECUTE $q$EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT o.id, ca.id FROM plan_exchange_observations o
      JOIN plan_crypto_assets ca ON upper(ca.symbol)=upper(o.base_symbol) AND ca.is_active IS TRUE
      WHERE o.is_active IS TRUE AND o.asset_name IS NOT NULL AND o.id<=100$q$ INTO v_plan;
    INSERT INTO plan_experiment_results VALUES ('dirty_batch_with_upper_index',i,v_plan);
  END LOOP;

  EXECUTE $q$EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
    SELECT o.id, ca.id FROM plan_exchange_observations o
    JOIN plan_crypto_assets ca ON upper(ca.symbol)=upper(o.base_symbol) AND ca.is_active IS TRUE
    WHERE o.is_active IS TRUE AND o.asset_name IS NOT NULL$q$ INTO v_plan;
  FOR i IN 1..5 LOOP
    EXECUTE $q$EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT o.id, ca.id FROM plan_exchange_observations o
      JOIN plan_crypto_assets ca ON upper(ca.symbol)=upper(o.base_symbol) AND ca.is_active IS TRUE
      WHERE o.is_active IS TRUE AND o.asset_name IS NOT NULL$q$ INTO v_plan;
    INSERT INTO plan_experiment_results VALUES ('full_scan_with_upper_index',i,v_plan);
  END LOOP;
END $$;

-- Median/min/max are repeated warm-cache timings, not a Production SLA.
SELECT scenario,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY (plan->0->>'Execution Time')::numeric) AS median_execution_ms,
       min((plan->0->>'Execution Time')::numeric) AS min_execution_ms,
       max((plan->0->>'Execution Time')::numeric) AS max_execution_ms,
       (array_agg(plan ORDER BY iteration))[1]->0->'Plan' AS representative_plan
FROM plan_experiment_results
GROUP BY scenario ORDER BY scenario;

\set ON_ERROR_STOP on

-- PostgreSQL 17 disposable regression fixture for the no-op UPDATE predicates.
-- This tests the guard semantics only; it does not execute the full Production RPC.

CREATE TEMP TABLE observations (
  id integer PRIMARY KEY,
  base_symbol text NOT NULL,
  coingecko_id text,
  match_status text,
  is_active boolean NOT NULL DEFAULT true,
  asset_name text NOT NULL DEFAULT 'fixture'
);
CREATE TEMP TABLE active_assets (symbol text PRIMARY KEY, is_active boolean NOT NULL);
CREATE TEMP TABLE chosen (
  id integer PRIMARY KEY,
  coingecko_id text,
  candidate_count bigint NOT NULL
);
CREATE TEMP TABLE update_audit (observation_id integer NOT NULL);

CREATE FUNCTION pg_temp.audit_observation_update()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO pg_temp.update_audit(observation_id) VALUES (NEW.id);
  RETURN NEW;
END;
$$;
CREATE TRIGGER observations_audit
AFTER UPDATE ON observations
FOR EACH ROW EXECUTE FUNCTION pg_temp.audit_observation_update();

INSERT INTO observations(id,base_symbol,coingecko_id,match_status) VALUES
  (1,'BTC','bitcoin','matched'),
  (2,'AMB',NULL,'ambiguous'),
  (3,'PEND',NULL,'pending'),
  (4,'NONE',NULL,'unmatched'),
  (5,'OLD','old-asset','matched'),
  (6,'NEW',NULL,'pending'),
  (7,'AMB2',NULL,'ambiguous'),
  (8,'MISSING','stale-asset','matched');

INSERT INTO active_assets VALUES ('BTC',true),('AMB',true),('PEND',true),('OLD',true),('NEW',true),('AMB2',true);
INSERT INTO chosen(id,coingecko_id,candidate_count) VALUES
  (1,'bitcoin',1),
  (2,NULL,2),
  (3,NULL,0),
  (5,'new-asset',1),
  (6,'new-asset',1),
  (7,'new-asset',1);

DO $$
DECLARE v_rows integer;
BEGIN
  UPDATE observations o
  SET coingecko_id=c.coingecko_id,
      match_status=CASE WHEN c.candidate_count=1 THEN 'matched'
                        WHEN c.candidate_count>1 THEN 'ambiguous'
                        ELSE 'pending' END
  FROM chosen c
  WHERE o.id=c.id
    AND (
      o.coingecko_id IS DISTINCT FROM c.coingecko_id
      OR o.match_status IS DISTINCT FROM
        CASE WHEN c.candidate_count=1 THEN 'matched'
             WHEN c.candidate_count>1 THEN 'ambiguous'
             ELSE 'pending' END
    );
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 3 THEN
    RAISE EXCEPTION 'expected 3 changed matcher rows, got %', v_rows;
  END IF;

  UPDATE observations o
  SET coingecko_id=NULL, match_status='unmatched'
  WHERE o.id=8
    AND o.is_active IS TRUE
    AND o.asset_name IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM active_assets ca
      WHERE upper(ca.symbol)=upper(o.base_symbol) AND ca.is_active IS TRUE
    )
    AND (o.coingecko_id IS NOT NULL OR o.match_status IS DISTINCT FROM 'unmatched');
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 1 THEN
    RAISE EXCEPTION 'expected 1 unmatched transition, got %', v_rows;
  END IF;

  IF (SELECT count(*) FROM update_audit) <> 4 THEN
    RAISE EXCEPTION 'expected exactly 4 physical updates after first pass';
  END IF;
  IF (SELECT coingecko_id FROM observations WHERE id=5) <> 'new-asset'
     OR (SELECT match_status FROM observations WHERE id=8) <> 'unmatched' THEN
    RAISE EXCEPTION 'changed match/unmatched transitions were not applied';
  END IF;

  -- Re-run the exact same candidate decisions: all four updates must be skipped.
  UPDATE observations o
  SET coingecko_id=c.coingecko_id,
      match_status=CASE WHEN c.candidate_count=1 THEN 'matched'
                        WHEN c.candidate_count>1 THEN 'ambiguous'
                        ELSE 'pending' END
  FROM chosen c
  WHERE o.id=c.id
    AND (
      o.coingecko_id IS DISTINCT FROM c.coingecko_id
      OR o.match_status IS DISTINCT FROM
        CASE WHEN c.candidate_count=1 THEN 'matched'
             WHEN c.candidate_count>1 THEN 'ambiguous'
             ELSE 'pending' END
    );
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN
    RAISE EXCEPTION 'second matcher pass should update 0 rows, got %', v_rows;
  END IF;

  UPDATE observations o
  SET coingecko_id=NULL, match_status='unmatched'
  WHERE o.id=8
    AND o.is_active IS TRUE
    AND o.asset_name IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM active_assets ca
      WHERE upper(ca.symbol)=upper(o.base_symbol) AND ca.is_active IS TRUE
    )
    AND (o.coingecko_id IS NOT NULL OR o.match_status IS DISTINCT FROM 'unmatched');
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN
    RAISE EXCEPTION 'second unmatched pass should update 0 rows, got %', v_rows;
  END IF;

  IF (SELECT count(*) FROM update_audit) <> 4 THEN
    RAISE EXCEPTION 'no-op second pass caused physical UPDATEs';
  END IF;
END;
$$;

SELECT 'no-op update guard fixture passed' AS result;

\set ON_ERROR_STOP on
TRUNCATE private.iran_catalog_reconcile_jobs;
INSERT INTO public.crypto_assets(coingecko_id,symbol,name,is_active) VALUES
 ('bitcoin','BTC','Bitcoin',true),
 ('wrapped-bitcoin','BTC','Wrapped Bitcoin',true),
 ('ethereum','ETH','Ethereum',true),
 ('dogecoin','DOGE','Dogecoin',true),
 ('kishu-inu','KISHU','Kishu Inu',true);
INSERT INTO public.exchange_asset_observations(exchange,market_symbol,base_symbol,asset_name,source_payload,is_active) VALUES
 ('nobitex','BTC','BTC','Bitcoin','{}',true),
 ('wallex','ETHUSDT','ETH','Ethereum','{}',true),
 ('nobitex','DOGE','DOGE','Doge','{}',true),
 ('nobitex','NOPE','NOPE','Unknown Asset','{}',true),
 ('kifpool','KISHU','KISHU','Kishu','{"nameId":"kishu-inu"}',true),
 ('nobitex','INACTIVE','BTC','Bitcoin','{}',false);

-- Generate one synthetic Kifpool observation for every verified alias tuple.
INSERT INTO public.crypto_assets(coingecko_id,symbol,name,is_active)
SELECT a.coingecko_id,
       CASE WHEN a.coingecko_id='kishu-inu' THEN 'KISHU' ELSE 'ALIAS' END,
       a.current_name,true
FROM private.test_verified_kifpool_aliases a
ON CONFLICT(coingecko_id) DO NOTHING;
INSERT INTO public.exchange_asset_observations(exchange,market_symbol,base_symbol,asset_name,source_payload,is_active)
SELECT 'kifpool',
       'ALIAS_'||a.coingecko_id,
       CASE WHEN a.coingecko_id='kishu-inu' THEN 'KISHU' ELSE 'ALIAS' END,
       a.legacy_name,
       jsonb_build_object('nameId',a.coingecko_id),
       true
FROM private.test_verified_kifpool_aliases a;

-- Exercise the separate ARPA source-ID transition.
INSERT INTO public.crypto_assets(coingecko_id,symbol,name,is_active)
VALUES ('arpa','ARPA','arpa',true);
INSERT INTO public.exchange_asset_observations(exchange,market_symbol,base_symbol,asset_name,source_payload,is_active)
VALUES ('kifpool','ARPA_LEGACY','ARPA','arpachain','{"nameId":"arpa-chain"}',true);

-- Full-scan baseline snapshot.
SELECT private.match_iran_exchange_observations(NULL);
CREATE TEMP TABLE expected_initial AS
SELECT id,coingecko_id,match_status FROM public.exchange_asset_observations;
-- Rewind only matcher outputs, then prove the queued incremental pass matches baseline.
UPDATE public.exchange_asset_observations SET coingecko_id=NULL,match_status='pending';
SELECT private.process_iran_match_dirty_batch(1000);
DO $$
BEGIN
 IF EXISTS (
   SELECT 1 FROM expected_initial e JOIN public.exchange_asset_observations o USING(id)
   WHERE e.coingecko_id IS DISTINCT FROM o.coingecko_id
      OR e.match_status IS DISTINCT FROM o.match_status
 ) THEN RAISE EXCEPTION 'Initial incremental result differs from full-scan baseline'; END IF;
 IF (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='BTC') <> 'ambiguous'
 THEN RAISE EXCEPTION 'Ambiguous BTC candidates were not preserved'; END IF;
 IF (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='ETHUSDT') <> 'matched'
 THEN RAISE EXCEPTION 'Exact ETH match failed'; END IF;
 IF (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='DOGE') <> 'pending'
 THEN RAISE EXCEPTION 'Short non-exact Doge name should remain pending'; END IF;
 IF (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='NOPE') <> 'unmatched'
 THEN RAISE EXCEPTION 'No-symbol observation should be unmatched'; END IF;
 IF (SELECT coingecko_id FROM public.exchange_asset_observations WHERE market_symbol='ARPA_LEGACY') <> 'arpa'
 THEN RAISE EXCEPTION 'Kifpool ARPA legacy source-ID transition was not preserved'; END IF;
 IF (SELECT count(*) FROM public.exchange_asset_observations o
     JOIN private.test_verified_kifpool_aliases a
       ON o.market_symbol='ALIAS_'||a.coingecko_id
     WHERE o.match_status='matched' AND o.coingecko_id=a.coingecko_id)
    <> (SELECT count(*) FROM private.test_verified_kifpool_aliases)
 THEN RAISE EXCEPTION 'One or more verified Kifpool aliases failed'; END IF;
 IF (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='INACTIVE') <> 'pending'
 THEN RAISE EXCEPTION 'Inactive observation should not be rewritten'; END IF;
END $$;

-- Heartbeat-only changes must not enqueue work.
TRUNCATE private.iran_exchange_match_dirty;
UPDATE public.exchange_asset_observations SET last_seen_at=now()+interval '1 second'
WHERE market_symbol='ETHUSDT';
DO $$ BEGIN
 IF (SELECT count(*) FROM private.iran_exchange_match_dirty)<>0
 THEN RAISE EXCEPTION 'last_seen_at-only update incorrectly dirtied a row'; END IF;
END $$;

-- A match-input change must enqueue only the affected observation.
UPDATE public.exchange_asset_observations SET asset_name='Ether'
WHERE market_symbol='ETHUSDT';
DO $$ BEGIN
 IF (SELECT count(*) FROM private.iran_exchange_match_dirty)<>1
 THEN RAISE EXCEPTION 'Expected exactly one dirty observation after asset_name change'; END IF;
END $$;

-- Capture the full-scan answer for the changed row, rewind that row, then compare incremental.
SELECT private.match_iran_exchange_observations(NULL);
CREATE TEMP TABLE expected_changed AS
SELECT id,coingecko_id,match_status FROM public.exchange_asset_observations
WHERE market_symbol='ETHUSDT';
UPDATE public.exchange_asset_observations SET coingecko_id=NULL,match_status='pending'
WHERE market_symbol='ETHUSDT';
SELECT private.process_iran_match_dirty_batch(100);
DO $$
BEGIN
 IF EXISTS (
   SELECT 1 FROM expected_changed e JOIN public.exchange_asset_observations o USING(id)
   WHERE e.coingecko_id IS DISTINCT FROM o.coingecko_id
      OR e.match_status IS DISTINCT FROM o.match_status
 ) THEN RAISE EXCEPTION 'Changed-row incremental result differs from full-scan baseline'; END IF;
 IF (SELECT count(*) FROM private.iran_exchange_match_dirty)<>0
 THEN RAISE EXCEPTION 'Dirty queue was not drained'; END IF;
END $$;


-- Two-session claim test: worker A holds row locks while worker B claims
-- the next disjoint batch through an independent PostgreSQL connection.
CREATE EXTENSION IF NOT EXISTS dblink;
INSERT INTO private.iran_exchange_match_dirty(observation_id, queued_at)
SELECT id, clock_timestamp()
FROM public.exchange_asset_observations
ORDER BY id
LIMIT 4
ON CONFLICT (observation_id) DO UPDATE SET queued_at=EXCLUDED.queued_at;

SELECT dblink_connect('matcher_worker_a', 'dbname=' || current_database());
SELECT dblink_connect('matcher_worker_b', 'dbname=' || current_database());
SELECT dblink_exec('matcher_worker_a', 'BEGIN');
SELECT dblink_send_query(
  'matcher_worker_a',
  'SELECT observation_id FROM private.iran_exchange_match_dirty ORDER BY queued_at, observation_id LIMIT 2 FOR UPDATE SKIP LOCKED'
);
-- dblink_get_result waits for the in-flight SELECT to finish while its transaction stays open.
CREATE TEMP TABLE worker_a_claim(observation_id bigint PRIMARY KEY);
INSERT INTO worker_a_claim
SELECT observation_id
FROM dblink_get_result('matcher_worker_a') AS claimed(observation_id bigint);
-- Drain the terminal empty result so the asynchronous dblink command is fully complete.
SELECT * FROM dblink_get_result('matcher_worker_a') AS drained(observation_id bigint);

SELECT dblink_exec('matcher_worker_b', 'BEGIN');
SELECT dblink_send_query(
  'matcher_worker_b',
  'SELECT observation_id FROM private.iran_exchange_match_dirty ORDER BY queued_at, observation_id LIMIT 2 FOR UPDATE SKIP LOCKED'
);
-- The second result is fetched while worker A still holds its row locks.
CREATE TEMP TABLE worker_b_claim(observation_id bigint PRIMARY KEY);
INSERT INTO worker_b_claim
SELECT observation_id
FROM dblink_get_result('matcher_worker_b') AS claimed(observation_id bigint);
SELECT * FROM dblink_get_result('matcher_worker_b') AS drained(observation_id bigint);

CREATE TEMP TABLE concurrency_assertions(ok boolean CHECK (ok));
INSERT INTO concurrency_assertions
SELECT
  (SELECT count(*) FROM worker_a_claim) = 2
  AND (SELECT count(*) FROM worker_b_claim) = 2
  AND NOT EXISTS (
    SELECT 1 FROM worker_a_claim a
    JOIN worker_b_claim b USING (observation_id)
  )
  AND (SELECT count(*) FROM (
      SELECT observation_id FROM worker_a_claim
      UNION
      SELECT observation_id FROM worker_b_claim
    ) claimed) = 4;

SELECT dblink_exec('matcher_worker_a', 'ROLLBACK');
SELECT dblink_exec('matcher_worker_b', 'ROLLBACK');
SELECT dblink_disconnect('matcher_worker_a');
SELECT dblink_disconnect('matcher_worker_b');
DELETE FROM private.iran_exchange_match_dirty
WHERE observation_id IN (
  SELECT observation_id FROM worker_a_claim
  UNION
  SELECT observation_id FROM worker_b_claim
);

SELECT 'Two-session SKIP LOCKED test passed' AS result;


SELECT 'Iran exchange matcher fixture tests passed' AS result;


-- Catalog reconciliation: a newly listed asset must rematch a prior unmatched row.
INSERT INTO public.exchange_asset_observations(exchange,market_symbol,base_symbol,asset_name,source_payload,is_active)
VALUES ('wallex','NEW_XRP','XRP','Ripple','{}',true);
SELECT private.match_iran_exchange_observations(NULL);
DO $$ BEGIN
  IF (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='NEW_XRP') <> 'unmatched'
  THEN RAISE EXCEPTION 'New-asset fixture row should start unmatched'; END IF;
END $$;

INSERT INTO public.crypto_assets(coingecko_id,symbol,name,is_active)
VALUES ('ripple','XRP','Ripple',true);
DO $$
BEGIN
  WHILE EXISTS (SELECT 1 FROM private.iran_catalog_reconcile_jobs WHERE completed_at IS NULL) LOOP
    PERFORM private.process_iran_catalog_reconcile_batch(2);
  END LOOP;
END $$;
SELECT private.process_iran_match_dirty_batch(1000);
DO $$ BEGIN
  IF (SELECT coingecko_id FROM public.exchange_asset_observations WHERE market_symbol='NEW_XRP') <> 'ripple'
  THEN RAISE EXCEPTION 'Catalog insert did not rematch the previously unmatched observation'; END IF;
END $$;

-- A symbol rename must revisit the old symbol and clear a now-stale match.
UPDATE public.crypto_assets SET symbol='XLM' WHERE coingecko_id='ripple';
DO $$
BEGIN
  WHILE EXISTS (SELECT 1 FROM private.iran_catalog_reconcile_jobs WHERE completed_at IS NULL) LOOP
    PERFORM private.process_iran_catalog_reconcile_batch(2);
  END LOOP;
END $$;
SELECT private.process_iran_match_dirty_batch(1000);
DO $$ BEGIN
  IF (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='NEW_XRP') <> 'unmatched'
     OR (SELECT coingecko_id FROM public.exchange_asset_observations WHERE market_symbol='NEW_XRP') IS NOT NULL
  THEN RAISE EXCEPTION 'Catalog symbol rename did not clear the stale match'; END IF;
END $$;

-- Deactivation must also invalidate an existing match through the old asset ID.
INSERT INTO public.exchange_asset_observations(exchange,market_symbol,base_symbol,asset_name,source_payload,is_active)
VALUES ('wallex','NEW_YYY','YYY','Ypsilon Coin','{}',true);
INSERT INTO public.crypto_assets(coingecko_id,symbol,name,is_active)
VALUES ('ypsilon-coin','YYY','Ypsilon Coin',true);
DO $$
BEGIN
  WHILE EXISTS (SELECT 1 FROM private.iran_catalog_reconcile_jobs WHERE completed_at IS NULL) LOOP
    PERFORM private.process_iran_catalog_reconcile_batch(2);
  END LOOP;
END $$;
SELECT private.process_iran_match_dirty_batch(1000);
DO $$ BEGIN
  IF (SELECT coingecko_id FROM public.exchange_asset_observations WHERE market_symbol='NEW_YYY') <> 'ypsilon-coin'
  THEN RAISE EXCEPTION 'Ypsilon setup match failed'; END IF;
END $$;
UPDATE public.crypto_assets SET is_active=false WHERE coingecko_id='ypsilon-coin';
DO $$
BEGIN
  WHILE EXISTS (SELECT 1 FROM private.iran_catalog_reconcile_jobs WHERE completed_at IS NULL) LOOP
    PERFORM private.process_iran_catalog_reconcile_batch(2);
  END LOOP;
END $$;
SELECT private.process_iran_match_dirty_batch(1000);
DO $$ BEGIN
  IF (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='NEW_YYY') <> 'unmatched'
     OR (SELECT coingecko_id FROM public.exchange_asset_observations WHERE market_symbol='NEW_YYY') IS NOT NULL
  THEN RAISE EXCEPTION 'Catalog deactivation did not invalidate the stale match'; END IF;
END $$;

-- More observations than one scan page: the persisted cursor must advance
-- over successive bounded calls until all three affected observations are queued.
INSERT INTO public.exchange_asset_observations(exchange,market_symbol,base_symbol,asset_name,source_payload,is_active) VALUES
 ('wallex','BATCH_1','BATCH','Batch Coin','{}',true),
 ('wallex','BATCH_2','BATCH','Batch Coin','{}',true),
 ('wallex','BATCH_3','BATCH','Batch Coin','{}',true);
INSERT INTO public.crypto_assets(coingecko_id,symbol,name,is_active)
VALUES ('batch-coin','BATCH','Batch Coin',true);
DO $$
DECLARE v_job bigint; v_first_cursor bigint; v_calls integer:=0;
BEGIN
  SELECT max(id) INTO v_job FROM private.iran_catalog_reconcile_jobs WHERE asset_id='batch-coin';
  PERFORM private.process_iran_catalog_reconcile_batch(2);
  SELECT cursor_id INTO v_first_cursor FROM private.iran_catalog_reconcile_jobs WHERE id=v_job;
  IF v_first_cursor<=0 OR (SELECT completed_at FROM private.iran_catalog_reconcile_jobs WHERE id=v_job) IS NOT NULL
  THEN RAISE EXCEPTION 'Catalog reconciliation cursor did not retain a partial page'; END IF;
  WHILE EXISTS (SELECT 1 FROM private.iran_catalog_reconcile_jobs WHERE id=v_job AND completed_at IS NULL) LOOP
    PERFORM private.process_iran_catalog_reconcile_batch(2);
    v_calls:=v_calls+1;
    IF v_calls>100 THEN RAISE EXCEPTION 'Catalog reconciliation cursor failed to converge'; END IF;
  END LOOP;
END $$;
SELECT private.process_iran_match_dirty_batch(1000);
DO $$ BEGIN
  IF (SELECT count(*) FROM public.exchange_asset_observations
      WHERE market_symbol IN ('BATCH_1','BATCH_2','BATCH_3')
        AND coingecko_id='batch-coin' AND match_status='matched')<>3
  THEN RAISE EXCEPTION 'Bounded catalog reconciliation did not process all pages'; END IF;
END $$;

SELECT 'Catalog-change reconciliation fixture tests passed' AS result;


-- Adding a verified legacy alias must reconsider only the matching Kifpool source/name.
INSERT INTO public.exchange_asset_observations(exchange,market_symbol,base_symbol,asset_name,source_payload,is_active)
VALUES ('kifpool','ALIAS_ADEX_NEW','ALIAS','adex-new','{"nameId":"adex"}',true);
SELECT private.match_iran_exchange_observations(NULL);
DO $$ BEGIN
  IF (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='ALIAS_ADEX_NEW')='matched'
  THEN RAISE EXCEPTION 'Unregistered Kifpool alias unexpectedly matched'; END IF;
END $$;
INSERT INTO private.test_verified_kifpool_aliases(coingecko_id,legacy_name,current_name)
VALUES ('adex','adex-new','heyaura');
DO $$
BEGIN
  WHILE EXISTS (SELECT 1 FROM private.iran_catalog_reconcile_jobs WHERE completed_at IS NULL) LOOP
    PERFORM private.process_iran_catalog_reconcile_batch(2);
  END LOOP;
END $$;
SELECT private.process_iran_match_dirty_batch(1000);
DO $$ BEGIN
  IF (SELECT coingecko_id FROM public.exchange_asset_observations WHERE market_symbol='ALIAS_ADEX_NEW') <> 'adex'
  THEN RAISE EXCEPTION 'Kifpool alias insertion did not rematch its observation'; END IF;
END $$;

SELECT 'Kifpool alias-change reconciliation fixture tests passed' AS result;


-- Removing a verified alias must not leave the old Kifpool match stale.
DELETE FROM private.test_verified_kifpool_aliases
WHERE coingecko_id='adex' AND legacy_name='adex-new' AND current_name='heyaura';
DO $$
BEGIN
  WHILE EXISTS (SELECT 1 FROM private.iran_catalog_reconcile_jobs WHERE completed_at IS NULL) LOOP
    PERFORM private.process_iran_catalog_reconcile_batch(2);
  END LOOP;
END $$;
SELECT private.process_iran_match_dirty_batch(1000);
DO $$ BEGIN
  IF (SELECT coingecko_id FROM public.exchange_asset_observations WHERE market_symbol='ALIAS_ADEX_NEW') IS NOT NULL
     OR (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='ALIAS_ADEX_NEW') <> 'pending'
  THEN RAISE EXCEPTION 'Removing Kifpool alias left a stale match'; END IF;
END $$;

SELECT 'Kifpool alias-removal stale-match test passed' AS result;

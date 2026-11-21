\set ON_ERROR_STOP on

-- Focused catalog-reconciliation queue tests only.
-- Existing matcher correctness, multipage convergence, alias transitions,
-- response-queue lease/retry, and response-worker concurrency tests run elsewhere.
-- This file adds rollback/restart recovery, interleaved catalog events, and
-- simultaneous catalog workers using two independent PostgreSQL sessions.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM private.iran_catalog_reconcile_jobs WHERE completed_at IS NULL) THEN
    RAISE EXCEPTION 'catalog queue must be drained before focused concurrency tests';
  END IF;
END $$;

-- 1) Worker crash before commit: cursor and dirty enqueue must roll back together.
INSERT INTO public.exchange_asset_observations
  (exchange,market_symbol,base_symbol,asset_name,source_payload,is_active)
VALUES
 ('wallex','RECOVERY_1','RCV','Recovery Coin','{}',true),
 ('wallex','RECOVERY_2','RCV','Recovery Coin','{}',true),
 ('wallex','RECOVERY_3','RCV','Recovery Coin','{}',true),
 ('wallex','RECOVERY_4','RCV','Recovery Coin','{}',true);
INSERT INTO public.crypto_assets(coingecko_id,symbol,name,is_active)
VALUES ('recovery-asset','RCV','Recovery Coin',true);

DELETE FROM private.iran_exchange_match_dirty d
USING public.exchange_asset_observations o
WHERE d.observation_id=o.id AND o.market_symbol LIKE 'RECOVERY_%';
UPDATE private.iran_catalog_reconcile_jobs
SET cursor_id=(SELECT min(id)-1 FROM public.exchange_asset_observations
               WHERE market_symbol LIKE 'RECOVERY_%')
WHERE asset_id='recovery-asset' AND completed_at IS NULL;

BEGIN;
SELECT private.process_iran_catalog_reconcile_batch(2);
DO $$
BEGIN
  IF (SELECT cursor_id FROM private.iran_catalog_reconcile_jobs
      WHERE asset_id='recovery-asset') <=
     (SELECT min(id)-1 FROM public.exchange_asset_observations
      WHERE market_symbol LIKE 'RECOVERY_%') THEN
    RAISE EXCEPTION 'worker did not advance the recovery cursor inside transaction';
  END IF;
  IF (SELECT count(*) FROM private.iran_exchange_match_dirty d
      JOIN public.exchange_asset_observations o ON o.id=d.observation_id
      WHERE o.market_symbol LIKE 'RECOVERY_%') <> 2 THEN
    RAISE EXCEPTION 'first recovery page did not enqueue exactly two rows';
  END IF;
END $$;
ROLLBACK;

DO $$
BEGIN
  IF (SELECT cursor_id FROM private.iran_catalog_reconcile_jobs
      WHERE asset_id='recovery-asset') <>
     (SELECT min(id)-1 FROM public.exchange_asset_observations
      WHERE market_symbol LIKE 'RECOVERY_%') THEN
    RAISE EXCEPTION 'rolled-back worker left cursor progress behind';
  END IF;
  IF EXISTS (SELECT 1 FROM private.iran_exchange_match_dirty d
             JOIN public.exchange_asset_observations o ON o.id=d.observation_id
             WHERE o.market_symbol LIKE 'RECOVERY_%') THEN
    RAISE EXCEPTION 'rolled-back worker left dirty rows behind';
  END IF;
END $$;

-- Restarted worker resumes from the durable cursor, commits each page, and completes.
SELECT private.process_iran_catalog_reconcile_batch(2);
DO $$
BEGIN
  IF (SELECT cursor_id FROM private.iran_catalog_reconcile_jobs
      WHERE asset_id='recovery-asset') <>
     (SELECT max(id) FROM (
        SELECT id FROM public.exchange_asset_observations
        WHERE market_symbol LIKE 'RECOVERY_%' ORDER BY id LIMIT 2
      ) first_committed_page) THEN
    RAISE EXCEPTION 'restarted worker did not resume at the first committed page';
  END IF;
END $$;
SELECT private.process_iran_catalog_reconcile_batch(2);
SELECT private.process_iran_catalog_reconcile_batch(2);
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM private.iran_catalog_reconcile_jobs
                 WHERE asset_id='recovery-asset' AND completed_at IS NOT NULL) THEN
    RAISE EXCEPTION 'restarted worker did not finish the persisted cursor';
  END IF;
  IF (SELECT count(*) FROM private.iran_exchange_match_dirty d
      JOIN public.exchange_asset_observations o ON o.id=d.observation_id
      WHERE o.market_symbol LIKE 'RECOVERY_%') <> 4 THEN
    RAISE EXCEPTION 'recovery pages did not durably enqueue all observations';
  END IF;
END $$;
SELECT private.process_iran_match_dirty_batch(1000);
DO $$
BEGIN
  IF (SELECT count(*) FROM public.exchange_asset_observations
      WHERE market_symbol LIKE 'RECOVERY_%'
        AND coingecko_id='recovery-asset' AND match_status='matched') <> 4 THEN
    RAISE EXCEPTION 'recovered catalog job did not result in all four matches';
  END IF;
END $$;

-- 2) A second catalog event arrives while the first event has a partial cursor.
INSERT INTO public.exchange_asset_observations
  (exchange,market_symbol,base_symbol,asset_name,source_payload,is_active)
VALUES
 ('wallex','INTERLEAVE_A_1','ILA','Interleave Alpha','{}',true),
 ('wallex','INTERLEAVE_A_2','ILA','Interleave Alpha','{}',true),
 ('wallex','INTERLEAVE_A_3','ILA','Interleave Alpha','{}',true);
INSERT INTO public.crypto_assets(coingecko_id,symbol,name,is_active)
VALUES ('interleave-alpha','ILA','Interleave Alpha',true);
UPDATE private.iran_catalog_reconcile_jobs
SET cursor_id=(SELECT min(id)-1 FROM public.exchange_asset_observations
               WHERE market_symbol LIKE 'INTERLEAVE_A_%')
WHERE asset_id='interleave-alpha' AND completed_at IS NULL;

SELECT private.process_iran_catalog_reconcile_batch(1);

INSERT INTO public.exchange_asset_observations
  (exchange,market_symbol,base_symbol,asset_name,source_payload,is_active)
VALUES
 ('wallex','INTERLEAVE_B_1','ILB','Interleave Beta','{}',true),
 ('wallex','INTERLEAVE_B_2','ILB','Interleave Beta','{}',true);
INSERT INTO public.crypto_assets(coingecko_id,symbol,name,is_active)
VALUES ('interleave-beta','ILB','Interleave Beta',true);

DO $$
BEGIN
  IF (SELECT cursor_id FROM private.iran_catalog_reconcile_jobs
      WHERE asset_id='interleave-alpha') <>
     (SELECT min(id) FROM public.exchange_asset_observations
      WHERE market_symbol LIKE 'INTERLEAVE_A_%') THEN
    RAISE EXCEPTION 'new catalog event reset or altered the older event cursor';
  END IF;
  IF (SELECT cursor_id FROM private.iran_catalog_reconcile_jobs
      WHERE asset_id='interleave-beta') <> 0 THEN
    RAISE EXCEPTION 'new catalog event did not start with an independent cursor';
  END IF;
END $$;

DO $$
DECLARE v_calls integer:=0;
BEGIN
  WHILE EXISTS (SELECT 1 FROM private.iran_catalog_reconcile_jobs
                WHERE asset_id='interleave-alpha' AND completed_at IS NULL) LOOP
    PERFORM private.process_iran_catalog_reconcile_batch(1);
    v_calls:=v_calls+1;
    IF v_calls>100 THEN RAISE EXCEPTION 'older interleaved event failed to converge'; END IF;
  END LOOP;
  v_calls:=0;
  WHILE EXISTS (SELECT 1 FROM private.iran_catalog_reconcile_jobs
                WHERE asset_id='interleave-beta' AND completed_at IS NULL) LOOP
    PERFORM private.process_iran_catalog_reconcile_batch(1);
    v_calls:=v_calls+1;
    IF v_calls>100 THEN RAISE EXCEPTION 'newer interleaved event failed to converge'; END IF;
  END LOOP;
END $$;
SELECT private.process_iran_match_dirty_batch(1000);
DO $$
BEGIN
  IF (SELECT count(*) FROM public.exchange_asset_observations
      WHERE market_symbol LIKE 'INTERLEAVE_A_%'
        AND coingecko_id='interleave-alpha' AND match_status='matched') <> 3 THEN
    RAISE EXCEPTION 'older event lost progress after a newer event arrived';
  END IF;
  IF (SELECT count(*) FROM public.exchange_asset_observations
      WHERE market_symbol LIKE 'INTERLEAVE_B_%'
        AND coingecko_id='interleave-beta' AND match_status='matched') <> 2 THEN
    RAISE EXCEPTION 'newer event was starved by the older event';
  END IF;
END $$;

-- 3) Two real PostgreSQL sessions concurrently process different catalog jobs.
-- Worker A deliberately holds its transaction/row lock while worker B runs.
INSERT INTO public.exchange_asset_observations
  (exchange,market_symbol,base_symbol,asset_name,source_payload,is_active)
VALUES
 ('wallex','CONCURRENT_A_1','CNA','Concurrent Alpha','{}',true),
 ('wallex','CONCURRENT_A_2','CNA','Concurrent Alpha','{}',true);
INSERT INTO public.crypto_assets(coingecko_id,symbol,name,is_active)
VALUES ('concurrent-alpha','CNA','Concurrent Alpha',true);
UPDATE private.iran_catalog_reconcile_jobs
SET cursor_id=(SELECT min(id)-1 FROM public.exchange_asset_observations
               WHERE market_symbol LIKE 'CONCURRENT_A_%')
WHERE asset_id='concurrent-alpha' AND completed_at IS NULL;

INSERT INTO public.exchange_asset_observations
  (exchange,market_symbol,base_symbol,asset_name,source_payload,is_active)
VALUES
 ('wallex','CONCURRENT_B_1','CNB','Concurrent Beta','{}',true),
 ('wallex','CONCURRENT_B_2','CNB','Concurrent Beta','{}',true);
INSERT INTO public.crypto_assets(coingecko_id,symbol,name,is_active)
VALUES ('concurrent-beta','CNB','Concurrent Beta',true);
UPDATE private.iran_catalog_reconcile_jobs
SET cursor_id=(SELECT min(id)-1 FROM public.exchange_asset_observations
               WHERE market_symbol LIKE 'CONCURRENT_B_%')
WHERE asset_id='concurrent-beta' AND completed_at IS NULL;

CREATE EXTENSION IF NOT EXISTS dblink;
SELECT dblink_connect('catalog_worker_a',
 'host=localhost port=5432 dbname=digiarz_matcher_test user=postgres password=postgres');
SELECT dblink_connect('catalog_worker_b',
 'host=localhost port=5432 dbname=digiarz_matcher_test user=postgres password=postgres');
SELECT dblink_exec('catalog_worker_a','BEGIN');
CREATE TEMP TABLE catalog_worker_results(worker text, processed_rows integer);
INSERT INTO catalog_worker_results
SELECT 'A',processed_rows
FROM dblink('catalog_worker_a',
 'SELECT private.process_iran_catalog_reconcile_batch(1)')
 AS t(processed_rows integer);

SELECT dblink_exec('catalog_worker_b','BEGIN');
INSERT INTO catalog_worker_results
SELECT 'B',processed_rows
FROM dblink('catalog_worker_b',
 'SELECT private.process_iran_catalog_reconcile_batch(1)')
 AS t(processed_rows integer);

-- Commit B while A still owns the oldest job lock. B must have skipped A.
SELECT dblink_exec('catalog_worker_b','COMMIT');
DO $$
BEGIN
  IF (SELECT cursor_id FROM private.iran_catalog_reconcile_jobs
      WHERE asset_id='concurrent-alpha') <>
     (SELECT min(id)-1 FROM public.exchange_asset_observations
      WHERE market_symbol LIKE 'CONCURRENT_A_%') THEN
    RAISE EXCEPTION 'worker B modified worker A locked job';
  END IF;
  IF (SELECT cursor_id FROM private.iran_catalog_reconcile_jobs
      WHERE asset_id='concurrent-beta') <>
     (SELECT min(id) FROM public.exchange_asset_observations
      WHERE market_symbol LIKE 'CONCURRENT_B_%') THEN
    RAISE EXCEPTION 'worker B did not skip the locked oldest job and claim the next job';
  END IF;
  IF (SELECT count(*) FROM catalog_worker_results WHERE worker='A' AND processed_rows=1) <> 1
     OR (SELECT count(*) FROM catalog_worker_results WHERE worker='B' AND processed_rows=1) <> 1 THEN
    RAISE EXCEPTION 'both concurrent workers did not process exactly one page';
  END IF;
END $$;

-- Release A, then verify the previously locked oldest event resumes and is not starved.
SELECT dblink_exec('catalog_worker_a','COMMIT');
SELECT dblink_disconnect('catalog_worker_a');
SELECT dblink_disconnect('catalog_worker_b');

DO $$
DECLARE v_calls integer:=0;
BEGIN
  WHILE EXISTS (SELECT 1 FROM private.iran_catalog_reconcile_jobs
                WHERE asset_id IN ('concurrent-alpha','concurrent-beta')
                  AND completed_at IS NULL) LOOP
    PERFORM private.process_iran_catalog_reconcile_batch(1);
    v_calls:=v_calls+1;
    IF v_calls>100 THEN RAISE EXCEPTION 'concurrent catalog jobs did not eventually converge'; END IF;
  END LOOP;
END $$;
SELECT private.process_iran_match_dirty_batch(1000);

DO $$
BEGIN
  IF (SELECT count(*) FROM public.exchange_asset_observations
      WHERE market_symbol LIKE 'CONCURRENT_A_%'
        AND coingecko_id='concurrent-alpha' AND match_status='matched') <> 2 THEN
    RAISE EXCEPTION 'oldest concurrently locked job did not resume after worker A committed';
  END IF;
  IF (SELECT count(*) FROM public.exchange_asset_observations
      WHERE market_symbol LIKE 'CONCURRENT_B_%'
        AND coingecko_id='concurrent-beta' AND match_status='matched') <> 2 THEN
    RAISE EXCEPTION 'second concurrent job did not complete';
  END IF;
  IF EXISTS (SELECT 1 FROM private.iran_catalog_reconcile_jobs
             WHERE asset_id IN ('concurrent-alpha','concurrent-beta')
               AND completed_at IS NULL) THEN
    RAISE EXCEPTION 'concurrent jobs left unfinished queue rows';
  END IF;
END $$;

SELECT 'Catalog queue recovery, interleaving, and concurrent-worker tests passed' AS result;

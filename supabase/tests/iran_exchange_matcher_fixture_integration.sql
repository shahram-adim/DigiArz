\set ON_ERROR_STOP on
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

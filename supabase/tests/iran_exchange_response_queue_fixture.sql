-- Disposable PostgreSQL 17 fixture only. No Production schema assumptions.
\set ON_ERROR_STOP on
CREATE EXTENSION IF NOT EXISTS dblink;
CREATE SCHEMA IF NOT EXISTS private;

CREATE TABLE public.test_http_responses (
  id bigint PRIMARY KEY,
  status_code integer,
  content text,
  error_msg text,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE TABLE public.test_sync_requests (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  response_id bigint NOT NULL UNIQUE REFERENCES public.test_http_responses(id),
  processed_at timestamptz,
  claim_token uuid,
  lease_until timestamptz,
  attempts integer NOT NULL DEFAULT 0,
  last_error text,
  dead_lettered_at timestamptz
);
CREATE TABLE public.test_ingested_responses (
  response_id bigint PRIMARY KEY REFERENCES public.test_http_responses(id),
  body jsonb NOT NULL,
  ingested_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE OR REPLACE FUNCTION private.claim_test_sync_requests(
  p_limit integer,
  p_lease interval,
  p_token uuid
) RETURNS TABLE(request_id bigint, response_id bigint, claim_token uuid, lease_until timestamptz)
LANGUAGE plpgsql AS $$
BEGIN
  IF p_limit < 1 OR p_limit > 100 OR p_lease <= interval '0 seconds' THEN
    RAISE EXCEPTION 'invalid claim bounds';
  END IF;
  RETURN QUERY
  WITH picked AS (
    SELECT q.id
    FROM public.test_sync_requests q
    WHERE q.processed_at IS NULL
      AND q.dead_lettered_at IS NULL
      AND (q.claim_token IS NULL OR q.lease_until < clock_timestamp())
    ORDER BY q.id
    FOR UPDATE SKIP LOCKED
    LIMIT p_limit
  )
  UPDATE public.test_sync_requests q
  SET claim_token = p_token,
      lease_until = clock_timestamp() + p_lease,
      attempts = q.attempts + 1
  FROM picked p
  WHERE q.id = p.id
  RETURNING q.id, q.response_id, q.claim_token, q.lease_until;
END $$;

CREATE OR REPLACE FUNCTION private.ingest_and_ack_test_batch(p_token uuid)
RETURNS integer LANGUAGE plpgsql AS $$
DECLARE v_count integer;
BEGIN
  INSERT INTO public.test_ingested_responses(response_id, body)
  SELECT q.response_id, r.content::jsonb
  FROM public.test_sync_requests q
  JOIN public.test_http_responses r ON r.id = q.response_id
  WHERE q.claim_token = p_token
    AND q.processed_at IS NULL
    AND q.lease_until >= clock_timestamp()
    AND r.status_code = 200
    AND r.content IS NOT NULL
    AND private.test_is_json(r.content)
  ON CONFLICT(response_id) DO NOTHING;

  UPDATE public.test_sync_requests q
  SET processed_at = clock_timestamp(),
      last_error = CASE
        WHEN r.status_code <> 200 THEN coalesce(r.error_msg, 'HTTP response was not successful')
        WHEN r.content IS NULL THEN 'Empty response body; skipped'
        WHEN NOT private.test_is_json(r.content) THEN 'Invalid JSON; skipped terminally'
        ELSE NULL
      END,
      claim_token = NULL,
      lease_until = NULL
  FROM public.test_http_responses r
  WHERE r.id = q.response_id
    AND q.claim_token = p_token
    AND q.processed_at IS NULL
    AND q.lease_until >= clock_timestamp();
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END $$;

CREATE OR REPLACE FUNCTION private.release_test_sync_claim(
  p_token uuid,
  p_error text,
  p_max_attempts integer DEFAULT 3
) RETURNS integer LANGUAGE plpgsql AS $$
DECLARE v_count integer;
BEGIN
  IF p_max_attempts < 1 OR p_error IS NULL OR length(trim(p_error)) = 0 THEN
    RAISE EXCEPTION 'invalid retry policy';
  END IF;
  UPDATE public.test_sync_requests q
  SET dead_lettered_at = CASE WHEN q.attempts >= p_max_attempts
                              THEN clock_timestamp() ELSE NULL END,
      last_error = CASE WHEN q.attempts >= p_max_attempts
                        THEN 'Dead-lettered after ' || q.attempts || ' attempts: ' || p_error
                        ELSE p_error END,
      claim_token = NULL,
      lease_until = NULL
  WHERE q.claim_token = p_token
    AND q.processed_at IS NULL
    AND q.dead_lettered_at IS NULL
    AND q.lease_until >= clock_timestamp();
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END $$;

CREATE OR REPLACE FUNCTION private.test_is_json(p_text text)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
  PERFORM p_text::jsonb;
  RETURN true;
EXCEPTION WHEN others THEN
  RETURN false;
END $$;

INSERT INTO public.test_http_responses(id,status_code,content,error_msg) VALUES
 (1001,200,'{"assets":[{"symbol":"BTC"}]}',NULL),
 (1002,200,'{"assets":[{"symbol":"ETH"}]}',NULL),
 (1003,200,'not-json',NULL),
 (1004,503,NULL,'upstream unavailable'),
 (1005,200,'{"assets":[{"symbol":"DOGE"}]}',NULL);
INSERT INTO public.test_sync_requests(response_id)
SELECT id FROM public.test_http_responses ORDER BY id;

BEGIN;
SELECT count(*) AS claimed FROM private.claim_test_sync_requests(2, interval '5 minutes',
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
ROLLBACK;
DO $$
BEGIN
 IF EXISTS (SELECT 1 FROM public.test_sync_requests WHERE claim_token IS NOT NULL) THEN
   RAISE EXCEPTION 'rolled-back claim left a lease behind';
 END IF;
END $$;

SELECT * FROM private.claim_test_sync_requests(2, interval '5 minutes',
 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
UPDATE public.test_sync_requests
SET lease_until = clock_timestamp() - interval '1 second'
WHERE claim_token='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
  AND processed_at IS NULL;

SELECT * FROM private.claim_test_sync_requests(2, interval '5 minutes',
 'cccccccc-cccc-4ccc-8ccc-cccccccccccc');
DO $$
BEGIN
 IF private.ingest_and_ack_test_batch('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb') <> 0 THEN
   RAISE EXCEPTION 'expired worker unexpectedly acknowledged reclaimed rows';
 END IF;
END $$;
SELECT private.ingest_and_ack_test_batch('cccccccc-cccc-4ccc-8ccc-cccccccccccc');

SELECT * FROM private.claim_test_sync_requests(2, interval '5 minutes',
 'abababab-abab-4aba-8aba-abababababab');
SELECT private.ingest_and_ack_test_batch('abababab-abab-4aba-8aba-abababababab');

INSERT INTO public.test_http_responses(id,status_code,content) VALUES
 (1006,200,'{"assets":[{"symbol":"ADA"}]}');
INSERT INTO public.test_sync_requests(response_id) VALUES (1006);
SELECT * FROM private.claim_test_sync_requests(10, interval '5 minutes',
 'dddddddd-dddd-4ddd-8ddd-dddddddddddd');
SELECT private.ingest_and_ack_test_batch('dddddddd-dddd-4ddd-8ddd-dddddddddddd');

DO $$
BEGIN
 IF EXISTS (SELECT 1 FROM public.test_sync_requests
            WHERE processed_at IS NULL AND dead_lettered_at IS NULL) THEN
   RAISE EXCEPTION 'fixture left requests neither processed nor dead-lettered';
 END IF;
 IF (SELECT count(*) FROM public.test_ingested_responses) <> 4 THEN
   RAISE EXCEPTION 'expected four valid JSON responses ingested exactly once';
 END IF;
 IF (SELECT last_error FROM public.test_sync_requests q JOIN public.test_http_responses r
     ON r.id=q.response_id WHERE r.id=1003) <> 'Invalid JSON; skipped terminally' THEN
   RAISE EXCEPTION 'invalid JSON policy was not recorded';
 END IF;
 IF (SELECT count(*) FROM public.test_ingested_responses WHERE response_id=1001) <> 1 THEN
   RAISE EXCEPTION 'idempotent ingestion failed';
 END IF;
END $$;

-- Transient worker failures are retried, then dead-lettered at the attempt cap.
INSERT INTO public.test_http_responses(id,status_code,content)
VALUES (1007,200,'{"assets":[{"symbol":"SOL"}]}');
INSERT INTO public.test_sync_requests(response_id) VALUES (1007);
SELECT * FROM private.claim_test_sync_requests(1, interval '5 minutes',
 '11111111-1111-4111-8111-111111111111');
DO $$
BEGIN
 IF private.release_test_sync_claim('11111111-1111-4111-8111-111111111111',
      'simulated transient worker failure',3) <> 1 THEN
   RAISE EXCEPTION 'first transient failure was not released for retry';
 END IF;
END $$;
SELECT * FROM private.claim_test_sync_requests(1, interval '5 minutes',
 '22222222-2222-4222-8222-222222222222');
DO $$
BEGIN
 IF private.release_test_sync_claim('22222222-2222-4222-8222-222222222222',
      'simulated transient worker failure',3) <> 1 THEN
   RAISE EXCEPTION 'second transient failure was not released for retry';
 END IF;
END $$;
SELECT * FROM private.claim_test_sync_requests(1, interval '5 minutes',
 '33333333-3333-4333-8333-333333333333');
DO $$
BEGIN
 IF private.release_test_sync_claim('33333333-3333-4333-8333-333333333333',
      'simulated transient worker failure',3) <> 1 THEN
   RAISE EXCEPTION 'third transient failure was not dead-lettered';
 END IF;
 IF NOT EXISTS (SELECT 1 FROM public.test_sync_requests
                WHERE response_id=1007 AND attempts=3
                  AND dead_lettered_at IS NOT NULL
                  AND last_error LIKE 'Dead-lettered after 3 attempts:%') THEN
   RAISE EXCEPTION 'dead-letter metadata missing at attempt cap';
 END IF;
 IF EXISTS (SELECT 1 FROM private.claim_test_sync_requests(1, interval '5 minutes',
      '44444444-4444-4444-8444-444444444444')) THEN
   RAISE EXCEPTION 'dead-lettered request was claimed again';
 END IF;
END $$;

TRUNCATE public.test_ingested_responses, public.test_sync_requests, public.test_http_responses RESTART IDENTITY CASCADE;
INSERT INTO public.test_http_responses(id,status_code,content)
SELECT 2000 + n, 200, '{"n":'||n||'}' FROM generate_series(1,4) n;
INSERT INTO public.test_sync_requests(response_id)
SELECT id FROM public.test_http_responses ORDER BY id;

CREATE TEMP TABLE worker_a_claims(response_id bigint);
CREATE TEMP TABLE worker_b_claims(response_id bigint);
SELECT dblink_connect('queue_worker_a',
 'host=localhost port=5432 dbname=digiarz_matcher_test user=postgres password=postgres');
SELECT dblink_connect('queue_worker_b',
 'host=localhost port=5432 dbname=digiarz_matcher_test user=postgres password=postgres');
SELECT dblink_exec('queue_worker_a','BEGIN');
SELECT dblink_exec('queue_worker_b','BEGIN');
INSERT INTO worker_a_claims
SELECT response_id FROM dblink('queue_worker_a', $q$
 WITH picked AS (
   SELECT id FROM public.test_sync_requests WHERE processed_at IS NULL
   ORDER BY id FOR UPDATE SKIP LOCKED LIMIT 2
 )
 UPDATE public.test_sync_requests q
 SET claim_token='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
     lease_until=clock_timestamp()+interval '5 minutes', attempts=attempts+1
 FROM picked p WHERE q.id=p.id
 RETURNING q.response_id
$q$) AS t(response_id bigint);
INSERT INTO worker_b_claims
SELECT response_id FROM dblink('queue_worker_b', $q$
 WITH picked AS (
   SELECT id FROM public.test_sync_requests WHERE processed_at IS NULL
     AND claim_token IS NULL
   ORDER BY id FOR UPDATE SKIP LOCKED LIMIT 2
 )
 UPDATE public.test_sync_requests q
 SET claim_token='ffffffff-ffff-4fff-8fff-ffffffffffff',
     lease_until=clock_timestamp()+interval '5 minutes', attempts=attempts+1
 FROM picked p WHERE q.id=p.id
 RETURNING q.response_id
$q$) AS t(response_id bigint);
DO $$
DECLARE a bigint[]; b bigint[];
BEGIN
 SELECT array_agg(response_id ORDER BY response_id) INTO a FROM worker_a_claims;
 SELECT array_agg(response_id ORDER BY response_id) INTO b FROM worker_b_claims;
 IF cardinality(a) <> 2 OR cardinality(b) <> 2 OR a && b OR
    (SELECT count(*) FROM worker_a_claims) + (SELECT count(*) FROM worker_b_claims) <> 4 THEN
   RAISE EXCEPTION 'concurrent claims were not disjoint and complete: %, %',a,b;
 END IF;
END $$;
SELECT dblink_exec('queue_worker_a','ROLLBACK');
SELECT dblink_exec('queue_worker_b','ROLLBACK');
SELECT dblink_disconnect('queue_worker_a');
SELECT dblink_disconnect('queue_worker_b');

DO $$
BEGIN
 IF EXISTS (SELECT 1 FROM public.test_sync_requests WHERE claim_token IS NOT NULL) THEN
   RAISE EXCEPTION 'rolled-back concurrent claims left leases behind';
 END IF;
END $$;

-- Candidate-only fair market-price scheduler. Disposable PostgreSQL 17 only.
-- This is NOT a Production migration and intentionally uses an isolated schema.
DROP SCHEMA IF EXISTS scheduler_candidate CASCADE;
CREATE SCHEMA scheduler_candidate;

CREATE TABLE scheduler_candidate.assets (
  coingecko_id text PRIMARY KEY,
  pair_symbol text NOT NULL UNIQUE,
  is_enabled boolean NOT NULL DEFAULT true
);
CREATE TABLE scheduler_candidate.state (
  singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
  cursor_id text,
  cycle_no bigint NOT NULL DEFAULT 1,
  updated_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
INSERT INTO scheduler_candidate.state(singleton) VALUES (true);

CREATE TABLE scheduler_candidate.batches (
  batch_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  requested_ids text[] NOT NULL,
  cursor_after_id text,
  state text NOT NULL CHECK (state IN ('in_flight','processed','failed')),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  completed_at timestamptz,
  http_status integer,
  error_text text,
  returned_ids text[] NOT NULL DEFAULT '{}',
  omitted_ids text[] NOT NULL DEFAULT '{}',
  UNIQUE(batch_id)
);
CREATE INDEX batches_inflight_gin ON scheduler_candidate.batches USING gin(requested_ids)
  WHERE state='in_flight';

CREATE TABLE scheduler_candidate.priority_queue (
  coingecko_id text PRIMARY KEY REFERENCES scheduler_candidate.assets(coingecko_id),
  enqueued_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE TABLE scheduler_candidate.retry_queue (
  coingecko_id text PRIMARY KEY REFERENCES scheduler_candidate.assets(coingecko_id),
  attempts integer NOT NULL DEFAULT 0,
  next_attempt_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  last_error text,
  updated_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE TABLE scheduler_candidate.prices (
  pair_symbol text PRIMARY KEY REFERENCES scheduler_candidate.assets(pair_symbol),
  price numeric NOT NULL CHECK (price > 0),
  source text NOT NULL,
  source_priority integer NOT NULL,
  observed_at timestamptz NOT NULL,
  received_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE OR REPLACE FUNCTION scheduler_candidate.admit_asset(
  p_id text, p_symbol text
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_id IS NULL OR p_id !~ '^[a-z0-9-]+$'
     OR p_symbol IS NULL OR p_symbol !~ '^[A-Z0-9]{2,15}USDT$' THEN
    RAISE EXCEPTION 'invalid canonical asset or pair identity';
  END IF;
  INSERT INTO scheduler_candidate.assets(coingecko_id,pair_symbol)
  VALUES(p_id,p_symbol)
  ON CONFLICT(coingecko_id) DO NOTHING;
  IF NOT EXISTS (
    SELECT 1 FROM scheduler_candidate.assets
    WHERE coingecko_id=p_id AND pair_symbol=p_symbol
  ) THEN
    RAISE EXCEPTION 'canonical asset already maps to a different pair';
  END IF;
  INSERT INTO scheduler_candidate.priority_queue(coingecko_id)
  VALUES(p_id) ON CONFLICT DO NOTHING;
END $$;

CREATE OR REPLACE FUNCTION scheduler_candidate.schedule_next_batch(
  p_batch_size integer DEFAULT 100,
  p_max_inflight integer DEFAULT 3
) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
  v_cursor text;
  v_ids text[];
  v_cursor_after text;
  v_batch bigint;
  v_inflight integer;
BEGIN
  IF p_batch_size < 1 OR p_batch_size > 500 THEN
    RAISE EXCEPTION 'batch size out of range';
  END IF;
  IF p_max_inflight < 1 OR p_max_inflight > 10 THEN
    RAISE EXCEPTION 'max in-flight batch count out of range';
  END IF;
  IF NOT pg_try_advisory_xact_lock(742019,31) THEN
    RETURN NULL;
  END IF;

  SELECT cursor_id INTO v_cursor
  FROM scheduler_candidate.state WHERE singleton FOR UPDATE;

  SELECT count(*) INTO v_inflight FROM scheduler_candidate.batches WHERE state='in_flight';
  IF v_inflight >= p_max_inflight THEN RETURN NULL; END IF;

  -- Weighted lanes prevent an endless stream of admissions/retries from starving
  -- the ordinary catalog rotation. For batches >=3, reserve 20% priority,
  -- 20% due retries and 60% normal IDs; unused quota is backfilled.
  WITH active_ids AS (
    SELECT DISTINCT unnest(b.requested_ids) AS id
    FROM scheduler_candidate.batches b WHERE b.state='in_flight'
  ),
  candidates AS (
    SELECT a.coingecko_id AS id, 0 AS lane, q.enqueued_at AS queued_at
    FROM scheduler_candidate.priority_queue q JOIN scheduler_candidate.assets a USING(coingecko_id)
    WHERE a.is_enabled
    UNION ALL
    SELECT a.coingecko_id, 1, r.next_attempt_at
    FROM scheduler_candidate.retry_queue r JOIN scheduler_candidate.assets a USING(coingecko_id)
    WHERE a.is_enabled AND r.next_attempt_at<=clock_timestamp()
      AND NOT EXISTS (SELECT 1 FROM scheduler_candidate.priority_queue p WHERE p.coingecko_id=a.coingecko_id)
    UNION ALL
    SELECT a.coingecko_id, 2, transaction_timestamp()
    FROM scheduler_candidate.assets a
    WHERE a.is_enabled
      AND NOT EXISTS (SELECT 1 FROM scheduler_candidate.priority_queue p WHERE p.coingecko_id=a.coingecko_id)
      AND NOT EXISTS (SELECT 1 FROM scheduler_candidate.retry_queue r WHERE r.coingecko_id=a.coingecko_id)
  ),
  ranked AS (
    SELECT c.id,c.lane,c.queued_at,
      row_number() OVER (PARTITION BY c.lane ORDER BY
        CASE WHEN c.lane=2 AND v_cursor IS NOT NULL AND c.id<=v_cursor THEN 1 ELSE 0 END,
        c.queued_at,c.id) AS lane_rank
    FROM candidates c
    WHERE NOT EXISTS (SELECT 1 FROM active_ids x WHERE x.id=c.id)
  ),
  quotas AS (
    SELECT
      CASE WHEN p_batch_size>=3 THEN greatest(1,ceil(p_batch_size*0.2)::integer) ELSE 0 END AS priority_limit,
      CASE WHEN p_batch_size>=3 THEN greatest(1,ceil(p_batch_size*0.2)::integer) ELSE 0 END AS retry_limit,
      p_batch_size - 2*CASE WHEN p_batch_size>=3 THEN greatest(1,ceil(p_batch_size*0.2)::integer) ELSE 0 END AS normal_limit
  ),
  quota_picks AS (
    SELECT r.* FROM ranked r CROSS JOIN quotas q
    WHERE (r.lane=0 AND r.lane_rank<=q.priority_limit)
       OR (r.lane=1 AND r.lane_rank<=q.retry_limit)
       OR (r.lane=2 AND r.lane_rank<=q.normal_limit)
  ),
  fill_picks AS (
    SELECT r.* FROM ranked r
    WHERE NOT EXISTS (SELECT 1 FROM quota_picks q WHERE q.id=r.id)
    -- Backfill unused quota into normal first, then retry, and priority last.
    ORDER BY CASE r.lane WHEN 2 THEN 0 WHEN 1 THEN 1 ELSE 2 END,r.lane_rank
    LIMIT greatest(0,p_batch_size-(SELECT count(*) FROM quota_picks))
  ),
  picked AS (
    SELECT * FROM quota_picks
    UNION ALL SELECT * FROM fill_picks
  )
  SELECT array_agg(id ORDER BY lane,lane_rank),
         (SELECT id FROM picked WHERE lane=2 ORDER BY lane_rank DESC LIMIT 1)
  INTO v_ids,v_cursor_after
  FROM picked;

  IF COALESCE(cardinality(v_ids),0)=0 THEN
    RETURN NULL;
  END IF;

  INSERT INTO scheduler_candidate.batches(requested_ids,cursor_after_id,state)
  VALUES(v_ids,v_cursor_after,'in_flight') RETURNING batch_id INTO v_batch;

  RETURN v_batch;
END $$;

CREATE OR REPLACE FUNCTION scheduler_candidate.accept_price(
  p_pair text, p_price numeric, p_source text,
  p_priority integer, p_observed_at timestamptz
) RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE v_rows integer;
BEGIN
  IF p_price IS NULL OR p_price<=0 OR p_price::text IN ('NaN','Infinity','-Infinity')
     OR p_observed_at IS NULL OR p_observed_at < clock_timestamp()-interval '2 minutes'
     OR p_observed_at > clock_timestamp()+interval '30 seconds'
     OR p_source IS NULL OR p_priority IS NULL OR p_priority<1 THEN
    RETURN false;
  END IF;
  INSERT INTO scheduler_candidate.prices(pair_symbol,price,source,source_priority,observed_at)
  VALUES(p_pair,p_price,p_source,p_priority,p_observed_at)
  ON CONFLICT(pair_symbol) DO UPDATE
    SET price=EXCLUDED.price,source=EXCLUDED.source,
        source_priority=EXCLUDED.source_priority,
        observed_at=EXCLUDED.observed_at,received_at=clock_timestamp()
    WHERE EXCLUDED.source_priority > scheduler_candidate.prices.source_priority
       OR (EXCLUDED.source_priority = scheduler_candidate.prices.source_priority
           AND EXCLUDED.observed_at > scheduler_candidate.prices.observed_at);
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  RETURN v_rows > 0;
END $$;

CREATE OR REPLACE FUNCTION scheduler_candidate.complete_batch(
  p_batch bigint, p_status integer, p_response jsonb, p_error text DEFAULT NULL
) RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_ids text[];
  v_returned text[] := '{}';
  v_omitted text[] := '{}';
  v_id text;
  v_price numeric;
  v_symbol text;
  v_observed_at timestamptz;
  v_now timestamptz := clock_timestamp();
BEGIN
  SELECT requested_ids INTO v_ids
  FROM scheduler_candidate.batches
  WHERE batch_id=p_batch AND state='in_flight'
  FOR UPDATE;
  IF NOT FOUND THEN
    -- Idempotent duplicate delivery: terminal batches are a no-op.
    IF EXISTS (SELECT 1 FROM scheduler_candidate.batches WHERE batch_id=p_batch AND state IN ('processed','failed')) THEN
      RETURN;
    END IF;
    RAISE EXCEPTION 'unknown batch';
  END IF;

  IF p_status=200 AND jsonb_typeof(p_response)='object' THEN
    FOREACH v_id IN ARRAY v_ids LOOP
      v_price := NULL;
      v_symbol := NULL;
      v_observed_at := NULL;
      BEGIN
        v_price := NULLIF(p_response->v_id->>'usd','')::numeric;
        v_observed_at := to_timestamp((p_response->v_id->>'last_updated_at')::double precision);
      EXCEPTION WHEN OTHERS THEN
        v_price := NULL;
        v_observed_at := NULL;
      END;
      SELECT pair_symbol INTO v_symbol FROM scheduler_candidate.assets
      WHERE coingecko_id=v_id AND is_enabled;
      IF v_price>0 AND v_price::text NOT IN ('NaN','Infinity','-Infinity')
         AND v_symbol IS NOT NULL AND v_observed_at IS NOT NULL
         AND scheduler_candidate.accept_price(v_symbol,v_price,'CoinGecko',100,v_observed_at) THEN
        v_returned := array_append(v_returned,v_id);
        DELETE FROM scheduler_candidate.retry_queue WHERE coingecko_id=v_id;
        DELETE FROM scheduler_candidate.priority_queue WHERE coingecko_id=v_id;
      ELSE
        v_omitted := array_append(v_omitted,v_id);
      END IF;
    END LOOP;
  ELSE
    v_omitted := v_ids;
  END IF;

  INSERT INTO scheduler_candidate.retry_queue(coingecko_id,attempts,next_attempt_at,last_error,updated_at)
  SELECT id,1,v_now + interval '30 seconds',COALESCE(p_error,'provider omitted/invalid price'),v_now
  FROM unnest(v_omitted) AS u(id)
  ON CONFLICT(coingecko_id) DO UPDATE
    SET attempts=scheduler_candidate.retry_queue.attempts+1,
        next_attempt_at=v_now + LEAST(interval '30 minutes',
          interval '30 seconds' * power(2,LEAST(scheduler_candidate.retry_queue.attempts,6))),
        last_error=EXCLUDED.last_error,updated_at=v_now;

  DELETE FROM scheduler_candidate.priority_queue WHERE coingecko_id=ANY(v_ids);

  UPDATE scheduler_candidate.batches
  SET state=CASE WHEN p_status=200 THEN 'processed' ELSE 'failed' END,
      completed_at=v_now,http_status=p_status,error_text=p_error,
      returned_ids=v_returned,omitted_ids=v_omitted
  WHERE batch_id=p_batch;

  UPDATE scheduler_candidate.state
  SET cursor_id=COALESCE(
      (SELECT cursor_after_id FROM scheduler_candidate.batches WHERE batch_id=p_batch),
      cursor_id),
      updated_at=v_now
  WHERE singleton;
END $$;

-- Tests: catalog > primary 515 boundary, no starvation across batches,
-- priority admissions, omissions/retries, idempotency, and source precedence.
DO $$
DECLARE
  v_batch bigint;
  v_count integer;
  v_id text;
  v_ids text[];
  v_before integer;
  v_after integer;
  v_ids_json jsonb;
BEGIN
  FOR i IN 1..1200 LOOP
    PERFORM scheduler_candidate.admit_asset(
      'asset-'||lpad(i::text,4,'0'),
      'A'||lpad(i::text,4,'0')||'USDT'
    );
  END LOOP;

  -- Clear initial admission priority to test normal cursor rotation at scale.
  DELETE FROM scheduler_candidate.priority_queue;

  -- Each completed batch has a 100-ID page; every asset is eventually covered.
  FOR page IN 1..12 LOOP
    v_batch := scheduler_candidate.schedule_next_batch(100);
    IF v_batch IS NULL THEN RAISE EXCEPTION 'scheduler returned no batch at page %',page; END IF;
    SELECT requested_ids INTO v_ids FROM scheduler_candidate.batches WHERE batch_id=v_batch;
    IF cardinality(v_ids)<>100 THEN RAISE EXCEPTION 'expected 100 IDs, got %',cardinality(v_ids); END IF;
    SELECT count(*) INTO v_count FROM unnest(v_ids) AS u(id)
      WHERE EXISTS (SELECT 1 FROM scheduler_candidate.batches b
        WHERE b.batch_id<>v_batch AND b.state='processed' AND u.id=ANY(b.requested_ids));
    IF v_count<>0 THEN RAISE EXCEPTION 'duplicate scheduling detected'; END IF;
    SELECT jsonb_object_agg(u.id,jsonb_build_object('usd',1.25,'last_updated_at',extract(epoch from clock_timestamp())::bigint)) INTO STRICT v_ids_json
    FROM unnest(v_ids) AS u(id);
    PERFORM scheduler_candidate.complete_batch(v_batch,200,v_ids_json);
  END LOOP;
  SELECT count(DISTINCT u.id) INTO v_count
  FROM scheduler_candidate.batches b CROSS JOIN LATERAL unnest(b.returned_ids) AS u(id)
  WHERE b.state='processed';
  IF v_count<>1200 THEN RAISE EXCEPTION 'fair cycle covered % of 1200 assets',v_count; END IF;

  -- The cursor wraps after the final ID and starts a fresh fair cycle.
  v_batch := scheduler_candidate.schedule_next_batch(100);
  SELECT requested_ids INTO v_ids FROM scheduler_candidate.batches WHERE batch_id=v_batch;
  IF v_ids[1] <> 'asset-0001' THEN
    RAISE EXCEPTION 'cursor did not wrap to first canonical ID: %',v_ids[1];
  END IF;
  PERFORM scheduler_candidate.complete_batch(v_batch,200,
    (SELECT jsonb_object_agg(u.id,jsonb_build_object('usd',1.30,'last_updated_at',extract(epoch from clock_timestamp())::bigint)) FROM unnest(v_ids) AS u(id)));

  -- Newly admitted assets are scheduled before ordinary cursor assets.
  PERFORM scheduler_candidate.admit_asset('new-priority','NEWUSDT');
  v_batch := scheduler_candidate.schedule_next_batch(5);
  SELECT requested_ids INTO v_ids FROM scheduler_candidate.batches WHERE batch_id=v_batch;
  IF NOT ('new-priority'=ANY(v_ids)) THEN RAISE EXCEPTION 'new asset did not receive priority'; END IF;

  -- Provider omission does not block unrelated work; it becomes retryable.
  PERFORM scheduler_candidate.complete_batch(v_batch,200,'{}'::jsonb);
  IF NOT EXISTS (SELECT 1 FROM scheduler_candidate.retry_queue WHERE coingecko_id='new-priority') THEN
    RAISE EXCEPTION 'omitted ID was not recorded for retry';
  END IF;
  UPDATE scheduler_candidate.retry_queue SET next_attempt_at=clock_timestamp()-interval '1 second'
  WHERE coingecko_id='new-priority';
  v_batch := scheduler_candidate.schedule_next_batch(5);
  SELECT requested_ids INTO v_ids FROM scheduler_candidate.batches WHERE batch_id=v_batch;
  IF NOT ('new-priority'=ANY(v_ids)) THEN RAISE EXCEPTION 'due retry was not scheduled'; END IF;
  PERFORM scheduler_candidate.complete_batch(v_batch,200,jsonb_build_object('new-priority',jsonb_build_object('usd',2.5,'last_updated_at',extract(epoch from clock_timestamp())::bigint)));
  PERFORM scheduler_candidate.complete_batch(v_batch,200,jsonb_build_object('new-priority',jsonb_build_object('usd',999,'last_updated_at',extract(epoch from clock_timestamp())::bigint)));
  IF (SELECT price FROM scheduler_candidate.prices WHERE pair_symbol='NEWUSDT')<>2.5 THEN
    RAISE EXCEPTION 'duplicate completion was not idempotent';
  END IF;

  -- Higher-priority source wins regardless of arrival order; lower priority
  -- cannot overwrite it, and same source only accepts newer observations.
  IF NOT scheduler_candidate.accept_price('NEWUSDT',3,'CoinGecko',100,clock_timestamp()) THEN
    RAISE EXCEPTION 'same-source newer quote was rejected';
  END IF;
  IF scheduler_candidate.accept_price('NEWUSDT',4,'Gate.io',50,clock_timestamp()) THEN
    RAISE EXCEPTION 'lower-priority source overwrote preferred quote';
  END IF;
  IF scheduler_candidate.accept_price('NEWUSDT',4,'CoinGecko',100,clock_timestamp()-interval '5 minutes') THEN
    RAISE EXCEPTION 'stale source observation was accepted';
  END IF;
  IF scheduler_candidate.accept_price('NEWUSDT','NaN'::numeric,'CoinGecko',100,clock_timestamp()) THEN
    RAISE EXCEPTION 'NaN price was accepted';
  END IF;
  IF NOT scheduler_candidate.accept_price('NEWUSDT',5,'ManualVerified',200,clock_timestamp()) THEN
    RAISE EXCEPTION 'higher-priority source was rejected';
  END IF;
  IF (SELECT price FROM scheduler_candidate.prices WHERE pair_symbol='NEWUSDT')<>5 THEN
    RAISE EXCEPTION 'source priority result is not deterministic';
  END IF;

  -- A provider HTTP failure is durable and retried; it does not become a quote.
  PERFORM scheduler_candidate.admit_asset('http-error-asset','ERRUSDT');
  v_batch := scheduler_candidate.schedule_next_batch(5);
  PERFORM scheduler_candidate.complete_batch(v_batch,503,NULL,'provider unavailable');
  IF NOT EXISTS (
    SELECT 1 FROM scheduler_candidate.retry_queue
    WHERE coingecko_id='http-error-asset' AND last_error='provider unavailable'
  ) THEN RAISE EXCEPTION 'HTTP failure was not recorded for retry'; END IF;
  UPDATE scheduler_candidate.retry_queue
  SET next_attempt_at=clock_timestamp()-interval '1 second'
  WHERE coingecko_id='http-error-asset';
  v_batch := scheduler_candidate.schedule_next_batch(5);
  PERFORM scheduler_candidate.complete_batch(v_batch,200,jsonb_build_object('http-error-asset',jsonb_build_object('usd',7.5,'last_updated_at',extract(epoch from clock_timestamp())::bigint)));
  IF (SELECT price FROM scheduler_candidate.prices WHERE pair_symbol='ERRUSDT')<>7.5 THEN
    RAISE EXCEPTION 'HTTP-failed asset did not recover on retry';
  END IF;

  -- A price without a provider-observed timestamp is omitted and retried;
  -- receipt time must never be substituted for source observation time.
  PERFORM scheduler_candidate.admit_asset('missing-time-asset','MISSTUSDT');
  v_batch := scheduler_candidate.schedule_next_batch(10);
  PERFORM scheduler_candidate.complete_batch(v_batch,200,
    jsonb_build_object('missing-time-asset',jsonb_build_object('usd',9.5)));
  IF NOT EXISTS (
    SELECT 1 FROM scheduler_candidate.retry_queue
    WHERE coingecko_id='missing-time-asset' AND last_error='provider omitted/invalid price'
  ) THEN RAISE EXCEPTION 'missing provider observation timestamp was not rejected'; END IF;

  -- Ticker collision is rejected instead of binding a second canonical ID.
  BEGIN
    PERFORM scheduler_candidate.admit_asset('same-ticker-different-id','NEWUSDT');
    RAISE EXCEPTION 'duplicate pair symbol was unexpectedly admitted';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;

  -- Continuous admission storm must not starve ordinary catalog assets.
  FOR i IN 1..5 LOOP
    FOR j IN 1..10 LOOP
      PERFORM scheduler_candidate.admit_asset(
        'storm-'||i::text||'-'||j::text,
        'ST'||lpad((i*10+j)::text,3,'0')||'USDT'
      );
    END LOOP;
    v_batch := scheduler_candidate.schedule_next_batch(10);
    SELECT requested_ids INTO v_ids FROM scheduler_candidate.batches WHERE batch_id=v_batch;
    SELECT count(*) INTO v_count FROM unnest(v_ids) AS u(id) WHERE id LIKE 'storm-%';
    IF v_count>2 THEN RAISE EXCEPTION 'priority storm consumed % of 10 slots',v_count; END IF;
    IF cardinality(v_ids)-v_count<6 THEN
      RAISE EXCEPTION 'ordinary catalog lane starved during admission storm';
    END IF;
    SELECT jsonb_object_agg(u.id,jsonb_build_object('usd',8.5,'last_updated_at',extract(epoch from clock_timestamp())::bigint)) INTO v_ids_json
    FROM unnest(v_ids) AS u(id);
    PERFORM scheduler_candidate.complete_batch(v_batch,200,v_ids_json);
  END LOOP;

  -- Bound the number of outstanding provider batches.
  PERFORM scheduler_candidate.schedule_next_batch(10,3);
  PERFORM scheduler_candidate.schedule_next_batch(10,3);
  PERFORM scheduler_candidate.schedule_next_batch(10,3);
  IF (SELECT count(DISTINCT u.id) FROM scheduler_candidate.batches b
      CROSS JOIN LATERAL unnest(b.requested_ids) AS u(id)
      WHERE b.state='in_flight')
     <> (SELECT COALESCE(sum(cardinality(requested_ids)),0)
         FROM scheduler_candidate.batches WHERE state='in_flight') THEN
    RAISE EXCEPTION 'in-flight batches contain duplicate canonical IDs';
  END IF;
  IF scheduler_candidate.schedule_next_batch(10,3) IS NOT NULL THEN
    RAISE EXCEPTION 'scheduler exceeded configured in-flight batch cap';
  END IF;
END $$;

SELECT 'PASS: candidate fairness, retry, idempotency, priority admission and source precedence' AS result;

-- Disposable PostgreSQL 17 regression for the exact Production market-price
-- scheduler bodies captured on 2026-11-27.
-- Source fingerprints:
--   private.request_market_price_overflow(): e6ed136175b0d340c9a86e51f7917a76
--   public.refresh_market_prices():          3788666d57957a66bf59031f54ceff03
-- This test executes only in the CI disposable database. It makes no HTTP calls.

DROP SCHEMA IF EXISTS net CASCADE;
DROP SCHEMA IF EXISTS private CASCADE;
DROP TABLE IF EXISTS public.demo_trading_pairs CASCADE;
DROP TABLE IF EXISTS public.admin_market_listings CASCADE;
DROP TABLE IF EXISTS public.crypto_assets CASCADE;
DROP TABLE IF EXISTS public.market_prices CASCADE;

CREATE SCHEMA net;
CREATE SCHEMA private;

CREATE TABLE public.crypto_assets (
  coingecko_id text PRIMARY KEY,
  symbol text NOT NULL,
  is_active boolean NOT NULL DEFAULT true
);
CREATE TABLE public.admin_market_listings (
  coingecko_id text PRIMARY KEY
);
CREATE TABLE public.demo_trading_pairs (
  pair_symbol text PRIMARY KEY,
  base_coingecko_id text NOT NULL,
  is_enabled boolean NOT NULL DEFAULT true
);
CREATE TABLE public.market_prices (
  symbol text PRIMARY KEY,
  price numeric NOT NULL,
  source text NOT NULL,
  updated_at timestamptz NOT NULL
);
CREATE TABLE private.market_price_sync_requests (
  request_id bigint PRIMARY KEY,
  provider text NOT NULL DEFAULT 'CoinGecko',
  queued_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE net.http_request_queue (
  id bigint PRIMARY KEY,
  url text NOT NULL
);
CREATE TABLE net._http_response (
  id bigint PRIMARY KEY,
  status_code integer,
  content text,
  timed_out boolean DEFAULT false,
  error_msg text
);
CREATE SEQUENCE net.http_request_id_seq;

-- Network stub: records the request and never performs external I/O.
CREATE OR REPLACE FUNCTION net.http_get(url text, timeout_milliseconds integer)
RETURNS bigint
LANGUAGE plpgsql
AS $stub$
DECLARE
  v_id bigint := nextval('net.http_request_id_seq');
BEGIN
  INSERT INTO net.http_request_queue(id,url) VALUES(v_id,url);
  RETURN v_id;
END;
$stub$;

-- Exact Production body captured with pg_get_functiondef on 2026-11-27.
CREATE OR REPLACE FUNCTION private.request_market_price_overflow()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_overflow_ids text[];
  v_total integer;
  v_offset integer;
  v_end integer;
  v_ids text;
  v_request_id bigint;
  v_requests integer := 0;
BEGIN
  IF NOT pg_catalog.pg_try_advisory_xact_lock(742019, 14) THEN
    RETURN 0;
  END IF;

  IF EXISTS (SELECT 1 FROM private.market_price_sync_requests)
     OR EXISTS (
       SELECT 1 FROM net.http_request_queue q
       WHERE q.url LIKE 'https://api.coingecko.com/api/v3/simple/price%'
     ) THEN
    RETURN 0;
  END IF;

  SELECT ARRAY(
    SELECT all_ids.coingecko_id
    FROM (
      SELECT DISTINCT ids.coingecko_id
      FROM (
        SELECT dp.base_coingecko_id AS coingecko_id
        FROM public.demo_trading_pairs AS dp
        WHERE dp.is_enabled IS TRUE
        UNION
        SELECT ca.coingecko_id
        FROM public.admin_market_listings AS l
        JOIN public.crypto_assets AS ca ON ca.coingecko_id = l.coingecko_id
        WHERE ca.is_active IS TRUE
      ) AS ids
      WHERE ids.coingecko_id ~ '^[a-z0-9-]+$'
    ) AS all_ids
    ORDER BY all_ids.coingecko_id
    OFFSET 515
  )
  INTO v_overflow_ids;

  v_total := COALESCE(pg_catalog.array_length(v_overflow_ids, 1), 0);
  IF v_total = 0 THEN
    RETURN 0;
  END IF;

  FOR v_offset IN 1..v_total BY 500 LOOP
    v_end := LEAST(v_offset + 499, v_total);
    v_ids := pg_catalog.array_to_string(v_overflow_ids[v_offset:v_end], ',');

    v_request_id := net.http_get(
      url := 'https://api.coingecko.com/api/v3/simple/price?ids='
        || v_ids || '&vs_currencies=usd',
      timeout_milliseconds := 20000
    );

    INSERT INTO private.market_price_sync_requests(request_id)
    VALUES (v_request_id)
    ON CONFLICT DO NOTHING;

    v_requests := v_requests + 1;
  END LOOP;

  RETURN v_requests;
END;
$function$;

-- Exact Production body captured with pg_get_functiondef on 2026-11-27.
CREATE OR REPLACE FUNCTION public.refresh_market_prices()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  r record;
  v_map record;
  v_ticker jsonb;
  v_symbol text;
  v_price numeric;
  v_ids text;
  v_request_id bigint;
BEGIN
  IF pg_catalog.pg_try_advisory_xact_lock(742019, 13) IS NOT TRUE THEN
    RETURN;
  END IF;

  FOR r IN
    SELECT q.request_id,q.provider,h.status_code,h.content,h.timed_out,h.error_msg
    FROM private.market_price_sync_requests q
    JOIN net._http_response h ON h.id=q.request_id
  LOOP
    IF r.status_code=200 AND COALESCE(r.timed_out,false)=false AND r.content IS NOT NULL THEN
      BEGIN
        IF r.provider='CoinGecko' THEN
          FOR v_map IN
            SELECT dp.pair_symbol AS symbol,dp.base_coingecko_id AS coingecko_id
            FROM public.demo_trading_pairs dp WHERE dp.is_enabled IS TRUE
            UNION
            SELECT pg_catalog.upper(ca.symbol)||'USDT',ca.coingecko_id
            FROM public.admin_market_listings l
            JOIN public.crypto_assets ca ON ca.coingecko_id=l.coingecko_id
            WHERE ca.is_active IS TRUE
          LOOP
            v_price:=NULLIF((r.content::jsonb->v_map.coingecko_id->>'usd'),'')::numeric;
            IF v_price>0 THEN
              INSERT INTO public.market_prices(symbol,price,source,updated_at)
              VALUES(v_map.symbol,v_price,'CoinGecko',now())
              ON CONFLICT(symbol) DO UPDATE SET price=EXCLUDED.price,source=EXCLUDED.source,updated_at=EXCLUDED.updated_at;
            END IF;
          END LOOP;

        ELSIF r.provider='KuCoin' AND r.content::jsonb->>'code'='200000' THEN
          FOR v_ticker IN SELECT value FROM jsonb_array_elements(r.content::jsonb->'data'->'ticker')
          LOOP
            v_symbol:=replace(v_ticker->>'symbol','-','');
            v_price:=NULLIF(v_ticker->>'last','')::numeric;
            IF v_symbol ~ '^[A-Z0-9]{2,24}USDT$' AND v_price>0
              AND EXISTS(SELECT 1 FROM public.demo_trading_pairs dp WHERE dp.is_enabled IS TRUE AND dp.pair_symbol=v_symbol) THEN
              INSERT INTO public.market_prices(symbol,price,source,updated_at)
              VALUES(v_symbol,v_price,'KuCoin',now())
              ON CONFLICT(symbol) DO UPDATE SET price=EXCLUDED.price,source=EXCLUDED.source,updated_at=EXCLUDED.updated_at;
            END IF;
          END LOOP;

        ELSIF r.provider='Gate.io' AND jsonb_typeof(r.content::jsonb)='array' THEN
          FOR v_ticker IN SELECT value FROM jsonb_array_elements(r.content::jsonb)
          LOOP
            v_symbol:=replace(v_ticker->>'currency_pair','_','');
            v_price:=NULLIF(v_ticker->>'last','')::numeric;
            IF v_symbol ~ '^[A-Z0-9]{2,24}USDT$' AND v_price>0
              AND EXISTS(SELECT 1 FROM public.demo_trading_pairs dp WHERE dp.is_enabled IS TRUE AND dp.pair_symbol=v_symbol) THEN
              INSERT INTO public.market_prices(symbol,price,source,updated_at)
              VALUES(v_symbol,v_price,'Gate.io',now())
              ON CONFLICT(symbol) DO UPDATE SET price=EXCLUDED.price,source=EXCLUDED.source,updated_at=EXCLUDED.updated_at;
            END IF;
          END LOOP;
        END IF;
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Market-price response processing failed for provider %: %',r.provider,SQLERRM;
      END;
    ELSE
      RAISE WARNING 'Market-price request failed for provider %. Status: %, Error: %',r.provider,r.status_code,r.error_msg;
    END IF;
    DELETE FROM private.market_price_sync_requests WHERE request_id=r.request_id;
  END LOOP;

  DELETE FROM private.market_price_sync_requests q
  WHERE q.queued_at < now() - interval '30 minutes'
    AND NOT EXISTS (SELECT 1 FROM net.http_request_queue nq WHERE nq.id = q.request_id)
    AND NOT EXISTS (SELECT 1 FROM net._http_response h WHERE h.id = q.request_id);

  IF EXISTS (
      SELECT 1 FROM net.http_request_queue nq
      WHERE nq.url LIKE 'https://api.coingecko.com/api/v3/simple/price%'
         OR nq.url = 'https://api.kucoin.com/api/v1/market/allTickers'
         OR nq.url = 'https://api.gateio.ws/api/v4/spot/tickers'
  ) OR EXISTS (
      SELECT 1 FROM private.market_price_sync_requests
  ) THEN
      RETURN;
  END IF;

  SELECT pg_catalog.string_agg(x.coingecko_id,',' ORDER BY x.coingecko_id) INTO v_ids
  FROM (
    SELECT ids.coingecko_id
    FROM (
      SELECT dp.base_coingecko_id AS coingecko_id FROM public.demo_trading_pairs dp WHERE dp.is_enabled IS TRUE
      UNION
      SELECT ca.coingecko_id FROM public.admin_market_listings l
      JOIN public.crypto_assets ca ON ca.coingecko_id=l.coingecko_id WHERE ca.is_active IS TRUE
    ) ids
    WHERE ids.coingecko_id ~ '^[a-z0-9-]+$'
    ORDER BY ids.coingecko_id
    LIMIT 515
  ) x;

  IF v_ids IS NOT NULL AND v_ids<>'' THEN
    v_request_id:=net.http_get(url:='https://api.coingecko.com/api/v3/simple/price?ids='||v_ids||'&vs_currencies=usd',timeout_milliseconds:=20000);
    INSERT INTO private.market_price_sync_requests(request_id,provider) VALUES(v_request_id,'CoinGecko') ON CONFLICT(request_id) DO NOTHING;
  END IF;

  v_request_id:=net.http_get(url:='https://api.kucoin.com/api/v1/market/allTickers',timeout_milliseconds:=15000);
  INSERT INTO private.market_price_sync_requests(request_id,provider) VALUES(v_request_id,'KuCoin') ON CONFLICT(request_id) DO NOTHING;

  v_request_id:=net.http_get(url:='https://api.gateio.ws/api/v4/spot/tickers',timeout_milliseconds:=15000);
  INSERT INTO private.market_price_sync_requests(request_id,provider) VALUES(v_request_id,'Gate.io') ON CONFLICT(request_id) DO NOTHING;
END;
$function$;

-- The fixture mirrors the captured cron cadence; it does not install pg_cron.
CREATE TEMP TABLE expected_cron(job_id integer, schedule text, function_name text);
INSERT INTO expected_cron VALUES
  (3, '* * * * *', 'public.refresh_market_prices'),
  (17, '5-59/10 * * * *', 'private.request_market_price_overflow');

DO $test$
DECLARE
  v_count integer;
  v_result integer;
  v_row record;
BEGIN
  IF (SELECT count(*) FROM expected_cron) <> 2
     OR NOT EXISTS (SELECT 1 FROM expected_cron WHERE job_id=3 AND schedule='* * * * *')
     OR NOT EXISTS (SELECT 1 FROM expected_cron WHERE job_id=17 AND schedule='5-59/10 * * * *') THEN
    RAISE EXCEPTION 'Captured Production cron cadence fixture mismatch';
  END IF;

  -- 516 enabled assets: the primary function takes the first 515.
  INSERT INTO public.demo_trading_pairs(pair_symbol,base_coingecko_id,is_enabled)
  SELECT 'A'||lpad(n::text,4,'0')||'USDT',
         'asset-'||lpad(n::text,4,'0'),
         true
  FROM generate_series(1,516) AS n;

  PERFORM public.refresh_market_prices();

  SELECT count(*) INTO v_count FROM private.market_price_sync_requests;
  IF v_count <> 3 THEN
    RAISE EXCEPTION 'Expected 3 primary tracked requests after empty-queue refresh; got %',v_count;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM net.http_request_queue
    WHERE url LIKE 'https://api.coingecko.com/api/v3/simple/price%'
      AND url LIKE '%asset-0515%'
      AND url NOT LIKE '%asset-0516%'
  ) THEN
    RAISE EXCEPTION 'Primary CoinGecko batch did not include first-515 boundary as expected';
  END IF;

  v_result := private.request_market_price_overflow();
  IF v_result <> 0 THEN
    RAISE EXCEPTION 'Overflow should be blocked while primary requests are tracked; returned %',v_result;
  END IF;

  -- Simulate completed provider requests: queued requests move to response rows.
  FOR v_row IN SELECT q.id,s.provider FROM net.http_request_queue q
               JOIN private.market_price_sync_requests s ON s.request_id=q.id
  LOOP
    INSERT INTO net._http_response(id,status_code,content,timed_out,error_msg)
    VALUES(
      v_row.id,
      200,
      CASE v_row.provider
        WHEN 'CoinGecko' THEN '{"asset-0001":{"usd":1}}'
        WHEN 'KuCoin' THEN '{"code":"200000","data":{"ticker":[]}}'
        WHEN 'Gate.io' THEN '[]'
      END,
      false,
      NULL
    );
  END LOOP;
  DELETE FROM net.http_request_queue;

  -- Production refresh processes and deletes the completed tracking rows, then
  -- immediately re-enqueues the primary 515 + both exchange feeds.
  PERFORM public.refresh_market_prices();

  SELECT count(*) INTO v_count FROM private.market_price_sync_requests;
  IF v_count <> 3 THEN
    RAISE EXCEPTION 'Expected next primary cycle to create 3 tracked requests; got %',v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM net.http_request_queue
  WHERE url LIKE 'https://api.coingecko.com/api/v3/simple/price%';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Expected one new primary CoinGecko request after response processing; got %',v_count;
  END IF;

  -- At the scheduled overflow invocation after the primary cycle, its global
  -- tracked-request guard blocks all IDs beyond the first 515.
  v_result := private.request_market_price_overflow();
  IF v_result <> 0 THEN
    RAISE EXCEPTION 'Expected overflow to be starved by the next primary cycle; returned %',v_result;
  END IF;

  IF EXISTS (
    SELECT 1 FROM net.http_request_queue
    WHERE url LIKE '%asset-0516%'
  ) THEN
    RAISE EXCEPTION 'The 516th asset unexpectedly entered a CoinGecko request during the blocked interleaving';
  END IF;

  -- Control case: once all outstanding primary work is absent, overflow can
  -- enqueue the 516th asset. This distinguishes the guard from bad ID sorting.
  DELETE FROM private.market_price_sync_requests;
  DELETE FROM net.http_request_queue;
  v_result := private.request_market_price_overflow();
  IF v_result <> 1 THEN
    RAISE EXCEPTION 'Expected one overflow batch for the 516th asset; got %',v_result;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM net.http_request_queue
    WHERE url LIKE 'https://api.coingecko.com/api/v3/simple/price%'
      AND url LIKE '%asset-0516%'
  ) THEN
    RAISE EXCEPTION 'Overflow control case failed to include the 516th asset';
  END IF;
END;
$test$;

DO $verify$
BEGIN
  IF (SELECT count(*) FROM private.market_price_sync_requests) <> 1 THEN
    RAISE EXCEPTION 'Expected exactly one overflow tracking row after control case';
  END IF;
  IF (SELECT count(*) FROM net.http_request_queue) <> 1 THEN
    RAISE EXCEPTION 'Expected exactly one network-stub queue row after control case';
  END IF;
END;
$verify$;

SELECT 'PASS: exact Production scheduler interleaving reproduced in disposable PostgreSQL' AS result;

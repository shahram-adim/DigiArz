-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: private.request_market_price_overflow()
-- PostgreSQL md5(pg_get_functiondef(...)): e6ed136175b0d340c9a86e51f7917a76
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=false, service_role=false.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
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
  -- Keep overflow scheduling separate from the primary price-refresh lock.
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

  -- The primary refresh request already asks for the first 515 sorted IDs.
  -- Fetch every remaining ID in batches below CoinGecko's documented limit.
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
$function$
;

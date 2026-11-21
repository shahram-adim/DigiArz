-- Prevent Bit24 batch upserts from targeting the same (exchange, market_symbol)
-- more than once. Conflicting base/quote metadata aborts the whole batch safely.
CREATE OR REPLACE FUNCTION public.process_bit24_exchange_sync()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  n integer := 0;
  p integer := 0;
  v_conflicts integer := 0;
BEGIN
  WITH resp AS (
    SELECT q.request_id, q.requested_at, r.content::jsonb AS j
    FROM public.bit24_exchange_sync_requests q
    JOIN net._http_response r ON r.id = q.request_id
    WHERE q.processed_at IS NULL
      AND r.status_code = 200
      AND r.content IS NOT NULL
  ),
  rows AS (
    SELECT
      r.request_id,
      r.requested_at,
      upper(replace(x->>'market_name', '/', '_')) AS market_symbol,
      upper(x->'base_coin'->>'symbol') AS base_symbol,
      upper(x->'quote_coin'->>'symbol') AS quote_symbol,
      x->'base_coin'->>'name' AS asset_name,
      x AS source_payload
    FROM resp r
    CROSS JOIN LATERAL jsonb_array_elements(r.j->'data'->'results') x
    WHERE x->'base_coin'->>'symbol' IS NOT NULL
      AND x->>'market_name' IS NOT NULL
  )
  SELECT count(*) INTO v_conflicts
  FROM (
    SELECT market_symbol
    FROM rows
    GROUP BY market_symbol
    HAVING count(DISTINCT (base_symbol, quote_symbol)) > 1
  ) conflicts;

  IF v_conflicts > 0 THEN
    RAISE EXCEPTION 'Bit24 sync safely aborted: % market symbols have conflicting base/quote metadata', v_conflicts;
  END IF;

  WITH resp AS (
    SELECT q.request_id, q.requested_at, r.content::jsonb AS j
    FROM public.bit24_exchange_sync_requests q
    JOIN net._http_response r ON r.id = q.request_id
    WHERE q.processed_at IS NULL
      AND r.status_code = 200
      AND r.content IS NOT NULL
  ),
  rows AS (
    SELECT
      r.request_id,
      r.requested_at,
      upper(replace(x->>'market_name', '/', '_')) AS market_symbol,
      upper(x->'base_coin'->>'symbol') AS base_symbol,
      upper(x->'quote_coin'->>'symbol') AS quote_symbol,
      x->'base_coin'->>'name' AS asset_name,
      x AS source_payload
    FROM resp r
    CROSS JOIN LATERAL jsonb_array_elements(r.j->'data'->'results') x
    WHERE x->'base_coin'->>'symbol' IS NOT NULL
      AND x->>'market_name' IS NOT NULL
  ),
  deduplicated AS (
    SELECT DISTINCT ON (market_symbol)
      market_symbol, base_symbol, quote_symbol, asset_name, source_payload
    FROM rows
    ORDER BY market_symbol, requested_at DESC, request_id DESC,
             (asset_name IS NOT NULL) DESC, source_payload::text DESC
  )
  INSERT INTO public.exchange_asset_observations(
    exchange, market_symbol, base_symbol, quote_symbol, asset_name,
    source_url, source_payload, is_active, last_seen_at
  )
  SELECT
    'bit24', market_symbol, base_symbol, quote_symbol, asset_name,
    'https://pro.bit24.cash/api/v3/markets', source_payload, true, now()
  FROM deduplicated
  ON CONFLICT(exchange, market_symbol) DO UPDATE
  SET
    base_symbol = EXCLUDED.base_symbol,
    quote_symbol = EXCLUDED.quote_symbol,
    asset_name = coalesce(EXCLUDED.asset_name, public.exchange_asset_observations.asset_name),
    source_payload = EXCLUDED.source_payload,
    is_active = EXCLUDED.is_active,
    last_seen_at = now()
  WHERE public.exchange_asset_observations.base_symbol IS DISTINCT FROM EXCLUDED.base_symbol
     OR public.exchange_asset_observations.quote_symbol IS DISTINCT FROM EXCLUDED.quote_symbol
     OR public.exchange_asset_observations.asset_name IS DISTINCT FROM coalesce(EXCLUDED.asset_name, public.exchange_asset_observations.asset_name)
     OR public.exchange_asset_observations.source_payload IS DISTINCT FROM EXCLUDED.source_payload
     OR public.exchange_asset_observations.is_active IS DISTINCT FROM EXCLUDED.is_active
     OR public.exchange_asset_observations.last_seen_at IS NULL
     OR public.exchange_asset_observations.last_seen_at < now() - interval '30 minutes';

  GET DIAGNOSTICS n = ROW_COUNT;

  UPDATE public.bit24_exchange_sync_requests q
  SET processed_at = now(),
      http_status = r.status_code,
      error_message = left(r.error_msg, 500)
  FROM net._http_response r
  WHERE r.id = q.request_id
    AND q.processed_at IS NULL;

  GET DIAGNOSTICS p = ROW_COUNT;

  WITH candidates AS (
    SELECT
      o.id,
      ca.coingecko_id,
      count(ca.coingecko_id) OVER (PARTITION BY o.id) AS candidate_count
    FROM public.exchange_asset_observations o
    JOIN public.crypto_assets ca
      ON upper(ca.symbol) = upper(o.base_symbol)
     AND ca.is_active IS TRUE
    WHERE o.exchange = 'bit24'
      AND o.is_active IS TRUE
      AND o.asset_name IS NOT NULL
      AND (
        regexp_replace(lower(o.asset_name), '[^a-z0-9]', '', 'g')
          = regexp_replace(lower(ca.name), '[^a-z0-9]', '', 'g')
        OR (
          length(regexp_replace(lower(o.asset_name), '[^a-z0-9]', '', 'g')) >= 5
          AND length(regexp_replace(lower(ca.name), '[^a-z0-9]', '', 'g')) >= 5
          AND (
            regexp_replace(lower(o.asset_name), '[^a-z0-9]', '', 'g')
              LIKE '%' || regexp_replace(lower(ca.name), '[^a-z0-9]', '', 'g') || '%'
            OR regexp_replace(lower(ca.name), '[^a-z0-9]', '', 'g')
              LIKE '%' || regexp_replace(lower(o.asset_name), '[^a-z0-9]', '', 'g') || '%'
          )
        )
      )
  ),
  chosen AS (
    SELECT
      id,
      min(coingecko_id) FILTER (WHERE candidate_count = 1) AS coingecko_id,
      max(candidate_count) AS candidate_count
    FROM candidates
    GROUP BY id
  )
  UPDATE public.exchange_asset_observations o
  SET
    coingecko_id = c.coingecko_id,
    match_status = CASE
      WHEN c.candidate_count = 1 THEN 'matched'
      WHEN c.candidate_count > 1 THEN 'ambiguous'
      ELSE 'pending'
    END
  FROM chosen c
  WHERE o.id = c.id
    AND (
      o.coingecko_id IS DISTINCT FROM c.coingecko_id
      OR o.match_status IS DISTINCT FROM CASE
        WHEN c.candidate_count = 1 THEN 'matched'
        WHEN c.candidate_count > 1 THEN 'ambiguous'
        ELSE 'pending'
      END
    );

  UPDATE public.exchange_asset_observations o
  SET coingecko_id = NULL, match_status = 'unmatched'
  WHERE o.exchange = 'bit24'
    AND o.is_active IS TRUE
    AND o.asset_name IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM public.crypto_assets ca
      WHERE upper(ca.symbol) = upper(o.base_symbol)
        AND ca.is_active IS TRUE
    )
    AND (o.coingecko_id IS NOT NULL OR o.match_status IS DISTINCT FROM 'unmatched');

  RETURN jsonb_build_object('processed_requests', p, 'upserted_rows', n);
END;
$function$;

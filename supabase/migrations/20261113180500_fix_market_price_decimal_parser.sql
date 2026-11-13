CREATE OR REPLACE FUNCTION public.refresh_market_prices()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'pg_catalog'
AS $function$
DECLARE
  r record;
  v_map record;
  v_request_id bigint;
  v_ids text;
  v_price_text text;
  v_price numeric;
BEGIN
  IF NOT pg_catalog.pg_try_advisory_xact_lock(742019, 13) THEN
    RETURN;
  END IF;

  FOR r IN
    SELECT q.request_id, h.status_code, h.content, h.timed_out, h.error_msg
    FROM private.market_price_sync_requests AS q
    JOIN net._http_response AS h ON h.id = q.request_id
  LOOP
    IF r.status_code = 200
       AND COALESCE(r.timed_out, false) = false
       AND r.content IS NOT NULL THEN
      BEGIN
        FOR v_map IN
          SELECT dp.pair_symbol AS symbol, dp.base_coingecko_id AS coingecko_id
          FROM public.demo_trading_pairs AS dp
          WHERE dp.is_enabled IS TRUE
          UNION
          SELECT pg_catalog.upper(ca.symbol) || 'USDT', ca.coingecko_id
          FROM public.admin_market_listings AS l
          JOIN public.crypto_assets AS ca ON ca.coingecko_id = l.coingecko_id
          WHERE ca.is_active IS TRUE
        LOOP
          v_price_text := r.content::jsonb -> v_map.coingecko_id ->> 'usd';
          IF v_price_text ~ '^[0-9]+(\.[0-9]+)?$' THEN
            v_price := v_price_text::numeric;
            IF v_price > 0 THEN
              INSERT INTO public.market_prices(symbol, price, source, updated_at)
              VALUES (v_map.symbol, v_price, 'CoinGecko', now())
              ON CONFLICT (symbol) DO UPDATE
              SET price = EXCLUDED.price,
                  source = EXCLUDED.source,
                  updated_at = EXCLUDED.updated_at;
            END IF;
          END IF;
        END LOOP;
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'CoinGecko market-price response processing failed: %', SQLERRM;
      END;
    ELSE
      RAISE WARNING 'CoinGecko market-price request failed. Status: %, Error: %',
        r.status_code, r.error_msg;
    END IF;

    DELETE FROM private.market_price_sync_requests
    WHERE request_id = r.request_id;
  END LOOP;

  DELETE FROM private.market_price_sync_requests
  WHERE queued_at < now() - interval '10 minutes';

  SELECT pg_catalog.string_agg(x.coingecko_id, ',' ORDER BY x.coingecko_id)
  INTO v_ids
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
  ) AS x;

  IF v_ids IS NULL OR v_ids = '' THEN
    RETURN;
  END IF;

  v_request_id := net.http_get(
    url := 'https://api.coingecko.com/api/v3/simple/price?ids='
      || v_ids || '&vs_currencies=usd',
    timeout_milliseconds := 20000
  );

  INSERT INTO private.market_price_sync_requests(request_id)
  VALUES (v_request_id)
  ON CONFLICT DO NOTHING;
END;
$function$;
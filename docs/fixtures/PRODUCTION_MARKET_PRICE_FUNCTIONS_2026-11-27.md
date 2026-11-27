# Production market-price scheduler source capture

> **Evidence-only fixture.** Captured from the linked Supabase Production database using read-only `pg_get_functiondef` and `cron.job` SELECT queries on 2026-11-27. This document is not a migration and must never be applied to Production. No secrets or row-level user data are included.

## Scheduler metadata

| jobid | jobname | schedule | command | active |
|---:|---|---|---|---|
| 3 | digiarz-market-price-refresh | `* * * * *` | `SELECT public.refresh_market_prices();` | true |
| 17 | digiarz-market-price-overflow | `5-59/10 * * * *` | `SELECT private.request_market_price_overflow();` | true |

## Function fingerprints

| Function | MD5 of exact `pg_get_functiondef(oid)` output |
|---|---|
| `private.request_market_price_overflow()` | `e6ed136175b0d340c9a86e51f7917a76` |
| `public.refresh_market_prices()` | `3788666d57957a66bf59031f54ceff03` |

## Captured function definitions

The definitions below are preserved verbatim from the read-only result. Keep them separate from candidate implementations and do not silently normalize or edit them.

### private.request_market_price_overflow()

```sql
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
$function$
```

### public.refresh_market_prices()

```sql
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
$function$
```

## Interpretation boundary

- The fingerprints identify the exact function-definition strings returned by the capture query at retrieval time. They are provenance markers, not cryptographic signatures.
- The scheduler metadata proves the configured cron cadence at capture time, not the exact wall-clock interleaving of historical invocations.
- A disposable regression based on these bodies can demonstrate the starvation interleaving under controlled queue states. It cannot retroactively prove which exact historical request omitted each stale asset because requested-ID batch history was not durably retained.
- Never run this document as a migration. Any test harness must extract the fenced function bodies into an isolated PostgreSQL 17 instance and stub HTTP/network dependencies.

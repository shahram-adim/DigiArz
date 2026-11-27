-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: refresh_market_prices()
-- PostgreSQL md5(pg_get_functiondef(...)): 3788666d57957a66bf59031f54ceff03
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=pg_catalog; EXECUTE anon=false, authenticated=false, service_role=false.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
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

  -- Back-pressure: do not enqueue another provider batch while earlier
  -- market-price requests remain queued or tracked. This also catches
  -- orphaned queue entries created by the previous stale-row cleanup.
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

  -- The overflow cron fetches all remaining IDs after this first stable batch.
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
;

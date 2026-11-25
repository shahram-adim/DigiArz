# Recovered Production Migration Sources — 2026-11-21

Status: source recovery only; NOT executable rollout instructions.

Reproduced from the Production `supabase_migrations.schema_migrations.statements` column on 2026-11-25. These files preserve historical source for review. Do not replay against Production. The backpressure migration replaces several live function definitions; the throttle migration changes Cron schedules. Any replay requires isolated testing and explicit owner approval.

## 20261121045434 — digiarz_backpressure_and_exchange_sync_bloat_guards

```sql

CREATE INDEX IF NOT EXISTS crypto_assets_upper_symbol_active_idx
ON public.crypto_assets (upper(symbol))
WHERE is_active IS TRUE;

DO $patch$
DECLARE
  v_def text;
  v_old text;
  v_new text;
BEGIN
  -- Market prices: keep request IDs until response/queue is truly gone;
  -- apply back-pressure when legacy or newly queued provider requests exist.
  v_def := pg_get_functiondef('public.refresh_market_prices()'::regprocedure);
  v_old := $old$  DELETE FROM private.market_price_sync_requests WHERE queued_at<now()-interval '10 minutes';

  -- The overflow cron fetches all remaining IDs after this first stable batch.$old$;
  v_new := $new$  DELETE FROM private.market_price_sync_requests q
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

  -- The overflow cron fetches all remaining IDs after this first stable batch.$new$;
  IF position(v_old in v_def) = 0 THEN
    RAISE EXCEPTION 'Expected market-price cleanup block not found; migration aborted';
  END IF;
  v_def := replace(v_def, v_old, v_new);
  EXECUTE v_def;

  -- Overflow CoinGecko batches must wait for the previous batch to clear.
  v_def := pg_get_functiondef('private.request_market_price_overflow()'::regprocedure);
  v_old := $old$  -- Keep overflow scheduling separate from the primary price-refresh lock.
  IF NOT pg_catalog.pg_try_advisory_xact_lock(742019, 14) THEN
    RETURN 0;
  END IF;

  -- The primary refresh request already asks for the first 515 sorted IDs.$old$;
  v_new := $new$  -- Keep overflow scheduling separate from the primary price-refresh lock.
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

  -- The primary refresh request already asks for the first 515 sorted IDs.$new$;
  IF position(v_old in v_def) = 0 THEN
    RAISE EXCEPTION 'Expected overflow lock block not found; migration aborted';
  END IF;
  v_def := replace(v_def, v_old, v_new);
  EXECUTE v_def;

  -- FX: do not enqueue repeated requests while an earlier request is pending.
  v_def := pg_get_functiondef('public.refresh_market_fx_rate()'::regprocedure);
  v_old := $old$    -- اگر نرخ بیش از ۲۰ دقیقه قدیمی شد، آن را کهنه علامت بزن$old$;
  v_new := $new$    -- Retry only when a request has genuinely disappeared from
    -- both pg_net tables; never orphan a request that is still queued.
    DELETE FROM private.market_fx_sync_requests q
    WHERE q.processed_at IS NULL
      AND q.queued_at < NOW() - INTERVAL '30 minutes'
      AND NOT EXISTS (SELECT 1 FROM net.http_request_queue nq WHERE nq.id = q.request_id)
      AND NOT EXISTS (SELECT 1 FROM net._http_response h WHERE h.id = q.request_id);

    -- اگر نرخ بیش از ۲۰ دقیقه قدیمی شد، آن را کهنه علامت بزن$new$;
  IF position(v_old in v_def) = 0 THEN
    RAISE EXCEPTION 'Expected FX cleanup insertion point not found; migration aborted';
  END IF;
  v_def := replace(v_def, v_old, v_new);
  v_old := $old$    IF NOT EXISTS (
        SELECT 1
        FROM private.market_fx_sync_state
        WHERE id = TRUE
          AND last_requested_at > NOW() - INTERVAL '10 minutes'
    )$old$;
  v_new := $new$    IF NOT EXISTS (
        SELECT 1
        FROM private.market_fx_sync_state
        WHERE id = TRUE
          AND last_requested_at > NOW() - INTERVAL '10 minutes'
    )
    AND NOT EXISTS (
        SELECT 1 FROM private.market_fx_sync_requests q
        WHERE q.processed_at IS NULL
    )$new$;
  IF position(v_old in v_def) = 0 THEN
    RAISE EXCEPTION 'Expected FX request throttle not found; migration aborted';
  END IF;
  v_def := replace(v_def, v_old, v_new);
  EXECUTE v_def;

  -- Iranian exchange discovery: preserve pending IDs and stop duplicate requests.
  v_def := pg_get_functiondef('public.request_iran_exchange_asset_sync()'::regprocedure);
  v_old := $old$begin
  select net.http_get('https://apiv2.nobitex.ir/v2/options'$old$;
  v_new := $new$begin
  DELETE FROM public.exchange_asset_sync_requests q
  WHERE q.processed_at IS NULL
    AND q.requested_at < now() - interval '30 minutes'
    AND NOT EXISTS (SELECT 1 FROM net.http_request_queue nq WHERE nq.id = q.request_id)
    AND NOT EXISTS (SELECT 1 FROM net._http_response h WHERE h.id = q.request_id);

  IF EXISTS (
    SELECT 1 FROM public.exchange_asset_sync_requests q
    WHERE q.processed_at IS NULL
  ) THEN
    RETURN 0;
  END IF;

  select net.http_get('https://apiv2.nobitex.ir/v2/options'$new$;
  IF position(v_old in v_def) = 0 THEN
    RAISE EXCEPTION 'Expected Iranian exchange request block not found; migration aborted';
  END IF;
  v_def := replace(v_def, v_old, v_new);
  EXECUTE v_def;

  -- Bit24 discovery: same pending-request protection.
  v_def := pg_get_functiondef('public.request_bit24_exchange_sync()'::regprocedure);
  v_old := $old$begin
 for p in 1..4 loop$old$;
  v_new := $new$begin
 DELETE FROM public.bit24_exchange_sync_requests q
 WHERE q.processed_at IS NULL
   AND q.requested_at < now() - interval '30 minutes'
   AND NOT EXISTS (SELECT 1 FROM net.http_request_queue nq WHERE nq.id = q.request_id)
   AND NOT EXISTS (SELECT 1 FROM net._http_response h WHERE h.id = q.request_id);

 IF EXISTS (
   SELECT 1 FROM public.bit24_exchange_sync_requests q
   WHERE q.processed_at IS NULL
 ) THEN
   RETURN 0;
 END IF;

 for p in 1..4 loop$new$;
  IF position(v_old in v_def) = 0 THEN
    RAISE EXCEPTION 'Expected Bit24 request block not found; migration aborted';
  END IF;
  v_def := replace(v_def, v_old, v_new);
  EXECUTE v_def;

  -- Crypto-assets recovery must not delete a request still present in pg_net.
  v_def := pg_get_functiondef('public.recover_stale_crypto_assets_sync()'::regprocedure);
  v_old := $old$  WHERE h.id IS NULL
    AND q.queued_at < pg_catalog.now() - interval '2 minutes';$old$;
  v_new := $new$  WHERE h.id IS NULL
    AND q.queued_at < pg_catalog.now() - interval '2 minutes'
    AND NOT EXISTS (
      SELECT 1 FROM net.http_request_queue nq WHERE nq.id = q.request_id
    );$new$;
  IF position(v_old in v_def) = 0 THEN
    RAISE EXCEPTION 'Expected crypto-assets retry selection not found; migration aborted';
  END IF;
  v_def := replace(v_def, v_old, v_new);
  v_old := $old$    AND NOT EXISTS (
      SELECT 1
      FROM net._http_response AS h
      WHERE h.id = q.request_id
    );$old$;
  v_new := $new$    AND NOT EXISTS (
      SELECT 1
      FROM net._http_response AS h
      WHERE h.id = q.request_id
    )
    AND NOT EXISTS (
      SELECT 1 FROM net.http_request_queue nq WHERE nq.id = q.request_id
    );$new$;
  IF position(v_old in v_def) = 0 THEN
    RAISE EXCEPTION 'Expected crypto-assets stale-delete predicate not found; migration aborted';
  END IF;
  v_def := replace(v_def, v_old, v_new);
  EXECUTE v_def;

  -- Iranian exchange processing: avoid rewriting identical observation rows.
  v_def := pg_get_functiondef('public.process_iran_exchange_asset_sync()'::regprocedure);
  v_old := $old$ on conflict(exchange,market_symbol) do update set base_symbol=excluded.base_symbol,quote_symbol=excluded.quote_symbol,
 asset_name=coalesce(excluded.asset_name,public.exchange_asset_observations.asset_name),source_payload=excluded.source_payload,is_active=excluded.is_active,last_seen_at=now();$old$;
  v_new := $new$ on conflict(exchange,market_symbol) do update set base_symbol=excluded.base_symbol,quote_symbol=excluded.quote_symbol,
 asset_name=coalesce(excluded.asset_name,public.exchange_asset_observations.asset_name),source_payload=excluded.source_payload,is_active=excluded.is_active,last_seen_at=now()
 WHERE public.exchange_asset_observations.base_symbol IS DISTINCT FROM EXCLUDED.base_symbol
    OR public.exchange_asset_observations.quote_symbol IS DISTINCT FROM EXCLUDED.quote_symbol
    OR public.exchange_asset_observations.asset_name IS DISTINCT FROM COALESCE(EXCLUDED.asset_name,public.exchange_asset_observations.asset_name)
    OR public.exchange_asset_observations.source_payload IS DISTINCT FROM EXCLUDED.source_payload
    OR public.exchange_asset_observations.is_active IS DISTINCT FROM EXCLUDED.is_active
    OR public.exchange_asset_observations.last_seen_at IS NULL
    OR public.exchange_asset_observations.last_seen_at < now() - interval '30 minutes';$new$;
  IF position(v_old in v_def) = 0 THEN
    RAISE EXCEPTION 'Expected Iranian observation upsert not found; migration aborted';
  END IF;
  v_def := replace(v_def, v_old, v_new);

  v_old := $old$ from chosen c where o.id=c.id;$old$;
  v_new := $new$ from chosen c where o.id=c.id
  and (
    o.coingecko_id IS DISTINCT FROM c.coingecko_id
    OR o.match_status IS DISTINCT FROM CASE
      WHEN c.candidate_count=1 THEN 'matched'
      WHEN c.candidate_count>1 THEN 'ambiguous'
      ELSE 'pending'
    END
  );$new$;
  IF position(v_old in v_def) = 0 THEN
    RAISE EXCEPTION 'Expected Iranian match update not found; migration aborted';
  END IF;
  v_def := replace(v_def, v_old, v_new);

  v_old := $old$    and regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')=regexp_replace(lower(ca.name),'[^a-z0-9]','','g')
  ));$old$;
  v_new := $new$    and regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')=regexp_replace(lower(ca.name),'[^a-z0-9]','','g')
  ))
  and (o.coingecko_id IS NOT NULL OR o.match_status IS DISTINCT FROM 'unmatched');$new$;
  IF position(v_old in v_def) = 0 THEN
    RAISE EXCEPTION 'Expected Iranian unmatched update not found; migration aborted';
  END IF;
  v_def := replace(v_def, v_old, v_new);
  EXECUTE v_def;

  -- Bit24 processing: same no-op update protection.
  v_def := pg_get_functiondef('public.process_bit24_exchange_sync()'::regprocedure);
  v_old := $old$ source_payload=excluded.source_payload,is_active=excluded.is_active,last_seen_at=now();$old$;
  v_new := $new$ source_payload=excluded.source_payload,is_active=excluded.is_active,last_seen_at=now()
 WHERE public.exchange_asset_observations.base_symbol IS DISTINCT FROM EXCLUDED.base_symbol
    OR public.exchange_asset_observations.quote_symbol IS DISTINCT FROM EXCLUDED.quote_symbol
    OR public.exchange_asset_observations.asset_name IS DISTINCT FROM COALESCE(EXCLUDED.asset_name,public.exchange_asset_observations.asset_name)
    OR public.exchange_asset_observations.source_payload IS DISTINCT FROM EXCLUDED.source_payload
    OR public.exchange_asset_observations.is_active IS DISTINCT FROM EXCLUDED.is_active
    OR public.exchange_asset_observations.last_seen_at IS NULL
    OR public.exchange_asset_observations.last_seen_at < now() - interval '30 minutes';$new$;
  IF position(v_old in v_def) = 0 THEN
    RAISE EXCEPTION 'Expected Bit24 observation upsert not found; migration aborted';
  END IF;
  v_def := replace(v_def, v_old, v_new);

  v_old := $old$ from chosen c where o.id=c.id;$old$;
  v_new := $new$ from chosen c where o.id=c.id
 and (
  o.coingecko_id IS DISTINCT FROM c.coingecko_id
  OR o.match_status IS DISTINCT FROM CASE
   WHEN c.candidate_count=1 THEN 'matched'
   WHEN c.candidate_count>1 THEN 'ambiguous'
   ELSE 'pending'
  END
 );$new$;
  IF position(v_old in v_def) = 0 THEN
    RAISE EXCEPTION 'Expected Bit24 match update not found; migration aborted';
  END IF;
  v_def := replace(v_def, v_old, v_new);

  v_old := $old$ and not exists(select 1 from public.crypto_assets ca where upper(ca.symbol)=upper(o.base_symbol) and ca.is_active is true);$old$;
  v_new := $new$ and not exists(select 1 from public.crypto_assets ca where upper(ca.symbol)=upper(o.base_symbol) and ca.is_active is true)
 and (o.coingecko_id is not null or o.match_status is distinct from 'unmatched');$new$;
  IF position(v_old in v_def) = 0 THEN
    RAISE EXCEPTION 'Expected Bit24 unmatched update not found; migration aborted';
  END IF;
  v_def := replace(v_def, v_old, v_new);
  EXECUTE v_def;
END
$patch$;

```

## 20261121045531 — snapshot_pg_net_unlogged_queue_before_recovery

```sql

CREATE TABLE private.digiarz_pg_net_queue_backup_20261121 AS
SELECT clock_timestamp() AS captured_at, q.*
FROM net.http_request_queue q;

CREATE TABLE private.digiarz_pg_net_response_backup_20261121 AS
SELECT clock_timestamp() AS captured_at, r.*
FROM net._http_response r;

```

## 20261121050216 — temporarily_throttle_exchange_asset_processors_20261121

```sql
select cron.alter_job(14, schedule := '1,31 * * * *');
select cron.alter_job(16, schedule := '16,46 * * * *');
```

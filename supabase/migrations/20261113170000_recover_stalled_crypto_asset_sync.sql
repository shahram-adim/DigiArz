-- Recover CoinGecko asset-catalog requests that never produced an HTTP response.
-- Serialize with refresh_crypto_assets() using the same transaction advisory lock.
CREATE OR REPLACE FUNCTION public.recover_stale_crypto_assets_sync()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_retry_page integer;
BEGIN
  PERFORM pg_catalog.pg_advisory_xact_lock(20261108, 500);

  SELECT min(q.page_number)
    INTO v_retry_page
  FROM private.crypto_assets_sync_requests AS q
  LEFT JOIN net._http_response AS h
    ON h.id = q.request_id
  WHERE h.id IS NULL
    AND q.queued_at < pg_catalog.now() - interval '2 minutes';

  DELETE FROM private.crypto_assets_sync_requests AS q
  WHERE q.queued_at < pg_catalog.now() - interval '2 minutes'
    AND NOT EXISTS (
      SELECT 1
      FROM net._http_response AS h
      WHERE h.id = q.request_id
    );

  IF v_retry_page IS NOT NULL THEN
    UPDATE private.crypto_assets_sync_state
       SET next_page = pg_catalog.least(next_page, v_retry_page),
           scan_complete = false,
           updated_at = pg_catalog.now()
     WHERE singleton = true;
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION public.recover_stale_crypto_assets_sync() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.recover_stale_crypto_assets_sync() TO postgres;

DO $block$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM cron.job
    WHERE jobname = 'digiarz-crypto-assets-stale-request-recovery'
  ) THEN
    PERFORM cron.schedule(
      'digiarz-crypto-assets-stale-request-recovery',
      '* * * * *',
      'SELECT public.recover_stale_crypto_assets_sync();'
    );
  END IF;
END;
$block$;

-- Recover the already-stalled page immediately; the existing refresh job
-- will enqueue that page again on its next minute.
SELECT public.recover_stale_crypto_assets_sync();

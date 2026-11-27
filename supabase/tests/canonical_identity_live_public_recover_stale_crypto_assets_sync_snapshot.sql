-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: recover_stale_crypto_assets_sync()
-- PostgreSQL md5(pg_get_functiondef(...)): 9ab6efcdb72cce454244f81aecc1da86
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=false, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.recover_stale_crypto_assets_sync()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
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
    AND q.queued_at < pg_catalog.now() - interval '2 minutes'
    AND NOT EXISTS (
      SELECT 1 FROM net.http_request_queue nq WHERE nq.id = q.request_id
    );

  DELETE FROM private.crypto_assets_sync_requests AS q
  WHERE q.queued_at < pg_catalog.now() - interval '2 minutes'
    AND NOT EXISTS (
      SELECT 1
      FROM net._http_response AS h
      WHERE h.id = q.request_id
    )
    AND NOT EXISTS (
      SELECT 1 FROM net.http_request_queue nq WHERE nq.id = q.request_id
    );

  IF v_retry_page IS NOT NULL THEN
    UPDATE private.crypto_assets_sync_state
       SET next_page = CASE WHEN next_page < v_retry_page THEN next_page ELSE v_retry_page END,
           scan_complete = false,
           updated_at = pg_catalog.now()
     WHERE singleton = true;
  END IF;
END;
$function$
;

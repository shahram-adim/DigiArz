-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: request_market_price_refresh()
-- PostgreSQL md5(pg_get_functiondef(...)): 140cb90d5a73059155d04fac4b309f4e
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.request_market_price_refresh()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_last timestamptz;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING errcode = '42501';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = v_uid AND p.is_active IS TRUE
  ) THEN
    RAISE EXCEPTION 'Active account required' USING errcode = '42501';
  END IF;

  SELECT c.last_requested_at INTO v_last
  FROM private.market_price_refresh_control c
  WHERE c.id IS TRUE
  FOR UPDATE;

  IF v_last > now() - interval '30 seconds' THEN
    RAISE EXCEPTION 'Market refresh was requested recently; wait before trying again';
  END IF;

  UPDATE private.market_price_refresh_control
  SET last_requested_at = now()
  WHERE id IS TRUE;

  PERFORM public.refresh_market_prices();

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Market price refresh queued',
    'minimum_interval_seconds', 30
  );
END;
$function$
;

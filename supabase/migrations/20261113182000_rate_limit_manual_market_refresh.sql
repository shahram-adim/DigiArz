CREATE TABLE IF NOT EXISTS private.market_price_refresh_control (
  id boolean PRIMARY KEY DEFAULT true CHECK (id IS TRUE),
  last_requested_at timestamptz NOT NULL DEFAULT now() - interval '1 hour'
);
ALTER TABLE private.market_price_refresh_control ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.market_price_refresh_control FROM PUBLIC, anon, authenticated, service_role;
INSERT INTO private.market_price_refresh_control(id)
VALUES(true)
ON CONFLICT(id) DO NOTHING;

-- The scheduled job and this guarded RPC are the only supported entry points.
REVOKE ALL ON FUNCTION public.refresh_market_prices() FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.request_market_price_refresh()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
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
$function$;

REVOKE ALL ON FUNCTION public.request_market_price_refresh() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.request_market_price_refresh() TO authenticated;
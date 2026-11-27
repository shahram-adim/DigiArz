-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: admin_disable_market_pair(text,text)
-- PostgreSQL md5(pg_get_functiondef(...)): 07ff2862b133f6dbeb3c0cf5d33c5878
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.admin_disable_market_pair(p_coingecko_id text, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_admin uuid := auth.uid();
  v_pair public.demo_trading_pairs%ROWTYPE;
  v_cancelled integer := 0;
  v_released integer := 0;
BEGIN
  IF v_admin IS NULL OR NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'Super administrator access required' USING errcode = '42501';
  END IF;
  IF p_coingecko_id IS NULL THEN
    RAISE EXCEPTION 'CoinGecko asset id is required';
  END IF;

  SELECT * INTO v_pair
  FROM public.demo_trading_pairs
  WHERE base_coingecko_id = pg_catalog.btrim(p_coingecko_id)
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trading pair not found';
  END IF;

  -- Cancel all outstanding conditional exits first so the worker cannot
  -- execute a trigger after the pair has been disabled.
  UPDATE public.conditional_orders AS co
  SET status = 'cancelled',
      last_error = 'Pair disabled by administrator',
      updated_at = now()
  FROM public.orders AS o
  WHERE co.order_id = o.id
    AND o.symbol = v_pair.pair_symbol
    AND o.order_type = 'conditional'
    AND o.status IN ('pending','partially_filled')
    AND co.status = 'pending';

  UPDATE public.order_reservations AS r
  SET released_amount = r.reserved_amount - r.consumed_amount,
      status = CASE WHEN r.consumed_amount >= r.reserved_amount THEN 'consumed' ELSE 'released' END,
      updated_at = now()
  FROM public.orders AS o
  WHERE r.order_id = o.id
    AND o.symbol = v_pair.pair_symbol
    AND o.order_type IN ('limit','conditional')
    AND o.status IN ('pending','partially_filled')
    AND r.status = 'reserved';

  GET DIAGNOSTICS v_released = ROW_COUNT;

  UPDATE public.orders
  SET status = 'cancelled',
      remaining_amount = amount - filled_amount
  WHERE symbol = v_pair.pair_symbol
    AND order_type IN ('limit','conditional')
    AND status IN ('pending','partially_filled');

  GET DIAGNOSTICS v_cancelled = ROW_COUNT;

  UPDATE public.demo_trading_pairs
  SET is_enabled = false, updated_at = now()
  WHERE pair_symbol = v_pair.pair_symbol;

  INSERT INTO private.market_pair_admin_audit(
    pair_symbol, coingecko_id, action, admin_user_id, reason, validation_snapshot
  )
  VALUES(v_pair.pair_symbol, v_pair.base_coingecko_id, 'disabled', v_admin,
         pg_catalog.left(COALESCE(p_reason, 'Disabled by super administrator'), 500),
         pg_catalog.jsonb_build_object(
           'cancelled_open_orders', v_cancelled,
           'reservations_released', v_released
         ));

  RETURN pg_catalog.jsonb_build_object(
    'success', true,
    'pair_symbol', v_pair.pair_symbol,
    'status', 'disabled',
    'cancelled_open_orders', v_cancelled,
    'reservations_released', v_released
  );
END;
$function$
;

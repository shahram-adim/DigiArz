-- DRAFT ONLY: trusted reconciliation of Reduce-only reservations after
-- an external position reduction has already been applied in the same transaction.
-- Never call this without the account mutex and position mutation protocol.
BEGIN;

CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.reconcile_demo_reduce_only_reservations(
  p_position_id uuid
)
RETURNS uuid[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_account_id uuid;
  v_user_id uuid;
  v_position public.demo_derivative_positions%ROWTYPE;
  v_order record;
  v_reserved numeric(38,18);
  v_cancelled_order_ids uuid[] := ARRAY[]::uuid[];
BEGIN
  IF p_position_id IS NULL THEN
    RAISE EXCEPTION 'Position id is required' USING ERRCODE='22023';
  END IF;

  -- Discover ownership without locking a child row; all writers serialize
  -- through the account row before locking positions or orders.
  SELECT p.account_id,p.user_id
    INTO v_account_id,v_user_id
  FROM public.demo_derivative_positions AS p
  WHERE p.id=p_position_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Derivative position not found' USING ERRCODE='P0002';
  END IF;

  PERFORM 1
  FROM public.demo_derivative_accounts AS a
  WHERE a.id=v_account_id AND a.user_id=v_user_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Derivative account not found' USING ERRCODE='P0002';
  END IF;

  SELECT p.* INTO v_position
  FROM public.demo_derivative_positions AS p
  WHERE p.id=p_position_id
    AND p.account_id=v_account_id
    AND p.user_id=v_user_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Derivative position not found' USING ERRCODE='P0002';
  END IF;

  SELECT COALESCE(sum(o.remaining_quantity),0)::numeric(38,18)
    INTO v_reserved
  FROM public.demo_derivative_orders AS o
  WHERE o.account_id=v_account_id
    AND o.user_id=v_user_id
    AND o.product_type=v_position.product_type
    AND o.symbol=v_position.symbol
    AND o.position_side=v_position.position_side
    AND o.reduce_only
    AND o.status IN ('pending','partially_filled');

  IF v_reserved<=v_position.quantity THEN
    RETURN v_cancelled_order_ids;
  END IF;

  -- Cancel newest active reservations first. The account mutex prevents
  -- placement/fill/cancel races while this deterministic order is reconciled.
  FOR v_order IN
    SELECT o.id,o.remaining_quantity
    FROM public.demo_derivative_orders AS o
    WHERE o.account_id=v_account_id
      AND o.user_id=v_user_id
      AND o.product_type=v_position.product_type
      AND o.symbol=v_position.symbol
      AND o.position_side=v_position.position_side
      AND o.reduce_only
      AND o.status IN ('pending','partially_filled')
    ORDER BY o.created_at DESC,o.id DESC
    FOR UPDATE
  LOOP
    EXIT WHEN v_reserved<=v_position.quantity;

    UPDATE public.demo_derivative_orders
    SET status='cancelled',updated_at=now()
    WHERE id=v_order.id
      AND account_id=v_account_id
      AND user_id=v_user_id
      AND status IN ('pending','partially_filled');

    IF FOUND THEN
      v_reserved := v_reserved-v_order.remaining_quantity;
      v_cancelled_order_ids := array_append(v_cancelled_order_ids,v_order.id);
    END IF;
  END LOOP;

  IF v_reserved>v_position.quantity THEN
    RAISE EXCEPTION 'Reduce-only reservation reconciliation could not restore invariant'
      USING ERRCODE='23514';
  END IF;

  RETURN v_cancelled_order_ids;
END;
$function$;

REVOKE ALL ON FUNCTION private.reconcile_demo_reduce_only_reservations(uuid)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.reconcile_demo_reduce_only_reservations(uuid)
  TO service_role;
GRANT USAGE ON SCHEMA private TO service_role;

CREATE OR REPLACE FUNCTION public.reconcile_demo_reduce_only_reservations(
  p_position_id uuid
)
RETURNS uuid[]
LANGUAGE sql
SECURITY INVOKER
SET search_path TO ''
AS $function$
  SELECT private.reconcile_demo_reduce_only_reservations(p_position_id);
$function$;

REVOKE ALL ON FUNCTION public.reconcile_demo_reduce_only_reservations(uuid)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.reconcile_demo_reduce_only_reservations(uuid)
  TO service_role;

COMMIT;

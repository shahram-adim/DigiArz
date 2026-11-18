-- DRAFT ONLY: account-serialized Reduce-only Limit placement and cancellation.
-- Apply only to a disposable PostgreSQL database after the derivatives schema draft.
-- These are not Production migrations and do not activate any client UI.

BEGIN;

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon;
GRANT USAGE ON SCHEMA private TO authenticated;

CREATE OR REPLACE FUNCTION private.place_demo_reduce_only_limit_order(
  p_account_id uuid,
  p_symbol text,
  p_position_side text,
  p_quantity numeric,
  p_limit_price numeric,
  p_client_request_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_user_id uuid;
  v_account_id uuid;
  v_position_id uuid;
  v_product_type text;
  v_leverage integer;
  v_margin_mode text;
  v_position_quantity numeric(38,18);
  v_reserved_quantity numeric(38,18);
  v_side text;
  v_existing public.demo_derivative_orders%ROWTYPE;
  v_order_id uuid;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000';
  END IF;
  IF p_quantity IS NULL OR p_quantity <= 0 OR
     p_limit_price IS NULL OR p_limit_price <= 0 OR
     p_client_request_id IS NULL OR
     p_position_side NOT IN ('long','short') THEN
    RAISE EXCEPTION 'Invalid Reduce-only Limit order arguments'
      USING ERRCODE='22023';
  END IF;

  -- Serialize every derivatives mutation for this user/account first.
  SELECT a.id INTO v_account_id
  FROM public.demo_derivative_accounts AS a
  WHERE a.id=p_account_id AND a.user_id=v_user_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Derivative account not found' USING ERRCODE='P0002';
  END IF;

  v_side := CASE p_position_side WHEN 'long' THEN 'sell' ELSE 'buy' END;

  -- Idempotency is evaluated while holding the account mutex.
  SELECT o.* INTO v_existing
  FROM public.demo_derivative_orders AS o
  WHERE o.user_id=v_user_id AND o.client_request_id=p_client_request_id;
  IF FOUND THEN
    IF v_existing.account_id<>p_account_id
       OR v_existing.symbol<>p_symbol
       OR v_existing.position_side<>p_position_side
       OR v_existing.side<>v_side
       OR NOT v_existing.reduce_only
       OR v_existing.order_type<>'limit'
       OR v_existing.quantity<>p_quantity
       OR v_existing.limit_price<>p_limit_price THEN
      RAISE EXCEPTION 'Idempotency key reused with different order parameters'
        USING ERRCODE='23505';
    END IF;
    RETURN v_existing.id;
  END IF;

  SELECT p.id,p.product_type,p.leverage,p.margin_mode,p.quantity
    INTO v_position_id,v_product_type,v_leverage,v_margin_mode,v_position_quantity
  FROM public.demo_derivative_positions AS p
  WHERE p.account_id=p_account_id
    AND p.user_id=v_user_id
    AND p.symbol=p_symbol
    AND p.position_side=p_position_side
    AND p.status='open'
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No matching open position to reduce'
      USING ERRCODE='P0002';
  END IF;

  SELECT COALESCE(sum(o.remaining_quantity),0)::numeric(38,18)
    INTO v_reserved_quantity
  FROM public.demo_derivative_orders AS o
  WHERE o.account_id=p_account_id
    AND o.product_type=v_product_type
    AND o.symbol=p_symbol
    AND o.position_side=p_position_side
    AND o.reduce_only
    AND o.status IN ('pending','partially_filled');

  IF p_quantity > v_position_quantity-v_reserved_quantity THEN
    RAISE EXCEPTION 'Reduce-only quantity exceeds unreserved position quantity'
      USING ERRCODE='23514';
  END IF;

  INSERT INTO public.demo_derivative_orders(
    user_id,account_id,product_type,symbol,position_side,side,order_type,
    quantity,limit_price,leverage,margin_mode,reduce_only,
    filled_quantity,remaining_quantity,status,client_request_id
  ) VALUES (
    v_user_id,p_account_id,v_product_type,p_symbol,p_position_side,v_side,'limit',
    p_quantity,p_limit_price,v_leverage,v_margin_mode,true,
    0,p_quantity,'pending',p_client_request_id
  )
  RETURNING id INTO v_order_id;

  RETURN v_order_id;
END;
$function$;

CREATE OR REPLACE FUNCTION private.cancel_demo_reduce_only_order(
  p_order_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_user_id uuid;
  v_account_id uuid;
  v_order public.demo_derivative_orders%ROWTYPE;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000';
  END IF;

  -- Discover the account without locking the order; acquire locks account-first.
  SELECT o.account_id INTO v_account_id
  FROM public.demo_derivative_orders AS o
  WHERE o.id=p_order_id AND o.user_id=v_user_id AND o.reduce_only;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reduce-only order not found' USING ERRCODE='P0002';
  END IF;

  PERFORM 1
  FROM public.demo_derivative_accounts AS a
  WHERE a.id=v_account_id AND a.user_id=v_user_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Derivative account not found' USING ERRCODE='P0002';
  END IF;

  SELECT o.* INTO v_order
  FROM public.demo_derivative_orders AS o
  WHERE o.id=p_order_id AND o.account_id=v_account_id AND o.user_id=v_user_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reduce-only order not found' USING ERRCODE='P0002';
  END IF;

  IF v_order.status NOT IN ('pending','partially_filled') THEN
    RETURN false;
  END IF;

  UPDATE public.demo_derivative_orders
  SET status='cancelled',updated_at=now()
  WHERE id=p_order_id AND user_id=v_user_id;

  -- Reservation is released by the terminal status; cash ledger is untouched.
  RETURN true;
END;
$function$;

REVOKE ALL ON FUNCTION private.place_demo_reduce_only_limit_order(uuid,text,text,numeric,numeric,uuid) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION private.cancel_demo_reduce_only_order(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.place_demo_reduce_only_limit_order(uuid,text,text,numeric,numeric,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.cancel_demo_reduce_only_order(uuid) TO authenticated;

-- Public RPC wrappers are SECURITY INVOKER; privileged writes stay in private helpers.
CREATE OR REPLACE FUNCTION public.place_demo_reduce_only_limit_order(
  p_account_id uuid,
  p_symbol text,
  p_position_side text,
  p_quantity numeric,
  p_limit_price numeric,
  p_client_request_id uuid
)
RETURNS uuid
LANGUAGE sql
SECURITY INVOKER
SET search_path TO ''
AS $function$
  SELECT private.place_demo_reduce_only_limit_order(
    p_account_id,p_symbol,p_position_side,p_quantity,p_limit_price,p_client_request_id
  );
$function$;

CREATE OR REPLACE FUNCTION public.cancel_demo_reduce_only_order(p_order_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path TO ''
AS $function$
  SELECT private.cancel_demo_reduce_only_order(p_order_id);
$function$;

REVOKE ALL ON FUNCTION public.place_demo_reduce_only_limit_order(uuid,text,text,numeric,numeric,uuid) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.cancel_demo_reduce_only_order(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.place_demo_reduce_only_limit_order(uuid,text,text,numeric,numeric,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_demo_reduce_only_order(uuid) TO authenticated;

COMMIT;

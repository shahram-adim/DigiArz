-- Read-only Production source snapshot for Stop-Limit QA, captured 2026-11-26.
-- Source: pg_get_functiondef('public.cancel_limit_order(uuid)'::regprocedure).
-- PostgreSQL md5(pg_get_functiondef(...)): 69360684173b6aabebc5ff4e4de2eed9
-- Verified metadata: owner=postgres; SECURITY DEFINER; search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.cancel_limit_order(p_order_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_order public.orders%ROWTYPE;
    v_rows integer;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    SELECT *
    INTO v_order
    FROM public.orders
    WHERE id = p_order_id
      AND user_id = v_uid
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order not found';
    END IF;

    IF v_order.order_type <> 'limit' THEN
        RAISE EXCEPTION 'Only limit orders can be cancelled here';
    END IF;

    IF v_order.status NOT IN ('pending', 'partially_filled') THEN
        RAISE EXCEPTION 'Order cannot be cancelled';
    END IF;

    UPDATE public.order_reservations
    SET released_amount = reserved_amount - consumed_amount,
        status = CASE
            WHEN consumed_amount >= reserved_amount THEN 'consumed'
            ELSE 'released'
        END,
        updated_at = now()
    WHERE order_id = p_order_id
      AND user_id = v_uid
      AND status = 'reserved'
      AND consumed_amount >= 0
      AND released_amount >= 0
      AND consumed_amount + released_amount <= reserved_amount;

    GET DIAGNOSTICS v_rows = ROW_COUNT;

    IF v_rows <> 1 THEN
        RAISE EXCEPTION
            'Cannot cancel order: exactly one valid active reservation is required';
    END IF;

    UPDATE public.orders
    SET status = 'cancelled',
        remaining_amount = amount - filled_amount
    WHERE id = p_order_id
      AND user_id = v_uid;

    GET DIAGNOSTICS v_rows = ROW_COUNT;

    IF v_rows <> 1 THEN
        RAISE EXCEPTION 'Order cancellation update failed';
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'order_id', p_order_id,
        'status', 'cancelled',
        'filled_amount', v_order.filled_amount,
        'remaining_amount', v_order.amount - v_order.filled_amount
    );
END;
$function$;

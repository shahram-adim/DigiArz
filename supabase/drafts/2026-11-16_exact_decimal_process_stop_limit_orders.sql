-- DRAFT ONLY — DO NOT APPLY TO PRODUCTION.
-- Candidate Stop-Limit worker with child-row locking during parent synchronization.
-- Rehearse with Limit execution and Stop-Limit cancellation before rollout.
CREATE OR REPLACE FUNCTION public.process_stop_limit_orders()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_cond record;
  v_res public.order_reservations%ROWTYPE;
  v_market_price numeric;
  v_result jsonb;
  v_child_id uuid;
  v_attempt integer;
  v_processed integer:=0;
  v_triggered integer:=0;
  v_synced integer:=0;
  v_rejected integer:=0;
  v_skipped integer:=0;
  v_rows integer;
BEGIN
  IF NOT pg_catalog.pg_try_advisory_xact_lock(739201128) THEN
    RETURN jsonb_build_object('success',true,'message','Another Stop-Limit cycle is running','processed',0);
  END IF;

  -- Keep the parent order in sync with its child Limit order after triggering.
  FOR v_cond IN
    SELECT c.id,c.order_id,c.user_id,c.execution_order_id,
           child.status AS child_status,child.filled_amount AS child_filled,
           child.remaining_amount AS child_remaining
    FROM public.conditional_orders c
    JOIN public.orders parent ON parent.id=c.order_id AND parent.user_id=c.user_id
    JOIN public.orders child ON child.id=c.execution_order_id AND child.user_id=c.user_id
    WHERE c.order_kind='stop_limit' AND c.status='triggered'
    ORDER BY c.updated_at
    FOR UPDATE OF c,parent,child SKIP LOCKED
  LOOP
    IF v_cond.child_status IN ('filled','cancelled','rejected') THEN
      UPDATE public.orders
      SET status=v_cond.child_status,
          filled_amount=v_cond.child_filled,
          remaining_amount=v_cond.child_remaining
      WHERE id=v_cond.order_id AND user_id=v_cond.user_id AND status='triggered';
      UPDATE public.conditional_orders
      SET status=v_cond.child_status,updated_at=now()
      WHERE id=v_cond.id AND status='triggered';
    ELSE
      UPDATE public.orders
      SET filled_amount=v_cond.child_filled,
          remaining_amount=v_cond.child_remaining
      WHERE id=v_cond.order_id AND user_id=v_cond.user_id AND status='triggered';
    END IF;
    v_synced:=v_synced+1;
  END LOOP;

  FOR v_cond IN
    SELECT c.id,c.order_id,c.user_id,c.symbol,c.side,c.trigger_price,c.limit_price,c.amount
    FROM public.conditional_orders c
    JOIN public.orders o ON o.id=c.order_id AND o.user_id=c.user_id
    JOIN public.profiles p ON p.id=c.user_id AND p.is_active IS TRUE
    WHERE c.order_kind='stop_limit' AND c.status='pending'
      AND o.status='pending' AND o.order_type='conditional'
    ORDER BY c.created_at
    FOR UPDATE OF c,o SKIP LOCKED
  LOOP
    IF v_cond.symbol IS NULL OR v_cond.symbol !~ '^[A-Z0-9]{2,15}USDT$'
       OR v_cond.side NOT IN ('buy','sell')
       OR v_cond.amount IS NULL OR v_cond.amount<=0
       OR v_cond.trigger_price IS NULL OR v_cond.trigger_price<=0
       OR v_cond.limit_price IS NULL OR v_cond.limit_price<=0
       OR (v_cond.side='buy' AND v_cond.limit_price<v_cond.trigger_price)
       OR (v_cond.side='sell' AND v_cond.limit_price>v_cond.trigger_price) THEN
      v_skipped:=v_skipped+1;
      CONTINUE;
    END IF;

    SELECT mp.price INTO v_market_price
    FROM public.market_prices mp
    WHERE mp.symbol=v_cond.symbol
      AND mp.updated_at>=now()-interval '1 minute'
    FOR SHARE;
    IF NOT FOUND OR v_market_price IS NULL OR v_market_price<=0 THEN
      v_skipped:=v_skipped+1;
      CONTINUE;
    END IF;

    IF (v_cond.side='buy' AND v_market_price<v_cond.trigger_price)
       OR (v_cond.side='sell' AND v_market_price>v_cond.trigger_price) THEN
      v_skipped:=v_skipped+1;
      CONTINUE;
    END IF;

    SELECT * INTO v_res
    FROM public.order_reservations r
    WHERE r.order_id=v_cond.order_id AND r.user_id=v_cond.user_id
    FOR UPDATE;
    IF NOT FOUND OR v_res.status<>'reserved'
       OR v_res.reserved_amount<=0 OR v_res.consumed_amount<0
       OR v_res.released_amount<0
       OR v_res.consumed_amount+v_res.released_amount>v_res.reserved_amount
       OR (v_cond.side='buy' AND v_res.asset<>'USDT')
       OR (v_cond.side='sell' AND v_res.asset<>left(v_cond.symbol,length(v_cond.symbol)-4)) THEN
      UPDATE public.conditional_orders
      SET attempt_count=attempt_count+1,
          last_error='Reservation validation failed; manual review required',
          updated_at=now()
      WHERE id=v_cond.id
      RETURNING attempt_count INTO v_attempt;

      IF v_attempt>=10 THEN
        -- Fail closed: stop retrying, but never release an invalid reservation.
        -- An operator must reconcile ownership and arithmetic before recovery.
        UPDATE public.orders
        SET status='rejected',remaining_amount=amount-filled_amount
        WHERE id=v_cond.order_id AND user_id=v_cond.user_id AND status='pending';

        UPDATE public.conditional_orders
        SET status='rejected',updated_at=now()
        WHERE id=v_cond.id AND status='pending';

        v_rejected:=v_rejected+1;
      ELSE
        v_skipped:=v_skipped+1;
      END IF;
      CONTINUE;
    END IF;

    BEGIN
      -- Release the trigger-stage reservation and create a fresh Limit reservation
      -- atomically. If placing the child order fails, the subtransaction restores it.
      UPDATE public.order_reservations
      SET released_amount=reserved_amount-consumed_amount,
          status='released',updated_at=now()
      WHERE id=v_res.id AND status='reserved';

      PERFORM pg_catalog.set_config('request.jwt.claim.sub',v_cond.user_id::text,true);
      PERFORM pg_catalog.set_config('request.jwt.claims',
        pg_catalog.jsonb_build_object('sub',v_cond.user_id::text,'role','authenticated')::text,true);

      v_result:=public.place_limit_order(v_cond.symbol,v_cond.side,v_cond.amount,v_cond.limit_price);
      IF COALESCE((v_result->>'success')::boolean,false) IS NOT TRUE THEN
        RAISE EXCEPTION 'Limit engine did not confirm Stop-Limit trigger';
      END IF;
      v_child_id:=(v_result->>'order_id')::uuid;
      IF v_child_id IS NULL THEN RAISE EXCEPTION 'Stop-Limit child order id missing'; END IF;

      UPDATE public.orders
      SET status='triggered',filled_amount=0,remaining_amount=amount
      WHERE id=v_cond.order_id AND user_id=v_cond.user_id AND status='pending';
      GET DIAGNOSTICS v_rows=ROW_COUNT;
      IF v_rows<>1 THEN RAISE EXCEPTION 'Stop-Limit parent order update failed'; END IF;

      UPDATE public.conditional_orders
      SET status='triggered',execution_order_id=v_child_id,
          triggered_at=now(),last_error=NULL,updated_at=now()
      WHERE id=v_cond.id AND status='pending';
      GET DIAGNOSTICS v_rows=ROW_COUNT;
      IF v_rows<>1 THEN RAISE EXCEPTION 'Stop-Limit trigger state update failed'; END IF;

      PERFORM pg_catalog.set_config('request.jwt.claim.sub','',true);
      PERFORM pg_catalog.set_config('request.jwt.claims','',true);
      v_processed:=v_processed+1;
      v_triggered:=v_triggered+1;
    EXCEPTION WHEN OTHERS THEN
      PERFORM pg_catalog.set_config('request.jwt.claim.sub','',true);
      PERFORM pg_catalog.set_config('request.jwt.claims','',true);
      UPDATE public.conditional_orders
      SET attempt_count=attempt_count+1,last_error=left(SQLERRM,500),updated_at=now()
      WHERE id=v_cond.id
      RETURNING attempt_count INTO v_attempt;

      IF v_attempt>=10 THEN
        SELECT * INTO v_res
        FROM public.order_reservations
        WHERE order_id=v_cond.order_id AND user_id=v_cond.user_id
        FOR UPDATE;
        IF FOUND AND v_res.status='reserved'
           AND v_res.consumed_amount>=0
           AND v_res.consumed_amount+v_res.released_amount<=v_res.reserved_amount THEN
          UPDATE public.order_reservations
          SET released_amount=reserved_amount-consumed_amount,
              status='released',updated_at=now()
          WHERE id=v_res.id;
        END IF;
        UPDATE public.orders
        SET status='rejected',remaining_amount=amount-filled_amount
        WHERE id=v_cond.order_id AND user_id=v_cond.user_id AND status='pending';
        UPDATE public.conditional_orders
        SET status='rejected',updated_at=now()
        WHERE id=v_cond.id AND status='pending';
        v_rejected:=v_rejected+1;
      ELSE
        v_skipped:=v_skipped+1;
      END IF;
    END;
  END LOOP;

  RETURN jsonb_build_object('success',true,'processed',v_processed,
    'triggered',v_triggered,'synced',v_synced,'rejected',v_rejected,'skipped',v_skipped);
END;
$function$

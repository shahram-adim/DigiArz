CREATE OR REPLACE FUNCTION public.process_conditional_orders()
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
  v_execution_order_id uuid;
  v_processed integer:=0;
  v_triggered integer:=0;
  v_rejected integer:=0;
  v_skipped integer:=0;
  v_rows integer;
BEGIN
  IF NOT pg_catalog.pg_try_advisory_xact_lock(739201127) THEN
    RETURN jsonb_build_object('success',true,'message','Another conditional cycle is running','processed',0);
  END IF;

  FOR v_cond IN
    SELECT c.id,c.order_id,c.user_id,c.symbol,c.order_kind,c.trigger_price,c.amount,
           o.filled_amount,o.remaining_amount
    FROM public.conditional_orders c
    JOIN public.orders o ON o.id=c.order_id AND o.user_id=c.user_id
    JOIN public.profiles p ON p.id=c.user_id AND p.is_active IS TRUE
    WHERE c.status='pending' AND o.status='pending' AND o.order_type='conditional'
    ORDER BY c.created_at
    FOR UPDATE OF c,o SKIP LOCKED
  LOOP
    IF v_cond.symbol IS NULL OR v_cond.symbol !~ '^[A-Z0-9]{2,15}USDT$'
       OR v_cond.amount IS NULL OR v_cond.amount<=0
       OR v_cond.trigger_price IS NULL OR v_cond.trigger_price<=0 THEN
      v_skipped:=v_skipped+1; CONTINUE;
    END IF;

    SELECT mp.price INTO v_market_price
    FROM public.market_prices mp
    WHERE mp.symbol=v_cond.symbol
      AND mp.updated_at>=now()-interval '1 minute'
    FOR SHARE;
    IF NOT FOUND OR v_market_price IS NULL OR v_market_price<=0 THEN
      v_skipped:=v_skipped+1; CONTINUE;
    END IF;

    IF (v_cond.order_kind='take_profit' AND v_market_price<v_cond.trigger_price)
       OR (v_cond.order_kind='stop_loss' AND v_market_price>v_cond.trigger_price) THEN
      v_skipped:=v_skipped+1; CONTINUE;
    END IF;

    SELECT * INTO v_res
    FROM public.order_reservations r
    WHERE r.order_id=v_cond.order_id AND r.user_id=v_cond.user_id
    FOR UPDATE;
    IF NOT FOUND OR v_res.status<>'reserved'
       OR v_res.asset<>left(v_cond.symbol,length(v_cond.symbol)-4)
       OR v_res.reserved_amount<v_cond.amount
       OR v_res.consumed_amount<0
       OR v_res.consumed_amount+v_res.released_amount>v_res.reserved_amount THEN
      UPDATE public.conditional_orders
      SET attempt_count=attempt_count+1,last_error='Reservation validation failed',updated_at=now()
      WHERE id=v_cond.id;
      v_skipped:=v_skipped+1; CONTINUE;
    END IF;

    BEGIN
      -- Release this order's own reservation inside the same transaction before
      -- calling the market engine; if execution fails, this subtransaction rolls back.
      UPDATE public.order_reservations
      SET released_amount=reserved_amount-consumed_amount,
          status='released',updated_at=now()
      WHERE id=v_res.id AND status='reserved';

      PERFORM pg_catalog.set_config('request.jwt.claim.sub',v_cond.user_id::text,true);
      PERFORM pg_catalog.set_config('request.jwt.claims',
        pg_catalog.jsonb_build_object('sub',v_cond.user_id::text,'role','authenticated')::text,true);

      v_result:=public.execute_demo_trade(v_cond.symbol,'sell',v_cond.amount,v_market_price);
      IF COALESCE((v_result->>'success')::boolean,false) IS NOT TRUE THEN
        RAISE EXCEPTION 'Market engine did not confirm conditional execution';
      END IF;
      v_execution_order_id:=(v_result->>'order_id')::uuid;

      UPDATE public.order_reservations
      SET consumed_amount=reserved_amount,released_amount=0,status='consumed',updated_at=now()
      WHERE id=v_res.id AND status='released'
        AND consumed_amount=0 AND released_amount=reserved_amount;
      GET DIAGNOSTICS v_rows=ROW_COUNT;
      IF v_rows<>1 THEN RAISE EXCEPTION 'Conditional reservation consumption update failed'; END IF;

      UPDATE public.orders
      SET status='filled',filled_amount=amount,remaining_amount=0
      WHERE id=v_cond.order_id AND user_id=v_cond.user_id AND status='pending';
      GET DIAGNOSTICS v_rows=ROW_COUNT;
      IF v_rows<>1 THEN RAISE EXCEPTION 'Conditional parent order update failed'; END IF;

      UPDATE public.conditional_orders
      SET status='filled',execution_order_id=v_execution_order_id,
          executed_price=(v_result->>'price')::numeric,
          triggered_at=now(),executed_at=now(),last_error=NULL,updated_at=now()
      WHERE id=v_cond.id AND status='pending';
      GET DIAGNOSTICS v_rows=ROW_COUNT;
      IF v_rows<>1 THEN RAISE EXCEPTION 'Conditional order completion update failed'; END IF;

      PERFORM pg_catalog.set_config('request.jwt.claim.sub','',true);
      PERFORM pg_catalog.set_config('request.jwt.claims','',true);
      v_processed:=v_processed+1;
      v_triggered:=v_triggered+1;
    EXCEPTION WHEN OTHERS THEN
      PERFORM pg_catalog.set_config('request.jwt.claim.sub','',true);
      PERFORM pg_catalog.set_config('request.jwt.claims','',true);
      -- The failed execution block rolled back the reservation release.
      UPDATE public.conditional_orders
      SET attempt_count=attempt_count+1,last_error=left(SQLERRM,500),updated_at=now()
      WHERE id=v_cond.id;
      SELECT * INTO v_res FROM public.order_reservations WHERE order_id=v_cond.order_id AND user_id=v_cond.user_id FOR UPDATE;
      IF FOUND AND (SELECT attempt_count FROM public.conditional_orders WHERE id=v_cond.id)>=10
         AND v_res.status='reserved'
         AND v_res.consumed_amount>=0
         AND v_res.consumed_amount+v_res.released_amount<=v_res.reserved_amount THEN
        UPDATE public.order_reservations
        SET released_amount=reserved_amount-consumed_amount,status='released',updated_at=now()
        WHERE id=v_res.id;
        UPDATE public.orders SET status='rejected',remaining_amount=amount-filled_amount
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
    'triggered',v_triggered,'rejected',v_rejected,'skipped',v_skipped);
END;
$function$
;

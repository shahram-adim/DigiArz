DO $migration$
DECLARE
  v_definition text;
  v_old text := $old$
      UPDATE public.conditional_orders
      SET attempt_count=attempt_count+1,last_error='Reservation validation failed',updated_at=now()
      WHERE id=v_cond.id;
      v_skipped:=v_skipped+1;
      CONTINUE;
$old$;
  v_new text := $new$
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
$new$;
BEGIN
  SELECT pg_catalog.pg_get_functiondef('public.process_stop_limit_orders()'::regprocedure)
  INTO v_definition;

  IF pg_catalog.strpos(v_definition, v_old)=0 THEN
    RAISE EXCEPTION 'Expected reservation-validation branch not found; migration aborted';
  END IF;

  v_definition := pg_catalog.replace(v_definition, v_old, v_new);
  EXECUTE v_definition;
END
$migration$;

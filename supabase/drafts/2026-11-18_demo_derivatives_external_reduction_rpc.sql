-- DRAFT ONLY: trusted external Futures position reduction.
-- Position accounting, immutable ledger posting, risk-event idempotency and
-- Reduce-only reservation reconciliation commit or roll back together.
-- This is NOT a liquidation engine and must not be exposed to client roles.

BEGIN;

GRANT USAGE ON SCHEMA private TO service_role;
GRANT SELECT ON TABLE
  public.demo_derivative_accounts,
  public.demo_derivative_positions,
  public.demo_derivative_risk_events,
  public.demo_derivative_ledger_transactions,
  public.demo_derivative_ledger_entries
TO service_role;

CREATE OR REPLACE FUNCTION private.apply_demo_external_futures_position_reduction(
  p_position_id uuid,
  p_event_id uuid,
  p_reduction_quantity numeric,
  p_execution_price numeric,
  p_fee_usdt numeric
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_account_id uuid;
  v_user_id uuid;
  v_position public.demo_derivative_positions%ROWTYPE;
  v_existing public.demo_derivative_risk_events%ROWTYPE;
  v_request_snapshot jsonb;
  v_result jsonb;
  v_new_quantity numeric(38,18);
  v_realized_pnl numeric(38,18);
  v_margin_release numeric(38,18);
  v_cancelled_order_ids uuid[];
  v_ledger_transaction_id uuid;
BEGIN
  IF p_position_id IS NULL OR p_event_id IS NULL
     OR p_reduction_quantity IS NULL OR p_reduction_quantity<=0
     OR p_execution_price IS NULL OR p_execution_price<=0
     OR p_fee_usdt IS NULL OR p_fee_usdt<0
     OR p_reduction_quantity<>round(p_reduction_quantity,18)
     OR p_execution_price<>round(p_execution_price,18)
     OR p_fee_usdt<>round(p_fee_usdt,18) THEN
    RAISE EXCEPTION 'Invalid external Futures reduction arguments or precision'
      USING ERRCODE='22023';
  END IF;

  v_request_snapshot := jsonb_build_object(
    'position_id',p_position_id,
    'reduction_quantity',p_reduction_quantity,
    'execution_price',p_execution_price,
    'fee_usdt',p_fee_usdt
  );

  -- Discover ownership without taking a child-row lock first.
  SELECT p.account_id,p.user_id
    INTO v_account_id,v_user_id
  FROM public.demo_derivative_positions AS p
  WHERE p.id=p_position_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Derivative position not found' USING ERRCODE='P0002';
  END IF;

  -- Mandatory global mutex: every Futures state writer locks account first.
  PERFORM 1
  FROM public.demo_derivative_accounts AS a
  WHERE a.id=v_account_id AND a.user_id=v_user_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Derivative account not found' USING ERRCODE='P0002';
  END IF;

  -- Check the durable event id before checking current position state so a
  -- retry remains idempotent after a partial or full close.
  SELECT e.* INTO v_existing
  FROM public.demo_derivative_risk_events AS e
  WHERE e.id=p_event_id;
  IF FOUND THEN
    IF v_existing.user_id<>v_user_id
       OR v_existing.account_id<>v_account_id
       OR v_existing.position_id<>p_position_id
       OR v_existing.event_type<>'external_reduction'
       OR v_existing.snapshot->'request' IS DISTINCT FROM v_request_snapshot THEN
      RAISE EXCEPTION 'External reduction event id reused with different payload'
        USING ERRCODE='23505';
    END IF;
    RETURN v_existing.snapshot->'result';
  END IF;

  SELECT p.* INTO v_position
  FROM public.demo_derivative_positions AS p
  WHERE p.id=p_position_id
    AND p.account_id=v_account_id
    AND p.user_id=v_user_id
  FOR UPDATE;
  IF NOT FOUND OR v_position.status<>'open' THEN
    RAISE EXCEPTION 'Open derivative position not found' USING ERRCODE='P0002';
  END IF;

  IF v_position.product_type<>'futures' THEN
    RAISE EXCEPTION 'External reduction currently supports Futures only'
      USING ERRCODE='23514';
  END IF;

  IF p_reduction_quantity>v_position.quantity THEN
    RAISE EXCEPTION 'Reduction quantity exceeds open position quantity'
      USING ERRCODE='23514';
  END IF;

  v_new_quantity := v_position.quantity-p_reduction_quantity;
  v_realized_pnl := round(
    CASE v_position.position_side
      WHEN 'long' THEN (p_execution_price-v_position.entry_price)*p_reduction_quantity
      ELSE (v_position.entry_price-p_execution_price)*p_reduction_quantity
    END,
    18
  );

  v_margin_release :=
    CASE
      WHEN v_position.margin_mode<>'isolated' THEN 0
      WHEN p_reduction_quantity=v_position.quantity THEN v_position.isolated_margin_usdt
      ELSE trunc(
        v_position.isolated_margin_usdt*p_reduction_quantity/v_position.quantity,
        18
      )
    END;

  UPDATE public.demo_derivative_positions
  SET quantity=v_new_quantity,
      isolated_margin_usdt=CASE
        WHEN v_new_quantity=0 THEN 0
        ELSE isolated_margin_usdt-v_margin_release
      END,
      realized_pnl_usdt=realized_pnl_usdt+v_realized_pnl,
      status=CASE WHEN v_new_quantity=0 THEN 'closed' ELSE 'open' END,
      closed_at=CASE WHEN v_new_quantity=0 THEN now() ELSE NULL END,
      version=version+1,
      updated_at=now()
  WHERE id=p_position_id
    AND account_id=v_account_id
    AND user_id=v_user_id;

  -- The event id is also the ledger idempotency key. If a ledger header exists
  -- without its risk event, the unique constraint fails closed and rolls back.
  IF v_realized_pnl<>0 OR p_fee_usdt<>0 OR v_margin_release<>0 THEN
    v_ledger_transaction_id := gen_random_uuid();
    INSERT INTO public.demo_derivative_ledger_transactions(
      id,user_id,idempotency_key,event_type,reference_id,metadata
    ) VALUES (
      v_ledger_transaction_id,v_user_id,p_event_id,'position_reduction',p_event_id,
      jsonb_build_object(
        'position_id',p_position_id,
        'reduction_quantity',p_reduction_quantity,
        'execution_price',p_execution_price,
        'realized_pnl_usdt',v_realized_pnl,
        'fee_usdt',p_fee_usdt,
        'isolated_margin_released_usdt',v_margin_release
      )
    );

    INSERT INTO public.demo_derivative_ledger_entries(
      transaction_id,user_id,asset,account_bucket,debit_amount,credit_amount
    )
    SELECT
      v_ledger_transaction_id,v_user_id,'USDT',e.account_bucket,
      e.debit_amount,e.credit_amount
    FROM (VALUES
      ('futures_cash'::text,
        CASE WHEN v_realized_pnl>0 THEN v_realized_pnl ELSE 0::numeric END,
        CASE WHEN v_realized_pnl<0 THEN -v_realized_pnl ELSE 0::numeric END),
      ('system_clearing'::text,
        CASE WHEN v_realized_pnl<0 THEN -v_realized_pnl ELSE 0::numeric END,
        CASE WHEN v_realized_pnl>0 THEN v_realized_pnl ELSE 0::numeric END),
      ('fee_revenue'::text,p_fee_usdt,0::numeric),
      ('futures_cash'::text,0::numeric,p_fee_usdt),
      ('futures_cash'::text,v_margin_release,0::numeric),
      ('isolated_margin'::text,0::numeric,v_margin_release)
    ) AS e(account_bucket,debit_amount,credit_amount)
    WHERE e.debit_amount>0 OR e.credit_amount>0;
  END IF;

  -- Same transaction: reduce the position first, then cancel newest active
  -- Reduce-only reservations until the remaining total fits the new quantity.
  v_cancelled_order_ids :=
    private.reconcile_demo_reduce_only_reservations(p_position_id);

  v_result := jsonb_build_object(
    'event_id',p_event_id,
    'position_id',p_position_id,
    'remaining_quantity',v_new_quantity,
    'realized_pnl_usdt',v_realized_pnl,
    'fee_usdt',p_fee_usdt,
    'isolated_margin_released_usdt',v_margin_release,
    'cancelled_order_ids',to_jsonb(v_cancelled_order_ids)
  );

  INSERT INTO public.demo_derivative_risk_events(
    id,user_id,account_id,position_id,event_type,snapshot
  ) VALUES (
    p_event_id,v_user_id,v_account_id,p_position_id,'external_reduction',
    jsonb_build_object('request',v_request_snapshot,'result',v_result)
  );

  RETURN v_result;
END;
$function$;

REVOKE ALL ON FUNCTION private.apply_demo_external_futures_position_reduction(uuid,uuid,numeric,numeric,numeric)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.apply_demo_external_futures_position_reduction(uuid,uuid,numeric,numeric,numeric)
  TO service_role;

CREATE OR REPLACE FUNCTION public.apply_demo_external_futures_position_reduction(
  p_position_id uuid,
  p_event_id uuid,
  p_reduction_quantity numeric,
  p_execution_price numeric,
  p_fee_usdt numeric
)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path TO ''
AS $function$
  SELECT private.apply_demo_external_futures_position_reduction(
    p_position_id,p_event_id,p_reduction_quantity,p_execution_price,p_fee_usdt
  );
$function$;

REVOKE ALL ON FUNCTION public.apply_demo_external_futures_position_reduction(uuid,uuid,numeric,numeric,numeric)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.apply_demo_external_futures_position_reduction(uuid,uuid,numeric,numeric,numeric)
  TO service_role;

COMMIT;

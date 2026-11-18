-- DRAFT ONLY: trusted-worker Reduce-only Limit fill and accounting transaction.
-- Apply only after the derivatives schema and Reduce-only placement/cancel drafts
-- in a disposable PostgreSQL database. Never expose service_role credentials to clients.

BEGIN;

GRANT USAGE ON SCHEMA private TO service_role;

CREATE OR REPLACE FUNCTION private.apply_demo_reduce_only_limit_fill(
  p_order_id uuid,
  p_fill_id uuid,
  p_fill_quantity numeric,
  p_execution_price numeric,
  p_fee_usdt numeric
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_account_id uuid;
  v_user_id uuid;
  v_order public.demo_derivative_orders%ROWTYPE;
  v_position public.demo_derivative_positions%ROWTYPE;
  v_existing public.demo_derivative_fills%ROWTYPE;
  v_new_filled numeric(38,18);
  v_new_remaining numeric(38,18);
  v_new_position_quantity numeric(38,18);
  v_new_average_price numeric(38,18);
  v_realized_pnl numeric(38,18);
  v_margin_release numeric(38,18);
  v_fill_sequence integer;
  v_ledger_transaction_id uuid;
BEGIN
  IF p_order_id IS NULL OR p_fill_id IS NULL
     OR p_fill_quantity IS NULL OR p_fill_quantity <= 0
     OR p_execution_price IS NULL OR p_execution_price <= 0
     OR p_fee_usdt IS NULL OR p_fee_usdt < 0
     OR p_fill_quantity <> round(p_fill_quantity,18)
     OR p_execution_price <> round(p_execution_price,18)
     OR p_fee_usdt <> round(p_fee_usdt,18) THEN
    RAISE EXCEPTION 'Invalid Reduce-only fill arguments or precision'
      USING ERRCODE='22023';
  END IF;

  -- Discover account ownership without taking an order lock first.
  SELECT o.account_id,o.user_id
    INTO v_account_id,v_user_id
  FROM public.demo_derivative_orders AS o
  WHERE o.id=p_order_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Derivative order not found' USING ERRCODE='P0002';
  END IF;

  -- Global serialization order: account, order, then position.
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
    RAISE EXCEPTION 'Derivative order not found' USING ERRCODE='P0002';
  END IF;

  -- A retry is checked before active-order/position state, so a successful
  -- final fill remains idempotent after the position has been closed.
  SELECT f.* INTO v_existing
  FROM public.demo_derivative_fills AS f
  WHERE f.id=p_fill_id;
  IF FOUND THEN
    IF v_existing.order_id<>p_order_id
       OR v_existing.quantity<>p_fill_quantity
       OR v_existing.price<>p_execution_price
       OR v_existing.fee_usdt<>p_fee_usdt THEN
      RAISE EXCEPTION 'Fill id reused with different execution data'
        USING ERRCODE='23505';
    END IF;
    RETURN v_existing.id;
  END IF;

  IF v_order.product_type<>'futures'
     OR NOT v_order.reduce_only
     OR v_order.order_type<>'limit'
     OR v_order.status NOT IN ('pending','partially_filled') THEN
    RAISE EXCEPTION 'Only active Futures Reduce-only Limit orders can be filled'
      USING ERRCODE='23514';
  END IF;

  IF p_fill_quantity > v_order.remaining_quantity THEN
    RAISE EXCEPTION 'Fill quantity exceeds order remaining quantity'
      USING ERRCODE='23514';
  END IF;

  IF (v_order.side='buy' AND p_execution_price>v_order.limit_price)
     OR (v_order.side='sell' AND p_execution_price<v_order.limit_price) THEN
    RAISE EXCEPTION 'Execution price violates the Limit price'
      USING ERRCODE='23514';
  END IF;

  SELECT p.* INTO v_position
  FROM public.demo_derivative_positions AS p
  WHERE p.account_id=v_account_id
    AND p.user_id=v_user_id
    AND p.product_type=v_order.product_type
    AND p.symbol=v_order.symbol
    AND p.position_side=v_order.position_side
    AND p.status='open'
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No open position remains for Reduce-only fill'
      USING ERRCODE='P0002';
  END IF;

  IF p_fill_quantity>v_position.quantity THEN
    RAISE EXCEPTION 'Fill quantity exceeds remaining position quantity'
      USING ERRCODE='23514';
  END IF;

  v_new_filled := v_order.filled_quantity+p_fill_quantity;
  v_new_remaining := v_order.remaining_quantity-p_fill_quantity;
  v_new_position_quantity := v_position.quantity-p_fill_quantity;
  v_new_average_price :=
    CASE WHEN v_new_filled=0 THEN NULL
    ELSE (
      COALESCE(v_order.average_fill_price,0)*v_order.filled_quantity
      + p_execution_price*p_fill_quantity
    )/v_new_filled END;

  v_realized_pnl := round(
    CASE v_position.position_side
      WHEN 'long' THEN (p_execution_price-v_position.entry_price)*p_fill_quantity
      ELSE (v_position.entry_price-p_execution_price)*p_fill_quantity
    END,
    18
  );

  v_margin_release :=
    CASE
      WHEN v_position.margin_mode<>'isolated' THEN 0
      WHEN p_fill_quantity=v_position.quantity THEN v_position.isolated_margin_usdt
      ELSE trunc(
        v_position.isolated_margin_usdt*p_fill_quantity/v_position.quantity,
        18
      )
    END;

  SELECT COALESCE(max(f.fill_sequence),0)+1
    INTO v_fill_sequence
  FROM public.demo_derivative_fills AS f
  WHERE f.order_id=p_order_id;

  INSERT INTO public.demo_derivative_fills(
    id,user_id,account_id,order_id,position_id,fill_sequence,
    symbol,position_side,side,quantity,price,fee_usdt
  ) VALUES (
    p_fill_id,v_user_id,v_account_id,p_order_id,v_position.id,v_fill_sequence,
    v_order.symbol,v_order.position_side,v_order.side,
    p_fill_quantity,p_execution_price,p_fee_usdt
  );

  UPDATE public.demo_derivative_positions
  SET quantity=v_new_position_quantity,
      isolated_margin_usdt=CASE
        WHEN v_new_position_quantity=0 THEN 0
        ELSE isolated_margin_usdt-v_margin_release
      END,
      realized_pnl_usdt=realized_pnl_usdt+v_realized_pnl,
      status=CASE WHEN v_new_position_quantity=0 THEN 'closed' ELSE 'open' END,
      closed_at=CASE WHEN v_new_position_quantity=0 THEN now() ELSE NULL END,
      version=version+1,
      updated_at=now()
  WHERE id=v_position.id AND account_id=v_account_id AND user_id=v_user_id;

  UPDATE public.demo_derivative_orders
  SET filled_quantity=v_new_filled,
      remaining_quantity=v_new_remaining,
      average_fill_price=v_new_average_price,
      status=CASE WHEN v_new_remaining=0 THEN 'filled' ELSE 'partially_filled' END,
      updated_at=now()
  WHERE id=p_order_id AND account_id=v_account_id AND user_id=v_user_id;

  -- One immutable, balanced USDT ledger group posts realized PnL, fee and
  -- isolated-margin release. Zero-value components create no empty ledger rows.
  IF v_realized_pnl<>0 OR p_fee_usdt<>0 OR v_margin_release<>0 THEN
    v_ledger_transaction_id := gen_random_uuid();
    INSERT INTO public.demo_derivative_ledger_transactions(
      id,user_id,idempotency_key,event_type,reference_id,metadata
    ) VALUES (
      v_ledger_transaction_id,v_user_id,p_fill_id,'reduce_only_fill',p_fill_id,
      jsonb_build_object(
        'order_id',p_order_id,
        'fill_quantity',p_fill_quantity,
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

  RETURN p_fill_id;
END;
$function$;

REVOKE ALL ON FUNCTION private.apply_demo_reduce_only_limit_fill(uuid,uuid,numeric,numeric,numeric) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.apply_demo_reduce_only_limit_fill(uuid,uuid,numeric,numeric,numeric) TO service_role;

-- Public RPC surface is callable only by service_role. The service key must
-- remain exclusively on trusted servers; never ship it in DigiArz Android.
CREATE OR REPLACE FUNCTION public.apply_demo_reduce_only_limit_fill(
  p_order_id uuid,
  p_fill_id uuid,
  p_fill_quantity numeric,
  p_execution_price numeric,
  p_fee_usdt numeric
)
RETURNS uuid
LANGUAGE sql
SECURITY INVOKER
SET search_path TO ''
AS $function$
  SELECT private.apply_demo_reduce_only_limit_fill(
    p_order_id,p_fill_id,p_fill_quantity,p_execution_price,p_fee_usdt
  );
$function$;

REVOKE ALL ON FUNCTION public.apply_demo_reduce_only_limit_fill(uuid,uuid,numeric,numeric,numeric) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.apply_demo_reduce_only_limit_fill(uuid,uuid,numeric,numeric,numeric) TO service_role;

COMMIT;

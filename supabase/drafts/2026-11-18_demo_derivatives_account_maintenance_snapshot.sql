-- DRAFT ONLY: transaction-pinned account position maintenance snapshot.
-- Requires derivative schema, private oracle storage/RPCs, and versioned maintenance tiers.
-- No Production deployment or client execution.
BEGIN;

CREATE OR REPLACE FUNCTION private.demo_derivative_account_maintenance_snapshot(p_account_id uuid)
RETURNS TABLE(
  account_id uuid,
  position_id uuid,
  symbol text,
  margin_mode text,
  position_side text,
  quantity numeric,
  entry_price numeric,
  mark_price numeric,
  oracle_snapshot_id uuid,
  oracle_snapshot_created_at timestamptz,
  oracle_expires_at timestamptz,
  wallet_cash_usdt numeric,
  notional numeric,
  unrealized_pnl numeric,
  maintenance_margin numeric,
  maintenance_rate numeric,
  maintenance_amount numeric,
  max_leverage smallint,
  tier_index smallint,
  schedule_id uuid,
  schedule_version integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_now timestamptz:=clock_timestamp();
  v_account_id uuid;
  v_wallet_cash numeric;
  v_position record;
  v_snapshot private.demo_derivative_price_snapshots%ROWTYPE;
  v_schedule_id uuid;
  v_schedule_version integer;
  v_tier private.demo_derivative_maintenance_tiers%ROWTYPE;
  v_notional numeric;
  v_pnl numeric;
  v_maintenance numeric;
BEGIN
  IF p_account_id IS NULL THEN
    RAISE EXCEPTION 'Account id is required' USING ERRCODE='22023';
  END IF;

  -- Every Futures writer takes this account row FOR UPDATE first. Holding
  -- FOR SHARE pins positions and the ledger projection for this whole call.
  SELECT a.id INTO v_account_id
  FROM public.demo_derivative_accounts a
  WHERE a.id=p_account_id
  FOR SHARE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unknown derivatives account' USING ERRCODE='P0002';
  END IF;

  SELECT b.futures_cash_usdt INTO v_wallet_cash
  FROM public.demo_derivative_futures_cash_balances b
  WHERE b.account_id=p_account_id;
  v_wallet_cash:=COALESCE(v_wallet_cash,0);

  -- Lock every active symbol schedule in deterministic order before computing
  -- any position. A concurrent activation must wait until this snapshot ends.
  PERFORM s.id
  FROM private.demo_derivative_maintenance_tier_schedules s
  JOIN (
    SELECT DISTINCT p.symbol
    FROM public.demo_derivative_positions p
    WHERE p.account_id=p_account_id
      AND p.product_type='futures' AND p.status='open'
  ) symbols ON symbols.symbol=s.symbol
  WHERE s.status='active' AND s.effective_from<=v_now
  ORDER BY s.symbol
  FOR SHARE OF s;

  FOR v_position IN
    SELECT p.id,p.symbol,p.margin_mode,p.position_side,p.quantity,p.entry_price,p.leverage
    FROM public.demo_derivative_positions p
    WHERE p.account_id=p_account_id
      AND p.product_type='futures' AND p.status='open'
    ORDER BY p.symbol,p.id
    FOR SHARE
  LOOP
    -- Select the newest oracle snapshot regardless of status. A newer stale,
    -- deviation, or insufficient-quorum result blocks use of an older healthy
    -- value even if that older snapshot has not yet reached expires_at.
    SELECT s.* INTO v_snapshot
    FROM private.demo_derivative_price_snapshots s
    WHERE s.symbol=v_position.symbol AND s.created_at<=v_now
    ORDER BY s.created_at DESC,s.id DESC
    LIMIT 1;
    IF NOT FOUND
       OR v_snapshot.snapshot_status<>'healthy'
       OR v_snapshot.mark_price IS NULL OR v_snapshot.mark_price<=0
       OR v_snapshot.as_of IS NULL OR v_snapshot.as_of>v_now
       OR v_snapshot.expires_at IS NULL OR v_snapshot.expires_at<=v_now THEN
      RAISE EXCEPTION 'Missing, stale, or unhealthy Futures oracle snapshot for %',v_position.symbol
        USING ERRCODE='55000';
    END IF;

    SELECT s.id,s.schedule_version
      INTO v_schedule_id,v_schedule_version
    FROM private.demo_derivative_maintenance_tier_schedules s
    WHERE s.symbol=v_position.symbol AND s.status='active' AND s.effective_from<=v_now
    FOR SHARE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'No active maintenance schedule for %',v_position.symbol USING ERRCODE='55000';
    END IF;
    IF NOT private.demo_derivative_maintenance_schedule_valid(v_schedule_id) THEN
      RAISE EXCEPTION 'Maintenance schedule integrity check failed for %',v_position.symbol
        USING ERRCODE='23514';
    END IF;

    v_notional:=ceil(v_position.quantity*v_snapshot.mark_price*1000000000000000000::numeric)
      /1000000000000000000::numeric;
    SELECT t.* INTO v_tier
    FROM private.demo_derivative_maintenance_tiers t
    WHERE t.schedule_id=v_schedule_id
      AND (t.max_notional IS NULL OR v_notional<=t.max_notional)
    ORDER BY t.tier_index
    LIMIT 1;
    IF v_tier.schedule_id IS NULL THEN
      RAISE EXCEPTION 'No maintenance tier for % notional %',v_position.symbol,v_notional
        USING ERRCODE='23514';
    END IF;
    IF v_position.leverage>v_tier.max_leverage THEN
      RAISE EXCEPTION 'Position leverage exceeds current maintenance tier cap for %',v_position.symbol
        USING ERRCODE='23514';
    END IF;

    v_maintenance:=ceil(v_notional*v_tier.maintenance_rate*1000000000000000000::numeric)
      /1000000000000000000::numeric-v_tier.maintenance_amount;
    IF v_maintenance<=0 THEN
      RAISE EXCEPTION 'Maintenance tier produced non-positive margin for %',v_position.symbol
        USING ERRCODE='23514';
    END IF;

    v_pnl:=CASE WHEN v_position.position_side='long'
      THEN round(v_position.quantity*(v_snapshot.mark_price-v_position.entry_price),18)
      ELSE round(v_position.quantity*(v_position.entry_price-v_snapshot.mark_price),18)
    END;

    account_id:=v_account_id;
    position_id:=v_position.id;
    symbol:=v_position.symbol;
    margin_mode:=v_position.margin_mode;
    position_side:=v_position.position_side;
    quantity:=v_position.quantity;
    entry_price:=v_position.entry_price;
    mark_price:=v_snapshot.mark_price;
    oracle_snapshot_id:=v_snapshot.id;
    oracle_snapshot_created_at:=v_snapshot.created_at;
    oracle_expires_at:=v_snapshot.expires_at;
    wallet_cash_usdt:=v_wallet_cash;
    notional:=v_notional;
    unrealized_pnl:=v_pnl;
    maintenance_margin:=v_maintenance;
    maintenance_rate:=v_tier.maintenance_rate;
    maintenance_amount:=v_tier.maintenance_amount;
    max_leverage:=v_tier.max_leverage;
    tier_index:=v_tier.tier_index;
    schedule_id:=v_schedule_id;
    schedule_version:=v_schedule_version;
    RETURN NEXT;
  END LOOP;
END;
$function$;

REVOKE ALL ON FUNCTION private.demo_derivative_account_maintenance_snapshot(uuid)
  FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_account_maintenance_snapshot(uuid) TO service_role;

COMMIT;

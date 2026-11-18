BEGIN;
-- DRAFT ONLY: account-level USDT Futures Cross risk snapshot. Never deploy to Production without approval.
CREATE FUNCTION private.demo_derivative_account_risk_snapshot(p_account_id uuid)
RETURNS TABLE(account_id uuid,wallet_cash_usdt numeric,cross_unrealized_pnl_usdt numeric,
 unposted_funding_liability_usdt numeric,unposted_funding_receivable_usdt numeric,
 close_fee_reserve_usdt numeric,equity_usdt numeric,maintenance_margin_usdt numeric,
 margin_ratio numeric,cross_position_count integer,position_snapshots jsonb)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $function$
DECLARE
 v_now timestamptz:=clock_timestamp(); v_account uuid; v_cash numeric:=0; v_pnl numeric:=0;
 v_liab numeric:=0; v_recv numeric:=0; v_fee_reserve numeric:=0; v_mm numeric:=0; v_equity numeric;
 v_count integer:=0; v_positions jsonb:='[]'::jsonb; v_pos record;
 v_fee_id uuid; v_fee_version integer; v_maker numeric; v_taker numeric;
 v_close_fee numeric; v_pos_liab numeric; v_pos_recv numeric; v_iso_equity numeric;
BEGIN
 IF p_account_id IS NULL THEN RAISE EXCEPTION 'Account id required' USING ERRCODE='22023'; END IF;
 SELECT a.id INTO v_account FROM public.demo_derivative_accounts a WHERE a.id=p_account_id FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Unknown derivatives account' USING ERRCODE='P0002'; END IF;
 SELECT COALESCE(b.futures_cash_usdt,0) INTO v_cash FROM public.demo_derivative_futures_cash_balances b WHERE b.account_id=p_account_id;
 v_cash:=COALESCE(v_cash,0);
 FOR v_pos IN
  SELECT m.position_id,m.symbol,m.margin_mode,m.position_side,m.quantity,m.entry_price,m.mark_price,
   m.oracle_snapshot_id,m.oracle_snapshot_created_at,m.oracle_expires_at,m.notional,m.unrealized_pnl,
   m.maintenance_margin,m.maintenance_rate,m.maintenance_amount,m.max_leverage,m.tier_index,
   m.schedule_id,m.schedule_version,p.leverage,p.isolated_margin_usdt
  FROM private.demo_derivative_account_maintenance_snapshot(p_account_id) m
  JOIN public.demo_derivative_positions p ON p.id=m.position_id AND p.account_id=p_account_id
  ORDER BY m.symbol,m.position_id
 LOOP
  SELECT f.id,f.schedule_version,f.maker_fee_rate,f.taker_fee_rate INTO v_fee_id,v_fee_version,v_maker,v_taker
  FROM private.demo_derivative_fee_schedules f
  WHERE f.symbol=v_pos.symbol AND f.status='active' AND f.effective_from<=v_now
  ORDER BY f.schedule_version DESC LIMIT 1 FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'No active trusted fee schedule for %',v_pos.symbol USING ERRCODE='55000'; END IF;
  v_close_fee:=ceil(v_pos.notional*v_taker*1000000000000000000::numeric)/1000000000000000000::numeric;
  SELECT COALESCE(sum(GREATEST(f.amount_usdt,0)),0),COALESCE(sum(GREATEST(-f.amount_usdt,0)),0)
   INTO v_pos_liab,v_pos_recv
  FROM public.demo_derivative_funding_events f
  WHERE f.account_id=p_account_id AND f.position_id=v_pos.position_id
   AND f.settled_at IS NULL AND f.interval_end<=v_now;
  IF v_pos.margin_mode='cross' THEN
   v_pnl:=v_pnl+v_pos.unrealized_pnl; v_mm:=v_mm+v_pos.maintenance_margin;
   v_fee_reserve:=v_fee_reserve+v_close_fee; v_count:=v_count+1; v_iso_equity:=NULL;
  ELSE
   v_iso_equity:=v_pos.isolated_margin_usdt+v_pos.unrealized_pnl+v_pos_recv-v_pos_liab-v_close_fee;
  END IF;
  v_positions:=v_positions||jsonb_build_array(jsonb_build_object(
   'position_id',v_pos.position_id,'symbol',v_pos.symbol,'margin_mode',v_pos.margin_mode,
   'position_side',v_pos.position_side,'quantity',v_pos.quantity,'entry_price',v_pos.entry_price,
   'mark_price',v_pos.mark_price,'oracle_snapshot_id',v_pos.oracle_snapshot_id,
   'oracle_snapshot_created_at',v_pos.oracle_snapshot_created_at,'oracle_expires_at',v_pos.oracle_expires_at,
   'notional',v_pos.notional,'unrealized_pnl_usdt',v_pos.unrealized_pnl,
   'maintenance_margin_usdt',v_pos.maintenance_margin,'maintenance_rate',v_pos.maintenance_rate,
   'maintenance_tier_index',v_pos.tier_index,'maintenance_schedule_id',v_pos.schedule_id,
   'maintenance_schedule_version',v_pos.schedule_version,'leverage',v_pos.leverage,
   'max_leverage',v_pos.max_leverage,'fee_schedule_id',v_fee_id,'fee_schedule_version',v_fee_version,
   'maker_fee_rate',v_maker,'taker_fee_rate',v_taker,'close_fee_reserve_usdt',v_close_fee,
   'unposted_funding_liability_usdt',v_pos_liab,'unposted_funding_receivable_usdt',v_pos_recv,
   'isolated_equity_usdt',v_iso_equity,
   'isolated_margin_ratio',CASE WHEN v_pos.margin_mode='isolated' AND v_pos.maintenance_margin>0
    THEN round(v_iso_equity/v_pos.maintenance_margin,18) ELSE NULL END
  ));
 END LOOP;
 -- Accrued funding on all Cross positions, including closed positions, is counted once.
 -- Settled events are excluded because their matching cash movements are already in the ledger.
 SELECT COALESCE(sum(GREATEST(f.amount_usdt,0)),0),COALESCE(sum(GREATEST(-f.amount_usdt,0)),0)
 INTO v_liab,v_recv
 FROM public.demo_derivative_funding_events f
 JOIN public.demo_derivative_positions p ON p.id=f.position_id AND p.account_id=f.account_id AND p.user_id=f.user_id
 WHERE f.account_id=p_account_id AND p.product_type='futures' AND p.margin_mode='cross'
  AND f.settled_at IS NULL AND f.interval_end<=v_now;
 v_equity:=v_cash+v_pnl+v_recv-v_liab-v_fee_reserve;
 account_id:=v_account; wallet_cash_usdt:=v_cash; cross_unrealized_pnl_usdt:=v_pnl;
 unposted_funding_liability_usdt:=v_liab; unposted_funding_receivable_usdt:=v_recv;
 close_fee_reserve_usdt:=v_fee_reserve; equity_usdt:=v_equity; maintenance_margin_usdt:=v_mm;
 margin_ratio:=CASE WHEN v_mm>0 THEN round(v_equity/v_mm,18) ELSE NULL END;
 cross_position_count:=v_count; position_snapshots:=v_positions; RETURN NEXT;
END;
$function$;
REVOKE ALL ON FUNCTION private.demo_derivative_account_risk_snapshot(uuid) FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_account_risk_snapshot(uuid) TO service_role;
COMMIT;

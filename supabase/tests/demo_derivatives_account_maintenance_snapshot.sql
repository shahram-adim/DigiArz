\set ON_ERROR_STOP on
-- Run after derivative schema, maintenance tiers, and trusted oracle RPC drafts/tests.

-- Extend the disposable test policy window so CI scheduling cannot expire a
-- snapshot between publication and the immediately following account query.
UPDATE private.demo_derivative_price_policies SET enabled=false
WHERE symbol IN ('BTCUSDT','ETHUSDT') AND policy_version=1 AND enabled;
INSERT INTO private.demo_derivative_price_policies(
  symbol,policy_version,enabled,eligible_providers,min_sources,max_age_ms,max_future_skew_ms,
  max_mark_deviation_bps,max_index_deviation_bps,max_mark_index_deviation_bps
) VALUES
  ('BTCUSDT',2,true,ARRAY['binance_usdm','bybit_linear','okx_swap'],2,60000,250,50,50,200),
  ('ETHUSDT',2,true,ARRAY['binance_usdm','bybit_linear'],2,60000,250,50,50,200);

-- Publish fresh BTC and ETH consensus snapshots for the pre-seeded account fixtures.
SET request.jwt.claim.role='service_role';
SET ROLE service_role;
DO $fresh_oracle$
DECLARE
  v_ts timestamptz:=clock_timestamp();
BEGIN
  PERFORM private.demo_derivative_price_start_cycle(
    'a2000000-0000-0000-0000-000000000001','BTCUSDT',
    ARRAY['binance_usdm','bybit_linear'],
    '{"binance_usdm":"BTCUSDT","bybit_linear":"BTCUSDT"}'::jsonb
  );
  PERFORM private.demo_derivative_price_record_provider_result(
    'a2000000-0000-0000-0000-000000000001','binance_usdm','accepted',
    20000,19990,v_ts,repeat('c',64),NULL
  );
  PERFORM private.demo_derivative_price_record_provider_result(
    'a2000000-0000-0000-0000-000000000001','bybit_linear','accepted',
    20010,19995,v_ts,repeat('d',64),NULL
  );
  PERFORM private.demo_derivative_price_publish_snapshot(
    'a2000000-0000-0000-0000-000000000001',
    'b2000000-0000-0000-0000-000000000001','healthy',
    20005,19992.5,ARRAY['binance_usdm','bybit_linear'],
    v_ts,v_ts+interval '60 seconds','[]'::jsonb
  );

  PERFORM private.demo_derivative_price_start_cycle(
    'a2000000-0000-0000-0000-000000000002','ETHUSDT',
    ARRAY['binance_usdm','bybit_linear'],
    '{"binance_usdm":"ETHUSDT","bybit_linear":"ETHUSDT"}'::jsonb
  );
  PERFORM private.demo_derivative_price_record_provider_result(
    'a2000000-0000-0000-0000-000000000002','binance_usdm','accepted',
    1800,1799,v_ts,repeat('e',64),NULL
  );
  PERFORM private.demo_derivative_price_record_provider_result(
    'a2000000-0000-0000-0000-000000000002','bybit_linear','accepted',
    1801,1800,v_ts,repeat('f',64),NULL
  );
  PERFORM private.demo_derivative_price_publish_snapshot(
    'a2000000-0000-0000-0000-000000000002',
    'b2000000-0000-0000-0000-000000000002','healthy',
    1800.5,1799.5,ARRAY['binance_usdm','bybit_linear'],
    v_ts,v_ts+interval '60 seconds','[]'::jsonb
  );
END;
$fresh_oracle$;
RESET ROLE;
RESET request.jwt.claim.role;

-- ETH v1 is deliberately invalid/draft from the maintenance tier validation test.
-- Activate a valid v2 schedule and add a cross-margin short position for user 1.
INSERT INTO private.demo_derivative_maintenance_tier_schedules(id,symbol,schedule_version)
VALUES ('c2000000-0000-0000-0000-000000000002','ETHUSDT',2);
INSERT INTO private.demo_derivative_maintenance_tiers(
 schedule_id,tier_index,max_notional,maintenance_rate,maintenance_amount,max_leverage
) VALUES
 ('c2000000-0000-0000-0000-000000000002',1,10000,0.01,0,50),
 ('c2000000-0000-0000-0000-000000000002',2,NULL,0.02,100,20);
SET request.jwt.claim.role='service_role';
SET ROLE service_role;
SELECT * FROM private.demo_derivative_activate_maintenance_schedule('c2000000-0000-0000-0000-000000000002');
RESET ROLE;
RESET request.jwt.claim.role;

INSERT INTO public.demo_derivative_positions(
 id,user_id,account_id,product_type,symbol,position_side,margin_mode,
 leverage,quantity,entry_price,isolated_margin_usdt
) VALUES (
 '40000000-0000-0000-0000-000000000003',
 '10000000-0000-0000-0000-000000000001',
 '20000000-0000-0000-0000-000000000001',
 'futures','ETHUSDT','short','cross',5,2,2000,0
);

DO $risk_snapshot$
DECLARE
  v_btc record;
  v_eth record;
  v_count integer;
BEGIN
  SELECT * INTO v_btc
  FROM private.demo_derivative_account_maintenance_snapshot('20000000-0000-0000-0000-000000000001')
  WHERE symbol='BTCUSDT';
  IF v_btc.position_id<>'40000000-0000-0000-0000-000000000001'
     OR v_btc.margin_mode<>'isolated'
     OR v_btc.mark_price<>20005
     OR v_btc.notional<>20005
     OR v_btc.unrealized_pnl<>19905
     OR v_btc.maintenance_margin<>600.175
     OR v_btc.schedule_version<>4
     OR v_btc.tier_index<>2
     OR v_btc.max_leverage<>20
     OR v_btc.wallet_cash_usdt<>10 THEN
    RAISE EXCEPTION 'BTC isolated maintenance snapshot is incorrect: %',row_to_json(v_btc);
  END IF;

  SELECT * INTO v_eth
  FROM private.demo_derivative_account_maintenance_snapshot('20000000-0000-0000-0000-000000000001')
  WHERE symbol='ETHUSDT';
  IF v_eth.position_id<>'40000000-0000-0000-0000-000000000003'
     OR v_eth.margin_mode<>'cross'
     OR v_eth.mark_price<>1800.5
     OR v_eth.notional<>3601
     OR v_eth.unrealized_pnl<>399
     OR v_eth.maintenance_margin<>36.01
     OR v_eth.schedule_version<>2
     OR v_eth.tier_index<>1 THEN
    RAISE EXCEPTION 'ETH cross maintenance snapshot is incorrect: %',row_to_json(v_eth);
  END IF;

  SELECT count(*) INTO v_count
  FROM private.demo_derivative_account_maintenance_snapshot('20000000-0000-0000-0000-000000000001');
  IF v_count<>2 THEN
    RAISE EXCEPTION 'Account snapshot did not return every open Futures position';
  END IF;

  SELECT count(*) INTO v_count
  FROM private.demo_derivative_account_maintenance_snapshot('20000000-0000-0000-0000-000000000002');
  IF v_count<>1 THEN
    RAISE EXCEPTION 'Second account snapshot leaked or omitted positions';
  END IF;
END;
$risk_snapshot$;


BEGIN;
-- Seed accrued and ledger-settled funding. Positive amounts are payables;
-- negative amounts are receivables. Settled funding changes cash once only.
INSERT INTO public.demo_derivative_funding_events(id,user_id,account_id,position_id,interval_start,interval_end,funding_rate,mark_price,position_notional_usdt,amount_usdt) VALUES
 ('50000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000003',clock_timestamp()-interval '3 hours',clock_timestamp()-interval '2 hours',0.0001,1800.5,3601,5),
 ('50000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000003',clock_timestamp()-interval '2 hours',clock_timestamp()-interval '1 hour',0.0001,1800.5,3601,2),
 ('50000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000003',clock_timestamp()-interval '1 hour',clock_timestamp()-interval '30 minutes',-0.00005,1800.5,3601,-1),
 ('50000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001',clock_timestamp()-interval '2 hours',clock_timestamp()-interval '1 hour',0.0001,20005,20005,7);
INSERT INTO public.demo_derivative_ledger_transactions(id,user_id,idempotency_key,event_type,reference_id,metadata)
VALUES('60000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001','funding','50000000-0000-0000-0000-000000000001','{"fixture":"funding-settlement"}'::jsonb);
INSERT INTO public.demo_derivative_ledger_entries(transaction_id,user_id,asset,account_bucket,debit_amount,credit_amount) VALUES
 ('60000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','USDT','futures_cash',0,5),
 ('60000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','USDT','system_clearing',5,0);
UPDATE public.demo_derivative_funding_events SET settled_at=clock_timestamp() WHERE id='50000000-0000-0000-0000-000000000001';
COMMIT;
DO $funding_guard_test$
BEGIN
 BEGIN
  UPDATE public.demo_derivative_funding_events SET amount_usdt=9 WHERE id='50000000-0000-0000-0000-000000000002';
  RAISE EXCEPTION 'Accrued funding unexpectedly mutable';
 EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL; END;
 BEGIN
  UPDATE public.demo_derivative_funding_events SET settled_at=clock_timestamp() WHERE id='50000000-0000-0000-0000-000000000002';
  RAISE EXCEPTION 'Funding unexpectedly settled without ledger';
 EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL; END;
END;
$funding_guard_test$;
DO $account_risk_test$
DECLARE v record;
BEGIN
 SELECT * INTO v FROM private.demo_derivative_account_risk_snapshot('20000000-0000-0000-0000-000000000001');
 IF v.wallet_cash_usdt<>5 OR v.cross_unrealized_pnl_usdt<>399
 OR v.unposted_funding_liability_usdt<>2 OR v.unposted_funding_receivable_usdt<>1
 OR v.close_fee_reserve_usdt<>2.1606 OR v.equity_usdt<>400.8394
 OR v.maintenance_margin_usdt<>36.01 OR v.margin_ratio<>round(400.8394/36.01,18)
 OR v.cross_position_count<>1 OR jsonb_array_length(v.position_snapshots)<>2 THEN
  RAISE EXCEPTION 'Cross account risk aggregation mismatch: %',row_to_json(v);
 END IF;
 IF v.position_snapshots->0->>'symbol'<>'BTCUSDT'
 OR (v.position_snapshots->0->>'unposted_funding_liability_usdt')::numeric<>7
 OR (v.position_snapshots->0->>'close_fee_reserve_usdt')::numeric<>12.003
 OR v.position_snapshots->1->>'symbol'<>'ETHUSDT'
 OR (v.position_snapshots->1->>'unposted_funding_liability_usdt')::numeric<>2
 OR (v.position_snapshots->1->>'unposted_funding_receivable_usdt')::numeric<>1 THEN
  RAISE EXCEPTION 'Per-position funding/fee values mismatch: %',v.position_snapshots;
 END IF;
END;
$account_risk_test$;

-- A newer stale oracle result must block the account snapshot rather than
-- silently falling back to the previous still-recorded healthy snapshot.
SET request.jwt.claim.role='service_role';
SET ROLE service_role;
DO $publish_stale$
DECLARE
  v_old timestamptz:=clock_timestamp()-interval '120 seconds';
BEGIN
  PERFORM private.demo_derivative_price_start_cycle(
    'a2000000-0000-0000-0000-000000000003','ETHUSDT',
    ARRAY['binance_usdm','bybit_linear'],
    '{"binance_usdm":"ETHUSDT","bybit_linear":"ETHUSDT"}'::jsonb
  );
  PERFORM private.demo_derivative_price_record_provider_result(
    'a2000000-0000-0000-0000-000000000003','binance_usdm','accepted',
    1800,1799,v_old,repeat('1',64),NULL
  );
  PERFORM private.demo_derivative_price_record_provider_result(
    'a2000000-0000-0000-0000-000000000003','bybit_linear','accepted',
    1801,1800,v_old,repeat('2',64),NULL
  );
  PERFORM private.demo_derivative_price_publish_snapshot(
    'a2000000-0000-0000-0000-000000000003',
    'b2000000-0000-0000-0000-000000000003','stale',
    NULL,NULL,ARRAY['binance_usdm','bybit_linear'],
    NULL,NULL,'[{"reason":"provider_timestamp_stale"}]'::jsonb
  );
END;
$publish_stale$;
RESET ROLE;
RESET request.jwt.claim.role;

DO $fail_closed$
BEGIN
  BEGIN
    PERFORM * FROM private.demo_derivative_account_maintenance_snapshot('20000000-0000-0000-0000-000000000001');
    RAISE EXCEPTION 'account snapshot unexpectedly used an older healthy ETH snapshot';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
  END;
  BEGIN
    PERFORM * FROM private.demo_derivative_account_risk_snapshot('20000000-0000-0000-0000-000000000001');
    RAISE EXCEPTION 'account risk snapshot unexpectedly used an older healthy ETH snapshot';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
  END;
END;
$fail_closed$;

DO $privileges$
BEGIN
  IF has_function_privilege('anon','private.demo_derivative_account_maintenance_snapshot(uuid)','EXECUTE')
     OR has_function_privilege('authenticated','private.demo_derivative_account_maintenance_snapshot(uuid)','EXECUTE')
     OR NOT has_function_privilege('service_role','private.demo_derivative_account_maintenance_snapshot(uuid)','EXECUTE')
     OR has_function_privilege('anon','private.demo_derivative_account_risk_snapshot(uuid)','EXECUTE')
     OR has_function_privilege('authenticated','private.demo_derivative_account_risk_snapshot(uuid)','EXECUTE')
     OR NOT has_function_privilege('service_role','private.demo_derivative_account_risk_snapshot(uuid)','EXECUTE') THEN
    RAISE EXCEPTION 'account maintenance snapshot grants are incorrect';
  END IF;
END;
$privileges$;

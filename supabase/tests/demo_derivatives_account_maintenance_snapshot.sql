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
    v_ts,v_ts+interval '5 seconds','[]'::jsonb
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
    v_ts,v_ts+interval '5 seconds','[]'::jsonb
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
END;
$fail_closed$;

DO $privileges$
BEGIN
  IF has_function_privilege('anon','private.demo_derivative_account_maintenance_snapshot(uuid)','EXECUTE')
     OR has_function_privilege('authenticated','private.demo_derivative_account_maintenance_snapshot(uuid)','EXECUTE')
     OR NOT has_function_privilege('service_role','private.demo_derivative_account_maintenance_snapshot(uuid)','EXECUTE') THEN
    RAISE EXCEPTION 'account maintenance snapshot grants are incorrect';
  END IF;
END;
$privileges$;

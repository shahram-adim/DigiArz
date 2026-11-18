\set ON_ERROR_STOP on
-- Run after demo_derivatives_schema_setup.sql and the oracle storage draft.
DO $policy$
BEGIN
  INSERT INTO private.demo_derivative_price_policies(
    symbol,policy_version,enabled,eligible_providers,min_sources,max_age_ms,max_future_skew_ms,
    max_mark_deviation_bps,max_index_deviation_bps,max_mark_index_deviation_bps
  ) VALUES ('BTCUSDT',1,true,ARRAY['binance_usdm','bybit_linear','okx_swap'],2,5000,250,50,50,200);
  BEGIN
    INSERT INTO private.demo_derivative_price_policies(
      symbol,policy_version,enabled,eligible_providers,min_sources,max_age_ms,max_future_skew_ms,
      max_mark_deviation_bps,max_index_deviation_bps,max_mark_index_deviation_bps
    ) VALUES ('BTCUSDT',2,true,ARRAY['binance_usdm','bybit_linear'],2,5000,250,50,50,200);
    RAISE EXCEPTION 'second enabled policy unexpectedly accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
END;
$policy$;

INSERT INTO private.demo_derivative_price_cycles(id,symbol,policy_version,expected_providers)
VALUES ('a1000000-0000-0000-0000-000000000001','BTCUSDT',1,ARRAY['binance_usdm','bybit_linear']);
INSERT INTO private.demo_derivative_price_cycle_sources(cycle_id,provider,provider_instrument)
VALUES
 ('a1000000-0000-0000-0000-000000000001','binance_usdm','BTCUSDT'),
 ('a1000000-0000-0000-0000-000000000001','bybit_linear','BTCUSDT');

DO $incomplete_cycle$
BEGIN
  BEGIN
    UPDATE private.demo_derivative_price_cycles SET cycle_status='completed'
    WHERE id='a1000000-0000-0000-0000-000000000001';
    RAISE EXCEPTION 'cycle with pending sources unexpectedly completed';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END;
$incomplete_cycle$;

INSERT INTO private.demo_derivative_price_observations(
 cycle_id,symbol,provider,mark_price,index_price,provider_timestamp,validation_status,response_sha256
) VALUES
 ('a1000000-0000-0000-0000-000000000001','BTCUSDT','binance_usdm',100,99.5,clock_timestamp(),'accepted',repeat('a',64)),
 ('a1000000-0000-0000-0000-000000000001','BTCUSDT','bybit_linear',100.1,99.6,clock_timestamp(),'accepted',repeat('b',64));
UPDATE private.demo_derivative_price_cycle_sources
SET source_status='received',provider_timestamp=clock_timestamp(),received_at=clock_timestamp(),response_sha256=repeat('a',64)
WHERE cycle_id='a1000000-0000-0000-0000-000000000001' AND provider='binance_usdm';
UPDATE private.demo_derivative_price_cycle_sources
SET source_status='received',provider_timestamp=clock_timestamp(),received_at=clock_timestamp(),response_sha256=repeat('b',64)
WHERE cycle_id='a1000000-0000-0000-0000-000000000001' AND provider='bybit_linear';

INSERT INTO private.demo_derivative_price_snapshots(
 cycle_id,symbol,policy_version,snapshot_status,mark_price,index_price,source_count,source_providers,as_of,expires_at
) VALUES (
 'a1000000-0000-0000-0000-000000000001','BTCUSDT',1,'healthy',100.05,99.55,2,
 ARRAY['binance_usdm','bybit_linear'],clock_timestamp(),clock_timestamp()+interval '5 seconds'
);
UPDATE private.demo_derivative_price_cycles SET cycle_status='completed'
WHERE id='a1000000-0000-0000-0000-000000000001';

DO $assertions$
BEGIN
  IF (SELECT cycle_status FROM private.demo_derivative_price_cycles
      WHERE id='a1000000-0000-0000-0000-000000000001')<>'completed' THEN
    RAISE EXCEPTION 'cycle did not complete';
  END IF;
  IF (SELECT count(*) FROM private.demo_derivative_price_observations
      WHERE cycle_id='a1000000-0000-0000-0000-000000000001')<>2 THEN
    RAISE EXCEPTION 'provider observation history incomplete';
  END IF;
  IF has_table_privilege('authenticated','private.demo_derivative_price_observations','SELECT')
     OR has_table_privilege('anon','private.demo_derivative_price_snapshots','SELECT') THEN
    RAISE EXCEPTION 'client role unexpectedly has oracle table access';
  END IF;
  IF has_table_privilege('service_role','private.demo_derivative_price_observations','UPDATE')
     OR has_table_privilege('service_role','private.demo_derivative_price_snapshots','DELETE') THEN
    RAISE EXCEPTION 'trusted collector has mutation privilege on append-only records';
  END IF;
  BEGIN
    UPDATE private.demo_derivative_price_observations SET mark_price=101
    WHERE cycle_id='a1000000-0000-0000-0000-000000000001' AND provider='binance_usdm';
    RAISE EXCEPTION 'append-only observation unexpectedly updated';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
  END;
  BEGIN
    DELETE FROM private.demo_derivative_price_snapshots
    WHERE cycle_id='a1000000-0000-0000-0000-000000000001';
    RAISE EXCEPTION 'append-only snapshot unexpectedly deleted';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
  END;
END;
$assertions$;

DO $rejected_cycle$
DECLARE v_cycle uuid := 'a1000000-0000-0000-0000-000000000002';
BEGIN
  INSERT INTO private.demo_derivative_price_cycles(id,symbol,policy_version,expected_providers)
  VALUES (v_cycle,'BTCUSDT',1,ARRAY['binance_usdm','bybit_linear']);
  INSERT INTO private.demo_derivative_price_cycle_sources(cycle_id,provider,provider_instrument)
  VALUES (v_cycle,'binance_usdm','BTCUSDT'),(v_cycle,'bybit_linear','BTCUSDT');
  UPDATE private.demo_derivative_price_cycle_sources
    SET source_status='failed',received_at=clock_timestamp(),failure_reason='provider_timeout'
    WHERE cycle_id=v_cycle AND provider='binance_usdm';
  UPDATE private.demo_derivative_price_cycle_sources
    SET source_status='failed',received_at=clock_timestamp(),failure_reason='provider_timeout'
    WHERE cycle_id=v_cycle AND provider='bybit_linear';
  INSERT INTO private.demo_derivative_price_snapshots(
    cycle_id,symbol,policy_version,snapshot_status,source_count,source_providers,rejected_details
  ) VALUES (v_cycle,'BTCUSDT',1,'insufficient_quorum',0,ARRAY[]::text_,'[{"reason":"provider_timeout"}]'::jsonb);
  UPDATE private.demo_derivative_price_cycles SET cycle_status='completed' WHERE id=v_cycle;
END;
$rejected_cycle$;

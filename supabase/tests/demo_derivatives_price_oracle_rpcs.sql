\set ON_ERROR_STOP on
-- Run after the oracle storage and trusted RPC drafts in disposable PostgreSQL 17.

INSERT INTO private.demo_derivative_price_policies(
  symbol,policy_version,enabled,eligible_providers,min_sources,max_age_ms,max_future_skew_ms,
  max_mark_deviation_bps,max_index_deviation_bps,max_mark_index_deviation_bps
) VALUES ('ETHUSDT',1,true,ARRAY['binance_usdm','bybit_linear'],2,5000,250,50,50,200);

SET request.jwt.claim.role='service_role';
SET ROLE service_role;

DO $start_cycle$
DECLARE v_id uuid;
BEGIN
  v_id:=private.demo_derivative_price_start_cycle(
    'a1000000-0000-0000-0000-000000000010','ETHUSDT',
    ARRAY['bybit_linear','binance_usdm'],
    '{"binance_usdm":"ETHUSDT","bybit_linear":"ETHUSDT"}'::jsonb
  );
  IF v_id<>'a1000000-0000-0000-0000-000000000010' THEN
    RAISE EXCEPTION 'cycle creation returned an unexpected id';
  END IF;
  IF private.demo_derivative_price_start_cycle(
    'a1000000-0000-0000-0000-000000000010','ETHUSDT',
    ARRAY['binance_usdm','bybit_linear'],
    '{"binance_usdm":"ETHUSDT","bybit_linear":"ETHUSDT"}'::jsonb
  )<>v_id THEN
    RAISE EXCEPTION 'identical cycle retry was not idempotent';
  END IF;
  BEGIN
    PERFORM private.demo_derivative_price_start_cycle(
      'a1000000-0000-0000-0000-000000000010','ETHUSDT',
      ARRAY['binance_usdm','bybit_linear'],
      '{"binance_usdm":"ETHUSDT-PERP","bybit_linear":"ETHUSDT"}'::jsonb
    );
    RAISE EXCEPTION 'cycle id reuse with different instrument map unexpectedly succeeded';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
END;
$start_cycle$;

DO $provider_results$
DECLARE v_ts timestamptz:=clock_timestamp();
BEGIN
  IF private.demo_derivative_price_record_provider_result(
    'a1000000-0000-0000-0000-000000000010','binance_usdm','accepted',
    100,99.9,v_ts,repeat('a',64),NULL
  )<>'received' THEN RAISE EXCEPTION 'first provider result was not recorded'; END IF;

  -- A healthy snapshot cannot be published while another expected provider is pending.
  BEGIN
    PERFORM private.demo_derivative_price_publish_snapshot(
      'a1000000-0000-0000-0000-000000000010',
      'b1000000-0000-0000-0000-000000000010','healthy',
      100,99.9,ARRAY['binance_usdm'],v_ts,v_ts+interval '5 seconds','[]'::jsonb
    );
    RAISE EXCEPTION 'snapshot unexpectedly published with a pending provider';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  IF private.demo_derivative_price_record_provider_result(
    'a1000000-0000-0000-0000-000000000010','bybit_linear','accepted',
    100.1,100.0,v_ts,repeat('b',64),NULL
  )<>'received' THEN RAISE EXCEPTION 'second provider result was not recorded'; END IF;

  -- Identical retries are harmless; a changed payload under the same provider/cycle is rejected.
  PERFORM private.demo_derivative_price_record_provider_result(
    'a1000000-0000-0000-0000-000000000010','binance_usdm','accepted',
    100,99.9,v_ts,repeat('a',64),NULL
  );
  BEGIN
    PERFORM private.demo_derivative_price_record_provider_result(
      'a1000000-0000-0000-0000-000000000010','binance_usdm','accepted',
      101,99.9,v_ts,repeat('a',64),NULL
    );
    RAISE EXCEPTION 'provider retry with changed price unexpectedly succeeded';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;

  IF private.demo_derivative_price_publish_snapshot(
    'a1000000-0000-0000-0000-000000000010',
    'b1000000-0000-0000-0000-000000000010','healthy',
    100.05,99.95,ARRAY['binance_usdm','bybit_linear'],
    v_ts,v_ts+interval '5 seconds','[]'::jsonb
  )<>'b1000000-0000-0000-0000-000000000010' THEN
    RAISE EXCEPTION 'snapshot publication returned an unexpected id';
  END IF;

  -- Publication retry and late duplicate provider delivery must be idempotent.
  PERFORM private.demo_derivative_price_publish_snapshot(
    'a1000000-0000-0000-0000-000000000010',
    'b1000000-0000-0000-0000-000000000010','healthy',
    100.05,99.95,ARRAY['binance_usdm','bybit_linear'],
    v_ts,v_ts+interval '5 seconds','[]'::jsonb
  );
  PERFORM private.demo_derivative_price_record_provider_result(
    'a1000000-0000-0000-0000-000000000010','bybit_linear','accepted',
    100.1,100.0,v_ts,repeat('b',64),NULL
  );
END;
$provider_results$;

RESET ROLE;
RESET request.jwt.claim.role;

DO $persisted$
BEGIN
  IF (SELECT cycle_status FROM private.demo_derivative_price_cycles
      WHERE id='a1000000-0000-0000-0000-000000000010')<>'completed' THEN
    RAISE EXCEPTION 'price cycle was not atomically completed';
  END IF;
  IF (SELECT snapshot_status FROM private.demo_derivative_price_snapshots
      WHERE id='b1000000-0000-0000-0000-000000000010')<>'healthy' THEN
    RAISE EXCEPTION 'healthy snapshot was not persisted';
  END IF;
  IF has_table_privilege('service_role','private.demo_derivative_price_observations','INSERT')
     OR has_table_privilege('service_role','private.demo_derivative_price_snapshots','INSERT') THEN
    RAISE EXCEPTION 'service_role can bypass the narrow ingestion RPCs';
  END IF;
  IF has_function_privilege('anon','private.demo_derivative_price_start_cycle(uuid,text,text[],jsonb)','EXECUTE')
     OR has_function_privilege('authenticated','private.demo_derivative_price_publish_snapshot(uuid,uuid,text,numeric,numeric,text[],timestamp with time zone,timestamp with time zone,jsonb)','EXECUTE') THEN
    RAISE EXCEPTION 'client role unexpectedly has oracle RPC execution';
  END IF;
  IF NOT has_function_privilege('service_role','private.demo_derivative_price_start_cycle(uuid,text,text[],jsonb)','EXECUTE')
     OR NOT has_function_privilege('service_role','private.demo_derivative_price_record_provider_result(uuid,text,text,numeric,numeric,timestamp with time zone,text,text)','EXECUTE')
     OR NOT has_function_privilege('service_role','private.demo_derivative_price_publish_snapshot(uuid,uuid,text,numeric,numeric,text[],timestamp with time zone,timestamp with time zone,jsonb)','EXECUTE') THEN
    RAISE EXCEPTION 'service_role is missing an oracle RPC grant';
  END IF;
END;
$persisted$;

SET ROLE authenticated;
SET request.jwt.claim.role='authenticated';
DO $unauthorized$
BEGIN
  BEGIN
    PERFORM private.demo_derivative_price_start_cycle(
      'a1000000-0000-0000-0000-000000000099','ETHUSDT',
      ARRAY['binance_usdm','bybit_linear'],
      '{"binance_usdm":"ETHUSDT","bybit_linear":"ETHUSDT"}'::jsonb
    );
    RAISE EXCEPTION 'authenticated role unexpectedly invoked oracle ingestion';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$unauthorized$;
RESET ROLE;
RESET request.jwt.claim.role;

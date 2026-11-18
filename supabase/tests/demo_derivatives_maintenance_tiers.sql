\set ON_ERROR_STOP on
-- Run after demo_derivatives_schema_setup.sql and the maintenance-tier draft.

INSERT INTO private.demo_derivative_maintenance_tier_schedules(id,symbol,schedule_version)
VALUES
 ('c1000000-0000-0000-0000-000000000001','BTCUSDT',1),
 ('c1000000-0000-0000-0000-000000000002','BTCUSDT',2),
 ('c1000000-0000-0000-0000-000000000003','ETHUSDT',1);

INSERT INTO private.demo_derivative_maintenance_tiers(
 schedule_id,tier_index,max_notional,maintenance_rate,maintenance_amount,max_leverage
) VALUES
 ('c1000000-0000-0000-0000-000000000001',1,10000,0.01,0,100),
 ('c1000000-0000-0000-0000-000000000001',2,50000,0.02,100,50),
 ('c1000000-0000-0000-0000-000000000001',3,NULL,0.05,1600,25),
 ('c1000000-0000-0000-0000-000000000002',1,10000,0.015,0,75),
 ('c1000000-0000-0000-0000-000000000002',2,NULL,0.025,100,25),
 ('c1000000-0000-0000-0000-000000000003',1,10000,0.01,0,100),
 ('c1000000-0000-0000-0000-000000000003',2,NULL,0.02,99,50);

-- Activate v1, then verify resolver results at and above a tier boundary.
SELECT * FROM private.demo_derivative_activate_maintenance_schedule('c1000000-0000-0000-0000-000000000001');

DO $assert_v1$
DECLARE v record;
BEGIN
  SELECT * INTO v FROM private.demo_derivative_resolve_maintenance_tier('BTCUSDT',10000);
  IF v.schedule_version<>1 OR v.tier_index<>1 OR v.maintenance_margin<>100 OR v.max_leverage<>100 THEN
    RAISE EXCEPTION 'BTC v1 first tier resolution is incorrect: %',row_to_json(v);
  END IF;
  SELECT * INTO v FROM private.demo_derivative_resolve_maintenance_tier('BTCUSDT',20000);
  IF v.schedule_version<>1 OR v.tier_index<>2 OR v.maintenance_margin<>300 OR v.max_leverage<>50 THEN
    RAISE EXCEPTION 'BTC v1 second tier resolution is incorrect: %',row_to_json(v);
  END IF;
END;
$assert_v1$;

-- A discontinuous schedule must not activate, and the current version remains active.
DO $invalid_schedule$
BEGIN
  BEGIN
    PERFORM * FROM private.demo_derivative_activate_maintenance_schedule('c1000000-0000-0000-0000-000000000003');
    RAISE EXCEPTION 'discontinuous maintenance schedule unexpectedly activated';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  IF (SELECT status FROM private.demo_derivative_maintenance_tier_schedules
      WHERE id='c1000000-0000-0000-0000-000000000003')<>'draft' THEN
    RAISE EXCEPTION 'invalid schedule did not remain draft';
  END IF;
  IF (SELECT count(*) FROM private.demo_derivative_maintenance_tier_schedules
      WHERE symbol='BTCUSDT' AND status='active')<>1 THEN
    RAISE EXCEPTION 'invalid schedule changed the existing active schedule';
  END IF;
END;
$invalid_schedule$;

-- A newer valid version retires v1 atomically and becomes the only active version.
SELECT * FROM private.demo_derivative_activate_maintenance_schedule('c1000000-0000-0000-0000-000000000002');

DO $assert_v2$
DECLARE v record;
BEGIN
  IF (SELECT status FROM private.demo_derivative_maintenance_tier_schedules
      WHERE id='c1000000-0000-0000-0000-000000000001')<>'retired' THEN
    RAISE EXCEPTION 'previous maintenance schedule was not retired';
  END IF;
  IF (SELECT count(*) FROM private.demo_derivative_maintenance_tier_schedules
      WHERE symbol='BTCUSDT' AND status='active')<>1 THEN
    RAISE EXCEPTION 'more than one active schedule exists for a symbol';
  END IF;
  SELECT * INTO v FROM private.demo_derivative_resolve_maintenance_tier('BTCUSDT',20000);
  IF v.schedule_version<>2 OR v.tier_index<>2 OR v.maintenance_margin<>400 OR v.max_leverage<>25 THEN
    RAISE EXCEPTION 'BTC v2 schedule was not resolved: %',row_to_json(v);
  END IF;
END;
$assert_v2$;

-- Active/retired schedules and their tiers are immutable.
DO $immutability$
BEGIN
  BEGIN
    UPDATE private.demo_derivative_maintenance_tiers SET maintenance_rate=0.03
    WHERE schedule_id='c1000000-0000-0000-0000-000000000002' AND tier_index=1;
    RAISE EXCEPTION 'active tier unexpectedly updated';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
  END;
  BEGIN
    UPDATE private.demo_derivative_maintenance_tier_schedules SET schedule_version=9
    WHERE id='c1000000-0000-0000-0000-000000000001';
    RAISE EXCEPTION 'retired schedule unexpectedly updated';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
  END;
END;
$immutability$;

-- Service role may call the resolver, but neither clients nor service role can
-- directly read/write the private configuration tables.
DO $privileges$
BEGIN
  IF has_schema_privilege('anon','private','USAGE')
     OR has_schema_privilege('authenticated','private','USAGE')
     OR NOT has_schema_privilege('service_role','private','USAGE') THEN
    RAISE EXCEPTION 'private schema usage grants are incorrect';
  END IF;
  IF has_table_privilege('anon','private.demo_derivative_maintenance_tiers','SELECT')
     OR has_table_privilege('authenticated','private.demo_derivative_maintenance_tiers','SELECT')
     OR has_table_privilege('service_role','private.demo_derivative_maintenance_tiers','SELECT')
     OR has_table_privilege('service_role','private.demo_derivative_maintenance_tiers','INSERT') THEN
    RAISE EXCEPTION 'private maintenance configuration table is directly accessible';
  END IF;
  IF has_function_privilege('anon','private.demo_derivative_resolve_maintenance_tier(text,numeric)','EXECUTE')
     OR has_function_privilege('authenticated','private.demo_derivative_resolve_maintenance_tier(text,numeric)','EXECUTE')
     OR NOT has_function_privilege('service_role','private.demo_derivative_resolve_maintenance_tier(text,numeric)','EXECUTE') THEN
    RAISE EXCEPTION 'maintenance resolver execution grants are incorrect';
  END IF;
END;
$privileges$;

SET ROLE service_role;
DO $service_role_resolution$
DECLARE v record;
BEGIN
  SELECT * INTO v FROM private.demo_derivative_resolve_maintenance_tier('BTCUSDT',20000);
  IF v.schedule_version<>2 OR v.maintenance_margin<>400 THEN
    RAISE EXCEPTION 'service_role resolver returned an unexpected tier';
  END IF;
END;
$service_role_resolution$;
RESET ROLE;

DO $invalid_inputs$
BEGIN
  BEGIN
    PERFORM * FROM private.demo_derivative_resolve_maintenance_tier('BTCUSDT',0);
    RAISE EXCEPTION 'zero notional unexpectedly resolved';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    PERFORM * FROM private.demo_derivative_resolve_maintenance_tier('BTC/USDT',100);
    RAISE EXCEPTION 'invalid symbol unexpectedly resolved';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    PERFORM * FROM private.demo_derivative_resolve_maintenance_tier('ETHUSDT',100);
    RAISE EXCEPTION 'symbol without active schedule unexpectedly resolved';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
  END;
END;
$invalid_inputs$;

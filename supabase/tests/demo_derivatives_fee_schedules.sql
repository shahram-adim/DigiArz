\set ON_ERROR_STOP on
INSERT INTO private.demo_derivative_fee_schedules(id,symbol,schedule_version,maker_fee_rate,taker_fee_rate) VALUES
 ('d2000000-0000-0000-0000-000000000001','BTCUSDT',1,0.0002,0.0006),
 ('d2000000-0000-0000-0000-000000000002','ETHUSDT',1,0.0002,0.0006);
SET request.jwt.claim.role='service_role'; SET ROLE service_role;
SELECT * FROM private.demo_derivative_activate_fee_schedule('d2000000-0000-0000-0000-000000000001');
SELECT * FROM private.demo_derivative_activate_fee_schedule('d2000000-0000-0000-0000-000000000002');
RESET ROLE; RESET request.jwt.claim.role;
INSERT INTO private.demo_derivative_fee_schedules(id,symbol,schedule_version,maker_fee_rate,taker_fee_rate)
 VALUES('d2000000-0000-0000-0000-000000000003','BTCUSDT',2,0.0002,0.0006);
SET request.jwt.claim.role='service_role'; SET ROLE service_role;
SELECT * FROM private.demo_derivative_activate_fee_schedule('d2000000-0000-0000-0000-000000000003');
DO $resolver$
DECLARE v record;
BEGIN
 SELECT * INTO v FROM private.demo_derivative_resolve_fee_schedule('BTCUSDT');
 IF v.schedule_version<>2 OR v.taker_fee_rate<>0.0006 THEN RAISE EXCEPTION 'BTC fee resolver mismatch: %',row_to_json(v); END IF;
 SELECT * INTO v FROM private.demo_derivative_resolve_fee_schedule('ETHUSDT');
 IF v.schedule_version<>1 OR v.taker_fee_rate<>0.0006 THEN RAISE EXCEPTION 'ETH fee resolver mismatch: %',row_to_json(v); END IF;
END;
$resolver$;
RESET ROLE; RESET request.jwt.claim.role;
DO $guards$
BEGIN
 BEGIN
  UPDATE private.demo_derivative_fee_schedules SET taker_fee_rate=0.0007 WHERE id='d2000000-0000-0000-0000-000000000003';
  RAISE EXCEPTION 'Active fee schedule mutation unexpectedly succeeded';
 EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL; END;
 BEGIN
  INSERT INTO private.demo_derivative_fee_schedules(id,symbol,schedule_version,maker_fee_rate,taker_fee_rate)
  VALUES('d2000000-0000-0000-0000-000000000004','BTCUSDT',3,0.001,0.0005);
  RAISE EXCEPTION 'Invalid maker/taker ordering unexpectedly succeeded';
 EXCEPTION WHEN check_violation THEN NULL; END;
 BEGIN
  PERFORM * FROM private.demo_derivative_activate_fee_schedule('d2000000-0000-0000-0000-000000000001');
  RAISE EXCEPTION 'Retired fee schedule unexpectedly reactivated';
 EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL; END;
END;
$guards$;
DO $privileges$
BEGIN
 IF has_table_privilege('anon','private.demo_derivative_fee_schedules','SELECT')
 OR has_table_privilege('authenticated','private.demo_derivative_fee_schedules','SELECT')
 OR has_table_privilege('service_role','private.demo_derivative_fee_schedules','SELECT')
 OR has_function_privilege('anon','private.demo_derivative_activate_fee_schedule(uuid)','EXECUTE')
 OR has_function_privilege('authenticated','private.demo_derivative_activate_fee_schedule(uuid)','EXECUTE')
 OR NOT has_function_privilege('service_role','private.demo_derivative_activate_fee_schedule(uuid)','EXECUTE')
 OR has_function_privilege('anon','private.demo_derivative_resolve_fee_schedule(text)','EXECUTE')
 OR has_function_privilege('authenticated','private.demo_derivative_resolve_fee_schedule(text)','EXECUTE')
 OR NOT has_function_privilege('service_role','private.demo_derivative_resolve_fee_schedule(text)','EXECUTE') THEN
  RAISE EXCEPTION 'Fee schedule privileges are incorrect';
 END IF;
END;
$privileges$;

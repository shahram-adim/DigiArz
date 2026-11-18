BEGIN;
-- DRAFT ONLY: versioned server-owned Futures fee schedules.
CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC,anon,authenticated;
GRANT USAGE ON SCHEMA private TO service_role;
CREATE TABLE private.demo_derivative_fee_schedules(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 symbol text NOT NULL CHECK(symbol ~ '^[A-Z0-9]{2,15}USDT$'),
 schedule_version integer NOT NULL CHECK(schedule_version>0),
 maker_fee_rate numeric(20,18) NOT NULL CHECK(maker_fee_rate>=0 AND maker_fee_rate<1),
 taker_fee_rate numeric(20,18) NOT NULL CHECK(taker_fee_rate>=maker_fee_rate AND taker_fee_rate<1),
 status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','active','retired')),
 effective_from timestamptz NOT NULL DEFAULT clock_timestamp(),
 retired_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(symbol,schedule_version),
 CHECK((status='retired' AND retired_at IS NOT NULL) OR (status<>'retired' AND retired_at IS NULL))
);
CREATE UNIQUE INDEX demo_derivative_fee_one_active_schedule_uidx
 ON private.demo_derivative_fee_schedules(symbol) WHERE status='active';
CREATE FUNCTION private.guard_demo_derivative_fee_schedule()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $function$
BEGIN
 IF TG_OP='DELETE' THEN RAISE EXCEPTION 'Fee schedules cannot be deleted' USING ERRCODE='55000'; END IF;
 IF OLD.status='retired' THEN RAISE EXCEPTION 'Retired fee schedules are immutable' USING ERRCODE='55000'; END IF;
 IF OLD.status='active' THEN
  IF NEW.status<>'retired' OR (to_jsonb(NEW)-'status'-'retired_at') IS DISTINCT FROM (to_jsonb(OLD)-'status'-'retired_at') THEN
   RAISE EXCEPTION 'Active fee schedules are immutable' USING ERRCODE='55000';
  END IF;
  NEW.retired_at:=COALESCE(NEW.retired_at,clock_timestamp()); RETURN NEW;
 END IF;
 IF NEW.status NOT IN ('draft','active') THEN RAISE EXCEPTION 'Invalid fee schedule transition' USING ERRCODE='55000'; END IF;
 IF NEW.status='active' AND NEW.effective_from>clock_timestamp() THEN RAISE EXCEPTION 'Fee schedule is not yet effective' USING ERRCODE='23514'; END IF;
 RETURN NEW;
END;
$function$;
CREATE TRIGGER demo_derivative_fee_schedule_guard BEFORE UPDATE OR DELETE
 ON private.demo_derivative_fee_schedules FOR EACH ROW EXECUTE FUNCTION private.guard_demo_derivative_fee_schedule();
CREATE FUNCTION private.demo_derivative_activate_fee_schedule(p_id uuid)
RETURNS TABLE(schedule_id uuid,symbol text,schedule_version integer,maker_fee_rate numeric,taker_fee_rate numeric)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $function$
DECLARE v_symbol text; v_status text;
BEGIN
 SELECT s.symbol INTO v_symbol FROM private.demo_derivative_fee_schedules s WHERE s.id=p_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Unknown fee schedule' USING ERRCODE='P0002'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(v_symbol,1));
 SELECT s.status INTO v_status FROM private.demo_derivative_fee_schedules s WHERE s.id=p_id FOR UPDATE;
 IF v_status='active' THEN
  RETURN QUERY SELECT s.id,s.symbol,s.schedule_version,s.maker_fee_rate,s.taker_fee_rate FROM private.demo_derivative_fee_schedules s WHERE s.id=p_id; RETURN;
 END IF;
 IF v_status<>'draft' THEN RAISE EXCEPTION 'Only draft fee schedules can be activated' USING ERRCODE='55000'; END IF;
 IF EXISTS(SELECT 1 FROM private.demo_derivative_fee_schedules s WHERE s.symbol=v_symbol AND s.status IN('active','retired')
  AND s.schedule_version>=(SELECT x.schedule_version FROM private.demo_derivative_fee_schedules x WHERE x.id=p_id)) THEN
  RAISE EXCEPTION 'Fee schedule version must increase monotonically' USING ERRCODE='23514';
 END IF;
 UPDATE private.demo_derivative_fee_schedules s SET status='retired',retired_at=clock_timestamp() WHERE s.symbol=v_symbol AND s.status='active';
 UPDATE private.demo_derivative_fee_schedules s SET status='active' WHERE s.id=p_id;
 RETURN QUERY SELECT s.id,s.symbol,s.schedule_version,s.maker_fee_rate,s.taker_fee_rate FROM private.demo_derivative_fee_schedules s WHERE s.id=p_id;
END;
$function$;
CREATE FUNCTION private.demo_derivative_resolve_fee_schedule(p_symbol text)
RETURNS TABLE(schedule_id uuid,symbol text,schedule_version integer,maker_fee_rate numeric,taker_fee_rate numeric)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $function$
BEGIN
 IF p_symbol IS NULL OR p_symbol !~ '^[A-Z0-9]{2,15}USDT$' THEN RAISE EXCEPTION 'Invalid Futures symbol' USING ERRCODE='22023'; END IF;
 RETURN QUERY SELECT s.id,s.symbol,s.schedule_version,s.maker_fee_rate,s.taker_fee_rate
 FROM private.demo_derivative_fee_schedules s
 WHERE s.symbol=p_symbol AND s.status='active' AND s.effective_from<=clock_timestamp()
 ORDER BY s.schedule_version DESC LIMIT 1 FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'No active fee schedule for %',p_symbol USING ERRCODE='55000'; END IF;
END;
$function$;
REVOKE ALL ON private.demo_derivative_fee_schedules FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.guard_demo_derivative_fee_schedule() FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.demo_derivative_activate_fee_schedule(uuid) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.demo_derivative_resolve_fee_schedule(text) FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_activate_fee_schedule(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_resolve_fee_schedule(text) TO service_role;
COMMIT;

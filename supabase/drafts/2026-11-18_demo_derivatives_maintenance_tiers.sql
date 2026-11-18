-- DRAFT ONLY: versioned server-owned Futures maintenance tiers.
-- Apply only to disposable PostgreSQL CI. Never deploy to Supabase Production without approval.
BEGIN;

CREATE SCHEMA IF NOT EXISTS private;
GRANT USAGE ON SCHEMA private TO service_role;

CREATE TABLE private.demo_derivative_maintenance_tier_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  symbol text NOT NULL CHECK (symbol ~ '^[A-Z0-9]{2,15}USDT$'),
  schedule_version integer NOT NULL CHECK (schedule_version > 0),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','active','retired')),
  effective_from timestamptz NOT NULL DEFAULT clock_timestamp(),
  retired_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  UNIQUE (symbol,schedule_version),
  CHECK ((status='retired' AND retired_at IS NOT NULL) OR (status<>'retired' AND retired_at IS NULL))
);

CREATE UNIQUE INDEX demo_derivative_maintenance_one_active_schedule_uidx
  ON private.demo_derivative_maintenance_tier_schedules(symbol)
  WHERE status='active';

CREATE TABLE private.demo_derivative_maintenance_tiers (
  schedule_id uuid NOT NULL
    REFERENCES private.demo_derivative_maintenance_tier_schedules(id) ON DELETE RESTRICT,
  tier_index smallint NOT NULL CHECK (tier_index > 0),
  max_notional numeric(38,18),
  maintenance_rate numeric(20,18) NOT NULL CHECK (maintenance_rate > 0 AND maintenance_rate < 1),
  maintenance_amount numeric(38,18) NOT NULL DEFAULT 0 CHECK (maintenance_amount >= 0),
  max_leverage smallint NOT NULL CHECK (max_leverage BETWEEN 1 AND 125),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (schedule_id,tier_index),
  CHECK (max_notional IS NULL OR max_notional > 0)
);

CREATE INDEX demo_derivative_maintenance_tiers_lookup_idx
  ON private.demo_derivative_maintenance_tiers(schedule_id,max_notional);

-- Uses the same conservative 18-decimal ceiling as the TypeScript/JavaScript
-- exact-decimal preview. Maintenance = ceil(notional * rate, 18dp) - cumulative deduction.
CREATE OR REPLACE FUNCTION private.demo_derivative_maintenance_schedule_valid(p_schedule_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM private.demo_derivative_maintenance_tiers t
  WHERE t.schedule_id=p_schedule_id;
  IF v_count=0 THEN RETURN false; END IF;

  IF EXISTS (
    SELECT 1
    FROM (
      SELECT
        t.*,
        row_number() OVER (ORDER BY t.tier_index) AS row_no,
        count(*) OVER () AS tier_count,
        lag(t.tier_index) OVER (ORDER BY t.tier_index) AS previous_index,
        lag(t.max_notional) OVER (ORDER BY t.tier_index) AS previous_max,
        lag(t.maintenance_rate) OVER (ORDER BY t.tier_index) AS previous_rate,
        lag(t.maintenance_amount) OVER (ORDER BY t.tier_index) AS previous_amount,
        lag(t.max_leverage) OVER (ORDER BY t.tier_index) AS previous_leverage
      FROM private.demo_derivative_maintenance_tiers t
      WHERE t.schedule_id=p_schedule_id
    ) ordered_tiers
    WHERE
      (row_no=1 AND maintenance_amount<>0)
      OR (row_no<tier_count AND max_notional IS NULL)
      OR (row_no=tier_count AND max_notional IS NOT NULL)
      OR (row_no>1 AND (
        tier_index<>previous_index+1
        OR previous_max IS NULL
        OR max_notional<=previous_max
        OR maintenance_rate<previous_rate
        OR max_leverage>previous_leverage
        OR ceil(previous_max*maintenance_rate*1000000000000000000::numeric)
             /1000000000000000000::numeric - maintenance_amount
           <> ceil(previous_max*previous_rate*1000000000000000000::numeric)
             /1000000000000000000::numeric - previous_amount
      ))
  ) THEN
    RETURN false;
  END IF;
  RETURN true;
END;
$function$;

CREATE OR REPLACE FUNCTION private.guard_demo_derivative_maintenance_schedule()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
  IF TG_OP='DELETE' THEN
    RAISE EXCEPTION 'Maintenance schedules cannot be deleted' USING ERRCODE='55000';
  END IF;
  IF OLD.status='retired' THEN
    RAISE EXCEPTION 'Retired maintenance schedules are immutable' USING ERRCODE='55000';
  END IF;
  IF OLD.status='active' THEN
    IF NEW.status<>'retired'
       OR (to_jsonb(NEW)-'status'-'retired_at') IS DISTINCT FROM (to_jsonb(OLD)-'status'-'retired_at') THEN
      RAISE EXCEPTION 'Active maintenance schedules are immutable; retire to replace' USING ERRCODE='55000';
    END IF;
    NEW.retired_at:=COALESCE(NEW.retired_at,clock_timestamp());
    RETURN NEW;
  END IF;
  IF NEW.status NOT IN ('draft','active') THEN
    RAISE EXCEPTION 'Invalid maintenance schedule transition' USING ERRCODE='55000';
  END IF;
  IF NEW.status='active' AND NOT private.demo_derivative_maintenance_schedule_valid(OLD.id) THEN
    RAISE EXCEPTION 'Maintenance tier schedule is incomplete or inconsistent' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER demo_derivative_maintenance_schedule_guard
  BEFORE UPDATE OR DELETE ON private.demo_derivative_maintenance_tier_schedules
  FOR EACH ROW EXECUTE FUNCTION private.guard_demo_derivative_maintenance_schedule();

CREATE OR REPLACE FUNCTION private.guard_demo_derivative_maintenance_tier()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_schedule_id uuid;
  v_status text;
BEGIN
  IF TG_OP='DELETE' THEN
    v_schedule_id:=OLD.schedule_id;
  ELSE
    v_schedule_id:=NEW.schedule_id;
  END IF;
  SELECT s.status INTO v_status
  FROM private.demo_derivative_maintenance_tier_schedules s
  WHERE s.id=v_schedule_id;
  IF v_status IS DISTINCT FROM 'draft' THEN
    RAISE EXCEPTION 'Tiers can only change while their schedule is draft' USING ERRCODE='55000';
  END IF;
  IF TG_OP='DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER demo_derivative_maintenance_tier_guard
  BEFORE INSERT OR UPDATE OR DELETE ON private.demo_derivative_maintenance_tiers
  FOR EACH ROW EXECUTE FUNCTION private.guard_demo_derivative_maintenance_tier();

CREATE OR REPLACE FUNCTION private.demo_derivative_activate_maintenance_schedule(p_schedule_id uuid)
RETURNS TABLE(schedule_id uuid,symbol text,schedule_version integer,activated_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_symbol text;
  v_status text;
BEGIN
  SELECT s.symbol,s.status INTO v_symbol,v_status
  FROM private.demo_derivative_maintenance_tier_schedules s
  WHERE s.id=p_schedule_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unknown maintenance schedule' USING ERRCODE='P0002';
  END IF;
  IF v_status<>'draft' THEN
    RAISE EXCEPTION 'Only a draft maintenance schedule can be activated' USING ERRCODE='55000';
  END IF;
  IF NOT private.demo_derivative_maintenance_schedule_valid(p_schedule_id) THEN
    RAISE EXCEPTION 'Maintenance tier schedule is incomplete or inconsistent' USING ERRCODE='23514';
  END IF;

  UPDATE private.demo_derivative_maintenance_tier_schedules s
  SET status='retired',retired_at=clock_timestamp()
  WHERE s.symbol=v_symbol AND s.status='active';

  UPDATE private.demo_derivative_maintenance_tier_schedules s
  SET status='active'
  WHERE s.id=p_schedule_id;

  RETURN QUERY
  SELECT s.id,s.symbol,s.schedule_version,s.effective_from
  FROM private.demo_derivative_maintenance_tier_schedules s
  WHERE s.id=p_schedule_id;
END;
$function$;

CREATE OR REPLACE FUNCTION private.demo_derivative_resolve_maintenance_tier(
  p_symbol text,
  p_notional numeric
)
RETURNS TABLE(
  schedule_id uuid,
  schedule_version integer,
  tier_index smallint,
  max_notional numeric,
  maintenance_rate numeric,
  maintenance_amount numeric,
  max_leverage smallint,
  maintenance_margin numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_schedule_id uuid;
  v_schedule_version integer;
  v_tier private.demo_derivative_maintenance_tiers%ROWTYPE;
  v_maintenance numeric;
BEGIN
  IF p_symbol IS NULL OR p_symbol !~ '^[A-Z0-9]{2,15}USDT$' THEN
    RAISE EXCEPTION 'Invalid Futures symbol' USING ERRCODE='22023';
  END IF;
  IF p_notional IS NULL OR p_notional<=0 THEN
    RAISE EXCEPTION 'Notional must be positive' USING ERRCODE='22023';
  END IF;

  SELECT s.id,s.schedule_version INTO v_schedule_id,v_schedule_version
  FROM private.demo_derivative_maintenance_tier_schedules s
  WHERE s.symbol=p_symbol AND s.status='active' AND s.effective_from<=clock_timestamp()
  ORDER BY s.schedule_version DESC
  LIMIT 1
  FOR SHARE;
  IF v_schedule_id IS NULL THEN
    RAISE EXCEPTION 'No active maintenance schedule for symbol %',p_symbol USING ERRCODE='55000';
  END IF;
  IF NOT private.demo_derivative_maintenance_schedule_valid(v_schedule_id) THEN
    RAISE EXCEPTION 'Active maintenance schedule failed integrity validation' USING ERRCODE='23514';
  END IF;

  SELECT t.* INTO v_tier
  FROM private.demo_derivative_maintenance_tiers t
  WHERE t.schedule_id=v_schedule_id
    AND (t.max_notional IS NULL OR p_notional<=t.max_notional)
  ORDER BY t.tier_index
  LIMIT 1;
  IF v_tier.schedule_id IS NULL THEN
    RAISE EXCEPTION 'No matching maintenance tier for symbol %',p_symbol USING ERRCODE='23514';
  END IF;
  v_maintenance:=ceil(p_notional*v_tier.maintenance_rate*1000000000000000000::numeric)
    /1000000000000000000::numeric-v_tier.maintenance_amount;
  IF v_maintenance<=0 THEN
    RAISE EXCEPTION 'Maintenance tier produced non-positive margin' USING ERRCODE='23514';
  END IF;

  RETURN QUERY SELECT v_schedule_id,v_schedule_version,v_tier.tier_index,v_tier.max_notional,
    v_tier.maintenance_rate,v_tier.maintenance_amount,v_tier.max_leverage,v_maintenance;
END;
$function$;

REVOKE ALL ON private.demo_derivative_maintenance_tier_schedules FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON private.demo_derivative_maintenance_tiers FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.demo_derivative_maintenance_schedule_valid(uuid) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.guard_demo_derivative_maintenance_schedule() FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.guard_demo_derivative_maintenance_tier() FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.demo_derivative_activate_maintenance_schedule(uuid) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.demo_derivative_resolve_maintenance_tier(text,numeric) FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_activate_maintenance_schedule(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_resolve_maintenance_tier(text,numeric) TO service_role;

COMMIT;

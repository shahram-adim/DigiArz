-- DRAFT ONLY: private, append-only Futures mark/index oracle storage.
-- No Production migration. No public Data API objects or client ingestion grants.
BEGIN;
CREATE SCHEMA IF NOT EXISTS private;
GRANT USAGE ON SCHEMA private TO service_role;

CREATE TABLE private.demo_derivative_price_policies (
  symbol text NOT NULL CHECK (symbol ~ '^[A-Z0-9]{2,15}USDT$'),
  policy_version integer NOT NULL CHECK (policy_version > 0),
  enabled boolean NOT NULL DEFAULT false,
  eligible_providers text[] NOT NULL,
  min_sources smallint NOT NULL CHECK (min_sources BETWEEN 2 AND 3),
  max_age_ms bigint NOT NULL CHECK (max_age_ms > 0),
  max_future_skew_ms bigint NOT NULL DEFAULT 0 CHECK (max_future_skew_ms >= 0),
  max_mark_deviation_bps numeric(12,4) NOT NULL CHECK (max_mark_deviation_bps >= 0),
  max_index_deviation_bps numeric(12,4) NOT NULL CHECK (max_index_deviation_bps >= 0),
  max_mark_index_deviation_bps numeric(12,4) NOT NULL CHECK (max_mark_index_deviation_bps >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (symbol,policy_version),
  CHECK (cardinality(eligible_providers) BETWEEN min_sources AND 3),
  CHECK (eligible_providers <@ ARRAY['binance_usdm','bybit_linear','okx_swap']::text[])
);
CREATE UNIQUE INDEX demo_derivative_price_policy_one_enabled_uidx
  ON private.demo_derivative_price_policies(symbol) WHERE enabled;

CREATE TABLE private.demo_derivative_price_cycles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  symbol text NOT NULL,
  policy_version integer NOT NULL,
  expected_providers text[] NOT NULL,
  cycle_status text NOT NULL DEFAULT 'collecting'
    CHECK (cycle_status IN ('collecting','completed','failed')),
  started_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  completed_at timestamptz,
  failure_reason text,
  FOREIGN KEY (symbol,policy_version)
    REFERENCES private.demo_derivative_price_policies(symbol,policy_version),
  UNIQUE (id,symbol),
  CHECK (cardinality(expected_providers) BETWEEN 2 AND 3),
  CHECK (expected_providers <@ ARRAY['binance_usdm','bybit_linear','okx_swap']::text[]),
  CHECK ((cycle_status='collecting' AND completed_at IS NULL)
      OR (cycle_status IN ('completed','failed') AND completed_at IS NOT NULL)),
  CHECK ((cycle_status='failed' AND failure_reason IS NOT NULL) OR cycle_status<>'failed')
);

CREATE TABLE private.demo_derivative_price_cycle_sources (
  cycle_id uuid NOT NULL REFERENCES private.demo_derivative_price_cycles(id) ON DELETE RESTRICT,
  provider text NOT NULL CHECK (provider IN ('binance_usdm','bybit_linear','okx_swap')),
  provider_instrument text NOT NULL,
  source_status text NOT NULL DEFAULT 'pending'
    CHECK (source_status IN ('pending','received','failed')),
  provider_timestamp timestamptz,
  received_at timestamptz,
  response_sha256 text CHECK (response_sha256 IS NULL OR response_sha256 ~ '^[0-9a-f]{64}$'),
  failure_reason text,
  PRIMARY KEY (cycle_id,provider),
  CHECK ((source_status='pending' AND received_at IS NULL AND response_sha256 IS NULL AND failure_reason IS NULL)
      OR (source_status='received' AND received_at IS NOT NULL AND response_sha256 IS NOT NULL AND failure_reason IS NULL)
      OR (source_status='failed' AND received_at IS NOT NULL AND failure_reason IS NOT NULL))
);

CREATE TABLE private.demo_derivative_price_observations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cycle_id uuid NOT NULL,
  symbol text NOT NULL,
  provider text NOT NULL,
  mark_price numeric(38,18),
  index_price numeric(38,18),
  provider_timestamp timestamptz,
  received_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  validation_status text NOT NULL CHECK (validation_status IN ('accepted','rejected')),
  rejection_reason text,
  response_sha256 text NOT NULL CHECK (response_sha256 ~ '^[0-9a-f]{64}$'),
  FOREIGN KEY (cycle_id,symbol)
    REFERENCES private.demo_derivative_price_cycles(id,symbol) ON DELETE RESTRICT,
  FOREIGN KEY (cycle_id,provider)
    REFERENCES private.demo_derivative_price_cycle_sources(cycle_id,provider) ON DELETE RESTRICT,
  UNIQUE (cycle_id,provider),
  CHECK (
    (validation_status='accepted' AND mark_price>0 AND index_price>0
      AND provider_timestamp IS NOT NULL AND rejection_reason IS NULL)
    OR
    (validation_status='rejected' AND rejection_reason IS NOT NULL)
  )
);

CREATE TABLE private.demo_derivative_price_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cycle_id uuid NOT NULL UNIQUE REFERENCES private.demo_derivative_price_cycles(id) ON DELETE RESTRICT,
  symbol text NOT NULL,
  policy_version integer NOT NULL,
  snapshot_status text NOT NULL CHECK (snapshot_status IN ('healthy','stale','insufficient_quorum','deviation')),
  mark_price numeric(38,18),
  index_price numeric(38,18),
  source_count smallint NOT NULL CHECK (source_count BETWEEN 0 AND 3),
  source_providers text[] NOT NULL DEFAULT ARRAY[]::text[],
  as_of timestamptz,
  expires_at timestamptz,
  rejected_details jsonb NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(rejected_details)='array'),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  FOREIGN KEY (symbol,policy_version)
    REFERENCES private.demo_derivative_price_policies(symbol,policy_version),
  CHECK (cardinality(source_providers)=source_count),
  CHECK (source_providers <@ ARRAY['binance_usdm','bybit_linear','okx_swap']::text[]),
  CHECK (
    (snapshot_status='healthy' AND mark_price>0 AND index_price>0
      AND source_count>=2 AND as_of IS NOT NULL AND expires_at>as_of)
    OR
    (snapshot_status<>'healthy' AND mark_price IS NULL AND index_price IS NULL
      AND as_of IS NULL AND expires_at IS NULL)
  )
);

CREATE INDEX demo_derivative_price_cycles_symbol_started_idx
  ON private.demo_derivative_price_cycles(symbol,started_at DESC);
CREATE INDEX demo_derivative_price_observations_symbol_received_idx
  ON private.demo_derivative_price_observations(symbol,received_at DESC);
CREATE INDEX demo_derivative_price_snapshots_symbol_created_idx
  ON private.demo_derivative_price_snapshots(symbol,created_at DESC);

CREATE OR REPLACE FUNCTION private.guard_demo_derivative_price_policy()
RETURNS trigger LANGUAGE plpgsql SET search_path TO '' AS $function$
BEGIN
  IF TG_OP='DELETE' OR (to_jsonb(NEW)-'enabled') IS DISTINCT FROM (to_jsonb(OLD)-'enabled') THEN
    RAISE EXCEPTION 'Price policy versions are immutable; only enabled state may change' USING ERRCODE='55000';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER demo_derivative_price_policy_guard
  BEFORE UPDATE OR DELETE ON private.demo_derivative_price_policies
  FOR EACH ROW EXECUTE FUNCTION private.guard_demo_derivative_price_policy();

CREATE OR REPLACE FUNCTION private.guard_demo_derivative_price_cycle()
RETURNS trigger LANGUAGE plpgsql SET search_path TO '' AS $function$
DECLARE v_expected integer; v_terminal integer; v_has_snapshot boolean;
BEGIN
  IF TG_OP='DELETE' THEN
    RAISE EXCEPTION 'Price cycles are immutable audit records' USING ERRCODE='55000';
  END IF;
  IF TG_OP='INSERT' THEN
    IF cardinality(NEW.expected_providers)<>(SELECT count(DISTINCT x.provider) FROM unnest(NEW.expected_providers) AS x(provider)) THEN
      RAISE EXCEPTION 'Expected provider list contains duplicates' USING ERRCODE='23514';
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM private.demo_derivative_price_policies p
      WHERE p.symbol=NEW.symbol AND p.policy_version=NEW.policy_version AND p.enabled
        AND cardinality(NEW.expected_providers)>=p.min_sources
        AND NEW.expected_providers <@ p.eligible_providers
    ) THEN
      RAISE EXCEPTION 'No enabled compatible price policy for cycle' USING ERRCODE='23514';
    END IF;
    RETURN NEW;
  END IF;
  IF OLD.cycle_status<>'collecting' OR NEW.cycle_status NOT IN ('completed','failed') THEN
    RAISE EXCEPTION 'Price cycle transition is immutable or invalid' USING ERRCODE='55000';
  END IF;
  SELECT cardinality(OLD.expected_providers),count(*) FILTER (WHERE s.source_status<>'pending')
    INTO v_expected,v_terminal
  FROM private.demo_derivative_price_cycle_sources s WHERE s.cycle_id=OLD.id;
  IF v_terminal<>v_expected THEN
    RAISE EXCEPTION 'Price cycle cannot finish while provider responses are pending' USING ERRCODE='23514';
  END IF;
  IF NEW.cycle_status='completed' THEN
    SELECT EXISTS(SELECT 1 FROM private.demo_derivative_price_snapshots x WHERE x.cycle_id=OLD.id)
      INTO v_has_snapshot;
    IF NOT v_has_snapshot THEN
      RAISE EXCEPTION 'Completed price cycle requires immutable snapshot' USING ERRCODE='23514';
    END IF;
  END IF;
  NEW.completed_at:=COALESCE(NEW.completed_at,clock_timestamp());
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION private.guard_demo_derivative_price_cycle_source()
RETURNS trigger LANGUAGE plpgsql SET search_path TO '' AS $function$
DECLARE v_status text;
BEGIN
  IF TG_OP='DELETE' THEN
    RAISE EXCEPTION 'Provider cycle results cannot be deleted' USING ERRCODE='55000';
  END IF;
  IF TG_OP='INSERT' THEN
    IF NOT EXISTS (
      SELECT 1 FROM private.demo_derivative_price_cycles c
      WHERE c.id=NEW.cycle_id AND c.cycle_status='collecting'
        AND NEW.provider=ANY(c.expected_providers)
    ) THEN
      RAISE EXCEPTION 'Unexpected provider or closed price cycle' USING ERRCODE='23514';
    END IF;
    RETURN NEW;
  END IF;
  IF OLD.source_status<>'pending' OR NEW.source_status NOT IN ('received','failed') THEN
    RAISE EXCEPTION 'Provider cycle result is immutable' USING ERRCODE='55000';
  END IF;
  SELECT c.cycle_status INTO v_status
  FROM private.demo_derivative_price_cycles c WHERE c.id=OLD.cycle_id;
  IF v_status<>'collecting' THEN
    RAISE EXCEPTION 'Cannot update provider result after cycle closure' USING ERRCODE='55000';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION private.guard_demo_derivative_price_observation()
RETURNS trigger LANGUAGE plpgsql SET search_path TO '' AS $function$
DECLARE v_cycle_status text; v_source_status text;
BEGIN
  IF TG_OP<>'INSERT' THEN
    RAISE EXCEPTION 'Price observations are append-only' USING ERRCODE='55000';
  END IF;
  SELECT c.cycle_status,s.source_status INTO v_cycle_status,v_source_status
  FROM private.demo_derivative_price_cycles c
  JOIN private.demo_derivative_price_cycle_sources s
    ON s.cycle_id=c.id AND s.provider=NEW.provider
  WHERE c.id=NEW.cycle_id AND c.symbol=NEW.symbol;
  IF v_cycle_status IS DISTINCT FROM 'collecting' OR v_source_status IS DISTINCT FROM 'pending' THEN
    RAISE EXCEPTION 'Observation requires a collecting cycle and pending provider' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION private.guard_demo_derivative_price_snapshot()
RETURNS trigger LANGUAGE plpgsql SET search_path TO '' AS $function$
DECLARE v_cycle_status text; v_min_sources integer; v_source_count integer;
BEGIN
  IF TG_OP<>'INSERT' THEN
    RAISE EXCEPTION 'Price snapshots are append-only' USING ERRCODE='55000';
  END IF;
  SELECT c.cycle_status,p.min_sources INTO v_cycle_status,v_min_sources
  FROM private.demo_derivative_price_cycles c
  JOIN private.demo_derivative_price_policies p
    ON p.symbol=c.symbol AND p.policy_version=c.policy_version
  WHERE c.id=NEW.cycle_id AND c.symbol=NEW.symbol AND c.policy_version=NEW.policy_version;
  IF v_cycle_status IS DISTINCT FROM 'collecting' THEN
    RAISE EXCEPTION 'Snapshot requires a collecting cycle' USING ERRCODE='23514';
  END IF;
  IF cardinality(NEW.source_providers)<>(SELECT count(DISTINCT x.provider) FROM unnest(NEW.source_providers) AS x(provider)) THEN
    RAISE EXCEPTION 'Snapshot source list contains duplicates' USING ERRCODE='23514';
  END IF;
  SELECT count(DISTINCT u.provider) INTO v_source_count
  FROM unnest(NEW.source_providers) AS u(provider)
  JOIN private.demo_derivative_price_cycle_sources s
    ON s.cycle_id=NEW.cycle_id AND s.provider=u.provider
  WHERE s.source_status='received';
  IF v_source_count<>NEW.source_count THEN
    RAISE EXCEPTION 'Snapshot providers must match received provider responses' USING ERRCODE='23514';
  END IF;
  IF NEW.snapshot_status='healthy' AND NEW.source_count<v_min_sources THEN
    RAISE EXCEPTION 'Healthy snapshot does not satisfy configured quorum' USING ERRCODE='23514';
  END IF;
  IF EXISTS (
    SELECT 1 FROM private.demo_derivative_price_cycle_sources s
    WHERE s.cycle_id=NEW.cycle_id AND s.source_status='pending'
  ) THEN
    RAISE EXCEPTION 'Snapshot cannot publish before every provider response is terminal' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER demo_derivative_price_cycle_guard
  BEFORE INSERT OR UPDATE OR DELETE ON private.demo_derivative_price_cycles
  FOR EACH ROW EXECUTE FUNCTION private.guard_demo_derivative_price_cycle();
CREATE TRIGGER demo_derivative_price_cycle_source_guard
  BEFORE INSERT OR UPDATE OR DELETE ON private.demo_derivative_price_cycle_sources
  FOR EACH ROW EXECUTE FUNCTION private.guard_demo_derivative_price_cycle_source();
CREATE TRIGGER demo_derivative_price_observation_guard
  BEFORE INSERT OR UPDATE OR DELETE ON private.demo_derivative_price_observations
  FOR EACH ROW EXECUTE FUNCTION private.guard_demo_derivative_price_observation();
CREATE TRIGGER demo_derivative_price_snapshot_guard
  BEFORE INSERT OR UPDATE OR DELETE ON private.demo_derivative_price_snapshots
  FOR EACH ROW EXECUTE FUNCTION private.guard_demo_derivative_price_snapshot();

ALTER TABLE private.demo_derivative_price_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.demo_derivative_price_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.demo_derivative_price_cycle_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.demo_derivative_price_observations ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.demo_derivative_price_snapshots ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON private.demo_derivative_price_policies,
  private.demo_derivative_price_cycles,private.demo_derivative_price_cycle_sources,
  private.demo_derivative_price_observations,private.demo_derivative_price_snapshots
  FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT,INSERT ON private.demo_derivative_price_policies TO service_role;
GRANT UPDATE(enabled) ON private.demo_derivative_price_policies TO service_role;
GRANT SELECT,INSERT,UPDATE ON private.demo_derivative_price_cycles TO service_role;
GRANT SELECT,INSERT,UPDATE ON private.demo_derivative_price_cycle_sources TO service_role;
GRANT SELECT,INSERT ON private.demo_derivative_price_observations TO service_role;
GRANT SELECT,INSERT ON private.demo_derivative_price_snapshots TO service_role;

REVOKE ALL ON FUNCTION private.guard_demo_derivative_price_policy() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.guard_demo_derivative_price_cycle() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.guard_demo_derivative_price_cycle_source() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.guard_demo_derivative_price_observation() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.guard_demo_derivative_price_snapshot() FROM PUBLIC,anon,authenticated;
COMMIT;

-- DRAFT ONLY: trusted server-side Futures price-oracle ingestion/publication RPCs.
-- No Production migration. Never expose service_role credentials to browser or Android.
BEGIN;

CREATE OR REPLACE FUNCTION private.demo_derivative_price_start_cycle(
  p_cycle_id uuid,
  p_symbol text,
  p_expected_providers text[],
  p_provider_instruments jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_expected text[];
  v_policy_version integer;
  v_min_sources integer;
  v_existing private.demo_derivative_price_cycles%ROWTYPE;
  v_existing_instruments jsonb;
  v_inserted integer;
BEGIN
  IF current_setting('request.jwt.claim.role',true) IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Trusted service_role required' USING ERRCODE='42501';
  END IF;
  IF p_cycle_id IS NULL OR p_symbol IS NULL OR p_symbol !~ '^[A-Z0-9]{2,15}USDT     OR p_expected_providers IS NULL OR p_provider_instruments IS NULL
     OR jsonb_typeof(p_provider_instruments)<>'object' THEN
    RAISE EXCEPTION 'Invalid price-cycle request' USING ERRCODE='22023';
  END IF;
  SELECT array_agg(x.provider ORDER BY x.provider) INTO v_expected
  FROM unnest(p_expected_providers) AS x(provider);
  IF cardinality(v_expected) NOT BETWEEN 2 AND 3
     OR cardinality(v_expected)<>(SELECT count(DISTINCT x.provider) FROM unnest(p_expected_providers) AS x(provider))
     OR EXISTS (
       SELECT 1 FROM jsonb_each(p_provider_instruments) e
       WHERE jsonb_typeof(e.value)<>'string' OR length(btrim(e.value #>> '{}'))=0
     )
     OR (SELECT count(*) FROM jsonb_object_keys(p_provider_instruments))<>cardinality(v_expected)
     OR v_expected IS DISTINCT FROM ARRAY(
       SELECT k.key FROM jsonb_object_keys(p_provider_instruments) AS k(key) ORDER BY k.key
     ) THEN
    RAISE EXCEPTION 'Provider list and instrument map must match exactly and contain 2-3 unique providers' USING ERRCODE='22023';
  END IF;

  SELECT * INTO v_existing
  FROM private.demo_derivative_price_cycles c
  WHERE c.id=p_cycle_id
  FOR UPDATE;
  IF FOUND THEN
    SELECT coalesce(jsonb_object_agg(s.provider,s.provider_instrument),'{}'::jsonb)
      INTO v_existing_instruments
    FROM private.demo_derivative_price_cycle_sources s
    WHERE s.cycle_id=p_cycle_id;
    IF v_existing.symbol IS DISTINCT FROM p_symbol
       OR v_existing.expected_providers IS DISTINCT FROM v_expected
       OR v_existing_instruments IS DISTINCT FROM p_provider_instruments THEN
      RAISE EXCEPTION 'Cycle id was already used with a different request' USING ERRCODE='23505';
    END IF;
    RETURN p_cycle_id;
  END IF;

  SELECT p.policy_version,p.min_sources
    INTO v_policy_version,v_min_sources
  FROM private.demo_derivative_price_policies p
  WHERE p.symbol=p_symbol AND p.enabled
  FOR SHARE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No enabled price policy for symbol' USING ERRCODE='23514';
  END IF;
  IF cardinality(v_expected)<v_min_sources OR NOT (v_expected <@ (
    SELECT p.eligible_providers FROM private.demo_derivative_price_policies p
    WHERE p.symbol=p_symbol AND p.policy_version=v_policy_version
  )) THEN
    RAISE EXCEPTION 'Requested providers do not satisfy the enabled policy' USING ERRCODE='23514';
  END IF;

  INSERT INTO private.demo_derivative_price_cycles(id,symbol,policy_version,expected_providers)
  VALUES (p_cycle_id,p_symbol,v_policy_version,v_expected)
  ON CONFLICT (id) DO NOTHING;
  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted=0 THEN
    SELECT * INTO STRICT v_existing FROM private.demo_derivative_price_cycles c
    WHERE c.id=p_cycle_id FOR UPDATE;
    SELECT coalesce(jsonb_object_agg(s.provider,s.provider_instrument),'{}'::jsonb)
      INTO v_existing_instruments
    FROM private.demo_derivative_price_cycle_sources s WHERE s.cycle_id=p_cycle_id;
    IF v_existing.symbol IS DISTINCT FROM p_symbol
       OR v_existing.expected_providers IS DISTINCT FROM v_expected
       OR v_existing_instruments IS DISTINCT FROM p_provider_instruments THEN
      RAISE EXCEPTION 'Concurrent cycle creation used a different request' USING ERRCODE='23505';
    END IF;
    RETURN p_cycle_id;
  END IF;

  INSERT INTO private.demo_derivative_price_cycle_sources(cycle_id,provider,provider_instrument)
  SELECT p_cycle_id,e.key,e.value #>> '{}'
  FROM jsonb_each(p_provider_instruments) e
  ORDER BY e.key;
  RETURN p_cycle_id;
END;
$function$;

CREATE OR REPLACE FUNCTION private.demo_derivative_price_record_provider_result(
  p_cycle_id uuid,
  p_provider text,
  p_result_status text,
  p_mark_price numeric,
  p_index_price numeric,
  p_provider_timestamp timestamptz,
  p_response_sha256 text,
  p_rejection_reason text DEFAULT NULL
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_cycle private.demo_derivative_price_cycles%ROWTYPE;
  v_source private.demo_derivative_price_cycle_sources%ROWTYPE;
  v_observation private.demo_derivative_price_observations%ROWTYPE;
BEGIN
  IF current_setting('request.jwt.claim.role',true) IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Trusted service_role required' USING ERRCODE='42501';
  END IF;
  IF p_cycle_id IS NULL OR p_provider IS NULL OR p_provider NOT IN ('binance_usdm','bybit_linear','okx_swap')
     OR p_result_status IS NULL OR p_result_status NOT IN ('accepted','rejected','failed') THEN
    RAISE EXCEPTION 'Invalid provider result request' USING ERRCODE='22023';
  END IF;
  IF p_result_status='failed' THEN
    IF p_rejection_reason IS NULL OR length(btrim(p_rejection_reason))=0
       OR p_mark_price IS NOT NULL OR p_index_price IS NOT NULL THEN
      RAISE EXCEPTION 'Failed provider result requires a reason and no prices' USING ERRCODE='22023';
    END IF;
  ELSE
    IF p_provider_timestamp IS NULL OR p_response_sha256 IS NULL OR p_response_sha256 !~ '^[0-9a-f]{64}      RAISE EXCEPTION 'Received provider result requires timestamp and SHA-256' USING ERRCODE='22023';
    END IF;
    IF p_result_status='accepted' THEN
      IF p_mark_price IS NULL OR p_mark_price<=0 OR p_index_price IS NULL OR p_index_price<=0
         OR p_rejection_reason IS NOT NULL THEN
        RAISE EXCEPTION 'Accepted result requires positive mark/index prices and no rejection reason' USING ERRCODE='22023';
      END IF;
    ELSE
      IF p_mark_price IS NOT NULL OR p_index_price IS NOT NULL
         OR p_rejection_reason IS NULL OR length(btrim(p_rejection_reason))=0 THEN
        RAISE EXCEPTION 'Rejected result requires a reason and no usable prices' USING ERRCODE='22023';
      END IF;
    END IF;
  END IF;

  SELECT * INTO STRICT v_cycle
  FROM private.demo_derivative_price_cycles c
  WHERE c.id=p_cycle_id
  FOR UPDATE;
  SELECT * INTO STRICT v_source
  FROM private.demo_derivative_price_cycle_sources s
  WHERE s.cycle_id=p_cycle_id AND s.provider=p_provider
  FOR UPDATE;

  IF v_source.source_status<>'pending' THEN
    IF p_result_status='failed' AND v_source.source_status='failed'
       AND v_source.failure_reason IS NOT DISTINCT FROM p_rejection_reason THEN
      RETURN v_source.source_status;
    ELSIF p_result_status IN ('accepted','rejected') AND v_source.source_status='received' THEN
      SELECT * INTO STRICT v_observation
      FROM private.demo_derivative_price_observations o
      WHERE o.cycle_id=p_cycle_id AND o.provider=p_provider;
      IF v_observation.validation_status=p_result_status
         AND v_observation.mark_price IS NOT DISTINCT FROM p_mark_price
         AND v_observation.index_price IS NOT DISTINCT FROM p_index_price
         AND v_observation.provider_timestamp IS NOT DISTINCT FROM p_provider_timestamp
         AND v_observation.response_sha256 IS NOT DISTINCT FROM p_response_sha256
         AND v_observation.rejection_reason IS NOT DISTINCT FROM p_rejection_reason THEN
        RETURN v_source.source_status;
      END IF;
    END IF;
    RAISE EXCEPTION 'Provider result retry differs from the persisted result' USING ERRCODE='23505';
  END IF;
  IF v_cycle.cycle_status<>'collecting' THEN
    RAISE EXCEPTION 'Price cycle is already terminal' USING ERRCODE='55000';
  END IF;

  IF p_result_status='failed' THEN
    UPDATE private.demo_derivative_price_cycle_sources
    SET source_status='failed',received_at=clock_timestamp(),failure_reason=p_rejection_reason
    WHERE cycle_id=p_cycle_id AND provider=p_provider;
  ELSE
    INSERT INTO private.demo_derivative_price_observations(
      cycle_id,symbol,provider,mark_price,index_price,provider_timestamp,
      validation_status,rejection_reason,response_sha256
    ) VALUES (
      p_cycle_id,v_cycle.symbol,p_provider,p_mark_price,p_index_price,p_provider_timestamp,
      p_result_status,p_rejection_reason,p_response_sha256
    );
    UPDATE private.demo_derivative_price_cycle_sources
    SET source_status='received',provider_timestamp=p_provider_timestamp,
        received_at=clock_timestamp(),response_sha256=p_response_sha256
    WHERE cycle_id=p_cycle_id AND provider=p_provider;
  END IF;
  RETURN CASE WHEN p_result_status='failed' THEN 'failed' ELSE 'received' END;
END;
$function$;

CREATE OR REPLACE FUNCTION private.demo_derivative_price_publish_snapshot(
  p_cycle_id uuid,
  p_snapshot_id uuid,
  p_snapshot_status text,
  p_mark_price numeric,
  p_index_price numeric,
  p_source_providers text[],
  p_as_of timestamptz,
  p_expires_at timestamptz,
  p_rejected_details jsonb DEFAULT '[]'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_cycle private.demo_derivative_price_cycles%ROWTYPE;
  v_policy private.demo_derivative_price_policies%ROWTYPE;
  v_existing private.demo_derivative_price_snapshots%ROWTYPE;
  v_accepted text[];
  v_marks numeric[];
  v_indices numeric[];
  v_count integer;
  v_mark_median numeric;
  v_index_median numeric;
  v_as_of timestamptz;
  v_stale boolean;
  v_future boolean;
  v_deviation boolean;
BEGIN
  IF current_setting('request.jwt.claim.role',true) IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Trusted service_role required' USING ERRCODE='42501';
  END IF;
  IF p_cycle_id IS NULL OR p_snapshot_id IS NULL
     OR p_snapshot_status IS NULL OR p_snapshot_status NOT IN ('healthy','stale','insufficient_quorum','deviation')
     OR p_source_providers IS NULL
     OR p_rejected_details IS NULL OR jsonb_typeof(p_rejected_details)<>'array' THEN
    RAISE EXCEPTION 'Invalid snapshot publication request' USING ERRCODE='22023';
  END IF;

  SELECT * INTO STRICT v_cycle
  FROM private.demo_derivative_price_cycles c
  WHERE c.id=p_cycle_id
  FOR UPDATE;

  IF v_cycle.cycle_status='completed' THEN
    SELECT * INTO STRICT v_existing
    FROM private.demo_derivative_price_snapshots s
    WHERE s.cycle_id=p_cycle_id;
    IF v_existing.id=p_snapshot_id
       AND v_existing.snapshot_status=p_snapshot_status
       AND v_existing.mark_price IS NOT DISTINCT FROM p_mark_price
       AND v_existing.index_price IS NOT DISTINCT FROM p_index_price
       AND v_existing.source_providers IS NOT DISTINCT FROM p_source_providers
       AND v_existing.as_of IS NOT DISTINCT FROM p_as_of
       AND v_existing.expires_at IS NOT DISTINCT FROM p_expires_at
       AND v_existing.rejected_details IS NOT DISTINCT FROM p_rejected_details THEN
      RETURN p_snapshot_id;
    END IF;
    RAISE EXCEPTION 'Snapshot retry differs from the published result' USING ERRCODE='23505';
  END IF;
  IF v_cycle.cycle_status<>'collecting' THEN
    RAISE EXCEPTION 'Price cycle is not publishable' USING ERRCODE='55000';
  END IF;

  SELECT * INTO STRICT v_policy
  FROM private.demo_derivative_price_policies p
  WHERE p.symbol=v_cycle.symbol AND p.policy_version=v_cycle.policy_version;

  SELECT coalesce(array_agg(o.provider ORDER BY o.provider),'{}'::text[]),
         coalesce(array_agg(o.mark_price ORDER BY o.mark_price),'{}'::numeric[]),
         coalesce(array_agg(o.index_price ORDER BY o.index_price),'{}'::numeric[]),
         count(*),min(o.provider_timestamp)
    INTO v_accepted,v_marks,v_indices,v_count,v_as_of
  FROM private.demo_derivative_price_observations o
  WHERE o.cycle_id=p_cycle_id AND o.validation_status='accepted';

  IF cardinality(p_source_providers)<>(SELECT count(DISTINCT x.provider) FROM unnest(p_source_providers) x(provider))
     OR ARRAY(SELECT x.provider FROM unnest(p_source_providers) x(provider) ORDER BY x.provider)
        IS DISTINCT FROM v_accepted THEN
    RAISE EXCEPTION 'Snapshot source list must exactly match accepted observations' USING ERRCODE='23514';
  END IF;

  IF p_snapshot_status='healthy' THEN
    IF v_count<v_policy.min_sources THEN
      RAISE EXCEPTION 'Healthy snapshot does not meet policy quorum' USING ERRCODE='23514';
    END IF;
    IF EXISTS (
      SELECT 1 FROM private.demo_derivative_price_observations o
      WHERE o.cycle_id=p_cycle_id AND o.validation_status='accepted'
        AND (o.provider_timestamp < clock_timestamp()-(v_policy.max_age_ms*interval '1 millisecond')
          OR o.provider_timestamp > clock_timestamp()+(v_policy.max_future_skew_ms*interval '1 millisecond'))
    ) THEN
      RAISE EXCEPTION 'Healthy snapshot contains stale or future-dated observations' USING ERRCODE='23514';
    END IF;
    v_mark_median := (v_marks[(v_count+1)/2]+v_marks[(v_count+2)/2])/2;
    v_index_median := (v_indices[(v_count+1)/2]+v_indices[(v_count+2)/2])/2;
    SELECT EXISTS (
      SELECT 1 FROM private.demo_derivative_price_observations o
      WHERE o.cycle_id=p_cycle_id AND o.validation_status='accepted'
        AND (abs(o.mark_price-v_mark_median)/v_mark_median*10000>v_policy.max_mark_deviation_bps
          OR abs(o.index_price-v_index_median)/v_index_median*10000>v_policy.max_index_deviation_bps)
    ) INTO v_deviation;
    IF v_deviation
       OR abs(v_mark_median-v_index_median)/v_index_median*10000>v_policy.max_mark_index_deviation_bps THEN
      RAISE EXCEPTION 'Healthy snapshot violates configured price-deviation policy' USING ERRCODE='23514';
    END IF;
    IF p_mark_price IS DISTINCT FROM round(v_mark_median,18)
       OR p_index_price IS DISTINCT FROM round(v_index_median,18)
       OR p_as_of IS DISTINCT FROM v_as_of
       OR p_expires_at IS DISTINCT FROM (v_as_of+v_policy.max_age_ms*interval '1 millisecond') THEN
      RAISE EXCEPTION 'Published consensus prices or validity window do not match observations' USING ERRCODE='23514';
    END IF;
  ELSE
    IF p_mark_price IS NOT NULL OR p_index_price IS NOT NULL OR p_as_of IS NOT NULL OR p_expires_at IS NOT NULL
       OR jsonb_array_length(p_rejected_details)=0 THEN
      RAISE EXCEPTION 'Non-healthy snapshots must have null prices/times and an explanatory detail' USING ERRCODE='23514';
    END IF;
    IF p_snapshot_status='insufficient_quorum' AND v_count>=v_policy.min_sources THEN
      RAISE EXCEPTION 'Insufficient-quorum status is inconsistent with accepted sources' USING ERRCODE='23514';
    END IF;
    IF p_snapshot_status IN ('stale','deviation') AND v_count<v_policy.min_sources THEN
      RAISE EXCEPTION 'Stale/deviation status requires a complete quorum' USING ERRCODE='23514';
    END IF;
  END IF;

  INSERT INTO private.demo_derivative_price_snapshots(
    id,cycle_id,symbol,policy_version,snapshot_status,mark_price,index_price,
    source_count,source_providers,as_of,expires_at,rejected_details
  ) VALUES (
    p_snapshot_id,p_cycle_id,v_cycle.symbol,v_cycle.policy_version,p_snapshot_status,
    p_mark_price,p_index_price,v_count,v_accepted,p_as_of,p_expires_at,p_rejected_details
  );
  UPDATE private.demo_derivative_price_cycles
  SET cycle_status='completed',completed_at=clock_timestamp()
  WHERE id=p_cycle_id;
  RETURN p_snapshot_id;
END;
$function$;

REVOKE ALL ON FUNCTION private.demo_derivative_price_start_cycle(uuid,text,text[],jsonb) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.demo_derivative_price_record_provider_result(uuid,text,text,numeric,numeric,timestamptz,text,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.demo_derivative_price_publish_snapshot(uuid,uuid,text,numeric,numeric,text[],timestamptz,timestamptz,jsonb) FROM PUBLIC,anon,authenticated;
GRANT USAGE ON SCHEMA private TO service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_price_start_cycle(uuid,text,text[],jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_price_record_provider_result(uuid,text,text,numeric,numeric,timestamptz,text,text) TO service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_price_publish_snapshot(uuid,uuid,text,numeric,numeric,text[],timestamptz,timestamptz,jsonb) TO service_role;

COMMIT;

     OR p_expected_providers IS NULL OR p_provider_instruments IS NULL
     OR jsonb_typeof(p_provider_instruments)<>'object' THEN
    RAISE EXCEPTION 'Invalid price-cycle request' USING ERRCODE='22023';
  END IF;
  SELECT array_agg(x.provider ORDER BY x.provider) INTO v_expected
  FROM unnest(p_expected_providers) AS x(provider);
  IF cardinality(v_expected) NOT BETWEEN 2 AND 3
     OR cardinality(v_expected)<>(SELECT count(DISTINCT x.provider) FROM unnest(p_expected_providers) AS x(provider))
     OR EXISTS (
       SELECT 1 FROM jsonb_each(p_provider_instruments) e
       WHERE jsonb_typeof(e.value)<>'string' OR length(btrim(e.value #>> '{}'))=0
     )
     OR (SELECT count(*) FROM jsonb_object_keys(p_provider_instruments))<>cardinality(v_expected)
     OR v_expected IS DISTINCT FROM ARRAY(
       SELECT k.key FROM jsonb_object_keys(p_provider_instruments) AS k(key) ORDER BY k.key
     ) THEN
    RAISE EXCEPTION 'Provider list and instrument map must match exactly and contain 2-3 unique providers' USING ERRCODE='22023';
  END IF;

  SELECT * INTO v_existing
  FROM private.demo_derivative_price_cycles c
  WHERE c.id=p_cycle_id
  FOR UPDATE;
  IF FOUND THEN
    SELECT coalesce(jsonb_object_agg(s.provider,s.provider_instrument),'{}'::jsonb)
      INTO v_existing_instruments
    FROM private.demo_derivative_price_cycle_sources s
    WHERE s.cycle_id=p_cycle_id;
    IF v_existing.symbol IS DISTINCT FROM p_symbol
       OR v_existing.expected_providers IS DISTINCT FROM v_expected
       OR v_existing_instruments IS DISTINCT FROM p_provider_instruments THEN
      RAISE EXCEPTION 'Cycle id was already used with a different request' USING ERRCODE='23505';
    END IF;
    RETURN p_cycle_id;
  END IF;

  SELECT p.policy_version,p.min_sources
    INTO v_policy_version,v_min_sources
  FROM private.demo_derivative_price_policies p
  WHERE p.symbol=p_symbol AND p.enabled
  FOR SHARE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No enabled price policy for symbol' USING ERRCODE='23514';
  END IF;
  IF cardinality(v_expected)<v_min_sources OR NOT (v_expected <@ (
    SELECT p.eligible_providers FROM private.demo_derivative_price_policies p
    WHERE p.symbol=p_symbol AND p.policy_version=v_policy_version
  )) THEN
    RAISE EXCEPTION 'Requested providers do not satisfy the enabled policy' USING ERRCODE='23514';
  END IF;

  INSERT INTO private.demo_derivative_price_cycles(id,symbol,policy_version,expected_providers)
  VALUES (p_cycle_id,p_symbol,v_policy_version,v_expected)
  ON CONFLICT (id) DO NOTHING;
  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted=0 THEN
    SELECT * INTO STRICT v_existing FROM private.demo_derivative_price_cycles c
    WHERE c.id=p_cycle_id FOR UPDATE;
    SELECT coalesce(jsonb_object_agg(s.provider,s.provider_instrument),'{}'::jsonb)
      INTO v_existing_instruments
    FROM private.demo_derivative_price_cycle_sources s WHERE s.cycle_id=p_cycle_id;
    IF v_existing.symbol IS DISTINCT FROM p_symbol
       OR v_existing.expected_providers IS DISTINCT FROM v_expected
       OR v_existing_instruments IS DISTINCT FROM p_provider_instruments THEN
      RAISE EXCEPTION 'Concurrent cycle creation used a different request' USING ERRCODE='23505';
    END IF;
    RETURN p_cycle_id;
  END IF;

  INSERT INTO private.demo_derivative_price_cycle_sources(cycle_id,provider,provider_instrument)
  SELECT p_cycle_id,e.key,e.value #>> '{}'
  FROM jsonb_each(p_provider_instruments) e
  ORDER BY e.key;
  RETURN p_cycle_id;
END;
$function$;

CREATE OR REPLACE FUNCTION private.demo_derivative_price_record_provider_result(
  p_cycle_id uuid,
  p_provider text,
  p_result_status text,
  p_mark_price numeric,
  p_index_price numeric,
  p_provider_timestamp timestamptz,
  p_response_sha256 text,
  p_rejection_reason text DEFAULT NULL
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_cycle private.demo_derivative_price_cycles%ROWTYPE;
  v_source private.demo_derivative_price_cycle_sources%ROWTYPE;
  v_observation private.demo_derivative_price_observations%ROWTYPE;
BEGIN
  IF current_setting('request.jwt.claim.role',true) IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Trusted service_role required' USING ERRCODE='42501';
  END IF;
  IF p_cycle_id IS NULL OR p_provider IS NULL OR p_provider NOT IN ('binance_usdm','bybit_linear','okx_swap')
     OR p_result_status IS NULL OR p_result_status NOT IN ('accepted','rejected','failed') THEN
    RAISE EXCEPTION 'Invalid provider result request' USING ERRCODE='22023';
  END IF;
  IF p_result_status='failed' THEN
    IF p_rejection_reason IS NULL OR length(btrim(p_rejection_reason))=0
       OR p_mark_price IS NOT NULL OR p_index_price IS NOT NULL THEN
      RAISE EXCEPTION 'Failed provider result requires a reason and no prices' USING ERRCODE='22023';
    END IF;
  ELSE
    IF p_provider_timestamp IS NULL OR p_response_sha256 IS NULL OR p_response_sha256 !~ '^[0-9a-f]{64}
      RAISE EXCEPTION 'Received provider result requires timestamp and SHA-256' USING ERRCODE='22023';
    END IF;
    IF p_result_status='accepted' THEN
      IF p_mark_price IS NULL OR p_mark_price<=0 OR p_index_price IS NULL OR p_index_price<=0
         OR p_rejection_reason IS NOT NULL THEN
        RAISE EXCEPTION 'Accepted result requires positive mark/index prices and no rejection reason' USING ERRCODE='22023';
      END IF;
    ELSE
      IF p_mark_price IS NOT NULL OR p_index_price IS NOT NULL
         OR p_rejection_reason IS NULL OR length(btrim(p_rejection_reason))=0 THEN
        RAISE EXCEPTION 'Rejected result requires a reason and no usable prices' USING ERRCODE='22023';
      END IF;
    END IF;
  END IF;

  SELECT * INTO STRICT v_cycle
  FROM private.demo_derivative_price_cycles c
  WHERE c.id=p_cycle_id
  FOR UPDATE;
  SELECT * INTO STRICT v_source
  FROM private.demo_derivative_price_cycle_sources s
  WHERE s.cycle_id=p_cycle_id AND s.provider=p_provider
  FOR UPDATE;

  IF v_source.source_status<>'pending' THEN
    IF p_result_status='failed' AND v_source.source_status='failed'
       AND v_source.failure_reason IS NOT DISTINCT FROM p_rejection_reason THEN
      RETURN v_source.source_status;
    ELSIF p_result_status IN ('accepted','rejected') AND v_source.source_status='received' THEN
      SELECT * INTO STRICT v_observation
      FROM private.demo_derivative_price_observations o
      WHERE o.cycle_id=p_cycle_id AND o.provider=p_provider;
      IF v_observation.validation_status=p_result_status
         AND v_observation.mark_price IS NOT DISTINCT FROM p_mark_price
         AND v_observation.index_price IS NOT DISTINCT FROM p_index_price
         AND v_observation.provider_timestamp IS NOT DISTINCT FROM p_provider_timestamp
         AND v_observation.response_sha256 IS NOT DISTINCT FROM p_response_sha256
         AND v_observation.rejection_reason IS NOT DISTINCT FROM p_rejection_reason THEN
        RETURN v_source.source_status;
      END IF;
    END IF;
    RAISE EXCEPTION 'Provider result retry differs from the persisted result' USING ERRCODE='23505';
  END IF;
  IF v_cycle.cycle_status<>'collecting' THEN
    RAISE EXCEPTION 'Price cycle is already terminal' USING ERRCODE='55000';
  END IF;

  IF p_result_status='failed' THEN
    UPDATE private.demo_derivative_price_cycle_sources
    SET source_status='failed',received_at=clock_timestamp(),failure_reason=p_rejection_reason
    WHERE cycle_id=p_cycle_id AND provider=p_provider;
  ELSE
    INSERT INTO private.demo_derivative_price_observations(
      cycle_id,symbol,provider,mark_price,index_price,provider_timestamp,
      validation_status,rejection_reason,response_sha256
    ) VALUES (
      p_cycle_id,v_cycle.symbol,p_provider,p_mark_price,p_index_price,p_provider_timestamp,
      p_result_status,p_rejection_reason,p_response_sha256
    );
    UPDATE private.demo_derivative_price_cycle_sources
    SET source_status='received',provider_timestamp=p_provider_timestamp,
        received_at=clock_timestamp(),response_sha256=p_response_sha256
    WHERE cycle_id=p_cycle_id AND provider=p_provider;
  END IF;
  RETURN CASE WHEN p_result_status='failed' THEN 'failed' ELSE 'received' END;
END;
$function$;

CREATE OR REPLACE FUNCTION private.demo_derivative_price_publish_snapshot(
  p_cycle_id uuid,
  p_snapshot_id uuid,
  p_snapshot_status text,
  p_mark_price numeric,
  p_index_price numeric,
  p_source_providers text[],
  p_as_of timestamptz,
  p_expires_at timestamptz,
  p_rejected_details jsonb DEFAULT '[]'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_cycle private.demo_derivative_price_cycles%ROWTYPE;
  v_policy private.demo_derivative_price_policies%ROWTYPE;
  v_existing private.demo_derivative_price_snapshots%ROWTYPE;
  v_accepted text[];
  v_marks numeric[];
  v_indices numeric[];
  v_count integer;
  v_mark_median numeric;
  v_index_median numeric;
  v_as_of timestamptz;
  v_stale boolean;
  v_future boolean;
  v_deviation boolean;
BEGIN
  IF current_setting('request.jwt.claim.role',true) IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Trusted service_role required' USING ERRCODE='42501';
  END IF;
  IF p_cycle_id IS NULL OR p_snapshot_id IS NULL
     OR p_snapshot_status IS NULL OR p_snapshot_status NOT IN ('healthy','stale','insufficient_quorum','deviation')
     OR p_source_providers IS NULL
     OR p_rejected_details IS NULL OR jsonb_typeof(p_rejected_details)<>'array' THEN
    RAISE EXCEPTION 'Invalid snapshot publication request' USING ERRCODE='22023';
  END IF;

  SELECT * INTO STRICT v_cycle
  FROM private.demo_derivative_price_cycles c
  WHERE c.id=p_cycle_id
  FOR UPDATE;

  IF v_cycle.cycle_status='completed' THEN
    SELECT * INTO STRICT v_existing
    FROM private.demo_derivative_price_snapshots s
    WHERE s.cycle_id=p_cycle_id;
    IF v_existing.id=p_snapshot_id
       AND v_existing.snapshot_status=p_snapshot_status
       AND v_existing.mark_price IS NOT DISTINCT FROM p_mark_price
       AND v_existing.index_price IS NOT DISTINCT FROM p_index_price
       AND v_existing.source_providers IS NOT DISTINCT FROM p_source_providers
       AND v_existing.as_of IS NOT DISTINCT FROM p_as_of
       AND v_existing.expires_at IS NOT DISTINCT FROM p_expires_at
       AND v_existing.rejected_details IS NOT DISTINCT FROM p_rejected_details THEN
      RETURN p_snapshot_id;
    END IF;
    RAISE EXCEPTION 'Snapshot retry differs from the published result' USING ERRCODE='23505';
  END IF;
  IF v_cycle.cycle_status<>'collecting' THEN
    RAISE EXCEPTION 'Price cycle is not publishable' USING ERRCODE='55000';
  END IF;

  SELECT * INTO STRICT v_policy
  FROM private.demo_derivative_price_policies p
  WHERE p.symbol=v_cycle.symbol AND p.policy_version=v_cycle.policy_version;

  SELECT coalesce(array_agg(o.provider ORDER BY o.provider),'{}'::text[]),
         coalesce(array_agg(o.mark_price ORDER BY o.mark_price),'{}'::numeric[]),
         coalesce(array_agg(o.index_price ORDER BY o.index_price),'{}'::numeric[]),
         count(*),min(o.provider_timestamp)
    INTO v_accepted,v_marks,v_indices,v_count,v_as_of
  FROM private.demo_derivative_price_observations o
  WHERE o.cycle_id=p_cycle_id AND o.validation_status='accepted';

  IF cardinality(p_source_providers)<>(SELECT count(DISTINCT x.provider) FROM unnest(p_source_providers) x(provider))
     OR ARRAY(SELECT x.provider FROM unnest(p_source_providers) x(provider) ORDER BY x.provider)
        IS DISTINCT FROM v_accepted THEN
    RAISE EXCEPTION 'Snapshot source list must exactly match accepted observations' USING ERRCODE='23514';
  END IF;

  IF p_snapshot_status='healthy' THEN
    IF v_count<v_policy.min_sources THEN
      RAISE EXCEPTION 'Healthy snapshot does not meet policy quorum' USING ERRCODE='23514';
    END IF;
    IF EXISTS (
      SELECT 1 FROM private.demo_derivative_price_observations o
      WHERE o.cycle_id=p_cycle_id AND o.validation_status='accepted'
        AND (o.provider_timestamp < clock_timestamp()-(v_policy.max_age_ms*interval '1 millisecond')
          OR o.provider_timestamp > clock_timestamp()+(v_policy.max_future_skew_ms*interval '1 millisecond'))
    ) THEN
      RAISE EXCEPTION 'Healthy snapshot contains stale or future-dated observations' USING ERRCODE='23514';
    END IF;
    v_mark_median := (v_marks[(v_count+1)/2]+v_marks[(v_count+2)/2])/2;
    v_index_median := (v_indices[(v_count+1)/2]+v_indices[(v_count+2)/2])/2;
    SELECT EXISTS (
      SELECT 1 FROM private.demo_derivative_price_observations o
      WHERE o.cycle_id=p_cycle_id AND o.validation_status='accepted'
        AND (abs(o.mark_price-v_mark_median)/v_mark_median*10000>v_policy.max_mark_deviation_bps
          OR abs(o.index_price-v_index_median)/v_index_median*10000>v_policy.max_index_deviation_bps)
    ) INTO v_deviation;
    IF v_deviation
       OR abs(v_mark_median-v_index_median)/v_index_median*10000>v_policy.max_mark_index_deviation_bps THEN
      RAISE EXCEPTION 'Healthy snapshot violates configured price-deviation policy' USING ERRCODE='23514';
    END IF;
    IF p_mark_price IS DISTINCT FROM round(v_mark_median,18)
       OR p_index_price IS DISTINCT FROM round(v_index_median,18)
       OR p_as_of IS DISTINCT FROM v_as_of
       OR p_expires_at IS DISTINCT FROM (v_as_of+v_policy.max_age_ms*interval '1 millisecond') THEN
      RAISE EXCEPTION 'Published consensus prices or validity window do not match observations' USING ERRCODE='23514';
    END IF;
  ELSE
    IF p_mark_price IS NOT NULL OR p_index_price IS NOT NULL OR p_as_of IS NOT NULL OR p_expires_at IS NOT NULL
       OR jsonb_array_length(p_rejected_details)=0 THEN
      RAISE EXCEPTION 'Non-healthy snapshots must have null prices/times and an explanatory detail' USING ERRCODE='23514';
    END IF;
    IF p_snapshot_status='insufficient_quorum' AND v_count>=v_policy.min_sources THEN
      RAISE EXCEPTION 'Insufficient-quorum status is inconsistent with accepted sources' USING ERRCODE='23514';
    END IF;
    IF p_snapshot_status IN ('stale','deviation') AND v_count<v_policy.min_sources THEN
      RAISE EXCEPTION 'Stale/deviation status requires a complete quorum' USING ERRCODE='23514';
    END IF;
  END IF;

  INSERT INTO private.demo_derivative_price_snapshots(
    id,cycle_id,symbol,policy_version,snapshot_status,mark_price,index_price,
    source_count,source_providers,as_of,expires_at,rejected_details
  ) VALUES (
    p_snapshot_id,p_cycle_id,v_cycle.symbol,v_cycle.policy_version,p_snapshot_status,
    p_mark_price,p_index_price,v_count,v_accepted,p_as_of,p_expires_at,p_rejected_details
  );
  UPDATE private.demo_derivative_price_cycles
  SET cycle_status='completed',completed_at=clock_timestamp()
  WHERE id=p_cycle_id;
  RETURN p_snapshot_id;
END;
$function$;

REVOKE ALL ON FUNCTION private.demo_derivative_price_start_cycle(uuid,text,text[],jsonb) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.demo_derivative_price_record_provider_result(uuid,text,text,numeric,numeric,timestamptz,text,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.demo_derivative_price_publish_snapshot(uuid,uuid,text,numeric,numeric,text[],timestamptz,timestamptz,jsonb) FROM PUBLIC,anon,authenticated;
GRANT USAGE ON SCHEMA private TO service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_price_start_cycle(uuid,text,text[],jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_price_record_provider_result(uuid,text,text,numeric,numeric,timestamptz,text,text) TO service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_price_publish_snapshot(uuid,uuid,text,numeric,numeric,text[],timestamptz,timestamptz,jsonb) TO service_role;

COMMIT;

      RAISE EXCEPTION 'Received provider result requires timestamp and SHA-256' USING ERRCODE='22023';
    END IF;
    IF p_result_status='accepted' THEN
      IF p_mark_price IS NULL OR p_mark_price<=0 OR p_index_price IS NULL OR p_index_price<=0
         OR p_rejection_reason IS NOT NULL THEN
        RAISE EXCEPTION 'Accepted result requires positive mark/index prices and no rejection reason' USING ERRCODE='22023';
      END IF;
    ELSE
      IF p_mark_price IS NOT NULL OR p_index_price IS NOT NULL
         OR p_rejection_reason IS NULL OR length(btrim(p_rejection_reason))=0 THEN
        RAISE EXCEPTION 'Rejected result requires a reason and no usable prices' USING ERRCODE='22023';
      END IF;
    END IF;
  END IF;

  SELECT * INTO STRICT v_cycle
  FROM private.demo_derivative_price_cycles c
  WHERE c.id=p_cycle_id
  FOR UPDATE;
  SELECT * INTO STRICT v_source
  FROM private.demo_derivative_price_cycle_sources s
  WHERE s.cycle_id=p_cycle_id AND s.provider=p_provider
  FOR UPDATE;

  IF v_source.source_status<>'pending' THEN
    IF p_result_status='failed' AND v_source.source_status='failed'
       AND v_source.failure_reason IS NOT DISTINCT FROM p_rejection_reason THEN
      RETURN v_source.source_status;
    ELSIF p_result_status IN ('accepted','rejected') AND v_source.source_status='received' THEN
      SELECT * INTO STRICT v_observation
      FROM private.demo_derivative_price_observations o
      WHERE o.cycle_id=p_cycle_id AND o.provider=p_provider;
      IF v_observation.validation_status=p_result_status
         AND v_observation.mark_price IS NOT DISTINCT FROM p_mark_price
         AND v_observation.index_price IS NOT DISTINCT FROM p_index_price
         AND v_observation.provider_timestamp IS NOT DISTINCT FROM p_provider_timestamp
         AND v_observation.response_sha256 IS NOT DISTINCT FROM p_response_sha256
         AND v_observation.rejection_reason IS NOT DISTINCT FROM p_rejection_reason THEN
        RETURN v_source.source_status;
      END IF;
    END IF;
    RAISE EXCEPTION 'Provider result retry differs from the persisted result' USING ERRCODE='23505';
  END IF;
  IF v_cycle.cycle_status<>'collecting' THEN
    RAISE EXCEPTION 'Price cycle is already terminal' USING ERRCODE='55000';
  END IF;

  IF p_result_status='failed' THEN
    UPDATE private.demo_derivative_price_cycle_sources
    SET source_status='failed',received_at=clock_timestamp(),failure_reason=p_rejection_reason
    WHERE cycle_id=p_cycle_id AND provider=p_provider;
  ELSE
    INSERT INTO private.demo_derivative_price_observations(
      cycle_id,symbol,provider,mark_price,index_price,provider_timestamp,
      validation_status,rejection_reason,response_sha256
    ) VALUES (
      p_cycle_id,v_cycle.symbol,p_provider,p_mark_price,p_index_price,p_provider_timestamp,
      p_result_status,p_rejection_reason,p_response_sha256
    );
    UPDATE private.demo_derivative_price_cycle_sources
    SET source_status='received',provider_timestamp=p_provider_timestamp,
        received_at=clock_timestamp(),response_sha256=p_response_sha256
    WHERE cycle_id=p_cycle_id AND provider=p_provider;
  END IF;
  RETURN CASE WHEN p_result_status='failed' THEN 'failed' ELSE 'received' END;
END;
$function$;

CREATE OR REPLACE FUNCTION private.demo_derivative_price_publish_snapshot(
  p_cycle_id uuid,
  p_snapshot_id uuid,
  p_snapshot_status text,
  p_mark_price numeric,
  p_index_price numeric,
  p_source_providers text[],
  p_as_of timestamptz,
  p_expires_at timestamptz,
  p_rejected_details jsonb DEFAULT '[]'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_cycle private.demo_derivative_price_cycles%ROWTYPE;
  v_policy private.demo_derivative_price_policies%ROWTYPE;
  v_existing private.demo_derivative_price_snapshots%ROWTYPE;
  v_accepted text[];
  v_marks numeric[];
  v_indices numeric[];
  v_count integer;
  v_mark_median numeric;
  v_index_median numeric;
  v_as_of timestamptz;
  v_stale boolean;
  v_future boolean;
  v_deviation boolean;
BEGIN
  IF current_setting('request.jwt.claim.role',true) IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Trusted service_role required' USING ERRCODE='42501';
  END IF;
  IF p_cycle_id IS NULL OR p_snapshot_id IS NULL
     OR p_snapshot_status IS NULL OR p_snapshot_status NOT IN ('healthy','stale','insufficient_quorum','deviation')
     OR p_source_providers IS NULL
     OR p_rejected_details IS NULL OR jsonb_typeof(p_rejected_details)<>'array' THEN
    RAISE EXCEPTION 'Invalid snapshot publication request' USING ERRCODE='22023';
  END IF;

  SELECT * INTO STRICT v_cycle
  FROM private.demo_derivative_price_cycles c
  WHERE c.id=p_cycle_id
  FOR UPDATE;

  IF v_cycle.cycle_status='completed' THEN
    SELECT * INTO STRICT v_existing
    FROM private.demo_derivative_price_snapshots s
    WHERE s.cycle_id=p_cycle_id;
    IF v_existing.id=p_snapshot_id
       AND v_existing.snapshot_status=p_snapshot_status
       AND v_existing.mark_price IS NOT DISTINCT FROM p_mark_price
       AND v_existing.index_price IS NOT DISTINCT FROM p_index_price
       AND v_existing.source_providers IS NOT DISTINCT FROM p_source_providers
       AND v_existing.as_of IS NOT DISTINCT FROM p_as_of
       AND v_existing.expires_at IS NOT DISTINCT FROM p_expires_at
       AND v_existing.rejected_details IS NOT DISTINCT FROM p_rejected_details THEN
      RETURN p_snapshot_id;
    END IF;
    RAISE EXCEPTION 'Snapshot retry differs from the published result' USING ERRCODE='23505';
  END IF;
  IF v_cycle.cycle_status<>'collecting' THEN
    RAISE EXCEPTION 'Price cycle is not publishable' USING ERRCODE='55000';
  END IF;

  SELECT * INTO STRICT v_policy
  FROM private.demo_derivative_price_policies p
  WHERE p.symbol=v_cycle.symbol AND p.policy_version=v_cycle.policy_version;

  SELECT coalesce(array_agg(o.provider ORDER BY o.provider),'{}'::text[]),
         coalesce(array_agg(o.mark_price ORDER BY o.mark_price),'{}'::numeric[]),
         coalesce(array_agg(o.index_price ORDER BY o.index_price),'{}'::numeric[]),
         count(*),min(o.provider_timestamp)
    INTO v_accepted,v_marks,v_indices,v_count,v_as_of
  FROM private.demo_derivative_price_observations o
  WHERE o.cycle_id=p_cycle_id AND o.validation_status='accepted';

  IF cardinality(p_source_providers)<>(SELECT count(DISTINCT x.provider) FROM unnest(p_source_providers) x(provider))
     OR ARRAY(SELECT x.provider FROM unnest(p_source_providers) x(provider) ORDER BY x.provider)
        IS DISTINCT FROM v_accepted THEN
    RAISE EXCEPTION 'Snapshot source list must exactly match accepted observations' USING ERRCODE='23514';
  END IF;

  IF p_snapshot_status='healthy' THEN
    IF v_count<v_policy.min_sources THEN
      RAISE EXCEPTION 'Healthy snapshot does not meet policy quorum' USING ERRCODE='23514';
    END IF;
    IF EXISTS (
      SELECT 1 FROM private.demo_derivative_price_observations o
      WHERE o.cycle_id=p_cycle_id AND o.validation_status='accepted'
        AND (o.provider_timestamp < clock_timestamp()-(v_policy.max_age_ms*interval '1 millisecond')
          OR o.provider_timestamp > clock_timestamp()+(v_policy.max_future_skew_ms*interval '1 millisecond'))
    ) THEN
      RAISE EXCEPTION 'Healthy snapshot contains stale or future-dated observations' USING ERRCODE='23514';
    END IF;
    v_mark_median := (v_marks[(v_count+1)/2]+v_marks[(v_count+2)/2])/2;
    v_index_median := (v_indices[(v_count+1)/2]+v_indices[(v_count+2)/2])/2;
    SELECT EXISTS (
      SELECT 1 FROM private.demo_derivative_price_observations o
      WHERE o.cycle_id=p_cycle_id AND o.validation_status='accepted'
        AND (abs(o.mark_price-v_mark_median)/v_mark_median*10000>v_policy.max_mark_deviation_bps
          OR abs(o.index_price-v_index_median)/v_index_median*10000>v_policy.max_index_deviation_bps)
    ) INTO v_deviation;
    IF v_deviation
       OR abs(v_mark_median-v_index_median)/v_index_median*10000>v_policy.max_mark_index_deviation_bps THEN
      RAISE EXCEPTION 'Healthy snapshot violates configured price-deviation policy' USING ERRCODE='23514';
    END IF;
    IF p_mark_price IS DISTINCT FROM round(v_mark_median,18)
       OR p_index_price IS DISTINCT FROM round(v_index_median,18)
       OR p_as_of IS DISTINCT FROM v_as_of
       OR p_expires_at IS DISTINCT FROM (v_as_of+v_policy.max_age_ms*interval '1 millisecond') THEN
      RAISE EXCEPTION 'Published consensus prices or validity window do not match observations' USING ERRCODE='23514';
    END IF;
  ELSE
    IF p_mark_price IS NOT NULL OR p_index_price IS NOT NULL OR p_as_of IS NOT NULL OR p_expires_at IS NOT NULL
       OR jsonb_array_length(p_rejected_details)=0 THEN
      RAISE EXCEPTION 'Non-healthy snapshots must have null prices/times and an explanatory detail' USING ERRCODE='23514';
    END IF;
    IF p_snapshot_status='insufficient_quorum' AND v_count>=v_policy.min_sources THEN
      RAISE EXCEPTION 'Insufficient-quorum status is inconsistent with accepted sources' USING ERRCODE='23514';
    END IF;
    IF p_snapshot_status IN ('stale','deviation') AND v_count<v_policy.min_sources THEN
      RAISE EXCEPTION 'Stale/deviation status requires a complete quorum' USING ERRCODE='23514';
    END IF;
  END IF;

  INSERT INTO private.demo_derivative_price_snapshots(
    id,cycle_id,symbol,policy_version,snapshot_status,mark_price,index_price,
    source_count,source_providers,as_of,expires_at,rejected_details
  ) VALUES (
    p_snapshot_id,p_cycle_id,v_cycle.symbol,v_cycle.policy_version,p_snapshot_status,
    p_mark_price,p_index_price,v_count,v_accepted,p_as_of,p_expires_at,p_rejected_details
  );
  UPDATE private.demo_derivative_price_cycles
  SET cycle_status='completed',completed_at=clock_timestamp()
  WHERE id=p_cycle_id;
  RETURN p_snapshot_id;
END;
$function$;

REVOKE ALL ON FUNCTION private.demo_derivative_price_start_cycle(uuid,text,text[],jsonb) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.demo_derivative_price_record_provider_result(uuid,text,text,numeric,numeric,timestamptz,text,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.demo_derivative_price_publish_snapshot(uuid,uuid,text,numeric,numeric,text[],timestamptz,timestamptz,jsonb) FROM PUBLIC,anon,authenticated;
GRANT USAGE ON SCHEMA private TO service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_price_start_cycle(uuid,text,text[],jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_price_record_provider_result(uuid,text,text,numeric,numeric,timestamptz,text,text) TO service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_price_publish_snapshot(uuid,uuid,text,numeric,numeric,text[],timestamptz,timestamptz,jsonb) TO service_role;

COMMIT;

     OR p_expected_providers IS NULL OR p_provider_instruments IS NULL
     OR jsonb_typeof(p_provider_instruments)<>'object' THEN
    RAISE EXCEPTION 'Invalid price-cycle request' USING ERRCODE='22023';
  END IF;
  SELECT array_agg(x.provider ORDER BY x.provider) INTO v_expected
  FROM unnest(p_expected_providers) AS x(provider);
  IF cardinality(v_expected) NOT BETWEEN 2 AND 3
     OR cardinality(v_expected)<>(SELECT count(DISTINCT x.provider) FROM unnest(p_expected_providers) AS x(provider))
     OR EXISTS (
       SELECT 1 FROM jsonb_each(p_provider_instruments) e
       WHERE jsonb_typeof(e.value)<>'string' OR length(btrim(e.value #>> '{}'))=0
     )
     OR (SELECT count(*) FROM jsonb_object_keys(p_provider_instruments))<>cardinality(v_expected)
     OR v_expected IS DISTINCT FROM ARRAY(
       SELECT k.key FROM jsonb_object_keys(p_provider_instruments) AS k(key) ORDER BY k.key
     ) THEN
    RAISE EXCEPTION 'Provider list and instrument map must match exactly and contain 2-3 unique providers' USING ERRCODE='22023';
  END IF;

  SELECT * INTO v_existing
  FROM private.demo_derivative_price_cycles c
  WHERE c.id=p_cycle_id
  FOR UPDATE;
  IF FOUND THEN
    SELECT coalesce(jsonb_object_agg(s.provider,s.provider_instrument),'{}'::jsonb)
      INTO v_existing_instruments
    FROM private.demo_derivative_price_cycle_sources s
    WHERE s.cycle_id=p_cycle_id;
    IF v_existing.symbol IS DISTINCT FROM p_symbol
       OR v_existing.expected_providers IS DISTINCT FROM v_expected
       OR v_existing_instruments IS DISTINCT FROM p_provider_instruments THEN
      RAISE EXCEPTION 'Cycle id was already used with a different request' USING ERRCODE='23505';
    END IF;
    RETURN p_cycle_id;
  END IF;

  SELECT p.policy_version,p.min_sources
    INTO v_policy_version,v_min_sources
  FROM private.demo_derivative_price_policies p
  WHERE p.symbol=p_symbol AND p.enabled
  FOR SHARE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No enabled price policy for symbol' USING ERRCODE='23514';
  END IF;
  IF cardinality(v_expected)<v_min_sources OR NOT (v_expected <@ (
    SELECT p.eligible_providers FROM private.demo_derivative_price_policies p
    WHERE p.symbol=p_symbol AND p.policy_version=v_policy_version
  )) THEN
    RAISE EXCEPTION 'Requested providers do not satisfy the enabled policy' USING ERRCODE='23514';
  END IF;

  INSERT INTO private.demo_derivative_price_cycles(id,symbol,policy_version,expected_providers)
  VALUES (p_cycle_id,p_symbol,v_policy_version,v_expected)
  ON CONFLICT (id) DO NOTHING;
  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted=0 THEN
    SELECT * INTO STRICT v_existing FROM private.demo_derivative_price_cycles c
    WHERE c.id=p_cycle_id FOR UPDATE;
    SELECT coalesce(jsonb_object_agg(s.provider,s.provider_instrument),'{}'::jsonb)
      INTO v_existing_instruments
    FROM private.demo_derivative_price_cycle_sources s WHERE s.cycle_id=p_cycle_id;
    IF v_existing.symbol IS DISTINCT FROM p_symbol
       OR v_existing.expected_providers IS DISTINCT FROM v_expected
       OR v_existing_instruments IS DISTINCT FROM p_provider_instruments THEN
      RAISE EXCEPTION 'Concurrent cycle creation used a different request' USING ERRCODE='23505';
    END IF;
    RETURN p_cycle_id;
  END IF;

  INSERT INTO private.demo_derivative_price_cycle_sources(cycle_id,provider,provider_instrument)
  SELECT p_cycle_id,e.key,e.value #>> '{}'
  FROM jsonb_each(p_provider_instruments) e
  ORDER BY e.key;
  RETURN p_cycle_id;
END;
$function$;

CREATE OR REPLACE FUNCTION private.demo_derivative_price_record_provider_result(
  p_cycle_id uuid,
  p_provider text,
  p_result_status text,
  p_mark_price numeric,
  p_index_price numeric,
  p_provider_timestamp timestamptz,
  p_response_sha256 text,
  p_rejection_reason text DEFAULT NULL
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_cycle private.demo_derivative_price_cycles%ROWTYPE;
  v_source private.demo_derivative_price_cycle_sources%ROWTYPE;
  v_observation private.demo_derivative_price_observations%ROWTYPE;
BEGIN
  IF current_setting('request.jwt.claim.role',true) IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Trusted service_role required' USING ERRCODE='42501';
  END IF;
  IF p_cycle_id IS NULL OR p_provider IS NULL OR p_provider NOT IN ('binance_usdm','bybit_linear','okx_swap')
     OR p_result_status IS NULL OR p_result_status NOT IN ('accepted','rejected','failed') THEN
    RAISE EXCEPTION 'Invalid provider result request' USING ERRCODE='22023';
  END IF;
  IF p_result_status='failed' THEN
    IF p_rejection_reason IS NULL OR length(btrim(p_rejection_reason))=0
       OR p_mark_price IS NOT NULL OR p_index_price IS NOT NULL THEN
      RAISE EXCEPTION 'Failed provider result requires a reason and no prices' USING ERRCODE='22023';
    END IF;
  ELSE
    IF p_provider_timestamp IS NULL OR p_response_sha256 IS NULL OR p_response_sha256 !~ '^[0-9a-f]{64}
      RAISE EXCEPTION 'Received provider result requires timestamp and SHA-256' USING ERRCODE='22023';
    END IF;
    IF p_result_status='accepted' THEN
      IF p_mark_price IS NULL OR p_mark_price<=0 OR p_index_price IS NULL OR p_index_price<=0
         OR p_rejection_reason IS NOT NULL THEN
        RAISE EXCEPTION 'Accepted result requires positive mark/index prices and no rejection reason' USING ERRCODE='22023';
      END IF;
    ELSE
      IF p_mark_price IS NOT NULL OR p_index_price IS NOT NULL
         OR p_rejection_reason IS NULL OR length(btrim(p_rejection_reason))=0 THEN
        RAISE EXCEPTION 'Rejected result requires a reason and no usable prices' USING ERRCODE='22023';
      END IF;
    END IF;
  END IF;

  SELECT * INTO STRICT v_cycle
  FROM private.demo_derivative_price_cycles c
  WHERE c.id=p_cycle_id
  FOR UPDATE;
  SELECT * INTO STRICT v_source
  FROM private.demo_derivative_price_cycle_sources s
  WHERE s.cycle_id=p_cycle_id AND s.provider=p_provider
  FOR UPDATE;

  IF v_source.source_status<>'pending' THEN
    IF p_result_status='failed' AND v_source.source_status='failed'
       AND v_source.failure_reason IS NOT DISTINCT FROM p_rejection_reason THEN
      RETURN v_source.source_status;
    ELSIF p_result_status IN ('accepted','rejected') AND v_source.source_status='received' THEN
      SELECT * INTO STRICT v_observation
      FROM private.demo_derivative_price_observations o
      WHERE o.cycle_id=p_cycle_id AND o.provider=p_provider;
      IF v_observation.validation_status=p_result_status
         AND v_observation.mark_price IS NOT DISTINCT FROM p_mark_price
         AND v_observation.index_price IS NOT DISTINCT FROM p_index_price
         AND v_observation.provider_timestamp IS NOT DISTINCT FROM p_provider_timestamp
         AND v_observation.response_sha256 IS NOT DISTINCT FROM p_response_sha256
         AND v_observation.rejection_reason IS NOT DISTINCT FROM p_rejection_reason THEN
        RETURN v_source.source_status;
      END IF;
    END IF;
    RAISE EXCEPTION 'Provider result retry differs from the persisted result' USING ERRCODE='23505';
  END IF;
  IF v_cycle.cycle_status<>'collecting' THEN
    RAISE EXCEPTION 'Price cycle is already terminal' USING ERRCODE='55000';
  END IF;

  IF p_result_status='failed' THEN
    UPDATE private.demo_derivative_price_cycle_sources
    SET source_status='failed',received_at=clock_timestamp(),failure_reason=p_rejection_reason
    WHERE cycle_id=p_cycle_id AND provider=p_provider;
  ELSE
    INSERT INTO private.demo_derivative_price_observations(
      cycle_id,symbol,provider,mark_price,index_price,provider_timestamp,
      validation_status,rejection_reason,response_sha256
    ) VALUES (
      p_cycle_id,v_cycle.symbol,p_provider,p_mark_price,p_index_price,p_provider_timestamp,
      p_result_status,p_rejection_reason,p_response_sha256
    );
    UPDATE private.demo_derivative_price_cycle_sources
    SET source_status='received',provider_timestamp=p_provider_timestamp,
        received_at=clock_timestamp(),response_sha256=p_response_sha256
    WHERE cycle_id=p_cycle_id AND provider=p_provider;
  END IF;
  RETURN CASE WHEN p_result_status='failed' THEN 'failed' ELSE 'received' END;
END;
$function$;

CREATE OR REPLACE FUNCTION private.demo_derivative_price_publish_snapshot(
  p_cycle_id uuid,
  p_snapshot_id uuid,
  p_snapshot_status text,
  p_mark_price numeric,
  p_index_price numeric,
  p_source_providers text[],
  p_as_of timestamptz,
  p_expires_at timestamptz,
  p_rejected_details jsonb DEFAULT '[]'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_cycle private.demo_derivative_price_cycles%ROWTYPE;
  v_policy private.demo_derivative_price_policies%ROWTYPE;
  v_existing private.demo_derivative_price_snapshots%ROWTYPE;
  v_accepted text[];
  v_marks numeric[];
  v_indices numeric[];
  v_count integer;
  v_mark_median numeric;
  v_index_median numeric;
  v_as_of timestamptz;
  v_stale boolean;
  v_future boolean;
  v_deviation boolean;
BEGIN
  IF current_setting('request.jwt.claim.role',true) IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Trusted service_role required' USING ERRCODE='42501';
  END IF;
  IF p_cycle_id IS NULL OR p_snapshot_id IS NULL
     OR p_snapshot_status IS NULL OR p_snapshot_status NOT IN ('healthy','stale','insufficient_quorum','deviation')
     OR p_source_providers IS NULL
     OR p_rejected_details IS NULL OR jsonb_typeof(p_rejected_details)<>'array' THEN
    RAISE EXCEPTION 'Invalid snapshot publication request' USING ERRCODE='22023';
  END IF;

  SELECT * INTO STRICT v_cycle
  FROM private.demo_derivative_price_cycles c
  WHERE c.id=p_cycle_id
  FOR UPDATE;

  IF v_cycle.cycle_status='completed' THEN
    SELECT * INTO STRICT v_existing
    FROM private.demo_derivative_price_snapshots s
    WHERE s.cycle_id=p_cycle_id;
    IF v_existing.id=p_snapshot_id
       AND v_existing.snapshot_status=p_snapshot_status
       AND v_existing.mark_price IS NOT DISTINCT FROM p_mark_price
       AND v_existing.index_price IS NOT DISTINCT FROM p_index_price
       AND v_existing.source_providers IS NOT DISTINCT FROM p_source_providers
       AND v_existing.as_of IS NOT DISTINCT FROM p_as_of
       AND v_existing.expires_at IS NOT DISTINCT FROM p_expires_at
       AND v_existing.rejected_details IS NOT DISTINCT FROM p_rejected_details THEN
      RETURN p_snapshot_id;
    END IF;
    RAISE EXCEPTION 'Snapshot retry differs from the published result' USING ERRCODE='23505';
  END IF;
  IF v_cycle.cycle_status<>'collecting' THEN
    RAISE EXCEPTION 'Price cycle is not publishable' USING ERRCODE='55000';
  END IF;

  SELECT * INTO STRICT v_policy
  FROM private.demo_derivative_price_policies p
  WHERE p.symbol=v_cycle.symbol AND p.policy_version=v_cycle.policy_version;

  SELECT coalesce(array_agg(o.provider ORDER BY o.provider),'{}'::text[]),
         coalesce(array_agg(o.mark_price ORDER BY o.mark_price),'{}'::numeric[]),
         coalesce(array_agg(o.index_price ORDER BY o.index_price),'{}'::numeric[]),
         count(*),min(o.provider_timestamp)
    INTO v_accepted,v_marks,v_indices,v_count,v_as_of
  FROM private.demo_derivative_price_observations o
  WHERE o.cycle_id=p_cycle_id AND o.validation_status='accepted';

  IF cardinality(p_source_providers)<>(SELECT count(DISTINCT x.provider) FROM unnest(p_source_providers) x(provider))
     OR ARRAY(SELECT x.provider FROM unnest(p_source_providers) x(provider) ORDER BY x.provider)
        IS DISTINCT FROM v_accepted THEN
    RAISE EXCEPTION 'Snapshot source list must exactly match accepted observations' USING ERRCODE='23514';
  END IF;

  IF p_snapshot_status='healthy' THEN
    IF v_count<v_policy.min_sources THEN
      RAISE EXCEPTION 'Healthy snapshot does not meet policy quorum' USING ERRCODE='23514';
    END IF;
    IF EXISTS (
      SELECT 1 FROM private.demo_derivative_price_observations o
      WHERE o.cycle_id=p_cycle_id AND o.validation_status='accepted'
        AND (o.provider_timestamp < clock_timestamp()-(v_policy.max_age_ms*interval '1 millisecond')
          OR o.provider_timestamp > clock_timestamp()+(v_policy.max_future_skew_ms*interval '1 millisecond'))
    ) THEN
      RAISE EXCEPTION 'Healthy snapshot contains stale or future-dated observations' USING ERRCODE='23514';
    END IF;
    v_mark_median := (v_marks[(v_count+1)/2]+v_marks[(v_count+2)/2])/2;
    v_index_median := (v_indices[(v_count+1)/2]+v_indices[(v_count+2)/2])/2;
    SELECT EXISTS (
      SELECT 1 FROM private.demo_derivative_price_observations o
      WHERE o.cycle_id=p_cycle_id AND o.validation_status='accepted'
        AND (abs(o.mark_price-v_mark_median)/v_mark_median*10000>v_policy.max_mark_deviation_bps
          OR abs(o.index_price-v_index_median)/v_index_median*10000>v_policy.max_index_deviation_bps)
    ) INTO v_deviation;
    IF v_deviation
       OR abs(v_mark_median-v_index_median)/v_index_median*10000>v_policy.max_mark_index_deviation_bps THEN
      RAISE EXCEPTION 'Healthy snapshot violates configured price-deviation policy' USING ERRCODE='23514';
    END IF;
    IF p_mark_price IS DISTINCT FROM round(v_mark_median,18)
       OR p_index_price IS DISTINCT FROM round(v_index_median,18)
       OR p_as_of IS DISTINCT FROM v_as_of
       OR p_expires_at IS DISTINCT FROM (v_as_of+v_policy.max_age_ms*interval '1 millisecond') THEN
      RAISE EXCEPTION 'Published consensus prices or validity window do not match observations' USING ERRCODE='23514';
    END IF;
  ELSE
    IF p_mark_price IS NOT NULL OR p_index_price IS NOT NULL OR p_as_of IS NOT NULL OR p_expires_at IS NOT NULL
       OR jsonb_array_length(p_rejected_details)=0 THEN
      RAISE EXCEPTION 'Non-healthy snapshots must have null prices/times and an explanatory detail' USING ERRCODE='23514';
    END IF;
    IF p_snapshot_status='insufficient_quorum' AND v_count>=v_policy.min_sources THEN
      RAISE EXCEPTION 'Insufficient-quorum status is inconsistent with accepted sources' USING ERRCODE='23514';
    END IF;
    IF p_snapshot_status IN ('stale','deviation') AND v_count<v_policy.min_sources THEN
      RAISE EXCEPTION 'Stale/deviation status requires a complete quorum' USING ERRCODE='23514';
    END IF;
  END IF;

  INSERT INTO private.demo_derivative_price_snapshots(
    id,cycle_id,symbol,policy_version,snapshot_status,mark_price,index_price,
    source_count,source_providers,as_of,expires_at,rejected_details
  ) VALUES (
    p_snapshot_id,p_cycle_id,v_cycle.symbol,v_cycle.policy_version,p_snapshot_status,
    p_mark_price,p_index_price,v_count,v_accepted,p_as_of,p_expires_at,p_rejected_details
  );
  UPDATE private.demo_derivative_price_cycles
  SET cycle_status='completed',completed_at=clock_timestamp()
  WHERE id=p_cycle_id;
  RETURN p_snapshot_id;
END;
$function$;

REVOKE ALL ON FUNCTION private.demo_derivative_price_start_cycle(uuid,text,text[],jsonb) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.demo_derivative_price_record_provider_result(uuid,text,text,numeric,numeric,timestamptz,text,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.demo_derivative_price_publish_snapshot(uuid,uuid,text,numeric,numeric,text[],timestamptz,timestamptz,jsonb) FROM PUBLIC,anon,authenticated;
GRANT USAGE ON SCHEMA private TO service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_price_start_cycle(uuid,text,text[],jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_price_record_provider_result(uuid,text,text,numeric,numeric,timestamptz,text,text) TO service_role;
GRANT EXECUTE ON FUNCTION private.demo_derivative_price_publish_snapshot(uuid,uuid,text,numeric,numeric,text[],timestamptz,timestamptz,jsonb) TO service_role;

COMMIT;

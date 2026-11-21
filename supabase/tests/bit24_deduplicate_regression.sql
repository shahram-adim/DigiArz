-- Regression tests for the two Bit24 deduplication edge cases.
-- This exercises the exact SQL expressions used by the migration in disposable CI.
DO $$
DECLARE
  v_conflicts integer;
  v_selected jsonb;
BEGIN
  -- Composite DISTINCT must treat (base, NULL) and (base, quote) as distinct.
  SELECT count(*) INTO v_conflicts
  FROM (
    SELECT market_symbol
    FROM (VALUES
      ('AAA_USDT'::text, 'AAA'::text, NULL::text),
      ('AAA_USDT'::text, 'AAA'::text, 'USDT'::text),
      ('BBB_USDT'::text, 'BBB'::text, 'USDT'::text),
      ('BBB_USDT'::text, 'BBB'::text, 'USDT'::text)
    ) AS rows(market_symbol, base_symbol, quote_symbol)
    GROUP BY market_symbol
    HAVING count(DISTINCT (base_symbol, quote_symbol)) > 1
  ) conflicts;

  IF v_conflicts <> 1 THEN
    RAISE EXCEPTION 'NULL-aware conflict regression failed: expected 1 conflicting market, got %', v_conflicts;
  END IF;

  -- The JSONB text tie-breaker must choose the same payload regardless of input order.
  WITH rows(market_symbol, requested_at, request_id, asset_name, source_payload) AS (
    VALUES
      ('AAA_USDT'::text, timestamptz '2026-01-01 00:00:00+00', 7::bigint, 'Alpha'::text, '{"z":1,"a":2}'::jsonb),
      ('AAA_USDT'::text, timestamptz '2026-01-01 00:00:00+00', 7::bigint, 'Alpha'::text, '{"z":2,"a":1}'::jsonb)
  )
  SELECT source_payload INTO v_selected
  FROM (
    SELECT DISTINCT ON (market_symbol)
      source_payload
    FROM rows
    ORDER BY market_symbol, requested_at DESC, request_id DESC,
             (asset_name IS NOT NULL) DESC, source_payload::text DESC
  ) chosen;

  IF v_selected IS DISTINCT FROM '{"z":1,"a":2}'::jsonb THEN
    RAISE EXCEPTION 'Deterministic JSONB tie-break regression failed: selected %', v_selected;
  END IF;
END;
$$;

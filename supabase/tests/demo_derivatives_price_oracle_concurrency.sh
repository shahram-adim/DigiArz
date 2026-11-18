#!/usr/bin/env bash
set -euo pipefail

: "${PGPASSWORD:?PGPASSWORD must be set for disposable PostgreSQL tests}"

PSQL=(psql -h localhost -U postgres -d digiarz_derivatives_schema_test -X -qAt -v ON_ERROR_STOP=1)
OUT_A="$(mktemp)"
OUT_B="$(mktemp)"
trap 'rm -f "$OUT_A" "$OUT_B"' EXIT

CYCLE_START="a1000000-0000-0000-0000-000000000020"
CYCLE_PROVIDER_SAME="a1000000-0000-0000-0000-000000000021"
CYCLE_PROVIDER_DIFF="a1000000-0000-0000-0000-000000000022"
CYCLE_PUBLISH="a1000000-0000-0000-0000-000000000023"
SNAPSHOT_ID="b1000000-0000-0000-0000-000000000023"

service_sql() {
  printf "SET ROLE service_role; SET request.jwt.claim.role='service_role'; %s" "$1"
}

start_sql() {
  local cycle_id="$1"
  service_sql "SELECT private.demo_derivative_price_start_cycle(
    '$cycle_id','ETHUSDT',ARRAY['binance_usdm','bybit_linear'],
    '{"binance_usdm":"ETHUSDT","bybit_linear":"ETHUSDT"}'::jsonb
  );"
}

record_sql() {
  local cycle_id="$1" provider="$2" mark="$3" index="$4" ts="$5" hash="$6"
  service_sql "SELECT private.demo_derivative_price_record_provider_result(
    '$cycle_id','$provider','accepted',$mark,$index,'$ts',repeat('$hash',64),NULL
  );"
}

publish_sql() {
  local cycle_id="$1" ts="$2"
  service_sql "SELECT private.demo_derivative_price_publish_snapshot(
    '$cycle_id','$SNAPSHOT_ID','healthy',100.05,99.95,
    ARRAY['binance_usdm','bybit_linear'],'$ts'::timestamptz,
    '$ts'::timestamptz+interval '5 seconds','[]'::jsonb
  );"
}

run_pair() {
  local sql_a="$1" sql_b="$2" app="$3"
  : >"$OUT_A"
  : >"$OUT_B"
  PGAPPNAME="${app}_a" "${PSQL[@]}" -c "$sql_a" >"$OUT_A" 2>&1 &
  local pid_a=$!
  PGAPPNAME="${app}_b" "${PSQL[@]}" -c "$sql_b" >"$OUT_B" 2>&1 &
  local pid_b=$!
  if wait "$pid_a"; then RC_A=0; else RC_A=$?; fi
  if wait "$pid_b"; then RC_B=0; else RC_B=$?; fi
}

# Two independent sessions create the same cycle at once. Both calls must
# converge on one cycle and exactly one pair of provider-source rows.
run_pair "$(start_sql "$CYCLE_START")" "$(start_sql "$CYCLE_START")" digiarz_oracle_cycle_race
if [[ "$RC_A" -ne 0 || "$RC_B" -ne 0 ]]; then
  echo "Concurrent identical cycle creation did not converge."
  cat "$OUT_A" "$OUT_B"
  exit 1
fi
START_STATE="$("${PSQL[@]}" -c "SELECT CASE
  WHEN (SELECT count(*) FROM private.demo_derivative_price_cycles WHERE id='$CYCLE_START')=1
   AND (SELECT count(*) FROM private.demo_derivative_price_cycle_sources WHERE cycle_id='$CYCLE_START')=2
  THEN 'ok' ELSE 'bad' END;")"
if [[ "$START_STATE" != "ok" ]]; then
  echo "Concurrent cycle creation left duplicate or incomplete source rows: $START_STATE"
  exit 1
fi
# Simulate a client that lost the successful response after commit and retries.
"${PSQL[@]}" -c "$(start_sql "$CYCLE_START")" >/dev/null

# Identical provider deliveries in two sessions must create one observation
# and both callers must receive the same idempotent result.
"${PSQL[@]}" -c "$(start_sql "$CYCLE_PROVIDER_SAME")" >/dev/null
TS_SAME="$("${PSQL[@]}" -c "SELECT clock_timestamp();")"
SAME_SQL="$(record_sql "$CYCLE_PROVIDER_SAME" binance_usdm 100 99.9 "$TS_SAME" c)"
run_pair "$SAME_SQL" "$SAME_SQL" digiarz_oracle_provider_same_race
if [[ "$RC_A" -ne 0 || "$RC_B" -ne 0 ]]; then
  echo "Concurrent identical provider results did not converge."
  cat "$OUT_A" "$OUT_B"
  exit 1
fi
SAME_STATE="$("${PSQL[@]}" -c "SELECT CASE
  WHEN (SELECT count(*) FROM private.demo_derivative_price_observations
        WHERE cycle_id='$CYCLE_PROVIDER_SAME' AND provider='binance_usdm')=1
   AND (SELECT source_status FROM private.demo_derivative_price_cycle_sources
        WHERE cycle_id='$CYCLE_PROVIDER_SAME' AND provider='binance_usdm')='received'
  THEN 'ok' ELSE 'bad' END;")"
if [[ "$SAME_STATE" != "ok" ]]; then
  echo "Concurrent identical provider results left inconsistent observation state: $SAME_STATE"
  exit 1
fi
"${PSQL[@]}" -c "$SAME_SQL" >/dev/null

# Different payloads racing for the same provider/cycle must have one winner;
# the losing payload must not overwrite the committed observation.
"${PSQL[@]}" -c "$(start_sql "$CYCLE_PROVIDER_DIFF")" >/dev/null
TS_DIFF="$("${PSQL[@]}" -c "SELECT clock_timestamp();")"
DIFF_A="$(record_sql "$CYCLE_PROVIDER_DIFF" binance_usdm 100 99.9 "$TS_DIFF" d)"
DIFF_B="$(record_sql "$CYCLE_PROVIDER_DIFF" binance_usdm 101 100.9 "$TS_DIFF" e)"
run_pair "$DIFF_A" "$DIFF_B" digiarz_oracle_provider_conflict_race
SUCCESS_COUNT=$(( (RC_A == 0) + (RC_B == 0) ))
FAIL_COUNT=$(( (RC_A != 0) + (RC_B != 0) ))
if [[ "$SUCCESS_COUNT" -ne 1 || "$FAIL_COUNT" -ne 1 ]] ||
   ! grep -Fq 'Provider result retry differs from the persisted result' "$OUT_A" "$OUT_B"; then
  echo "Expected one provider payload winner and one idempotency conflict."
  cat "$OUT_A" "$OUT_B"
  exit 1
fi
DIFF_STATE="$("${PSQL[@]}" -c "SELECT CASE
  WHEN (SELECT count(*) FROM private.demo_derivative_price_observations
        WHERE cycle_id='$CYCLE_PROVIDER_DIFF' AND provider='binance_usdm')=1
   AND (SELECT response_sha256 FROM private.demo_derivative_price_observations
        WHERE cycle_id='$CYCLE_PROVIDER_DIFF' AND provider='binance_usdm')
       IN (repeat('d',64),repeat('e',64))
  THEN 'ok' ELSE 'bad' END;")"
if [[ "$DIFF_STATE" != "ok" ]]; then
  echo "Conflicting provider race persisted an invalid observation: $DIFF_STATE"
  exit 1
fi

# Two accepted sources are then published by independent sessions with the
# same snapshot request. The cycle lock must serialize publication and make
# the second caller an idempotent retry, not a duplicate snapshot.
"${PSQL[@]}" -c "$(start_sql "$CYCLE_PUBLISH")" >/dev/null
TS_PUBLISH="$("${PSQL[@]}" -c "SELECT clock_timestamp();")"
"${PSQL[@]}" -c "$(record_sql "$CYCLE_PUBLISH" binance_usdm 100 99.9 "$TS_PUBLISH" f)" >/dev/null
"${PSQL[@]}" -c "$(record_sql "$CYCLE_PUBLISH" bybit_linear 100.1 100.0 "$TS_PUBLISH" 1)" >/dev/null
PUBLISH_SQL="$(publish_sql "$CYCLE_PUBLISH" "$TS_PUBLISH")"
run_pair "$PUBLISH_SQL" "$PUBLISH_SQL" digiarz_oracle_publish_race
if [[ "$RC_A" -ne 0 || "$RC_B" -ne 0 ]]; then
  echo "Concurrent identical snapshot publication did not converge."
  cat "$OUT_A" "$OUT_B"
  exit 1
fi
PUBLISH_STATE="$("${PSQL[@]}" -c "SELECT CASE
  WHEN (SELECT cycle_status FROM private.demo_derivative_price_cycles WHERE id='$CYCLE_PUBLISH')='completed'
   AND (SELECT count(*) FROM private.demo_derivative_price_snapshots WHERE cycle_id='$CYCLE_PUBLISH')=1
   AND (SELECT id FROM private.demo_derivative_price_snapshots WHERE cycle_id='$CYCLE_PUBLISH')='$SNAPSHOT_ID'
  THEN 'ok' ELSE 'bad' END;")"
if [[ "$PUBLISH_STATE" != "ok" ]]; then
  echo "Concurrent publication left duplicate snapshots or an incomplete cycle: $PUBLISH_STATE"
  exit 1
fi
# Simulate a lost post-commit acknowledgement and replay the exact publication.
"${PSQL[@]}" -c "$PUBLISH_SQL" >/dev/null

echo "Oracle two-session races passed: duplicate cycle creation converged; identical provider retries created one observation; conflicting provider payloads had one winner; concurrent snapshot publication created one snapshot; post-commit retries were idempotent."

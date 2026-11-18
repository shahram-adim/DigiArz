#!/usr/bin/env bash
set -euo pipefail

: "${PGPASSWORD:?PGPASSWORD must be set for disposable PostgreSQL tests}"

PSQL=(psql -h localhost -U postgres -d digiarz_derivatives_schema_test -X -qAt -v ON_ERROR_STOP=1)
OUT_A="$(mktemp)"
OUT_B="$(mktemp)"
trap 'rm -f "$OUT_A" "$OUT_B"' EXIT

SCHEDULE_V3="c1000000-0000-0000-0000-000000000013"
SCHEDULE_V4="c1000000-0000-0000-0000-000000000014"

"${PSQL[@]}" <<SQL
INSERT INTO private.demo_derivative_maintenance_tier_schedules(id,symbol,schedule_version)
VALUES ('$SCHEDULE_V3','BTCUSDT',3),('$SCHEDULE_V4','BTCUSDT',4);
INSERT INTO private.demo_derivative_maintenance_tiers(
 schedule_id,tier_index,max_notional,maintenance_rate,maintenance_amount,max_leverage
) VALUES
 ('$SCHEDULE_V3',1,10000,0.02,0,50),
 ('$SCHEDULE_V3',2,NULL,0.03,100,25),
 ('$SCHEDULE_V4',1,10000,0.025,0,40),
 ('$SCHEDULE_V4',2,NULL,0.035,100,20);
SQL

RESOLVE_AND_HOLD="SET ROLE service_role; BEGIN;
SELECT schedule_version FROM private.demo_derivative_resolve_maintenance_tier('BTCUSDT',20000);
SELECT pg_sleep(1.5);
COMMIT;"
PGAPPNAME=digiarz_maintenance_resolver_hold "${PSQL[@]}" -c "$RESOLVE_AND_HOLD" >"$OUT_A" 2>&1 &
PID_A=$!

READY=0
for _ in $(seq 1 60); do
  if grep -Fxq "2" "$OUT_A"; then READY=1; break; fi
  if ! kill -0 "$PID_A" 2>/dev/null; then break; fi
  sleep 0.05
done
if [[ "$READY" -ne 1 ]]; then
  echo "Resolver session did not acquire and return the active v2 schedule."
  cat "$OUT_A"
  exit 1
fi

ACTIVATE_V3="SET ROLE service_role; SELECT * FROM private.demo_derivative_activate_maintenance_schedule('$SCHEDULE_V3');"
PGAPPNAME=digiarz_maintenance_activate_v3 "${PSQL[@]}" -c "$ACTIVATE_V3" >"$OUT_B" 2>&1 &
PID_B=$!

if wait "$PID_A"; then RC_A=0; else RC_A=$?; fi
if wait "$PID_B"; then RC_B=0; else RC_B=$?; fi
if [[ "$RC_A" -ne 0 || "$RC_B" -ne 0 ]]; then
  echo "Resolver/activation race failed."
  cat "$OUT_A" "$OUT_B"
  exit 1
fi

STATE_V3="$("${PSQL[@]}" -c "SELECT CASE
  WHEN (SELECT status FROM private.demo_derivative_maintenance_tier_schedules WHERE id='$SCHEDULE_V3')='active'
   AND (SELECT status FROM private.demo_derivative_maintenance_tier_schedules WHERE symbol='BTCUSDT' AND schedule_version=2)='retired'
   AND (SELECT count(*) FROM private.demo_derivative_maintenance_tier_schedules WHERE symbol='BTCUSDT' AND status='active')=1
   AND (SELECT schedule_version FROM private.demo_derivative_resolve_maintenance_tier('BTCUSDT',20000))=3
  THEN 'ok' ELSE 'bad' END;")"
if [[ "$STATE_V3" != "ok" ]]; then
  echo "Resolver/activation race produced an inconsistent active version: $STATE_V3"
  exit 1
fi

ACTIVATE_V4="SET ROLE service_role; SELECT schedule_version FROM private.demo_derivative_activate_maintenance_schedule('$SCHEDULE_V4');"
: >"$OUT_A"
: >"$OUT_B"
PGAPPNAME=digiarz_maintenance_activate_v4_a "${PSQL[@]}" -c "$ACTIVATE_V4" >"$OUT_A" 2>&1 &
PID_A=$!
PGAPPNAME=digiarz_maintenance_activate_v4_b "${PSQL[@]}" -c "$ACTIVATE_V4" >"$OUT_B" 2>&1 &
PID_B=$!
if wait "$PID_A"; then RC_A=0; else RC_A=$?; fi
if wait "$PID_B"; then RC_B=0; else RC_B=$?; fi
if [[ "$RC_A" -ne 0 || "$RC_B" -ne 0 ]]; then
  echo "Concurrent idempotent maintenance schedule activation did not converge."
  cat "$OUT_A" "$OUT_B"
  exit 1
fi
if [[ "$(tr -d '[:space:]' <"$OUT_A")" != "4" || "$(tr -d '[:space:]' <"$OUT_B")" != "4" ]]; then
  echo "Concurrent activation retries did not return the same schedule version."
  cat "$OUT_A" "$OUT_B"
  exit 1
fi

STATE_V4="$("${PSQL[@]}" -c "SELECT CASE
  WHEN (SELECT status FROM private.demo_derivative_maintenance_tier_schedules WHERE id='$SCHEDULE_V3')='retired'
   AND (SELECT status FROM private.demo_derivative_maintenance_tier_schedules WHERE id='$SCHEDULE_V4')='active'
   AND (SELECT count(*) FROM private.demo_derivative_maintenance_tier_schedules WHERE symbol='BTCUSDT' AND status='active')=1
   AND (SELECT schedule_version FROM private.demo_derivative_resolve_maintenance_tier('BTCUSDT',20000))=4
  THEN 'ok' ELSE 'bad' END;")"
if [[ "$STATE_V4" != "ok" ]]; then
  echo "Concurrent activation retries left an inconsistent schedule state: $STATE_V4"
  exit 1
fi

echo "Maintenance tier concurrency passed: resolver snapshot pinned v2 while activation waited; v3 replaced v2 atomically; concurrent exact v4 activation retries converged on one active version."

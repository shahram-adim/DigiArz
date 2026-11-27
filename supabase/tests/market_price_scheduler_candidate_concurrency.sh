#!/usr/bin/env bash
set -euo pipefail

: "${DB_NAME:=digiarz_market_scheduler_candidate_test}"
LOCK_LOG=/tmp/digiarz-market-scheduler-lock.log
PGAPPNAME=digiarz_scheduler_lock_holder psql -h localhost -U postgres -d "$DB_NAME" \
  -v ON_ERROR_STOP=1 -c "BEGIN; SELECT pg_advisory_xact_lock(742019,31); SELECT pg_sleep(8); COMMIT;" \
  >"$LOCK_LOG" 2>&1 &
LOCK_PID=$!
cleanup() {
  if kill -0 "$LOCK_PID" 2>/dev/null; then kill "$LOCK_PID" 2>/dev/null || true; fi
  wait "$LOCK_PID" 2>/dev/null || true
}
trap cleanup EXIT

LOCK_READY=0
for attempt in $(seq 1 40); do
  ACTIVE=$(psql -h localhost -U postgres -d "$DB_NAME" -At \
    -c "SELECT count(*) FROM pg_stat_activity WHERE application_name='digiarz_scheduler_lock_holder' AND state='active' AND query LIKE '%pg_sleep(8)%';")
  if [ "$ACTIVE" = "1" ]; then LOCK_READY=1; break; fi
  sleep 0.25
done
if [ "$LOCK_READY" != "1" ]; then
  cat "$LOCK_LOG"
  echo "Timed out waiting for scheduler lock holder."
  exit 1
fi

RESULT=$(psql -h localhost -U postgres -d "$DB_NAME" -At -v ON_ERROR_STOP=1 \
  -c "SELECT scheduler_candidate.schedule_next_batch(10);")
if [ "$RESULT" != "" ]; then
  echo "Concurrent scheduler unexpectedly acquired a second batch while lock was held: $RESULT"
  exit 1
fi

wait "$LOCK_PID"
echo "PASS: concurrent scheduler invocation was rejected while advisory lease was held."

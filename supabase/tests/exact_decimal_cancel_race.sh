#!/usr/bin/env bash
set -euo pipefail

DB_ARGS=(-h localhost -U postgres -d digiarz_test -v ON_ERROR_STOP=1)
wait_for() {
  local sql="$1"
  local label="$2"
  for attempt in $(seq 1 80); do
    if [ "$(psql "${DB_ARGS[@]}" -At -c "$sql")" = "1" ]; then return 0; fi
    sleep 0.1
  done
  echo "Timed out waiting for: $label"
  return 1
}

# Race 1: worker has the order lock while its trade insert is deliberately paused.
PGAPPNAME=digiarz_race_worker psql "${DB_ARGS[@]}" \
  -c "SELECT public.process_limit_orders();" > /tmp/digiarz-race-worker.log 2>&1 &
WORKER_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity WHERE application_name='digiarz_race_worker' AND state='active' AND query LIKE '%process_limit_orders%' AND wait_event='PgSleep';" "worker holding order lock inside delayed trade insert"
PGAPPNAME=digiarz_race_cancel psql "${DB_ARGS[@]}" \
  -c "SELECT set_config('request.jwt.claim.sub','71000000-0000-0000-0000-000000000001',false); SELECT public.cancel_limit_order('71000000-0000-0000-0000-000000000011');" \
  > /tmp/digiarz-race-cancel.log 2>&1 &
CANCEL_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity WHERE application_name='digiarz_race_cancel' AND state='active' AND wait_event_type='Lock';" "cancellation waiting behind worker row lock"
wait "$WORKER_PID"
wait "$CANCEL_PID"

# Race 2: cancellation owns the order lock; SKIP LOCKED must leave it untouched.
PGAPPNAME=digiarz_cancel_first psql "${DB_ARGS[@]}" \
  -c "BEGIN; SELECT set_config('request.jwt.claim.sub','72000000-0000-0000-0000-000000000002',false); SELECT public.cancel_limit_order('72000000-0000-0000-0000-000000000022'); SELECT pg_sleep(2); COMMIT;" \
  > /tmp/digiarz-cancel-first.log 2>&1 &
CANCEL_FIRST_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity WHERE application_name='digiarz_cancel_first' AND state='active' AND query LIKE '%pg_sleep(2)%';" "cancellation transaction holding order lock"
PGAPPNAME=digiarz_worker_skipped psql "${DB_ARGS[@]}" \
  -c "SELECT public.process_limit_orders();" > /tmp/digiarz-worker-skipped.log 2>&1
wait "$CANCEL_FIRST_PID"

psql "${DB_ARGS[@]}" -f supabase/tests/exact_decimal_cancel_race_verify.sql

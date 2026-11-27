#!/usr/bin/env bash
set -euo pipefail
DB_NAME="${DB_NAME:-digiarz_stop_limit_parent_child_cancel_race_test}"
DB_ARGS=(-h localhost -U postgres -d "$DB_NAME" -v ON_ERROR_STOP=1)
wait_for() {
 local sql="$1"; local label="$2"
 for attempt in $(seq 1 150); do
  if [ "$(psql "${DB_ARGS[@]}" -At -c "$sql")" = "1" ]; then return 0; fi
  sleep 0.1
 done
 echo "Timed out waiting for: $label"; return 1
}

# Child cancellation locks the child order, then its reservation. The test
# trigger pauses while that transaction owns both locks.
PGAPPNAME=digiarz_child_cancel_first psql "${DB_ARGS[@]}" -c "
 SELECT set_config('request.jwt.claim.sub','79000000-0000-0000-0000-000000000009',false);
 SELECT public.cancel_limit_order('79000000-0000-0000-0000-000000000029');
 " >/tmp/digiarz-child-cancel-first.log 2>&1 &
CHILD_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity
 WHERE application_name='digiarz_child_cancel_first' AND state='active'
 AND wait_event='PgSleep';" "direct child cancellation paused after locking child and reservation"

# Parent cancellation locks the conditional and parent, then must wait for
# the child row held by the direct child cancellation.
PGAPPNAME=digiarz_parent_cancel_wait psql "${DB_ARGS[@]}" -c "
 SELECT set_config('request.jwt.claim.sub','79000000-0000-0000-0000-000000000009',false);
 SELECT public.cancel_stop_limit_order('79000000-0000-0000-0000-000000000019');
 " >/tmp/digiarz-parent-cancel-wait.log 2>&1 &
PARENT_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity
 WHERE application_name='digiarz_parent_cancel_wait' AND state='active'
 AND wait_event_type='Lock';" "Stop-Limit parent cancellation waiting for the child row"

wait "$CHILD_PID"
wait "$PARENT_PID"
psql "${DB_ARGS[@]}" -f supabase/tests/exact_decimal_stop_limit_parent_child_cancel_race_verify.sql

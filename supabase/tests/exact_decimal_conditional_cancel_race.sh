#!/usr/bin/env bash
set -euo pipefail
DB_ARGS=(-h localhost -U postgres -d digiarz_conditional_race_test -v ON_ERROR_STOP=1)
wait_for() {
 local sql="$1"; local label="$2"
 for attempt in $(seq 1 100); do
  if [ "$(psql "${DB_ARGS[@]}" -At -c "$sql")" = "1" ]; then return 0; fi
  sleep 0.1
 done
 echo "Timed out waiting for: $label"; return 1
}
# Race 1: conditional worker owns conditional+parent+reservation; cancellation waits and must reject after fill.
PGAPPNAME=digiarz_conditional_worker_first psql "${DB_ARGS[@]}" -c "SELECT public.process_conditional_orders();" >/tmp/digiarz-conditional-worker-first.log 2>&1 &
WORKER_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity WHERE application_name='digiarz_conditional_worker_first' AND state='active' AND query LIKE '%process_conditional_orders%' AND wait_event='PgSleep';" "conditional worker paused while holding execution locks"
PGAPPNAME=digiarz_conditional_cancel_wait psql "${DB_ARGS[@]}" -c "SELECT set_config('request.jwt.claim.sub','75000000-0000-0000-0000-000000000005',false); SELECT public.cancel_conditional_exit_order('75000000-0000-0000-0000-000000000015');" >/tmp/digiarz-conditional-cancel-wait.log 2>&1 &
CANCEL_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity WHERE application_name='digiarz_conditional_cancel_wait' AND state='active' AND wait_event_type='Lock';" "conditional cancellation waiting on worker lock"
wait "$WORKER_PID"
if wait "$CANCEL_PID"; then
 echo "Cancellation unexpectedly succeeded after conditional order execution."
 exit 1
fi
if ! grep -q 'Conditional order cannot be cancelled' /tmp/digiarz-conditional-cancel-wait.log; then
 cat /tmp/digiarz-conditional-cancel-wait.log
 echo "Cancellation failed for an unexpected reason."
 exit 1
fi
# Enable account B only after race 1 is complete.
psql "${DB_ARGS[@]}" -c "UPDATE public.profiles SET is_active=true WHERE id='76000000-0000-0000-0000-000000000006';"
# Race 2: cancellation locks the conditional row first; worker must skip it.
PGAPPNAME=digiarz_conditional_cancel_first psql "${DB_ARGS[@]}" -c "BEGIN; SELECT set_config('request.jwt.claim.sub','76000000-0000-0000-0000-000000000006',false); SELECT public.cancel_conditional_exit_order('76000000-0000-0000-0000-000000000026'); SELECT pg_sleep(2); COMMIT;" >/tmp/digiarz-conditional-cancel-first.log 2>&1 &
CANCEL_FIRST_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity WHERE application_name='digiarz_conditional_cancel_first' AND state='active' AND query LIKE '%pg_sleep(2)%';" "conditional cancellation holding row locks"
PGAPPNAME=digiarz_conditional_worker_skipped psql "${DB_ARGS[@]}" -c "SELECT public.process_conditional_orders();" >/tmp/digiarz-conditional-worker-skipped.log 2>&1
wait "$CANCEL_FIRST_PID"
psql "${DB_ARGS[@]}" -f supabase/tests/exact_decimal_conditional_cancel_race_verify.sql

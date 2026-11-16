#!/usr/bin/env bash
set -euo pipefail
DB_ARGS=(-h localhost -U postgres -d digiarz_stop_limit_race_test -v ON_ERROR_STOP=1)
wait_for() {
 local sql="$1"; local label="$2"
 for attempt in $(seq 1 100); do
   if [ "$(psql "${DB_ARGS[@]}" -At -c "$sql")" = "1" ]; then return 0; fi
   sleep 0.1
 done
 echo "Timed out waiting for: $label"; return 1
}
# Race 1: child worker holds child row; parent cancellation locks conditional+parent and waits for child.
PGAPPNAME=digiarz_stop_child_worker psql "${DB_ARGS[@]}" -c "SELECT public.process_limit_orders();" >/tmp/digiarz-stop-child-worker.log 2>&1 &
WORKER_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity WHERE application_name='digiarz_stop_child_worker' AND state='active' AND query LIKE '%process_limit_orders%' AND wait_event='PgSleep';" "child worker paused while holding child order lock"
PGAPPNAME=digiarz_stop_cancel_wait psql "${DB_ARGS[@]}" -c "SELECT set_config('request.jwt.claim.sub','73000000-0000-0000-0000-000000000003',false); SELECT public.cancel_stop_limit_order('73000000-0000-0000-0000-000000000013');" >/tmp/digiarz-stop-cancel-wait.log 2>&1 &
CANCEL_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity WHERE application_name='digiarz_stop_cancel_wait' AND state='active' AND wait_event_type='Lock';" "Stop-Limit cancellation waiting for child lock"
wait "$WORKER_PID"
wait "$CANCEL_PID"
# Enable second account only after race 1 has completed.
psql "${DB_ARGS[@]}" -c "UPDATE public.profiles SET is_active=true WHERE id='74000000-0000-0000-0000-000000000004';"
# Race 2: cancellation owns parent/conditional/child locks; child worker must SKIP LOCKED.
PGAPPNAME=digiarz_stop_cancel_first psql "${DB_ARGS[@]}" -c "BEGIN; SELECT set_config('request.jwt.claim.sub','74000000-0000-0000-0000-000000000004',false); SELECT public.cancel_stop_limit_order('74000000-0000-0000-0000-000000000024'); SELECT pg_sleep(2); COMMIT;" >/tmp/digiarz-stop-cancel-first.log 2>&1 &
CANCEL_FIRST_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity WHERE application_name='digiarz_stop_cancel_first' AND state='active' AND query LIKE '%pg_sleep(2)%';" "Stop-Limit cancellation holding all parent-child locks"
PGAPPNAME=digiarz_stop_worker_skipped psql "${DB_ARGS[@]}" -c "SELECT public.process_limit_orders();" >/tmp/digiarz-stop-worker-skipped.log 2>&1
wait "$CANCEL_FIRST_PID"

# Race 3: child worker owns a partially-filled child; parent sync must SKIP the locked child.
psql "${DB_ARGS[@]}" -c "UPDATE public.profiles SET is_active=true WHERE id='77000000-0000-0000-0000-000000000007';"
PGAPPNAME=digiarz_stop_sync_child_worker psql "${DB_ARGS[@]}" -c "SELECT public.process_limit_orders();" >/tmp/digiarz-stop-sync-child-worker.log 2>&1 &
SYNC_WORKER_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity WHERE application_name='digiarz_stop_sync_child_worker' AND state='active' AND query LIKE '%process_limit_orders%' AND wait_event='PgSleep';" "child worker paused during second partial fill"
SYNC_COUNT=$(psql "${DB_ARGS[@]}" -At -c "SELECT (public.process_stop_limit_orders()->>'synced')::int;")
if [ "$SYNC_COUNT" != "0" ]; then
 echo "Stop-Limit parent sync should skip a child row locked by its worker; got synced=$SYNC_COUNT"
 wait "$SYNC_WORKER_PID"
 exit 1
fi
wait "$SYNC_WORKER_PID"
psql "${DB_ARGS[@]}" -c "SELECT public.process_stop_limit_orders();" >/tmp/digiarz-stop-sync-after.log

psql "${DB_ARGS[@]}" -f supabase/tests/exact_decimal_stop_limit_cancel_race_verify.sql

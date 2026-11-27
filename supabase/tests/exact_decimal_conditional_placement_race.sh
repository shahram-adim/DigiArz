#!/usr/bin/env bash
set -euo pipefail
DB_NAME="${DB_NAME:-digiarz_conditional_placement_race_test}"
DB_ARGS=(-h localhost -U postgres -d "$DB_NAME" -v ON_ERROR_STOP=1)
wait_for() {
 local sql="$1"; local label="$2"
 for attempt in $(seq 1 150); do
  if [ "$(psql "${DB_ARGS[@]}" -At -c "$sql")" = "1" ]; then return 0; fi
  sleep 0.1
 done
 echo "Timed out waiting for: $label"; return 1
}

# Worker acquires the conditional/parent/reservation locks, then the settlement
# wallet and BTC inventory locks; the trade trigger pauses before commit.
PGAPPNAME=digiarz_conditional_placement_worker \
 psql "${DB_ARGS[@]}" -c "SELECT public.process_conditional_orders();" \
 >/tmp/digiarz-conditional-placement-worker.log 2>&1 &
WORKER_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity
 WHERE application_name='digiarz_conditional_placement_worker' AND state='active'
 AND query LIKE '%process_conditional_orders%' AND wait_event='PgSleep';" \
 "conditional worker paused while holding settlement locks"

# The competing sell placement must wait for the same user's wallet lock.
# Once the conditional sell commits, only 0.5 BTC remains; 0.6 BTC must fail.
PGAPPNAME=digiarz_conditional_placement_caller \
 psql "${DB_ARGS[@]}" -v ON_ERROR_STOP=1 -c "
 SELECT set_config('request.jwt.claim.sub','78000000-0000-0000-0000-000000000008',false);
 SELECT public.place_limit_order('BTCUSDT','sell',0.6,12);
 " >/tmp/digiarz-conditional-placement-caller.log 2>&1 &
PLACEMENT_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity
 WHERE application_name='digiarz_conditional_placement_caller' AND state='active'
 AND wait_event_type='Lock' AND query LIKE '%place_limit_order%';" \
 "same-user sell placement waiting behind conditional settlement"

wait "$WORKER_PID"
if wait "$PLACEMENT_PID"; then
 echo "Unsafe sell placement unexpectedly succeeded after conditional settlement."
 cat /tmp/digiarz-conditional-placement-caller.log
 exit 1
fi
if ! grep -Fq 'Insufficient available asset balance' /tmp/digiarz-conditional-placement-caller.log; then
 cat /tmp/digiarz-conditional-placement-caller.log
 echo "Competing placement failed for an unexpected reason."
 exit 1
fi
psql "${DB_ARGS[@]}" -f supabase/tests/exact_decimal_conditional_placement_race_verify.sql

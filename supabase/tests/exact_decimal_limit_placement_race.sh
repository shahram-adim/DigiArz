#!/usr/bin/env bash
set -euo pipefail

DB_NAME="${DB_NAME:-digiarz_limit_placement_race_test}"
DB_ARGS=(-h localhost -U postgres -d "$DB_NAME" -v ON_ERROR_STOP=1)

wait_for() {
  local sql="$1"
  local label="$2"
  for attempt in $(seq 1 200); do
    if [ "$(psql "${DB_ARGS[@]}" -At -c "$sql")" = "1" ]; then
      return 0
    fi
    sleep 0.1
  done
  echo "Timed out waiting for: $label"
  return 1
}

# The worker must hold its order, reservation, wallet, and inventory locks
# while paused in the trade INSERT trigger.
PGAPPNAME=digiarz_placement_race_worker \
  psql "${DB_ARGS[@]}" -c "SELECT public.process_limit_orders();" \
  >/tmp/digiarz-placement-race-worker.log 2>&1 &
WORKER_PID=$!

wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END
  FROM pg_stat_activity
  WHERE application_name='digiarz_placement_race_worker'
    AND state='active'
    AND query LIKE '%process_limit_orders%'
    AND wait_event='PgSleep';" \
  "Limit worker paused after acquiring its sell-side locks"

# Starting inventory is 1.5 BTC, with 1 BTC already reserved. The worker
# fills 0.25 BTC, leaving 1.25 BTC inventory and 0.75 BTC reserved. A new
# 0.6 BTC sell must be rejected because only 0.5 BTC is free.
PGAPPNAME=digiarz_placement_race_placement \
  psql "${DB_ARGS[@]}" -v ON_ERROR_STOP=1 -c "
    SELECT set_config(
      'request.jwt.claim.sub',
      '81000000-0000-0000-0000-000000000001',
      false
    );
    SELECT public.place_limit_order('BTCUSDT', 'sell', 0.6, 10);
  " >/tmp/digiarz-placement-race-placement.log 2>&1 &
PLACEMENT_PID=$!

wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END
  FROM pg_stat_activity
  WHERE application_name='digiarz_placement_race_placement'
    AND state='active'
    AND wait_event_type='Lock'
    AND query LIKE '%place_limit_order%';" \
  "new sell placement waiting behind the worker wallet lock"

wait "$WORKER_PID"

if wait "$PLACEMENT_PID"; then
  echo "Unsafe sell placement unexpectedly succeeded during the worker race."
  cat /tmp/digiarz-placement-race-placement.log
  exit 1
fi

if ! grep -Fq "Insufficient available asset balance" \
  /tmp/digiarz-placement-race-placement.log; then
  cat /tmp/digiarz-placement-race-placement.log
  echo "Placement failed for an unexpected reason."
  exit 1
fi

psql "${DB_ARGS[@]}" -f supabase/tests/exact_decimal_limit_placement_race_verify.sql

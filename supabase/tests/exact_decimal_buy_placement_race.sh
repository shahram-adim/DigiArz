#!/usr/bin/env bash
set -euo pipefail

DB_NAME="${DB_NAME:-digiarz_buy_placement_race_test}"
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

PGAPPNAME=digiarz_buy_race_first \
  psql "${DB_ARGS[@]}" -c "
    SELECT set_config('request.jwt.claim.sub','82000000-0000-0000-0000-000000000001',false);
    SELECT public.place_limit_order('BTCUSDT','buy',0.6,10);
  " >/tmp/digiarz-buy-race-first.log 2>&1 &
FIRST_PID=$!

wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END
  FROM pg_stat_activity
  WHERE application_name='digiarz_buy_race_first'
    AND state='active' AND wait_event='PgSleep'
    AND query LIKE '%place_limit_order%';" \
  "first buy placement paused while holding the wallet lock"

PGAPPNAME=digiarz_buy_race_second \
  psql "${DB_ARGS[@]}" -c "
    SELECT set_config('request.jwt.claim.sub','82000000-0000-0000-0000-000000000001',false);
    SELECT public.place_limit_order('BTCUSDT','buy',0.6,10);
  " >/tmp/digiarz-buy-race-second.log 2>&1 &
SECOND_PID=$!

wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END
  FROM pg_stat_activity
  WHERE application_name='digiarz_buy_race_second'
    AND state='active' AND wait_event_type='Lock'
    AND query LIKE '%place_limit_order%';" \
  "second buy placement waiting behind the wallet lock"

wait "$FIRST_PID"
if wait "$SECOND_PID"; then
  echo "Both competing buy placements unexpectedly succeeded."
  cat /tmp/digiarz-buy-race-second.log
  exit 1
fi

if ! grep -Fq "Insufficient available USDT balance" /tmp/digiarz-buy-race-second.log; then
  cat /tmp/digiarz-buy-race-second.log
  echo "Second placement failed for an unexpected reason."
  exit 1
fi

psql "${DB_ARGS[@]}" -f supabase/tests/exact_decimal_buy_placement_race_verify.sql

#!/usr/bin/env bash
set -euo pipefail
export PGPASSWORD="\${PGPASSWORD:-postgres}"
DB_HOST="\${PGHOST:-localhost}"
DB_USER="\${PGUSER:-postgres}"
DB_NAME="\${PGDATABASE:-digiarz_inactive_account_rpc_race_test}"
PSQL=(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -X -q)

wait_for_activity() {
  local app="$1" predicate="$2"
  for attempt in {1..160}; do
    if "\${PSQL[@]}" -At -c "SELECT 1 FROM pg_stat_activity WHERE application_name='$app' AND $predicate" | grep -q '^1$'; then
      return 0
    fi
    sleep 0.05
  done
  echo "Timed out waiting for PostgreSQL session $app ($predicate)."
  exit 1
}
wait_for_sleep_query() {
  wait_for_activity "$1" "state='active' AND query LIKE '%pg_sleep(2)%'"
}
wait_for_lock_wait() {
  wait_for_activity "$1" "wait_event_type='Lock'"
}

assert_placement_then_deactivation() {
  local tag="$1" uid="$2" call="$3"
  local place_app="place_first_$tag"
  local deactivate_app="deactivate_after_$tag"

  (PGAPPNAME="$place_app" "\${PSQL[@]}" -c "BEGIN; SELECT set_config('request.jwt.claim.sub','$uid',true); SELECT $call; SELECT pg_sleep(2); COMMIT;") >/tmp/digiarz-$tag-place-first.log 2>&1 &
  local place_pid=$!
  wait_for_sleep_query "$place_app"

  (PGAPPNAME="$deactivate_app" "\${PSQL[@]}" -c "BEGIN; SELECT set_config('request.jwt.claim.sub','$uid',true); SELECT public.deactivate_my_account(); COMMIT;") >/tmp/digiarz-$tag-deactivate-after.log 2>&1 &
  local deactivate_pid=$!
  wait_for_lock_wait "$deactivate_app"

  wait "$place_pid"
  wait "$deactivate_pid"

  "\${PSQL[@]}" -c "DO \\\$\\\$ BEGIN
    IF (SELECT is_active FROM public.profiles WHERE id='$uid') IS DISTINCT FROM false THEN RAISE EXCEPTION 'profile remained active: $tag'; END IF;
    IF EXISTS (SELECT 1 FROM public.orders WHERE user_id='$uid' AND status NOT IN ('cancelled','filled','rejected')) THEN RAISE EXCEPTION 'pending order survived deactivation: $tag'; END IF;
    IF EXISTS (SELECT 1 FROM public.order_reservations WHERE user_id='$uid' AND status='reserved') THEN RAISE EXCEPTION 'reservation remained active: $tag'; END IF;
    IF EXISTS (SELECT 1 FROM public.conditional_orders WHERE user_id='$uid' AND status='pending') THEN RAISE EXCEPTION 'conditional remained pending: $tag'; END IF;
  END \\\$\\\$;"
}

assert_deactivation_then_placement() {
  local tag="$1" uid="$2" call="$3"
  local hold_app="wallet_hold_$tag"
  local place_app="place_after_deactivate_$tag"

  (PGAPPNAME="$hold_app" "\${PSQL[@]}" -c "BEGIN; SELECT user_id FROM public.wallets WHERE user_id='$uid' FOR UPDATE; SELECT pg_sleep(2); COMMIT;") >/tmp/digiarz-$tag-wallet-hold.log 2>&1 &
  local hold_pid=$!
  wait_for_sleep_query "$hold_app"

  (PGAPPNAME="$place_app" "\${PSQL[@]}" -c "BEGIN; SELECT set_config('request.jwt.claim.sub','$uid',true); SELECT $call; COMMIT;") >/tmp/digiarz-$tag-place-after.log 2>&1 &
  local place_pid=$!
  wait_for_lock_wait "$place_app"

  "\${PSQL[@]}" -c "BEGIN; SELECT set_config('request.jwt.claim.sub','$uid',true); SELECT public.deactivate_my_account(); COMMIT;" >/tmp/digiarz-$tag-deactivate-first.log 2>&1
  wait "$hold_pid"

  if wait "$place_pid"; then
    echo "Placement unexpectedly succeeded after deactivation: $tag"
    exit 1
  fi
  grep -q "Account is inactive" "/tmp/digiarz-$tag-place-after.log"

  "\${PSQL[@]}" -c "DO \\\$\\\$ BEGIN
    IF (SELECT is_active FROM public.profiles WHERE id='$uid') IS DISTINCT FROM false THEN RAISE EXCEPTION 'profile remained active: $tag'; END IF;
    IF EXISTS (SELECT 1 FROM public.orders WHERE user_id='$uid') THEN RAISE EXCEPTION 'order inserted after deactivation: $tag'; END IF;
    IF EXISTS (SELECT 1 FROM public.order_reservations WHERE user_id='$uid') THEN RAISE EXCEPTION 'reservation inserted after deactivation: $tag'; END IF;
    IF EXISTS (SELECT 1 FROM public.conditional_orders WHERE user_id='$uid') THEN RAISE EXCEPTION 'conditional inserted after deactivation: $tag'; END IF;
  END \\\$\\\$;"
}

# Placement wins the profile-row lock first; deactivation waits, then cancels
# the successfully committed order and releases its reservation.
assert_placement_then_deactivation limit 11111111-1111-4111-8111-111111111111 "public.place_limit_order('BTCUSDT','buy',0.1,100)"
assert_placement_then_deactivation stop 22222222-2222-4222-8222-222222222222 "public.place_stop_limit_order('BTCUSDT','buy',0.1,90,100)"
assert_placement_then_deactivation exit 33333333-3333-4333-8333-333333333333 "public.place_conditional_exit_order('BTCUSDT','take_profit',0.1,110)"

# The RPC passes its initial active-account check and blocks on the wallet row.
# Deactivation commits while it waits; after the wallet lock is released, the
# captured Production BEFORE INSERT trigger must reject the stale placement.
assert_deactivation_then_placement limit 44444444-4444-4444-8444-444444444444 "public.place_limit_order('BTCUSDT','buy',0.1,100)"
assert_deactivation_then_placement stop 55555555-5555-4555-8555-555555555555 "public.place_stop_limit_order('BTCUSDT','buy',0.1,90,100)"
assert_deactivation_then_placement exit 66666666-6666-4666-8666-666666666666 "public.place_conditional_exit_order('BTCUSDT','take_profit',0.1,110)"

echo "PASS: captured Production placement RPCs serialize with deactivate_my_account; stale placements are rejected by the captured INSERT trigger."

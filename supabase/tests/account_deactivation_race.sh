#!/usr/bin/env bash
set -euo pipefail
DB_NAME="${DB_NAME:-digiarz_deactivation_race_test}"
DB_ARGS=(-h localhost -U postgres -d "$DB_NAME" -v ON_ERROR_STOP=1)
wait_for() {
 local sql="$1" label="$2"
 for attempt in $(seq 1 100); do
  if [ "$(psql "${DB_ARGS[@]}" -At -c "$sql")" = "1" ]; then return 0; fi
  sleep 0.1
 done
 echo "Timed out waiting for: $label"; return 1
}
# Case 1: the initial active check is stale by the time the write occurs.
PGAPPNAME=digiarz_unlocked_place psql "${DB_ARGS[@]}" -c "SELECT set_config('request.jwt.claim.sub','81000000-0000-4000-8000-000000000001',false); SELECT public.place_order_unlocked();" >/tmp/digiarz-unlocked-place.log 2>&1 &
PLACE_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity WHERE application_name='digiarz_unlocked_place' AND state='active' AND wait_event='PgSleep';" "unlocked order path after active-account check"
psql "${DB_ARGS[@]}" -c "SELECT public.deactivate_account_fixture('81000000-0000-4000-8000-000000000001');"
wait "$PLACE_PID"
psql "${DB_ARGS[@]}" -c "DO \$\$ BEGIN
 IF (SELECT is_active FROM public.profiles WHERE id='81000000-0000-4000-8000-000000000001') THEN RAISE EXCEPTION 'case 1 account remained active'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.orders WHERE user_id='81000000-0000-4000-8000-000000000001' AND status='pending') THEN RAISE EXCEPTION 'case 1 did not reproduce post-deactivation order write'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.order_reservations r JOIN public.orders o ON o.id=r.order_id WHERE o.user_id='81000000-0000-4000-8000-000000000001' AND r.status='reserved') THEN RAISE EXCEPTION 'case 1 did not reproduce orphan active reservation'; END IF;
END \$\$;"
# Case 2: order path locks profile first; deactivation must wait, then clean its order.
PGAPPNAME=digiarz_locked_place psql "${DB_ARGS[@]}" -c "SELECT set_config('request.jwt.claim.sub','82000000-0000-4000-8000-000000000002',false); SELECT public.place_order_profile_locked();" >/tmp/digiarz-locked-place.log 2>&1 &
LOCKED_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity WHERE application_name='digiarz_locked_place' AND state='active' AND wait_event='PgSleep';" "profile-locked order path"
PGAPPNAME=digiarz_deactivate_wait psql "${DB_ARGS[@]}" -c "SELECT public.deactivate_account_fixture('82000000-0000-4000-8000-000000000002');" >/tmp/digiarz-deactivate-wait.log 2>&1 &
DEACT_PID=$!
wait_for "SELECT CASE WHEN count(*)=1 THEN 1 ELSE 0 END FROM pg_stat_activity WHERE application_name='digiarz_deactivate_wait' AND state='active' AND wait_event_type='Lock';" "deactivation waiting for profile row"
wait "$LOCKED_PID"
wait "$DEACT_PID"
# Case 3: deactivation wins first; the later locked path must reject.
psql "${DB_ARGS[@]}" -c "SELECT public.deactivate_account_fixture('83000000-0000-4000-8000-000000000003');"
if psql "${DB_ARGS[@]}" -c "SELECT set_config('request.jwt.claim.sub','83000000-0000-4000-8000-000000000003',false); SELECT public.place_order_profile_locked();" >/tmp/digiarz-inactive-place.log 2>&1; then
 echo "Case 3 unexpectedly placed an order for an inactive account."; exit 1
fi
grep -q 'Account is inactive' /tmp/digiarz-inactive-place.log
psql "${DB_ARGS[@]}" -c "DO \$\$ BEGIN
 IF (SELECT is_active FROM public.profiles WHERE id='82000000-0000-4000-8000-000000000002') THEN RAISE EXCEPTION 'case 2 account remained active'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.orders WHERE user_id='82000000-0000-4000-8000-000000000002' AND status='cancelled') THEN RAISE EXCEPTION 'case 2 order was not cleaned up'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.order_reservations r JOIN public.orders o ON o.id=r.order_id WHERE o.user_id='82000000-0000-4000-8000-000000000002' AND r.status='released' AND r.released_amount=r.reserved_amount) THEN RAISE EXCEPTION 'case 2 reservation was not released'; END IF;
 IF EXISTS(SELECT 1 FROM public.orders WHERE user_id='83000000-0000-4000-8000-000000000003') THEN RAISE EXCEPTION 'case 3 created an order'; END IF;
END \$\$;"
echo "account deactivation/order placement two-session race: PASS (unlocked TOCTOU reproduced; profile-row serialization cases passed)"

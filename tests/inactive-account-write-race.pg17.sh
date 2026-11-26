#!/usr/bin/env bash
set -euo pipefail
export PGPASSWORD="${PGPASSWORD:-postgres}"
DB_HOST="${PGHOST:-localhost}"
DB_USER="${PGUSER:-postgres}"
DB_NAME="${PGDATABASE:-digiarz_inactive_account_race_test}"
PSQL=(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -X -q)
USER_ID='11111111-1111-4111-8111-111111111111'

# Placement obtains the Production trigger's FOR SHARE lock first. Deactivation
# must wait, so the already-started INSERT commits before the profile is disabled.
("${PSQL[@]}" <<SQL
BEGIN;
INSERT INTO public.orders(user_id) VALUES ('$USER_ID');
SELECT pg_sleep(2);
COMMIT;
SQL
) >/tmp/digiarz-placement-first.log 2>&1 &
PLACEMENT_PID=$!
sleep 0.35
("${PSQL[@]}" <<SQL
BEGIN;
UPDATE public.profiles SET is_active=false,deactivated_at=now()
WHERE id='$USER_ID';
COMMIT;
SQL
) >/tmp/digiarz-deactivate-after.log 2>&1 &
DEACTIVATE_PID=$!
wait "$PLACEMENT_PID"
wait "$DEACTIVATE_PID"
RESULT=$("${PSQL[@]}" -At -c "SELECT (SELECT count(*) FROM public.orders)||':'||(SELECT is_active FROM public.profiles WHERE id='$USER_ID')")
[[ "$RESULT" == "1:false" ]] || { echo "placement-first ordering unexpected: $RESULT"; exit 1; }

# Deactivation obtains the profile row lock first. INSERTs into each of the
# three guarded Production relations must wait, then be rejected by the trigger.
"${PSQL[@]}" -c "UPDATE public.profiles SET is_active=true,deactivated_at=NULL WHERE id='$USER_ID'"
("${PSQL[@]}" <<SQL
BEGIN;
UPDATE public.profiles SET is_active=false,deactivated_at=now()
WHERE id='$USER_ID';
SELECT pg_sleep(2);
COMMIT;
SQL
) >/tmp/digiarz-deactivate-first.log 2>&1 &
DEACTIVATE_PID=$!
sleep 0.35
wait_for_inactive() {
  local relation="$1"
  if "${PSQL[@]}" -c "INSERT INTO public.$relation(user_id) VALUES ('$USER_ID')" >"/tmp/digiarz-insert-$relation.log" 2>&1; then
    echo "INSERT unexpectedly succeeded on public.$relation after account deactivation."
    wait "$DEACTIVATE_PID"
    exit 1
  fi
  grep -q "Account is inactive" "/tmp/digiarz-insert-$relation.log"
}
# All three tables use the same Production trigger function and must reject.
wait_for_inactive orders
wait_for_inactive trades
wait_for_inactive transactions
wait "$DEACTIVATE_PID"
RESULT=$("${PSQL[@]}" -At -c "SELECT (SELECT count(*) FROM public.orders)||':'||(SELECT count(*) FROM public.trades)||':'||(SELECT count(*) FROM public.transactions)||':'||(SELECT is_active FROM public.profiles WHERE id='$USER_ID')")
[[ "$RESULT" == "1:0:0:false" ]] || { echo "deactivation-first ordering unexpected: $RESULT"; exit 1; }
echo "PASS: placement-first serializes before deactivation; deactivation-first rejects INSERTs on orders, trades and transactions."

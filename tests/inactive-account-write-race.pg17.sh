#!/usr/bin/env bash
set -euo pipefail
export PGPASSWORD="${PGPASSWORD:-postgres}"
DB_HOST="${PGHOST:-localhost}"
DB_USER="${PGUSER:-postgres}"
DB_NAME="${PGDATABASE:-digiarz_inactive_account_race_test}"
PSQL=(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -X -q)

# Placement obtains the Production trigger's FOR SHARE lock first. Deactivation
# must wait, so the already-started insert commits before the profile is disabled.
("${PSQL[@]}" <<'SQL'
BEGIN;
INSERT INTO public.orders(user_id) VALUES ('11111111-1111-4111-8111-111111111111');
SELECT pg_sleep(2);
COMMIT;
SQL
) >/tmp/digiarz-placement-first.log 2>&1 &
PLACEMENT_PID=$!
sleep 0.35
("${PSQL[@]}" <<'SQL'
BEGIN;
UPDATE public.profiles SET is_active=false,deactivated_at=now()
WHERE id='11111111-1111-4111-8111-111111111111';
COMMIT;
SQL
) >/tmp/digiarz-deactivate-after.log 2>&1 &
DEACTIVATE_PID=$!
wait "$PLACEMENT_PID"
wait "$DEACTIVATE_PID"
RESULT=$("${PSQL[@]}" -At -c "SELECT (SELECT count(*) FROM public.orders)||':'||(SELECT is_active FROM public.profiles WHERE id='11111111-1111-4111-8111-111111111111')")
[[ "$RESULT" == "1:false" ]] || { echo "placement-first ordering unexpected: $RESULT"; exit 1; }

# Deactivation obtains the profile row lock first. A subsequent INSERT waits,
# then the exact Production trigger sees is_active=false and rejects it.
"${PSQL[@]}" -c "UPDATE public.profiles SET is_active=true,deactivated_at=NULL WHERE id='11111111-1111-4111-8111-111111111111'"
("${PSQL[@]}" <<'SQL'
BEGIN;
UPDATE public.profiles SET is_active=false,deactivated_at=now()
WHERE id='11111111-1111-4111-8111-111111111111';
SELECT pg_sleep(2);
COMMIT;
SQL
) >/tmp/digiarz-deactivate-first.log 2>&1 &
DEACTIVATE_PID=$!
sleep 0.35
if "${PSQL[@]}" -c "INSERT INTO public.orders(user_id) VALUES ('11111111-1111-4111-8111-111111111111')" >/tmp/digiarz-insert-after-inactive.log 2>&1; then
  echo "INSERT unexpectedly succeeded after account deactivation."
  wait "$DEACTIVATE_PID"
  exit 1
fi
wait "$DEACTIVATE_PID"
RESULT=$("${PSQL[@]}" -At -c "SELECT (SELECT count(*) FROM public.orders)||':'||(SELECT is_active FROM public.profiles WHERE id='11111111-1111-4111-8111-111111111111')")
[[ "$RESULT" == "1:false" ]] || { echo "deactivation-first ordering unexpected: $RESULT"; exit 1; }
grep -q "Account is inactive" /tmp/digiarz-insert-after-inactive.log
echo "PASS: placement-first serializes before deactivation; deactivation-first rejects subsequent INSERT."

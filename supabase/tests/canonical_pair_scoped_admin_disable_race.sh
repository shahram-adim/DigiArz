#!/usr/bin/env bash
set -euo pipefail
: "${DB_NAME:?DB_NAME is required}"
: "${PGPASSWORD:?PGPASSWORD is required}"
DB_ARGS=(-h localhost -U postgres -d "$DB_NAME" -v ON_ERROR_STOP=1)

wait_for_active_query() {
  local app="$1" pattern="$2" active=""
  for attempt in $(seq 1 60); do
    active=$(psql "${DB_ARGS[@]}" -At -c "SELECT count(*) FROM pg_stat_activity WHERE application_name='$app' AND state='active' AND query LIKE '%$pattern%';")
    if [[ "$active" != "0" ]]; then return 0; fi
    sleep 0.1
  done
  echo "Timed out waiting for active query: $app / $pattern" >&2
  return 1
}

# Worker wins the pair lock first. Wait until the worker is inside its function
# before starting admin disable; admin must wait and must not rewrite the fill.
PGAPPNAME=digiarz_pair_worker_first psql "${DB_ARGS[@]}" \
  -c "SELECT canonical_pair_disable.process_order('20000000-0000-0000-0000-000000000005',1.5);" \
  >/tmp/digiarz-pair-worker-first.log 2>&1 &
WORKER_PID=$!
wait_for_active_query digiarz_pair_worker_first process_order
psql "${DB_ARGS[@]}" -c "SELECT canonical_pair_disable.disable_pair('10000000-0000-0000-0000-000000000003');"
wait "$WORKER_PID"

# Admin owns the pair lock first. Keep the transaction open after disabling;
# the worker starts only once the admin is visibly in its pause interval.
PGAPPNAME=digiarz_pair_admin_first psql "${DB_ARGS[@]}" <<'SQL' >/tmp/digiarz-pair-admin-first.log 2>&1 &
BEGIN;
SELECT pair_id FROM canonical_pair_disable.pairs
 WHERE pair_id='10000000-0000-0000-0000-000000000005' FOR UPDATE;
SELECT canonical_pair_disable.disable_pair('10000000-0000-0000-0000-000000000005');
SELECT pg_sleep(1.5);
COMMIT;
SQL
ADMIN_PID=$!
wait_for_active_query digiarz_pair_admin_first pg_sleep
PGAPPNAME=digiarz_pair_worker_after_disable psql "${DB_ARGS[@]}" \
  -c "SELECT canonical_pair_disable.process_order('20000000-0000-0000-0000-000000000007',0);" \
  >/tmp/digiarz-pair-worker-after-disable.log 2>&1 &
WORKER_PID=$!
wait "$ADMIN_PID"
wait "$WORKER_PID"

psql "${DB_ARGS[@]}" <<'SQL'
DO $$
BEGIN
  IF (SELECT status FROM canonical_pair_disable.orders WHERE order_id='20000000-0000-0000-0000-000000000005') <> 'filled' THEN RAISE EXCEPTION 'worker-first fill was not preserved'; END IF;
  IF (SELECT status FROM canonical_pair_disable.reservations WHERE order_id='20000000-0000-0000-0000-000000000005') <> 'consumed' THEN RAISE EXCEPTION 'worker-first reservation not consumed'; END IF;
  IF NOT (SELECT is_enabled FROM canonical_pair_disable.pairs WHERE pair_id='10000000-0000-0000-0000-000000000004') THEN RAISE EXCEPTION 'worker-first sibling pair disabled'; END IF;
  IF (SELECT status FROM canonical_pair_disable.orders WHERE order_id='20000000-0000-0000-0000-000000000006') <> 'pending' THEN RAISE EXCEPTION 'worker-first sibling order changed'; END IF;
  IF (SELECT status FROM canonical_pair_disable.reservations WHERE order_id='20000000-0000-0000-0000-000000000006') <> 'reserved' THEN RAISE EXCEPTION 'worker-first sibling reservation changed'; END IF;

  IF (SELECT status FROM canonical_pair_disable.orders WHERE order_id='20000000-0000-0000-0000-000000000007') <> 'cancelled' THEN RAISE EXCEPTION 'admin-first target order not cancelled'; END IF;
  IF (SELECT status FROM canonical_pair_disable.reservations WHERE order_id='20000000-0000-0000-0000-000000000007') <> 'released' THEN RAISE EXCEPTION 'admin-first target reservation not released'; END IF;
  IF NOT (SELECT is_enabled FROM canonical_pair_disable.pairs WHERE pair_id='10000000-0000-0000-0000-000000000006') THEN RAISE EXCEPTION 'admin-first sibling pair disabled'; END IF;
  IF (SELECT status FROM canonical_pair_disable.orders WHERE order_id='20000000-0000-0000-0000-000000000008') <> 'pending' THEN RAISE EXCEPTION 'admin-first sibling order changed'; END IF;
  IF (SELECT status FROM canonical_pair_disable.reservations WHERE order_id='20000000-0000-0000-0000-000000000008') <> 'reserved' THEN RAISE EXCEPTION 'admin-first sibling reservation changed'; END IF;
END;
$$;
SQL

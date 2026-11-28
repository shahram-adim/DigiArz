#!/usr/bin/env bash
set -euo pipefail
: "${DB_NAME:?DB_NAME is required}"
: "${PGPASSWORD:?PGPASSWORD is required}"
DB_ARGS=(-h localhost -U postgres -d "$DB_NAME" -v ON_ERROR_STOP=1)

# Worker wins the pair lock first. Admin disable must wait; the fill completes,
# and the same-symbol sibling pair must remain untouched.
psql "${DB_ARGS[@]}" -c "SELECT canonical_pair_disable.process_order('20000000-0000-0000-0000-000000000005',1.5);" >/tmp/digiarz-pair-worker-first.log 2>&1 &
WORKER_PID=$!
sleep 0.25
psql "${DB_ARGS[@]}" -c "SELECT canonical_pair_disable.disable_pair('10000000-0000-0000-0000-000000000003');"
wait "$WORKER_PID"

# Admin owns the pair lock first. The worker blocks, then sees the disabled
# pair and refuses execution; the sibling pair is unaffected.
(
  psql "${DB_ARGS[@]}" <<'SQL'
BEGIN;
SELECT pair_id FROM canonical_pair_disable.pairs
 WHERE pair_id='10000000-0000-0000-0000-000000000005' FOR UPDATE;
SELECT canonical_pair_disable.disable_pair('10000000-0000-0000-0000-000000000005');
SELECT pg_sleep(1.5);
COMMIT;
SQL
) >/tmp/digiarz-pair-admin-first.log 2>&1 &
ADMIN_PID=$!
sleep 0.25
psql "${DB_ARGS[@]}" -c "SELECT canonical_pair_disable.process_order('20000000-0000-0000-0000-000000000007',0);" >/tmp/digiarz-pair-worker-after-disable.log 2>&1 &
WORKER_PID=$!
wait "$ADMIN_PID"
wait "$WORKER_PID"

psql "${DB_ARGS[@]}" <<'SQL'
DO $$
BEGIN
  -- Worker-first: the in-flight fill completes; admin disable does not rewrite it.
  IF (SELECT status FROM canonical_pair_disable.orders WHERE order_id='20000000-0000-0000-0000-000000000005') <> 'filled' THEN RAISE EXCEPTION 'worker-first fill was not preserved'; END IF;
  IF (SELECT status FROM canonical_pair_disable.reservations WHERE order_id='20000000-0000-0000-0000-000000000005') <> 'consumed' THEN RAISE EXCEPTION 'worker-first reservation not consumed'; END IF;
  IF NOT (SELECT is_enabled FROM canonical_pair_disable.pairs WHERE pair_id='10000000-0000-0000-0000-000000000004') THEN RAISE EXCEPTION 'worker-first sibling pair disabled'; END IF;
  IF (SELECT status FROM canonical_pair_disable.orders WHERE order_id='20000000-0000-0000-0000-000000000006') <> 'pending' THEN RAISE EXCEPTION 'worker-first sibling order changed'; END IF;
  IF (SELECT status FROM canonical_pair_disable.reservations WHERE order_id='20000000-0000-0000-0000-000000000006') <> 'reserved' THEN RAISE EXCEPTION 'worker-first sibling reservation changed'; END IF;

  -- Admin-first: worker cannot execute after the pair was disabled and order cancelled.
  IF (SELECT status FROM canonical_pair_disable.orders WHERE order_id='20000000-0000-0000-0000-000000000007') <> 'cancelled' THEN RAISE EXCEPTION 'admin-first target order not cancelled'; END IF;
  IF (SELECT status FROM canonical_pair_disable.reservations WHERE order_id='20000000-0000-0000-0000-000000000007') <> 'released' THEN RAISE EXCEPTION 'admin-first target reservation not released'; END IF;
  IF NOT (SELECT is_enabled FROM canonical_pair_disable.pairs WHERE pair_id='10000000-0000-0000-0000-000000000006') THEN RAISE EXCEPTION 'admin-first sibling pair disabled'; END IF;
  IF (SELECT status FROM canonical_pair_disable.orders WHERE order_id='20000000-0000-0000-0000-000000000008') <> 'pending' THEN RAISE EXCEPTION 'admin-first sibling order changed'; END IF;
  IF (SELECT status FROM canonical_pair_disable.reservations WHERE order_id='20000000-0000-0000-0000-000000000008') <> 'reserved' THEN RAISE EXCEPTION 'admin-first sibling reservation changed'; END IF;
END;
$$;
SQL

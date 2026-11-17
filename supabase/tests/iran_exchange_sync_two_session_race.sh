#!/usr/bin/env bash
set -euo pipefail

: "${PGPASSWORD:?PGPASSWORD must be set}"
DB_HOST="${PGHOST:-localhost}"
DB_PORT="${PGPORT:-5432}"
DB_USER="${PGUSER:-postgres}"
DB_NAME="${PGDATABASE:-digiarz_iran_sync_two_session_test}"

psql_base=(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1)

# The eligible response causes the worker to enter the observation INSERT.
# Hold that INSERT briefly so a second session can commit a late HTTP response.
"${psql_base[@]}" <<'SQL'
INSERT INTO public.exchange_asset_sync_requests(exchange, request_id, requested_at)
VALUES ('nobitex', 2001, transaction_timestamp() - interval '1 minute');
INSERT INTO net._http_response(id, created, status_code, content, error_msg)
VALUES (2001, transaction_timestamp() - interval '1 minute', 200,
        '{"coins":[{"coin":"BTC","name":"Bitcoin"}]}', NULL);

CREATE OR REPLACE FUNCTION public.test_pause_observation_insert()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_sleep(8);
  RETURN NEW;
END;
$$;
CREATE TRIGGER test_pause_observation_insert
BEFORE INSERT ON public.exchange_asset_observations
FOR EACH ROW EXECUTE FUNCTION public.test_pause_observation_insert();
SQL

PGAPPNAME=iran_sync_worker_session "${psql_base[@]}" \
  -c "SELECT public.process_iran_exchange_asset_sync();" \
  >/tmp/iran-sync-worker-session.log 2>&1 &
worker_pid=$!

# Wait until session A has captured its response set and is paused in the
# observation insert trigger. The active pg_sleep is the synchronization point.
ready=0
for attempt in $(seq 1 80); do
  active=$("${psql_base[@]}" -Atc "SELECT count(*) FROM pg_stat_activity WHERE application_name='iran_sync_worker_session' AND state='active' AND query LIKE '%process_iran_exchange_asset_sync%';")
  if [[ "$active" == "1" ]]; then
    sleeping=$("${psql_base[@]}" -Atc "SELECT count(*) FROM pg_stat_activity WHERE application_name='iran_sync_worker_session' AND state='active' AND wait_event_type='Timeout';")
    if [[ "$sleeping" == "1" ]]; then ready=1; break; fi
  fi
  sleep 0.1
done

if [[ "$ready" != "1" ]]; then
  cat /tmp/iran-sync-worker-session.log || true
  kill "$worker_pid" 2>/dev/null || true
  echo "Worker did not reach the synchronization point."
  exit 1
fi

# Session B commits a new request and response after session A captured IDs.
"${psql_base[@]}" <<'SQL'
INSERT INTO public.exchange_asset_sync_requests(exchange, request_id, requested_at)
VALUES ('nobitex', 2002, transaction_timestamp());
INSERT INTO net._http_response(id, created, status_code, content, error_msg)
VALUES (2002, transaction_timestamp(), 200,
        '{"coins":[{"coin":"ETH","name":"Ethereum"}]}', NULL);
SQL

wait "$worker_pid"
cat /tmp/iran-sync-worker-session.log

"${psql_base[@]}" <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.exchange_asset_sync_requests
    WHERE request_id=2001 AND processed_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'worker did not process the response captured at start';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.exchange_asset_sync_requests
    WHERE request_id=2002 AND processed_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'late response was incorrectly marked processed in the same worker run';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.exchange_asset_observations
    WHERE exchange='nobitex' AND market_symbol='ETH'
  ) THEN
    RAISE EXCEPTION 'late response was ingested in the same worker run';
  END IF;
END;
$$;
DROP TRIGGER test_pause_observation_insert ON public.exchange_asset_observations;
DROP FUNCTION public.test_pause_observation_insert();
SQL

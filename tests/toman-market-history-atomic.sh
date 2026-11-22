#!/usr/bin/env bash
set -euo pipefail

psql -v ON_ERROR_STOP=1 <<'SQL'
create role service_role nologin;
create role anon nologin;
create role authenticated nologin;
create table public.market_toman_price_history (
  id bigserial primary key,
  exchange text not null,
  asset_symbol text not null,
  price_toman numeric not null,
  bid_toman numeric,
  ask_toman numeric,
  change_24h_pct numeric,
  volume_24h_toman numeric,
  recorded_at timestamptz not null,
  asset_name_fa text,
  asset_name_en text
);
SQL

psql -v ON_ERROR_STOP=1 -f supabase/migrations/20261122130000_atomic_toman_history_interval.sql

payload='[{"exchange":"nobitex","asset_symbol":"BTC","price_toman":3000000000,"recorded_at":"2026-11-22T13:00:00Z"}]'
first=$(psql -At -v ON_ERROR_STOP=1 -c "select public.insert_market_toman_history_if_due('$payload'::jsonb)")
[[ "$first" == "1" ]] || { echo "Expected first insert=1, got $first"; exit 1; }

repeat=$(psql -At -v ON_ERROR_STOP=1 -c "select public.insert_market_toman_history_if_due('$payload'::jsonb)")
[[ "$repeat" == "0" ]] || { echo "Expected repeated insert=0, got $repeat"; exit 1; }

later_payload='[{"exchange":"nobitex","asset_symbol":"BTC","price_toman":3100000000,"recorded_at":"2026-11-22T19:00:01Z"}]'
later=$(psql -At -v ON_ERROR_STOP=1 -c "select public.insert_market_toman_history_if_due('$later_payload'::jsonb)")
[[ "$later" == "1" ]] || { echo "Expected post-six-hour insert=1, got $later"; exit 1; }

concurrent_payload='[{"exchange":"wallex","asset_symbol":"ETH","price_toman":100000000,"recorded_at":"2026-11-22T13:00:00Z"}]'
(
  psql -v ON_ERROR_STOP=1 -c "begin; select public.insert_market_toman_history_if_due('$concurrent_payload'::jsonb); select pg_sleep(2); commit" >/tmp/toman-history-writer-a.log
) &
writer_a=$!
sleep 0.25
writer_b=$(psql -At -v ON_ERROR_STOP=1 -c "select public.insert_market_toman_history_if_due('$concurrent_payload'::jsonb)")
wait "$writer_a"
[[ "$writer_b" == "0" ]] || { echo "Expected concurrent second writer=0, got $writer_b"; cat /tmp/toman-history-writer-a.log; exit 1; }

count=$(psql -At -v ON_ERROR_STOP=1 -c "select count(*) from public.market_toman_price_history where exchange='wallex' and asset_symbol='ETH'")
[[ "$count" == "1" ]] || { echo "Expected one concurrent history row, got $count"; exit 1; }

echo "Atomic history migration, six-hour interval, and concurrent writer tests passed."

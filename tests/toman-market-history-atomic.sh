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

service_exec=$(psql -At -v ON_ERROR_STOP=1 -c "select has_function_privilege('service_role', 'public.insert_market_toman_history_if_due(jsonb)', 'EXECUTE')")
anon_exec=$(psql -At -v ON_ERROR_STOP=1 -c "select has_function_privilege('anon', 'public.insert_market_toman_history_if_due(jsonb)', 'EXECUTE')")
authenticated_exec=$(psql -At -v ON_ERROR_STOP=1 -c "select has_function_privilege('authenticated', 'public.insert_market_toman_history_if_due(jsonb)', 'EXECUTE')")
[[ "$service_exec" == "t" ]] || { echo "service_role cannot execute history RPC"; exit 1; }
[[ "$anon_exec" == "f" ]] || { echo "anon unexpectedly can execute history RPC"; exit 1; }
[[ "$authenticated_exec" == "f" ]] || { echo "authenticated unexpectedly can execute history RPC"; exit 1; }

if psql -v ON_ERROR_STOP=1 -c "select public.insert_market_toman_history_if_due(null::jsonb)" >/dev/null 2>&1; then echo "Null payload unexpectedly succeeded"; exit 1; fi
if psql -v ON_ERROR_STOP=1 -c "select public.insert_market_toman_history_if_due('{}'::jsonb)" >/dev/null 2>&1; then echo "Non-array payload unexpectedly succeeded"; exit 1; fi
empty=$(psql -At -v ON_ERROR_STOP=1 -c "select public.insert_market_toman_history_if_due('[]'::jsonb)")
[[ "$empty" == "0" ]] || { echo "Expected empty-array result=0, got $empty"; exit 1; }

if psql -v ON_ERROR_STOP=1 -c "select public.insert_market_toman_history_if_due('[{\"exchange\":\"nobitex\",\"asset_symbol\":\"BTC\",\"price_toman\":0,\"recorded_at\":now()}]'::jsonb)" >/dev/null 2>&1; then echo "Zero price unexpectedly succeeded"; exit 1; fi
if psql -v ON_ERROR_STOP=1 -c "select public.insert_market_toman_history_if_due('[{\"exchange\":\"nobitex\",\"asset_symbol\":\"BTC\",\"price_toman\":\"NaN\",\"recorded_at\":now()}]'::jsonb)" >/dev/null 2>&1; then echo "NaN price unexpectedly succeeded"; exit 1; fi
if psql -v ON_ERROR_STOP=1 -c "select public.insert_market_toman_history_if_due('[{\"exchange\":\"nobitex\",\"asset_symbol\":\"BTC\",\"price_toman\":1,\"recorded_at\":now()+interval \"10 minutes\"}]'::jsonb)" >/dev/null 2>&1; then echo "Future timestamp unexpectedly succeeded"; exit 1; fi

payload=$(psql -At -v ON_ERROR_STOP=1 -c "select jsonb_build_array(jsonb_build_object('exchange','nobitex','asset_symbol','BTC','price_toman',3000000000,'recorded_at',now()))")
first=$(psql -At -v ON_ERROR_STOP=1 -c "select public.insert_market_toman_history_if_due('$payload'::jsonb)")
[[ "$first" == "1" ]] || { echo "Expected first insert=1, got $first"; exit 1; }
repeat=$(psql -At -v ON_ERROR_STOP=1 -c "select public.insert_market_toman_history_if_due('$payload'::jsonb)")
[[ "$repeat" == "0" ]] || { echo "Expected repeated insert=0, got $repeat"; exit 1; }

psql -v ON_ERROR_STOP=1 -c "update public.market_toman_price_history set recorded_at=now()-interval '6 hours 1 second' where exchange='nobitex' and asset_symbol='BTC'" >/dev/null
later=$(psql -At -v ON_ERROR_STOP=1 -c "select public.insert_market_toman_history_if_due('$payload'::jsonb)")
[[ "$later" == "1" ]] || { echo "Expected post-six-hour insert=1, got $later"; exit 1; }

concurrent_payload=$(psql -At -v ON_ERROR_STOP=1 -c "select jsonb_build_array(jsonb_build_object('exchange','wallex','asset_symbol','ETH','price_toman',100000000,'recorded_at',now()))")
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
echo "Atomic history migration, input validation, six-hour interval, and concurrent writer tests passed."

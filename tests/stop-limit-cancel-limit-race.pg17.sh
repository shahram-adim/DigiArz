#!/usr/bin/env bash
set -euo pipefail
export PGPASSWORD="${PGPASSWORD:-postgres}"
DB_HOST="${PGHOST:-localhost}"
DB_USER="${PGUSER:-postgres}"
DB_NAME="${PGDATABASE:-digiarz_inactive_account_rpc_race_test}"
PSQL=(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -X -q)
USER_ID='99999999-9999-4999-8999-999999999999'
PARENT_ID='99999999-9999-4999-8999-000000000001'
CHILD_ID='99999999-9999-4999-8999-000000000002'
COND_ID='99999999-9999-4999-8999-000000000003'

wait_for_activity() {
  local app="$1" predicate="$2"
  for attempt in {1..120}; do
    if "${PSQL[@]}" -At -c "SELECT 1 FROM pg_stat_activity WHERE application_name='$app' AND $predicate" | grep -q '^1$'; then
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
  wait_for_activity "$1" "state='active' AND wait_event_type='Lock'"
}

"${PSQL[@]}" <<SQL
INSERT INTO public.profiles(id,is_active) VALUES ('$USER_ID',true);
INSERT INTO public.wallets(user_id,balance_usdt) VALUES ('$USER_ID',1000);
INSERT INTO public.demo_trading_pairs(pair_symbol,quote_asset,is_enabled)
VALUES ('BTCUSDT','USDT',true)
ON CONFLICT (pair_symbol) DO UPDATE SET is_enabled=true,quote_asset='USDT';
INSERT INTO public.demo_trading_fees(quote_asset,maker_fee_rate,taker_fee_rate,is_enabled)
VALUES ('USDT',0.001,0.002,true)
ON CONFLICT (quote_asset) DO UPDATE SET maker_fee_rate=0.001,taker_fee_rate=0.002,is_enabled=true;
INSERT INTO public.market_prices(symbol,price,updated_at)
VALUES ('BTCUSDT',90,now())
ON CONFLICT (symbol) DO UPDATE SET price=90,updated_at=now();
INSERT INTO public.orders(id,user_id,symbol,side,order_type,amount,price,status,filled_amount,remaining_amount)
VALUES
  ('$PARENT_ID','$USER_ID','BTCUSDT','buy','conditional',0.1,100,'triggered',0,0.1),
  ('$CHILD_ID','$USER_ID','BTCUSDT','buy','limit',0.1,100,'pending',0,0.1);
INSERT INTO public.conditional_orders(
  id,order_id,user_id,symbol,side,order_kind,trigger_price,limit_price,amount,status,execution_order_id
)
VALUES ('$COND_ID','$PARENT_ID','$USER_ID','BTCUSDT','buy','stop_limit',90,100,0.1,'triggered','$CHILD_ID');
INSERT INTO public.order_reservations(order_id,user_id,asset,reserved_amount,released_amount,consumed_amount,status)
VALUES ('$CHILD_ID','$USER_ID','USDT',10.01,0,0,'reserved');
SQL

# The Limit worker owns the child and reservation locks, then pauses on wallet.
(PGAPPNAME=digiarz_cancel_wallet_hold "${PSQL[@]}" <<SQL
BEGIN;
SELECT user_id FROM public.wallets WHERE user_id='$USER_ID' FOR UPDATE;
SELECT pg_sleep(2);
COMMIT;
SQL
) >/tmp/digiarz-cancel-wallet-hold.log 2>&1 &
WALLET_PID=$!
wait_for_sleep_query digiarz_cancel_wallet_hold

(PGAPPNAME=digiarz_limit_worker_cancel_race "${PSQL[@]}" -c "SELECT public.process_limit_orders();") >/tmp/digiarz-cancel-limit-worker.log 2>&1 &
LIMIT_PID=$!
wait_for_lock_wait digiarz_limit_worker_cancel_race

# Stop-Limit cancellation locks conditional -> parent -> child. It must wait
# for the Limit worker's child lock, then cancel the partially-filled remainder.
(PGAPPNAME=digiarz_stop_cancel "${PSQL[@]}" -c "BEGIN; SELECT set_config('request.jwt.claim.sub','$USER_ID',true); SELECT public.cancel_stop_limit_order('$PARENT_ID'); COMMIT;") >/tmp/digiarz-stop-cancel.log 2>&1 &
CANCEL_PID=$!
wait_for_lock_wait digiarz_stop_cancel

wait "$WALLET_PID"
wait "$LIMIT_PID"
wait "$CANCEL_PID"

"${PSQL[@]}" -c "DO \$\$ BEGIN
  IF (SELECT status FROM public.orders WHERE id='$CHILD_ID') IS DISTINCT FROM 'cancelled' THEN
    RAISE EXCEPTION 'child Limit order was not cancelled after partial fill';
  END IF;
  IF (SELECT filled_amount FROM public.orders WHERE id='$CHILD_ID') IS DISTINCT FROM 0.025
     OR (SELECT remaining_amount FROM public.orders WHERE id='$CHILD_ID') IS DISTINCT FROM 0.075 THEN
    RAISE EXCEPTION 'child partial fill accounting was not preserved';
  END IF;
  IF (SELECT status FROM public.orders WHERE id='$PARENT_ID') IS DISTINCT FROM 'cancelled'
     OR (SELECT filled_amount FROM public.orders WHERE id='$PARENT_ID') IS DISTINCT FROM 0.025
     OR (SELECT remaining_amount FROM public.orders WHERE id='$PARENT_ID') IS DISTINCT FROM 0.075 THEN
    RAISE EXCEPTION 'parent did not reconcile to cancelled child state';
  END IF;
  IF (SELECT status FROM public.conditional_orders WHERE id='$COND_ID') IS DISTINCT FROM 'cancelled' THEN
    RAISE EXCEPTION 'Stop-Limit conditional was not cancelled';
  END IF;
  IF (SELECT status FROM public.order_reservations WHERE order_id='$CHILD_ID') IS DISTINCT FROM 'released'
     OR (SELECT consumed_amount FROM public.order_reservations WHERE order_id='$CHILD_ID') <= 0 THEN
    RAISE EXCEPTION 'reservation consumption/release accounting was not preserved';
  END IF;
  IF (SELECT count(*) FROM public.trades WHERE order_id='$CHILD_ID') <> 1
     OR (SELECT count(*) FROM public.transactions WHERE user_id='$USER_ID') <> 1 THEN
    RAISE EXCEPTION 'partial-fill trade/transaction audit rows missing';
  END IF;
END \$\$;"
echo "PASS: Stop-Limit cancellation waits for actual Limit child fill, then preserves partial-fill accounting and releases the remainder."

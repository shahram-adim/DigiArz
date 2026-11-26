#!/usr/bin/env bash
set -euo pipefail
export PGPASSWORD="${PGPASSWORD:-postgres}"
DB_HOST="${PGHOST:-localhost}"
DB_USER="${PGUSER:-postgres}"
DB_NAME="${PGDATABASE:-digiarz_inactive_account_rpc_race_test}"
PSQL=(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -X -q)
USER_ID='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
PARENT_ID='bbbbbbbb-bbbb-4bbb-8bbb-000000000001'
COND_ID='bbbbbbbb-bbbb-4bbb-8bbb-000000000002'

"${PSQL[@]}" <<SQL
-- Keep the previous one-shot rollback scenario from being retried in this test.
UPDATE public.conditional_orders SET status='cancelled' WHERE user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
UPDATE public.orders SET status='cancelled' WHERE user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

CREATE OR REPLACE FUNCTION private.fail_test_conditional_trade_insert()
RETURNS trigger LANGUAGE plpgsql SET search_path TO ''
AS \$function\$
BEGIN
  IF NEW.user_id = '$USER_ID'::uuid THEN
    RAISE EXCEPTION 'intentional retry exhaustion test failure';
  END IF;
  RETURN NEW;
END;
\$function\$;
CREATE TRIGGER zz_test_fail_conditional_trade_insert
BEFORE INSERT ON public.trades
FOR EACH ROW EXECUTE FUNCTION private.fail_test_conditional_trade_insert();

INSERT INTO public.profiles(id,is_active) VALUES ('$USER_ID',true);
INSERT INTO public.wallets(user_id,balance_usdt) VALUES ('$USER_ID',1000);
INSERT INTO public.asset_balances(user_id,asset,balance) VALUES ('$USER_ID','BTC',1);
INSERT INTO public.demo_trading_pairs(pair_symbol,quote_asset,is_enabled)
VALUES ('BTCUSDT','USDT',true)
ON CONFLICT (pair_symbol) DO UPDATE SET is_enabled=true,quote_asset='USDT';
INSERT INTO public.demo_trading_fees(quote_asset,maker_fee_rate,taker_fee_rate,is_enabled)
VALUES ('USDT',0.001,0.002,true)
ON CONFLICT (quote_asset) DO UPDATE SET maker_fee_rate=0.001,taker_fee_rate=0.002,is_enabled=true;
INSERT INTO public.market_prices(symbol,price,updated_at)
VALUES ('BTCUSDT',100,now())
ON CONFLICT (symbol) DO UPDATE SET price=100,updated_at=now();
INSERT INTO public.orders(id,user_id,symbol,side,order_type,amount,price,status,filled_amount,remaining_amount)
VALUES ('$PARENT_ID','$USER_ID','BTCUSDT','sell','conditional',0.1,90,'pending',0,0.1);
INSERT INTO public.conditional_orders(
  id,order_id,user_id,symbol,side,order_kind,trigger_price,amount,status
)
VALUES ('$COND_ID','$PARENT_ID','$USER_ID','BTCUSDT','sell','take_profit',90,0.1,'pending');
INSERT INTO public.order_reservations(
  order_id,user_id,asset,reserved_amount,released_amount,consumed_amount,status
)
VALUES ('$PARENT_ID','$USER_ID','BTC',0.1,0,0,'reserved');
SQL

for attempt in {1..10}; do
  "${PSQL[@]}" -c "SELECT public.process_conditional_orders();" >"/tmp/digiarz-conditional-retry-$attempt.log" 2>&1
done

"${PSQL[@]}" -c "DO \$\$ BEGIN
  IF (SELECT attempt_count FROM public.conditional_orders WHERE id='$COND_ID') <> 10 THEN
    RAISE EXCEPTION 'conditional retry count did not reach ten';
  END IF;
  IF (SELECT status FROM public.conditional_orders WHERE id='$COND_ID') IS DISTINCT FROM 'rejected'
     OR (SELECT status FROM public.orders WHERE id='$PARENT_ID') IS DISTINCT FROM 'rejected' THEN
    RAISE EXCEPTION 'conditional order did not fail closed after ten attempts';
  END IF;
  IF (SELECT status FROM public.order_reservations WHERE order_id='$PARENT_ID') IS DISTINCT FROM 'released'
     OR (SELECT released_amount FROM public.order_reservations WHERE order_id='$PARENT_ID') IS DISTINCT FROM 0.1 THEN
    RAISE EXCEPTION 'valid reservation was not released at retry exhaustion';
  END IF;
  IF (SELECT balance_usdt FROM public.wallets WHERE user_id='$USER_ID') IS DISTINCT FROM 1000
     OR (SELECT balance FROM public.asset_balances WHERE user_id='$USER_ID' AND asset='BTC') IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'failed market executions changed user balances';
  END IF;
  IF (SELECT count(*) FROM public.orders WHERE user_id='$USER_ID') <> 1
     OR (SELECT count(*) FROM public.trades WHERE user_id='$USER_ID') <> 0
     OR (SELECT count(*) FROM public.transactions WHERE user_id='$USER_ID') <> 0 THEN
    RAISE EXCEPTION 'failed market execution rows were persisted';
  END IF;
END \$\$;"
"${PSQL[@]}" -c "DROP TRIGGER zz_test_fail_conditional_trade_insert ON public.trades;"
echo "PASS: ten failed conditional executions retain rollback safety, then reject the order and release its valid reservation."

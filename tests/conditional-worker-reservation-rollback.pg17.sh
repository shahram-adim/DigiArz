#!/usr/bin/env bash
set -euo pipefail
export PGPASSWORD="${PGPASSWORD:-postgres}"
DB_HOST="${PGHOST:-localhost}"
DB_USER="${PGUSER:-postgres}"
DB_NAME="${PGDATABASE:-digiarz_inactive_account_rpc_race_test}"
PSQL=(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -X -q)
USER_ID='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
PARENT_ID='aaaaaaaa-aaaa-4aaa-8aaa-000000000001'
COND_ID='aaaaaaaa-aaaa-4aaa-8aaa-000000000002'

# Inject a deterministic failure after execute_demo_trade has reached its
# guarded trades INSERT. The trigger is test-only and scoped to this user.
"${PSQL[@]}" <<SQL
CREATE OR REPLACE FUNCTION private.fail_test_conditional_trade_insert()
RETURNS trigger LANGUAGE plpgsql SET search_path TO ''
AS \$function\$
BEGIN
  IF NEW.user_id = '$USER_ID'::uuid THEN
    RAISE EXCEPTION 'intentional test failure after market balance updates';
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

"${PSQL[@]}" -c "SELECT public.process_conditional_orders();" >/tmp/digiarz-conditional-rollback.log 2>&1

# The failing subtransaction must restore the reservation, wallet, asset
# balance, parent order and all execution writes; only attempt diagnostics persist.
"${PSQL[@]}" -c "DO \$\$ BEGIN
  IF (SELECT status FROM public.order_reservations WHERE order_id='$PARENT_ID') IS DISTINCT FROM 'reserved'
     OR (SELECT released_amount FROM public.order_reservations WHERE order_id='$PARENT_ID') IS DISTINCT FROM 0
     OR (SELECT consumed_amount FROM public.order_reservations WHERE order_id='$PARENT_ID') IS DISTINCT FROM 0 THEN
    RAISE EXCEPTION 'reservation release was not rolled back after execution failure';
  END IF;
  IF (SELECT balance_usdt FROM public.wallets WHERE user_id='$USER_ID') IS DISTINCT FROM 1000 THEN
    RAISE EXCEPTION 'wallet update survived failed market execution';
  END IF;
  IF (SELECT balance FROM public.asset_balances WHERE user_id='$USER_ID' AND asset='BTC') IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'asset balance update survived failed market execution';
  END IF;
  IF (SELECT status FROM public.orders WHERE id='$PARENT_ID') IS DISTINCT FROM 'pending'
     OR (SELECT status FROM public.conditional_orders WHERE id='$COND_ID') IS DISTINCT FROM 'pending' THEN
    RAISE EXCEPTION 'parent/conditional state changed despite execution failure';
  END IF;
  IF (SELECT attempt_count FROM public.conditional_orders WHERE id='$COND_ID') <> 1
     OR (SELECT last_error FROM public.conditional_orders WHERE id='$COND_ID') NOT LIKE '%intentional test failure%' THEN
    RAISE EXCEPTION 'failure diagnostic was not recorded';
  END IF;
  IF (SELECT count(*) FROM public.orders WHERE user_id='$USER_ID') <> 1
     OR (SELECT count(*) FROM public.trades WHERE user_id='$USER_ID') <> 0
     OR (SELECT count(*) FROM public.transactions WHERE user_id='$USER_ID') <> 0 THEN
    RAISE EXCEPTION 'market execution rows survived failed subtransaction';
  END IF;
END \$\$;"

# Remove only the test-only failure trigger so subsequent test users can trade.
"${PSQL[@]}" -c "DROP TRIGGER zz_test_fail_conditional_trade_insert ON public.trades;"
echo "PASS: conditional worker exception rolls back reservation release and all partial market-engine writes while preserving retry diagnostics."

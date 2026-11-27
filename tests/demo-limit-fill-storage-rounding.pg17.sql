-- Characterization regression: PostgreSQL storage rounding for the live Limit fill shape.
-- This proves the typmod mismatch only; it does NOT invoke or replace process_limit_orders().
-- Disposable PostgreSQL 17 only. All objects are temporary and transaction-scoped.
\set ON_ERROR_STOP on
BEGIN;

CREATE TEMP TABLE ci_limit_orders (
  id integer PRIMARY KEY,
  amount numeric(24,8) NOT NULL,
  filled_amount numeric NOT NULL,
  remaining_amount numeric NOT NULL
) ON COMMIT DROP;
CREATE TEMP TABLE ci_limit_trades (
  amount numeric(24,8) NOT NULL
) ON COMMIT DROP;
CREATE TEMP TABLE ci_limit_asset_balances (
  balance numeric(28,8) NOT NULL
) ON COMMIT DROP;

INSERT INTO ci_limit_orders VALUES (1,0.12345678,0,0.12345678);
INSERT INTO ci_limit_asset_balances VALUES (1.00000000);

DO $characterize$
DECLARE
  v_amount numeric;
  v_remaining numeric;
  v_qty numeric;
  v_filled numeric := 0;
  v_cycle integer;
  v_trade_sum numeric;
  v_asset_balance numeric;
BEGIN
  SELECT amount,remaining_amount INTO v_amount,v_remaining
  FROM ci_limit_orders WHERE id=1;

  FOR v_cycle IN 1..4 LOOP
    v_qty := LEAST(v_remaining,v_amount*0.25);
    INSERT INTO ci_limit_trades(amount) VALUES (v_qty);
    UPDATE ci_limit_asset_balances
    SET balance=balance-v_qty;
    v_filled := v_filled+v_qty;
    v_remaining := GREATEST(v_amount-v_filled,0);
    UPDATE ci_limit_orders
    SET filled_amount=v_filled,remaining_amount=v_remaining
    WHERE id=1;
  END LOOP;

  SELECT sum(amount) INTO v_trade_sum FROM ci_limit_trades;
  SELECT balance INTO v_asset_balance FROM ci_limit_asset_balances;

  IF v_filled <> 0.12345678::numeric THEN
    RAISE EXCEPTION 'Unexpected order fill arithmetic: %',v_filled;
  END IF;
  IF v_trade_sum <> 0.12345680::numeric THEN
    RAISE EXCEPTION 'Expected numeric(24,8) trade rounding to 0.12345680, got %',v_trade_sum;
  END IF;
  IF v_asset_balance <> 0.87654324::numeric THEN
    RAISE EXCEPTION 'Expected repeated numeric(28,8) balance rounding to 0.87654324, got %',v_asset_balance;
  END IF;
  IF v_trade_sum = v_filled OR (1.00000000::numeric-v_asset_balance) = v_filled THEN
    RAISE EXCEPTION 'Expected the current 8-place storage mismatch was not reproduced';
  END IF;

  RAISE NOTICE 'Characterized: order_filled=%, trade_sum=%, sell_balance=%, expected_trade_delta=0.00000002',
    v_filled,v_trade_sum,v_asset_balance;
END
$characterize$;

ROLLBACK;

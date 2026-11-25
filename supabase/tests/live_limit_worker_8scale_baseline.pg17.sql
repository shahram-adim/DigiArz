-- Disposable PostgreSQL 17 baseline: exact read-only Production worker body
-- Fingerprint captured from Production catalog on 2026-11-25.
-- No Production function is invoked. All rows and tables below are synthetic.
-- Expected: reproduce 8-scale storage drift before evaluating widened candidate.
BEGIN;

CREATE TABLE public.profiles (id uuid PRIMARY KEY, is_active boolean NOT NULL);
CREATE TABLE public.demo_trading_pairs (
  pair_symbol text PRIMARY KEY, quote_asset text NOT NULL, is_enabled boolean NOT NULL
);
CREATE TABLE public.market_prices (
  symbol text PRIMARY KEY, price numeric(38,18) NOT NULL, updated_at timestamptz NOT NULL
);
CREATE TABLE public.orders (
  id uuid PRIMARY KEY, user_id uuid NOT NULL, symbol text NOT NULL,
  side text NOT NULL, order_type text NOT NULL, amount numeric(24,8) NOT NULL,
  price numeric(24,8) NOT NULL, filled_amount numeric NOT NULL,
  remaining_amount numeric NOT NULL, status text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.order_reservations (
  id uuid PRIMARY KEY, order_id uuid NOT NULL UNIQUE, user_id uuid NOT NULL,
  asset text NOT NULL, reserved_amount numeric NOT NULL,
  consumed_amount numeric NOT NULL, released_amount numeric NOT NULL,
  status text NOT NULL, updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.wallets (
  user_id uuid PRIMARY KEY, balance_usdt numeric(24,8) NOT NULL
);
CREATE TABLE public.asset_balances (
  user_id uuid NOT NULL, asset text NOT NULL, balance numeric(28,8) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(user_id,asset)
);
CREATE TABLE public.trades (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, order_id uuid NOT NULL,
  user_id uuid NOT NULL, symbol text NOT NULL, side text NOT NULL,
  amount numeric(24,8) NOT NULL, price numeric(24,8) NOT NULL
);
CREATE TABLE public.transactions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, user_id uuid NOT NULL,
  currency text NOT NULL, amount numeric(24,8) NOT NULL,
  transaction_type text NOT NULL, description text NOT NULL
);

CREATE FUNCTION public.get_demo_trading_fee_rate(p_quote text, p_kind text)
RETURNS numeric LANGUAGE sql STABLE SET search_path TO ''
AS $fee$ SELECT 0.001::numeric $fee$;

CREATE OR REPLACE FUNCTION public.process_limit_orders()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_order RECORD;
    v_reservation RECORD;
    v_market_price numeric;
    v_qty numeric;
    v_gross numeric;
    v_fee numeric;
    v_fee_rate numeric;
    v_total numeric;
    v_net numeric;
    v_remaining numeric;
    v_new_filled numeric;
    v_new_remaining numeric;
    v_consumed numeric;
    v_released numeric;
    v_target_remaining_reserve numeric;
    v_base_asset text;
    v_processed integer := 0;
    v_partial integer := 0;
    v_completed integer := 0;
    v_skipped integer := 0;
    v_rows integer;
BEGIN
    IF NOT pg_catalog.pg_try_advisory_xact_lock(739201126) THEN
        RETURN jsonb_build_object(
            'success', true,
            'message', 'Another execution cycle is running',
            'processed', 0
        );
    END IF;

    FOR v_order IN
        SELECT
            o.id,
            o.user_id,
            o.symbol,
            o.side,
            o.amount,
            o.price,
            o.filled_amount,
            o.remaining_amount
        FROM public.orders AS o
        WHERE o.order_type = 'limit'
          AND o.status IN ('pending', 'partially_filled')
          AND o.remaining_amount > 0
          AND EXISTS (SELECT 1 FROM public.profiles AS p WHERE p.id = o.user_id AND p.is_active IS TRUE)
        ORDER BY o.created_at ASC
        FOR UPDATE SKIP LOCKED
    LOOP
        IF v_order.symbol IS NULL
           OR v_order.symbol !~ '^[A-Z0-9]{2,15}USDT$'
           OR v_order.side IS NULL
           OR v_order.side NOT IN ('buy', 'sell')
           OR v_order.amount IS NULL
           OR v_order.amount <= 0
           OR v_order.price IS NULL
           OR v_order.price <= 0
           OR v_order.remaining_amount IS NULL
           OR v_order.remaining_amount <= 0 THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        v_base_asset := left(v_order.symbol, length(v_order.symbol) - 4);

        IF v_base_asset = '' OR v_base_asset = 'USDT' THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        IF NOT EXISTS (
            SELECT 1
            FROM public.demo_trading_pairs AS p
            WHERE p.pair_symbol = v_order.symbol
              AND p.quote_asset = 'USDT'
              AND p.is_enabled IS TRUE
        ) THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        SELECT mp.price
        INTO v_market_price
        FROM public.market_prices AS mp
        WHERE mp.symbol = v_order.symbol
          AND mp.updated_at >= now() - interval '1 minute';

        IF NOT FOUND OR v_market_price IS NULL OR v_market_price <= 0 THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        IF v_order.side = 'buy' AND v_market_price > v_order.price THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        IF v_order.side = 'sell' AND v_market_price < v_order.price THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        SELECT
            r.id,
            r.user_id,
            r.asset,
            r.reserved_amount,
            r.consumed_amount,
            r.released_amount,
            r.status
        INTO v_reservation
        FROM public.order_reservations AS r
        WHERE r.order_id = v_order.id
        FOR UPDATE;

        IF NOT FOUND
           OR v_reservation.user_id <> v_order.user_id
           OR v_reservation.status <> 'reserved'
           OR v_reservation.reserved_amount <= 0
           OR v_reservation.consumed_amount < 0
           OR v_reservation.released_amount < 0
           OR v_reservation.consumed_amount + v_reservation.released_amount
                > v_reservation.reserved_amount THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        -- Keep the same wallet-first lock order as trade placement.
        PERFORM 1
        FROM public.wallets AS w
        WHERE w.user_id = v_order.user_id
        FOR UPDATE;

        IF NOT FOUND THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        v_remaining := v_order.remaining_amount;
        v_qty := LEAST(v_remaining, v_order.amount * 0.25);

        IF v_qty <= 0 THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        v_gross := v_qty * v_market_price;
        v_fee_rate := public.get_demo_trading_fee_rate('USDT', 'maker');
        v_fee := v_gross * v_fee_rate;

        IF v_order.side = 'buy' THEN
            v_total := v_gross + v_fee;
            v_net := 0;

            IF v_reservation.asset <> 'USDT'
               OR v_reservation.consumed_amount
                  + v_reservation.released_amount + v_total
                  > v_reservation.reserved_amount THEN
                v_skipped := v_skipped + 1;
                CONTINUE;
            END IF;

            UPDATE public.wallets
            SET balance_usdt = balance_usdt - v_total
            WHERE user_id = v_order.user_id
              AND balance_usdt >= v_total;

            IF NOT FOUND THEN
                v_skipped := v_skipped + 1;
                CONTINUE;
            END IF;

            INSERT INTO public.asset_balances (
                user_id, asset, balance, updated_at
            )
            VALUES (
                v_order.user_id, v_base_asset, v_qty, now()
            )
            ON CONFLICT (user_id, asset)
            DO UPDATE SET
                balance = public.asset_balances.balance + EXCLUDED.balance,
                updated_at = now();
        ELSE
            v_total := 0;
            v_net := v_gross - v_fee;

            IF v_reservation.asset <> v_base_asset
               OR v_reservation.consumed_amount
                  + v_reservation.released_amount + v_qty
                  > v_reservation.reserved_amount THEN
                v_skipped := v_skipped + 1;
                CONTINUE;
            END IF;

            UPDATE public.asset_balances
            SET balance = balance - v_qty,
                updated_at = now()
            WHERE user_id = v_order.user_id
              AND asset = v_base_asset
              AND balance >= v_qty;

            IF NOT FOUND THEN
                v_skipped := v_skipped + 1;
                CONTINUE;
            END IF;

            UPDATE public.wallets
            SET balance_usdt = balance_usdt + v_net
            WHERE user_id = v_order.user_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Wallet not found for order %', v_order.id;
            END IF;
        END IF;

        v_new_filled := v_order.filled_amount + v_qty;
        v_new_remaining := GREATEST(v_order.amount - v_new_filled, 0);

        UPDATE public.orders
        SET filled_amount = v_new_filled,
            remaining_amount = v_new_remaining,
            status = CASE
                WHEN v_new_remaining <= 0 THEN 'filled'
                ELSE 'partially_filled'
            END
        WHERE id = v_order.id
          AND user_id = v_order.user_id;

        GET DIAGNOSTICS v_rows = ROW_COUNT;

        IF v_rows <> 1 THEN
            RAISE EXCEPTION 'Order update failed for order %', v_order.id;
        END IF;

        IF v_order.side = 'buy' THEN
            v_consumed := v_reservation.consumed_amount + v_total;
            v_target_remaining_reserve :=
                v_new_remaining * v_order.price * (1 + v_fee_rate);
        ELSE
            v_consumed := v_reservation.consumed_amount + v_qty;
            v_target_remaining_reserve := v_new_remaining;
        END IF;

        v_released := GREATEST(
            v_reservation.released_amount,
            v_reservation.reserved_amount
                - v_consumed
                - v_target_remaining_reserve
        );

        v_released := LEAST(
            v_released,
            v_reservation.reserved_amount - v_consumed
        );

        UPDATE public.order_reservations
        SET consumed_amount = v_consumed,
            released_amount = v_released,
            status = CASE
                WHEN v_new_remaining <= 0 THEN
                    CASE WHEN v_released > 0 THEN 'released'
                         ELSE 'consumed' END
                ELSE 'reserved'
            END,
            updated_at = now()
        WHERE id = v_reservation.id
          AND order_id = v_order.id
          AND user_id = v_order.user_id
          AND status = 'reserved';

        GET DIAGNOSTICS v_rows = ROW_COUNT;

        IF v_rows <> 1 THEN
            RAISE EXCEPTION 'Reservation update failed for order %', v_order.id;
        END IF;

        INSERT INTO public.trades (
            order_id, user_id, symbol, side, amount, price
        )
        VALUES (
            v_order.id, v_order.user_id, v_order.symbol,
            v_order.side, v_qty, v_market_price
        );

        IF v_order.side = 'buy' THEN
            INSERT INTO public.transactions (
                user_id, currency, amount, transaction_type, description
            )
            VALUES (
                v_order.user_id, 'USDT', v_total,
                'limit_buy', 'Limit buy execution: ' || v_order.symbol
            );
        ELSE
            INSERT INTO public.transactions (
                user_id, currency, amount, transaction_type, description
            )
            VALUES (
                v_order.user_id, 'USDT', v_net,
                'limit_sell', 'Limit sell execution: ' || v_order.symbol
            );
        END IF;

        v_processed := v_processed + 1;

        IF v_new_remaining <= 0 THEN
            v_completed := v_completed + 1;
        ELSE
            v_partial := v_partial + 1;
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'processed', v_processed,
        'partially_filled', v_partial,
        'completed', v_completed,
        'skipped', v_skipped,
        'fee_rate', v_fee_rate
    );
END;
$function$


INSERT INTO public.profiles VALUES
 ('10000000-0000-0000-0000-000000000001', true),
 ('20000000-0000-0000-0000-000000000002', true);
INSERT INTO public.demo_trading_pairs VALUES ('BTCUSDT','USDT',true);
INSERT INTO public.market_prices VALUES ('BTCUSDT',1.000000000000000000,now());
INSERT INTO public.wallets VALUES
 ('10000000-0000-0000-0000-000000000001',1.00000000),
 ('20000000-0000-0000-0000-000000000002',0);
INSERT INTO public.asset_balances VALUES
 ('10000000-0000-0000-0000-000000000001','BTC',0),
 ('20000000-0000-0000-0000-000000000002','BTC',1.00000000);

INSERT INTO public.orders (
 id,user_id,symbol,side,order_type,amount,price,filled_amount,remaining_amount,status
) VALUES
 ('a1000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  'BTCUSDT','buy','limit',0.12345678,1,0,0.12345678,'pending'),
 ('b2000000-0000-0000-0000-000000000002',
  '20000000-0000-0000-0000-000000000002',
  'BTCUSDT','sell','limit',0.12345678,1,0,0.12345678,'pending');

INSERT INTO public.order_reservations (
 id,order_id,user_id,asset,reserved_amount,consumed_amount,released_amount,status
) VALUES
 ('a1000000-0000-0000-0000-000000000011',
  'a1000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001','USDT',0.2,0,0,'reserved'),
 ('b2000000-0000-0000-0000-000000000022',
  'b2000000-0000-0000-0000-000000000002',
  '20000000-0000-0000-0000-000000000002','BTC',0.12345678,0,0,'reserved');

DO $baseline$
DECLARE
  i integer;
  v_filled numeric;
  v_trade_sum numeric;
  v_balance numeric;
  v_reserve_consumed numeric;
  v_wallet_delta numeric;
BEGIN
  FOR i IN 1..4 LOOP
    PERFORM public.process_limit_orders();
  END LOOP;

  SELECT filled_amount INTO v_filled FROM public.orders
  WHERE id='a1000000-0000-0000-0000-000000000001';
  SELECT sum(amount) INTO v_trade_sum FROM public.trades
  WHERE order_id='a1000000-0000-0000-0000-000000000001';
  SELECT balance INTO v_balance FROM public.asset_balances
  WHERE user_id='10000000-0000-0000-0000-000000000001' AND asset='BTC';
  IF v_filled <> 0.12345678 OR v_trade_sum <> 0.12345680 OR v_balance <> 0.12345680 THEN
    RAISE EXCEPTION 'Unexpected buy baseline: filled %, trade sum %, balance %',v_filled,v_trade_sum,v_balance;
  END IF;

  SELECT filled_amount INTO v_filled FROM public.orders
  WHERE id='b2000000-0000-0000-0000-000000000002';
  SELECT sum(amount) INTO v_trade_sum FROM public.trades
  WHERE order_id='b2000000-0000-0000-0000-000000000002';
  SELECT balance INTO v_balance FROM public.asset_balances
  WHERE user_id='20000000-0000-0000-0000-000000000002' AND asset='BTC';
  IF v_filled <> 0.12345678 OR v_trade_sum <> 0.12345680 OR v_balance <> 0.87654324 THEN
    RAISE EXCEPTION 'Unexpected sell baseline: filled %, trade sum %, balance %',v_filled,v_trade_sum,v_balance;
  END IF;

  SELECT consumed_amount INTO v_reserve_consumed FROM public.order_reservations
  WHERE order_id='a1000000-0000-0000-0000-000000000001';
  SELECT 1.00000000 - balance_usdt INTO v_wallet_delta FROM public.wallets
  WHERE user_id='10000000-0000-0000-0000-000000000001';
  IF v_reserve_consumed = v_wallet_delta THEN
    RAISE EXCEPTION 'Expected buy reservation-vs-wallet rounding mismatch was not reproduced';
  END IF;
END
$baseline$;

SELECT 'live Production Limit worker 8-scale baseline reproduced' AS result,
       (SELECT filled_amount FROM public.orders WHERE id='a1000000-0000-0000-0000-000000000001') AS order_filled,
       (SELECT sum(amount) FROM public.trades WHERE order_id='a1000000-0000-0000-0000-000000000001') AS buy_trade_sum,
       (SELECT balance FROM public.asset_balances WHERE user_id='10000000-0000-0000-0000-000000000001' AND asset='BTC') AS buy_base_balance,
       (SELECT balance FROM public.asset_balances WHERE user_id='20000000-0000-0000-0000-000000000002' AND asset='BTC') AS sell_base_balance,
       (SELECT consumed_amount FROM public.order_reservations WHERE order_id='a1000000-0000-0000-0000-000000000001') AS buy_reservation_consumed,
       (SELECT 1.00000000-balance_usdt FROM public.wallets WHERE user_id='10000000-0000-0000-0000-000000000001') AS buy_wallet_debit;

ROLLBACK;

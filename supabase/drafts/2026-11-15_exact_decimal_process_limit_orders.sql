-- DRAFT ONLY — DO NOT APPLY TO PRODUCTION.
-- Requires coordinated 18-place typmod migration for orders/trades/asset_balances
-- and isolated end-to-end tests of placement, reservations, cancellation,
-- Stop-Limit child synchronization, and conditional exits before approval.
-- Preserves the live worker's advisory lock, SKIP LOCKED, account/pair/price
-- checks, wallet-first lock order, reservation lifecycle, and transaction model.
-- Adds 18-place base fills, 8-place USDT settlement, and blocks zero-gross fills.
-- CREATE OR REPLACE preserves existing function grants; still verify grants
-- and worker callers during release rehearsal.

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
           OR v_order.amount > 1000000
           OR pg_catalog.scale(v_order.amount) > 18
           OR v_order.filled_amount IS NULL
           OR v_order.filled_amount < 0
           OR v_order.filled_amount > v_order.amount
           OR pg_catalog.scale(v_order.filled_amount) > 18
           OR v_order.price IS NULL
           OR v_order.price <= 0
           OR v_order.price >= 10000000000000000::numeric
           OR pg_catalog.scale(v_order.price) > 18
           OR v_order.remaining_amount IS NULL
           OR v_order.remaining_amount <= 0
           OR pg_catalog.scale(v_order.remaining_amount) > 18 THEN
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

        IF NOT FOUND OR v_market_price IS NULL OR v_market_price <= 0
           OR v_market_price >= 10000000000000000::numeric
           OR pg_catalog.scale(v_market_price) > 18 THEN
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
        v_qty := LEAST(v_remaining, round(v_order.amount * 0.25, 18));
        IF v_qty = 0 THEN
            v_qty := LEAST(v_remaining, 0.000000000000000001::numeric);
        END IF;

        IF v_qty <= 0 OR v_qty > v_remaining THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        -- Avoid leaving a dust remainder whose quote value rounds to zero.
        -- If the remainder cannot settle independently, include it in this fill.
        IF v_remaining > v_qty
           AND round((v_remaining - v_qty) * v_market_price, 8) <= 0 THEN
            v_qty := v_remaining;
        END IF;

        v_gross := round(v_qty * v_market_price, 8);
        -- Do not create or destroy base units when the 8-place USDT ledger
        -- cannot represent a positive quote amount.
        IF v_gross <= 0 THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;
        v_fee_rate := public.get_demo_trading_fee_rate('USDT', 'maker');
        v_fee := round(v_gross * v_fee_rate, 8);

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
        IF v_new_filled > v_order.amount THEN
            RAISE EXCEPTION 'Fill quantity exceeds order amount for order %', v_order.id;
        END IF;
        v_new_remaining := v_order.amount - v_new_filled;

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
                round(v_new_remaining * v_order.price * (1 + v_fee_rate), 8);
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
$function$;
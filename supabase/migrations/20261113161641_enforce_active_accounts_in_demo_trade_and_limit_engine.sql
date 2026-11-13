CREATE OR REPLACE FUNCTION public.execute_demo_trade(p_symbol text, p_side text, p_amount numeric, p_price numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_uid uuid;
    v_symbol text;
    v_base text;
    v_side text;
    v_price numeric;
    v_balance numeric;
    v_asset_balance numeric;
    v_reserved numeric := 0;
    v_available numeric := 0;
    v_gross numeric;
    v_total numeric;
    v_fee numeric;
    v_fee_rate numeric;
    v_order_id uuid;
BEGIN
    v_uid := auth.uid();

    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF NOT public.current_account_is_active() THEN
        RAISE EXCEPTION 'Account is inactive';
    END IF;

    v_symbol := upper(trim(p_symbol));
    v_side := lower(trim(p_side));

    IF v_symbol IS NULL
       OR v_symbol !~ '^[A-Z0-9]{2,15}USDT$' THEN
        RAISE EXCEPTION 'Unsupported trading pair';
    END IF;

    v_base := left(v_symbol, length(v_symbol) - 4);

    IF v_side IS NULL OR v_side NOT IN ('buy', 'sell')
       OR v_base = 'USDT' THEN
        RAISE EXCEPTION 'Invalid trade parameters';
    END IF;

    IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 1000000 THEN
        RAISE EXCEPTION 'Invalid amount';
    END IF;

    PERFORM 1
    FROM public.demo_trading_pairs AS dp
    WHERE dp.pair_symbol = v_symbol
      AND dp.quote_asset = 'USDT'
      AND dp.is_enabled IS TRUE
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Trading pair is not enabled';
    END IF;

    SELECT mp.price
    INTO v_price
    FROM public.market_prices AS mp
    WHERE mp.symbol = v_symbol
      AND mp.updated_at >= now() - interval '1 minute'
    FOR SHARE;

    IF NOT FOUND OR v_price IS NULL OR v_price <= 0 THEN
        RAISE EXCEPTION 'Market price unavailable or outdated';
    END IF;

    v_fee_rate := public.get_demo_trading_fee_rate('USDT', 'taker');
    v_gross := round(p_amount * v_price, 8);
    v_fee := round(v_gross * v_fee_rate, 8);

    INSERT INTO public.wallets (user_id)
    VALUES (v_uid)
    ON CONFLICT (user_id) DO NOTHING;

    SELECT balance_usdt
    INTO v_balance
    FROM public.wallets
    WHERE user_id = v_uid
    FOR UPDATE;

    IF v_balance IS NULL THEN
        v_balance := 0;
    END IF;

    IF v_side = 'buy' THEN
        SELECT COALESCE(
            SUM(r.reserved_amount - r.released_amount - r.consumed_amount),
            0
        )
        INTO v_reserved
        FROM public.order_reservations AS r
        WHERE r.user_id = v_uid
          AND r.asset = 'USDT'
          AND r.status = 'reserved';

        v_available := v_balance - v_reserved;
        v_total := v_gross + v_fee;

        IF v_available < v_total THEN
            RAISE EXCEPTION 'Insufficient available USDT balance';
        END IF;

        UPDATE public.wallets
        SET balance_usdt = balance_usdt - v_total
        WHERE user_id = v_uid;

        INSERT INTO public.asset_balances (
            user_id, asset, balance, updated_at
        )
        VALUES (v_uid, v_base, p_amount, now())
        ON CONFLICT (user_id, asset)
        DO UPDATE SET
            balance = public.asset_balances.balance + EXCLUDED.balance,
            updated_at = now();
    ELSE
        INSERT INTO public.asset_balances (user_id, asset, balance)
        VALUES (v_uid, v_base, 0)
        ON CONFLICT (user_id, asset) DO NOTHING;

        SELECT balance
        INTO v_asset_balance
        FROM public.asset_balances
        WHERE user_id = v_uid
          AND asset = v_base
        FOR UPDATE;

        SELECT COALESCE(
            SUM(r.reserved_amount - r.released_amount - r.consumed_amount),
            0
        )
        INTO v_reserved
        FROM public.order_reservations AS r
        WHERE r.user_id = v_uid
          AND r.asset = v_base
          AND r.status = 'reserved';

        v_available := COALESCE(v_asset_balance, 0) - v_reserved;

        IF v_available < p_amount THEN
            RAISE EXCEPTION 'Insufficient available asset balance';
        END IF;

        v_total := v_gross - v_fee;

        UPDATE public.asset_balances
        SET balance = balance - p_amount,
            updated_at = now()
        WHERE user_id = v_uid
          AND asset = v_base;

        UPDATE public.wallets
        SET balance_usdt = balance_usdt + v_total
        WHERE user_id = v_uid;
    END IF;

    INSERT INTO public.orders (
        user_id, symbol, side, order_type, amount, price, status,
        filled_amount, remaining_amount
    )
    VALUES (
        v_uid, v_symbol, v_side, 'market', p_amount, v_price, 'filled',
        p_amount, 0
    )
    RETURNING id INTO v_order_id;

    INSERT INTO public.trades (
        order_id, user_id, symbol, side, amount, price
    )
    VALUES (
        v_order_id, v_uid, v_symbol, v_side, p_amount, v_price
    );

    INSERT INTO public.transactions (
        user_id, currency, amount, transaction_type, description
    )
    VALUES (
        v_uid, 'USDT', v_total, v_side,
        'DigiArz demo trade: ' || v_symbol
    );

    RETURN jsonb_build_object(
        'success', true,
        'order_id', v_order_id,
        'symbol', v_symbol,
        'side', v_side,
        'amount', p_amount,
        'price', v_price,
        'fee', v_fee,
        'total', v_total,
        'currency', 'USDT'
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.place_limit_order(p_symbol text, p_side text, p_amount numeric, p_limit_price numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_uid uuid;
    v_symbol text;
    v_side text;
    v_base_asset text;
    v_asset text;
    v_wallet_balance numeric := 0;
    v_asset_balance numeric := 0;
    v_reserved_balance numeric := 0;
    v_required_amount numeric := 0;
    v_order_id uuid;
    v_fee_rate numeric;
BEGIN
    v_uid := auth.uid();

    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF NOT public.current_account_is_active() THEN
        RAISE EXCEPTION 'Account is inactive';
    END IF;

    v_symbol := upper(btrim(p_symbol));
    v_side := lower(btrim(p_side));

    IF v_symbol IS NULL
       OR v_symbol !~ '^[A-Z0-9]{2,15}USDT$' THEN
        RAISE EXCEPTION 'Invalid trading symbol';
    END IF;

    IF v_side IS NULL OR v_side NOT IN ('buy', 'sell') THEN
        RAISE EXCEPTION 'Order side must be buy or sell';
    END IF;

    IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 1000000 THEN
        RAISE EXCEPTION 'Invalid order amount';
    END IF;

    IF p_limit_price IS NULL OR p_limit_price <= 0 THEN
        RAISE EXCEPTION 'Invalid limit price';
    END IF;

    v_base_asset := left(v_symbol, length(v_symbol) - 4);

    IF v_base_asset = '' OR v_base_asset = 'USDT' THEN
        RAISE EXCEPTION 'Invalid base asset';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.demo_trading_pairs AS p
        WHERE p.pair_symbol = v_symbol
          AND p.quote_asset = 'USDT'
          AND p.is_enabled IS TRUE
    ) THEN
        RAISE EXCEPTION 'Trading pair is not enabled';
    END IF;

    SELECT w.balance_usdt
    INTO v_wallet_balance
    FROM public.wallets AS w
    WHERE w.user_id = v_uid
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User wallet not found';
    END IF;

    v_fee_rate := public.get_demo_trading_fee_rate('USDT', 'maker');
    IF v_side = 'buy' THEN
        v_asset := 'USDT';
        v_required_amount := p_amount * p_limit_price * (1 + v_fee_rate);

        SELECT COALESCE(
            SUM(GREATEST(
                r.reserved_amount - r.consumed_amount - r.released_amount,
                0
            )),
            0
        )
        INTO v_reserved_balance
        FROM public.order_reservations AS r
        WHERE r.user_id = v_uid
          AND r.asset = v_asset
          AND r.status = 'reserved';

        IF v_wallet_balance - v_reserved_balance < v_required_amount THEN
            RAISE EXCEPTION 'Insufficient available USDT balance';
        END IF;
    ELSE
        v_asset := v_base_asset;

        SELECT COALESCE(ab.balance, 0)
        INTO v_asset_balance
        FROM public.asset_balances AS ab
        WHERE ab.user_id = v_uid
          AND ab.asset = v_asset
        FOR UPDATE;

        IF NOT FOUND THEN
            v_asset_balance := 0;
        END IF;

        SELECT COALESCE(
            SUM(GREATEST(
                r.reserved_amount - r.consumed_amount - r.released_amount,
                0
            )),
            0
        )
        INTO v_reserved_balance
        FROM public.order_reservations AS r
        WHERE r.user_id = v_uid
          AND r.asset = v_asset
          AND r.status = 'reserved';

        IF v_asset_balance - v_reserved_balance < p_amount THEN
            RAISE EXCEPTION 'Insufficient available asset balance';
        END IF;

        v_required_amount := p_amount;
    END IF;

    INSERT INTO public.orders (
        user_id, symbol, side, order_type, amount, price, status,
        filled_amount, remaining_amount
    )
    VALUES (
        v_uid, v_symbol, v_side, 'limit', p_amount, p_limit_price,
        'pending', 0, p_amount
    )
    RETURNING id INTO v_order_id;

    INSERT INTO public.order_reservations (
        order_id, user_id, asset, reserved_amount,
        released_amount, consumed_amount, status
    )
    VALUES (
        v_order_id, v_uid, v_asset, v_required_amount,
        0, 0, 'reserved'
    );

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Limit order placed successfully',
        'order_id', v_order_id,
        'symbol', v_symbol,
        'side', v_side,
        'order_type', 'limit',
        'amount', p_amount,
        'limit_price', p_limit_price,
        'reserved_asset', v_asset,
        'reserved_amount', v_required_amount,
        'fee_rate', v_fee_rate,
        'status', 'pending'
    );
END;
$function$;

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
$function$;
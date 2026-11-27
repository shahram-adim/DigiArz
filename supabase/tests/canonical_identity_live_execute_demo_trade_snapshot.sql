-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: execute_demo_trade(text,text,numeric,numeric)
-- PostgreSQL md5(pg_get_functiondef(...)): 4289e358b0c7293fc33f86c2511486d7
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
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
$function$
;

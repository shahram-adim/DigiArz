-- Read-only Production source snapshot for Stop-Limit QA, captured 2026-11-26.
-- Source: pg_get_functiondef('public.place_limit_order(text,text,numeric,numeric)'::regprocedure).
-- PostgreSQL md5(pg_get_functiondef(...)): 3eab167c47bf8ff2e1705b9f243380ec
-- Verified metadata: owner=postgres; SECURITY DEFINER; search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
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

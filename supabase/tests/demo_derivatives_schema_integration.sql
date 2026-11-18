\set ON_ERROR_STOP on

INSERT INTO auth.users(id) VALUES
  ('10000000-0000-0000-0000-000000000001'),
  ('10000000-0000-0000-0000-000000000002');

INSERT INTO public.demo_derivative_accounts(id,user_id) VALUES
  ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002');

INSERT INTO public.demo_derivative_orders(
  id,user_id,account_id,product_type,symbol,position_side,side,order_type,
  quantity,leverage,margin_mode,filled_quantity,remaining_quantity,status,client_request_id
) VALUES (
  '30000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  'futures','BTCUSDT','long','buy','market',1,5,'isolated',1,0,'filled',
  '31000000-0000-0000-0000-000000000001'
);

INSERT INTO public.demo_derivative_positions(
  id,user_id,account_id,product_type,symbol,position_side,margin_mode,
  leverage,quantity,entry_price,isolated_margin_usdt
) VALUES (
  '40000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  'futures','BTCUSDT','long','isolated',5,1,100,20
), (
  '40000000-0000-0000-0000-000000000002',
  '10000000-0000-0000-0000-000000000002',
  '20000000-0000-0000-0000-000000000002',
  'futures','BTCUSDT','long','isolated',5,1,100,20
);

INSERT INTO public.demo_derivative_fills(
  id,user_id,account_id,order_id,position_id,fill_sequence,
  symbol,position_side,side,quantity,price,fee_usdt
) VALUES (
  '50000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  '30000000-0000-0000-0000-000000000001',
  '40000000-0000-0000-0000-000000000001',
  1,'BTCUSDT','long','buy',1,100,0.04
);

INSERT INTO public.demo_margin_loans(
  id,user_id,account_id,position_id,loan_asset,principal,
  interest_rate_per_hour,collateral_mode
) VALUES (
  '60000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  '40000000-0000-0000-0000-000000000001',
  'USDT',10,0.0001,'isolated'
);

INSERT INTO public.demo_derivative_funding_events(
  id,user_id,account_id,position_id,interval_start,interval_end,
  funding_rate,mark_price,position_notional_usdt,amount_usdt
) VALUES (
  '70000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  '40000000-0000-0000-0000-000000000001',
  '2026-11-18 00:00:00+00','2026-11-18 08:00:00+00',
  0.001,100,100,0.1
);

INSERT INTO public.demo_derivative_risk_events(
  id,user_id,account_id,position_id,event_type,snapshot
) VALUES (
  '80000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  '40000000-0000-0000-0000-000000000001',
  'margin_warning','{"margin_ratio":"1.2"}'::jsonb
);

BEGIN;

INSERT INTO public.demo_derivative_ledger_transactions(
  id,user_id,idempotency_key,event_type
) VALUES (
  '90000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '91000000-0000-0000-0000-000000000001',
  'futures_transfer'
);

INSERT INTO public.demo_derivative_ledger_entries(
  id,transaction_id,user_id,asset,account_bucket,debit_amount,credit_amount
) VALUES
  ('92000000-0000-0000-0000-000000000001','90000000-0000-0000-0000-000000000001',
   '10000000-0000-0000-0000-000000000001','USDT','futures_cash',10,0),
  ('92000000-0000-0000-0000-000000000002','90000000-0000-0000-0000-000000000001',
   '10000000-0000-0000-0000-000000000001','USDT','system_clearing',0,10);

COMMIT;

DO $open_position_uniqueness$
BEGIN
  BEGIN
    INSERT INTO public.demo_derivative_positions(
      id,user_id,account_id,product_type,symbol,position_side,margin_mode,
      leverage,quantity,entry_price,isolated_margin_usdt
    ) VALUES (
      '40000000-0000-0000-0000-000000000099',
      '10000000-0000-0000-0000-000000000001',
      '20000000-0000-0000-0000-000000000001',
      'futures','BTCUSDT','long','isolated',5,0.25,101,5
    );
    RAISE EXCEPTION 'duplicate open position for same account/product/symbol/side unexpectedly accepted';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;
END;
$open_position_uniqueness$;

DO $order_direction_checks$
BEGIN
  BEGIN
    INSERT INTO public.demo_derivative_orders(
      id,user_id,account_id,product_type,symbol,position_side,side,order_type,
      quantity,leverage,margin_mode,reduce_only,remaining_quantity,client_request_id
    ) VALUES (
      '30000000-0000-0000-0000-000000000099',
      '10000000-0000-0000-0000-000000000001',
      '20000000-0000-0000-0000-000000000001',
      'futures','BTCUSDT','long','sell','limit',
      0.1,5,'cross',false,0.1,
      '31000000-0000-0000-0000-000000000099'
    );
    RAISE EXCEPTION 'sell-long opening order unexpectedly accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO public.demo_derivative_orders(
      id,user_id,account_id,product_type,symbol,position_side,side,order_type,
      quantity,leverage,margin_mode,reduce_only,remaining_quantity,client_request_id
    ) VALUES (
      '30000000-0000-0000-0000-000000000098',
      '10000000-0000-0000-0000-000000000001',
      '20000000-0000-0000-0000-000000000001',
      'futures','BTCUSDT','short','buy','limit',
      0.1,5,'cross',false,0.1,
      '31000000-0000-0000-0000-000000000098'
    );
    RAISE EXCEPTION 'buy-short opening order unexpectedly accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END;
$order_direction_checks$;

DO $market_atomicity_checks$
BEGIN
  BEGIN
    INSERT INTO public.demo_derivative_orders(
      id,user_id,account_id,product_type,symbol,position_side,side,order_type,
      quantity,leverage,margin_mode,filled_quantity,remaining_quantity,status,client_request_id
    ) VALUES (
      '30000000-0000-0000-0000-000000000097',
      '10000000-0000-0000-0000-000000000001',
      '20000000-0000-0000-0000-000000000001',
      'futures','ETHUSDT','long','buy','market',1,5,'cross',0,1,'pending',
      '31000000-0000-0000-0000-000000000097'
    );
    RAISE EXCEPTION 'resting market order unexpectedly accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END;
$market_atomicity_checks$;

DO $relationship_checks$
BEGIN
  BEGIN
    INSERT INTO public.demo_derivative_fills(
      id,user_id,account_id,order_id,position_id,fill_sequence,
      symbol,position_side,side,quantity,price,fee_usdt
    ) VALUES (
      '51000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001',
      '20000000-0000-0000-0000-000000000001',
      '30000000-0000-0000-0000-000000000001',
      '40000000-0000-0000-0000-000000000002',
      2,'BTCUSDT','long','buy',0.1,100,0.01
    );
    RAISE EXCEPTION 'cross-account fill unexpectedly accepted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO public.demo_margin_loans(
      id,user_id,account_id,position_id,loan_asset,principal,collateral_mode
    ) VALUES (
      '61000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001',
      '20000000-0000-0000-0000-000000000001',
      '40000000-0000-0000-0000-000000000002',
      'USDT',1,'isolated'
    );
    RAISE EXCEPTION 'cross-account margin loan unexpectedly accepted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO public.demo_derivative_funding_events(
      id,user_id,account_id,position_id,interval_start,interval_end,
      funding_rate,mark_price,position_notional_usdt,amount_usdt
    ) VALUES (
      '71000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001',
      '20000000-0000-0000-0000-000000000001',
      '40000000-0000-0000-0000-000000000002',
      '2026-11-18 08:00:00+00','2026-11-18 16:00:00+00',
      0.001,100,100,0.1
    );
    RAISE EXCEPTION 'cross-account funding event unexpectedly accepted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO public.demo_derivative_risk_events(
      id,user_id,account_id,position_id,event_type
    ) VALUES (
      '81000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001',
      '20000000-0000-0000-0000-000000000001',
      '40000000-0000-0000-0000-000000000002',
      'margin_warning'
    );
    RAISE EXCEPTION 'cross-account risk event unexpectedly accepted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;
END;
$relationship_checks$;

DO $checks$
BEGIN
  IF (SELECT count(*) FROM public.demo_derivative_accounts) <> 2 THEN
    RAISE EXCEPTION 'account fixture count mismatch';
  END IF;
  IF (SELECT outstanding_amount FROM public.demo_margin_loans
      WHERE id='60000000-0000-0000-0000-000000000001') <> 10 THEN
    RAISE EXCEPTION 'generated loan outstanding amount mismatch';
  END IF;
  IF (SELECT count(*) FROM public.demo_derivative_ledger_entries
      WHERE transaction_id='90000000-0000-0000-0000-000000000001') <> 2 THEN
    RAISE EXCEPTION 'ledger entry fixture count mismatch';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='demo_derivative_accounts'
      AND column_name IN ('futures_cash_usdt','margin_cash_usdt')
  ) THEN
    RAISE EXCEPTION 'mutable account cash columns must not exist';
  END IF;
  IF (SELECT futures_cash_usdt FROM public.demo_derivative_futures_cash_balances
      WHERE user_id='10000000-0000-0000-0000-000000000001') <> 10 THEN
    RAISE EXCEPTION 'ledger-derived Futures cash projection mismatch';
  END IF;
  IF (SELECT futures_cash_usdt FROM public.demo_derivative_futures_cash_balances
      WHERE user_id='10000000-0000-0000-0000-000000000002') <> 0 THEN
    RAISE EXCEPTION 'empty Futures cash projection must be zero';
  END IF;

END;
$checks$;

SET ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',false);

DO $rls_checks$
BEGIN
  IF (SELECT count(*) FROM public.demo_derivative_accounts) <> 1 THEN
    RAISE EXCEPTION 'RLS did not restrict accounts to the current user';
  END IF;
  IF (SELECT count(*) FROM public.demo_derivative_orders) <> 1 THEN
    RAISE EXCEPTION 'RLS did not restrict orders to the current user';
  END IF;
  IF (SELECT count(*) FROM public.demo_derivative_futures_cash_balances) <> 1
     OR (SELECT futures_cash_usdt FROM public.demo_derivative_futures_cash_balances) <> 10 THEN
    RAISE EXCEPTION 'RLS did not restrict ledger cash projection to the current user';
  END IF;
  BEGIN
    INSERT INTO public.demo_derivative_accounts(user_id)
    VALUES ('10000000-0000-0000-0000-000000000001');
    RAISE EXCEPTION 'authenticated unexpectedly inserted an account directly';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END;
$rls_checks$;
RESET ROLE;

DO $ledger_append_checks$
BEGIN
  BEGIN
    INSERT INTO public.demo_derivative_ledger_entries(
      id,transaction_id,user_id,asset,account_bucket,debit_amount,credit_amount
    ) VALUES (
      '93000000-0000-0000-0000-000000000001',
      '90000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001',
      'USDT','futures_cash',1,0
    );
    RAISE EXCEPTION 'late ledger append unexpectedly accepted';
  EXCEPTION WHEN SQLSTATE '55000' THEN
    NULL;
  END;
END;
$ledger_append_checks$;

DO $immutable_checks$
BEGIN
  BEGIN
    UPDATE public.demo_derivative_ledger_entries
    SET debit_amount=11
    WHERE id='92000000-0000-0000-0000-000000000001';
    RAISE EXCEPTION 'ledger entry unexpectedly allowed mutation';
  EXCEPTION WHEN SQLSTATE '55000' THEN
    NULL;
  END;

  BEGIN
    DELETE FROM public.demo_derivative_ledger_transactions
    WHERE id='90000000-0000-0000-0000-000000000001';
    RAISE EXCEPTION 'ledger header unexpectedly allowed deletion';
  EXCEPTION WHEN SQLSTATE '55000' THEN
    NULL;
  END;
END;
$immutable_checks$;

SELECT 'demo derivatives schema integration passed' AS result;

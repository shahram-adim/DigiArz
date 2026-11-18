\set ON_ERROR_STOP on

INSERT INTO auth.users(id) VALUES
  ('10000000-0000-0000-0000-000000000001'),
  ('10000000-0000-0000-0000-000000000002');

INSERT INTO public.demo_derivative_accounts(id,user_id,futures_cash_usdt,margin_cash_usdt) VALUES
  ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',1000,500),
  ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002',250,125);

INSERT INTO public.demo_derivative_orders(
  id,user_id,account_id,product_type,symbol,position_side,order_type,
  quantity,leverage,margin_mode,remaining_quantity,client_request_id
) VALUES (
  '30000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  'futures','BTCUSDT','long','market',1,5,'isolated',1,
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
);

INSERT INTO public.demo_derivative_fills(
  id,user_id,account_id,order_id,position_id,fill_sequence,
  symbol,position_side,quantity,price,fee_usdt
) VALUES (
  '50000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  '30000000-0000-0000-0000-000000000001',
  '40000000-0000-0000-0000-000000000001',
  1,'BTCUSDT','long',1,100,0.04
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

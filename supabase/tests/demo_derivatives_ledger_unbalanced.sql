\set ON_ERROR_STOP on
BEGIN;

INSERT INTO public.demo_derivative_ledger_transactions(
  id,user_id,idempotency_key,event_type
) VALUES (
  'a0000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  'a1000000-0000-0000-0000-000000000001',
  'futures_transfer'
);

INSERT INTO public.demo_derivative_ledger_entries(
  id,transaction_id,user_id,asset,account_bucket,debit_amount,credit_amount
) VALUES
  ('a2000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001',
   '10000000-0000-0000-0000-000000000001','USDT','futures_cash',10,0),
  ('a2000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000001',
   '10000000-0000-0000-0000-000000000001','USDT','system_clearing',5,0);

SET CONSTRAINTS ALL IMMEDIATE;
ROLLBACK;

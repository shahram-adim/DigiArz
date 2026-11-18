\set ON_ERROR_STOP on

-- This integration test runs only in a disposable PostgreSQL database as its
-- owner. Production/client roles have no access to these private objects.

DO $catalog$
BEGIN
  IF (SELECT count(*) FROM private.demo_platform_ledger_accounts) <> 4 THEN
    RAISE EXCEPTION 'platform chart of accounts is incomplete';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='private.demo_derivative_deficit_events'::regclass
      AND contype='f'
      AND pg_get_constraintdef(oid) ILIKE '%auth.users%'
  ) THEN
    RAISE EXCEPTION 'platform deficit journal must not depend on a fabricated auth user';
  END IF;
  IF has_schema_privilege('anon','private','USAGE')
     OR has_schema_privilege('authenticated','private','USAGE')
     OR has_schema_privilege('service_role','private','USAGE') THEN
    RAISE EXCEPTION 'private platform ledger schema is unexpectedly exposed';
  END IF;
  IF has_table_privilege('authenticated','private.demo_platform_ledger_entries','SELECT')
     OR has_table_privilege('service_role','private.demo_platform_ledger_entries','INSERT') THEN
    RAISE EXCEPTION 'platform ledger table grants are unexpectedly exposed';
  END IF;
END;
$catalog$;

-- Seed 100 USDT: Dr cash / Cr fund equity.
BEGIN;
INSERT INTO private.demo_platform_ledger_transactions(
 id,idempotency_key,payload_hash,event_type,event_reference,policy_version
) VALUES (
 'a1000000-0000-0000-0000-000000000001','seed-1',repeat('a',64),
 'insurance_seed','a2000000-0000-0000-0000-000000000001','seed-policy-v1'
);
INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,debit_amount)
VALUES ('a1000000-0000-0000-0000-000000000001','insurance_cash_usdt',100);
INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,credit_amount)
VALUES ('a1000000-0000-0000-0000-000000000001','insurance_fund_equity_usdt',100);
COMMIT;

DO $seed_balance$
BEGIN
 IF (SELECT insurance_cash_usdt FROM private.demo_platform_insurance_balance)<>100 THEN
  RAISE EXCEPTION 'seed balance must be derived from immutable entries';
 END IF;
END;
$seed_balance$;

-- Full coverage: open deficit 30, apply insurance 30. Insurance draw is not
-- separately counted as a recovery.
BEGIN;
INSERT INTO private.demo_platform_ledger_transactions(
 id,idempotency_key,payload_hash,event_type,event_reference,policy_version
) VALUES (
 'a1000000-0000-0000-0000-000000000002','payout-full-1',repeat('b',64),
 'insurance_payout','a2000000-0000-0000-0000-000000000002','liquidation-policy-draft'
);
INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,debit_amount)
VALUES ('a1000000-0000-0000-0000-000000000002','liquidation_loss_expense_usdt',30);
INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,credit_amount)
VALUES ('a1000000-0000-0000-0000-000000000002','insurance_cash_usdt',30);
INSERT INTO private.demo_derivative_deficit_events(
 id,idempotency_key,payload_hash,source_liquidation_event_id,account_id,event_type,amount_usdt
) VALUES (
 'a3000000-0000-0000-0000-000000000001','deficit-open-1',repeat('c',64),
 'a2000000-0000-0000-0000-000000000002','a4000000-0000-0000-0000-000000000001',
 'deficit_opened',30
);
INSERT INTO private.demo_derivative_deficit_events(
 id,idempotency_key,payload_hash,source_liquidation_event_id,account_id,event_type,amount_usdt,platform_ledger_transaction_id
) VALUES (
 'a3000000-0000-0000-0000-000000000002','deficit-insurance-1',repeat('d',64),
 'a2000000-0000-0000-0000-000000000002','a4000000-0000-0000-0000-000000000001',
 'insurance_applied',30,'a1000000-0000-0000-0000-000000000002'
);
COMMIT;

DO $full_coverage$
BEGIN
 IF (SELECT insurance_cash_usdt FROM private.demo_platform_insurance_balance)<>70 THEN
  RAISE EXCEPTION 'full payout must reduce platform cash exactly';
 END IF;
 IF (SELECT remaining_deficit_usdt FROM private.demo_derivative_deficit_exposure
     WHERE source_liquidation_event_id='a2000000-0000-0000-0000-000000000002')<>0 THEN
  RAISE EXCEPTION 'fully insured deficit must be zero';
 END IF;
 IF (SELECT recovered_usdt FROM private.demo_derivative_deficit_exposure
     WHERE source_liquidation_event_id='a2000000-0000-0000-0000-000000000002')<>0 THEN
  RAISE EXCEPTION 'insurance application must not be double-counted as recovery';
 END IF;
END;
$full_coverage$;

-- Partial insurance plus later genuine recovery.
BEGIN;
INSERT INTO private.demo_platform_ledger_transactions(
 id,idempotency_key,payload_hash,event_type,event_reference,policy_version
) VALUES (
 'a1000000-0000-0000-0000-000000000003','payout-partial-1',repeat('e',64),
 'insurance_payout','a2000000-0000-0000-0000-000000000003','liquidation-policy-draft'
);
INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,debit_amount)
VALUES ('a1000000-0000-0000-0000-000000000003','liquidation_loss_expense_usdt',20);
INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,credit_amount)
VALUES ('a1000000-0000-0000-0000-000000000003','insurance_cash_usdt',20);
INSERT INTO private.demo_derivative_deficit_events(
 id,idempotency_key,payload_hash,source_liquidation_event_id,account_id,event_type,amount_usdt
) VALUES (
 'a3000000-0000-0000-0000-000000000003','deficit-open-2',repeat('f',64),
 'a2000000-0000-0000-0000-000000000003','a4000000-0000-0000-0000-000000000001',
 'deficit_opened',50
);
INSERT INTO private.demo_derivative_deficit_events(
 id,idempotency_key,payload_hash,source_liquidation_event_id,account_id,event_type,amount_usdt,platform_ledger_transaction_id
) VALUES (
 'a3000000-0000-0000-0000-000000000004','deficit-insurance-2',repeat('1',64),
 'a2000000-0000-0000-0000-000000000003','a4000000-0000-0000-0000-000000000001',
 'insurance_applied',20,'a1000000-0000-0000-0000-000000000003'
);
INSERT INTO private.demo_platform_ledger_transactions(
 id,idempotency_key,payload_hash,event_type,event_reference,policy_version
) VALUES (
 'a1000000-0000-0000-0000-000000000004','recovery-1',repeat('2',64),
 'insurance_recovery','a2000000-0000-0000-0000-000000000004','recovery-policy-draft'
);
INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,debit_amount)
VALUES ('a1000000-0000-0000-0000-000000000004','insurance_cash_usdt',10);
INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,credit_amount)
VALUES ('a1000000-0000-0000-0000-000000000004','insurance_recovery_income_usdt',10);
INSERT INTO private.demo_derivative_deficit_events(
 id,idempotency_key,payload_hash,source_liquidation_event_id,account_id,event_type,amount_usdt,platform_ledger_transaction_id
) VALUES (
 'a3000000-0000-0000-0000-000000000005','deficit-recovery-2',repeat('3',64),
 'a2000000-0000-0000-0000-000000000003','a4000000-0000-0000-0000-000000000001',
 'recovery_received',10,'a1000000-0000-0000-0000-000000000004'
);
COMMIT;

DO $partial_recovery$
BEGIN
 IF (SELECT insurance_cash_usdt FROM private.demo_platform_insurance_balance)<>60 THEN
  RAISE EXCEPTION 'partial payout and recovery cash projection mismatch';
 END IF;
 IF (SELECT remaining_deficit_usdt FROM private.demo_derivative_deficit_exposure
     WHERE source_liquidation_event_id='a2000000-0000-0000-0000-000000000003')<>20 THEN
  RAISE EXCEPTION 'partial insurance and recovery residual mismatch';
 END IF;
END;
$partial_recovery$;

-- A payout larger than the derived cash balance is rejected at the deferred
-- balance boundary. The inner PL/pgSQL block rolls back only the attempted post.
DO $overdraw$
BEGIN
 BEGIN
  INSERT INTO private.demo_platform_ledger_transactions(
   id,idempotency_key,payload_hash,event_type,event_reference,policy_version
  ) VALUES (
   'a1000000-0000-0000-0000-000000000005','payout-overdraw',repeat('4',64),
   'insurance_payout','a2000000-0000-0000-0000-000000000005','liquidation-policy-draft'
  );
  INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,debit_amount)
  VALUES ('a1000000-0000-0000-0000-000000000005','liquidation_loss_expense_usdt',61);
  INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,credit_amount)
  VALUES ('a1000000-0000-0000-0000-000000000005','insurance_cash_usdt',61);
  SET CONSTRAINTS ALL IMMEDIATE;
  RAISE EXCEPTION 'overdrawn insurance payout unexpectedly committed';
 EXCEPTION WHEN check_violation THEN
  NULL;
 END;
END;
$overdraw$;

-- Unbalanced ledger group is rejected by its deferred constraint trigger.
DO $unbalanced$
BEGIN
 BEGIN
  INSERT INTO private.demo_platform_ledger_transactions(
   id,idempotency_key,payload_hash,event_type,event_reference,policy_version
  ) VALUES (
   'a1000000-0000-0000-0000-000000000006','unbalanced-seed',repeat('5',64),
   'insurance_seed','a2000000-0000-0000-0000-000000000006','seed-policy-v1'
  );
  INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,debit_amount)
  VALUES ('a1000000-0000-0000-0000-000000000006','insurance_cash_usdt',5);
  SET CONSTRAINTS ALL IMMEDIATE;
  RAISE EXCEPTION 'unbalanced platform ledger transaction unexpectedly accepted';
 EXCEPTION WHEN check_violation THEN
  NULL;
 END;
END;
$unbalanced$;

-- Deficit over-recovery and mutation attempts are rejected.
DO $deficit_guards$
BEGIN
 BEGIN
  INSERT INTO private.demo_derivative_deficit_events(
   id,idempotency_key,payload_hash,source_liquidation_event_id,account_id,event_type,amount_usdt,platform_ledger_transaction_id
  ) VALUES (
   'a3000000-0000-0000-0000-000000000006','excess-recovery',repeat('6',64),
   'a2000000-0000-0000-0000-000000000003','a4000000-0000-0000-0000-000000000001',
   'recovery_received',21,'a1000000-0000-0000-0000-000000000004'
  );
  RAISE EXCEPTION 'over-recovery unexpectedly accepted';
 EXCEPTION WHEN check_violation THEN
  NULL;
 END;

 BEGIN
  UPDATE private.demo_platform_ledger_entries SET debit_amount=999
   WHERE transaction_id='a1000000-0000-0000-0000-000000000001';
  RAISE EXCEPTION 'platform ledger entry unexpectedly mutable';
 EXCEPTION WHEN SQLSTATE '55000' THEN
  NULL;
 END;

 BEGIN
  DELETE FROM private.demo_derivative_deficit_events
   WHERE id='a3000000-0000-0000-0000-000000000001';
  RAISE EXCEPTION 'deficit event unexpectedly deletable';
 EXCEPTION WHEN SQLSTATE '55000' THEN
  NULL;
 END;
END;
$deficit_guards$;

-- Duplicate idempotency key is rejected by the unique constraint.
DO $idempotency$
BEGIN
 BEGIN
  INSERT INTO private.demo_platform_ledger_transactions(
   id,idempotency_key,payload_hash,event_type,event_reference,policy_version
  ) VALUES (
   'a1000000-0000-0000-0000-000000000007','seed-1',repeat('7',64),
   'insurance_seed','a2000000-0000-0000-0000-000000000007','seed-policy-v1'
  );
  RAISE EXCEPTION 'duplicate platform idempotency key unexpectedly accepted';
 EXCEPTION WHEN unique_violation THEN
  NULL;
 END;
END;
$idempotency$;

SELECT 'demo derivatives insurance and deficit ledger integration passed' AS result;

-- DRAFT ONLY: platform-owned demo Futures insurance ledger and deficit memorandum.
-- Apply only to disposable PostgreSQL CI until migration reconciliation and explicit release approval.
-- No posting RPC, payout worker, liquidation path or Production deployment is created here.
BEGIN;

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated, service_role;

CREATE TABLE private.demo_platform_ledger_accounts (
  account_code text PRIMARY KEY CHECK (account_code IN (
    'insurance_cash_usdt',
    'insurance_fund_equity_usdt',
    'liquidation_loss_expense_usdt',
    'insurance_recovery_income_usdt'
  )),
  asset text NOT NULL DEFAULT 'USDT' CHECK (asset='USDT'),
  normal_balance text NOT NULL CHECK (normal_balance IN ('debit','credit')),
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO private.demo_platform_ledger_accounts(account_code,normal_balance) VALUES
 ('insurance_cash_usdt','debit'),
 ('insurance_fund_equity_usdt','credit'),
 ('liquidation_loss_expense_usdt','debit'),
 ('insurance_recovery_income_usdt','credit');

CREATE TABLE private.demo_platform_ledger_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  idempotency_key text NOT NULL UNIQUE CHECK (length(idempotency_key) BETWEEN 1 AND 200),
  payload_hash text NOT NULL CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  event_type text NOT NULL CHECK (event_type IN ('insurance_seed','insurance_payout','insurance_recovery')),
  event_reference uuid NOT NULL,
  policy_version text NOT NULL CHECK (length(policy_version) BETWEEN 1 AND 100),
  created_xid xid8 NOT NULL DEFAULT pg_current_xact_id(),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(event_type,event_reference)
);

CREATE TABLE private.demo_platform_ledger_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES private.demo_platform_ledger_transactions(id),
  account_code text NOT NULL REFERENCES private.demo_platform_ledger_accounts(account_code),
  asset text NOT NULL DEFAULT 'USDT' CHECK (asset='USDT'),
  debit_amount numeric(38,18) NOT NULL DEFAULT 0 CHECK (debit_amount >= 0),
  credit_amount numeric(38,18) NOT NULL DEFAULT 0 CHECK (credit_amount >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((debit_amount > 0 AND credit_amount = 0) OR
         (credit_amount > 0 AND debit_amount = 0))
);

CREATE INDEX demo_platform_ledger_entries_tx_idx
 ON private.demo_platform_ledger_entries(transaction_id,account_code);

CREATE VIEW private.demo_platform_insurance_balance AS
SELECT 'USDT'::text AS asset,
       COALESCE(sum(e.debit_amount-e.credit_amount)
         FILTER (WHERE e.account_code='insurance_cash_usdt'),0::numeric) AS insurance_cash_usdt
FROM private.demo_platform_ledger_entries e;

CREATE FUNCTION private.guard_demo_platform_ledger_transaction()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $function$
BEGIN
  -- Serialize all platform cash movements. The deferred balance check then
  -- observes a committed predecessor plus this transaction, never a stale balance.
  PERFORM 1 FROM private.demo_platform_ledger_accounts
   WHERE account_code='insurance_cash_usdt' FOR UPDATE;
  RETURN NEW;
END;
$function$;

CREATE FUNCTION private.prevent_demo_platform_ledger_append()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $function$
DECLARE v_created_xid xid8;
BEGIN
  SELECT created_xid INTO v_created_xid
    FROM private.demo_platform_ledger_transactions
   WHERE id=NEW.transaction_id FOR KEY SHARE;
  IF v_created_xid IS NULL OR v_created_xid <> pg_current_xact_id() THEN
    RAISE EXCEPTION 'Platform ledger transaction is finalized; late append is forbidden'
      USING ERRCODE='55000';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE FUNCTION private.validate_demo_platform_ledger_group()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $function$
DECLARE
  v_tx uuid;
  v_event_type text;
  v_count integer;
  v_debits numeric(38,18);
  v_credits numeric(38,18);
  v_cash_debit numeric(38,18);
  v_cash_credit numeric(38,18);
  v_equity_credit numeric(38,18);
  v_loss_debit numeric(38,18);
  v_recovery_credit numeric(38,18);
  v_balance numeric(38,18);
BEGIN
  IF TG_TABLE_NAME='demo_platform_ledger_transactions' THEN
    v_tx := NEW.id;
  ELSE
    v_tx := COALESCE(NEW.transaction_id,OLD.transaction_id);
  END IF;
  SELECT event_type INTO v_event_type
    FROM private.demo_platform_ledger_transactions WHERE id=v_tx;
  IF v_event_type IS NULL THEN RETURN NULL; END IF;
  SELECT count(*),COALESCE(sum(debit_amount),0),COALESCE(sum(credit_amount),0),
         COALESCE(sum(debit_amount) FILTER (WHERE account_code='insurance_cash_usdt'),0),
         COALESCE(sum(credit_amount) FILTER (WHERE account_code='insurance_cash_usdt'),0)
    INTO v_count,v_debits,v_credits,v_cash_debit,v_cash_credit
    FROM private.demo_platform_ledger_entries WHERE transaction_id=v_tx;
  IF v_count <> 2 OR v_debits <> v_credits THEN
    RAISE EXCEPTION 'Platform ledger transaction must contain exactly two balanced USDT entries'
      USING ERRCODE='23514';
  END IF;
  SELECT COALESCE(sum(credit_amount),0) INTO v_equity_credit
    FROM private.demo_platform_ledger_entries
   WHERE transaction_id=v_tx AND account_code='insurance_fund_equity_usdt';
  SELECT COALESCE(sum(debit_amount),0) INTO v_loss_debit
    FROM private.demo_platform_ledger_entries
   WHERE transaction_id=v_tx AND account_code='liquidation_loss_expense_usdt';
  SELECT COALESCE(sum(credit_amount),0) INTO v_recovery_credit
    FROM private.demo_platform_ledger_entries
   WHERE transaction_id=v_tx AND account_code='insurance_recovery_income_usdt';

  IF v_event_type='insurance_seed' THEN
    IF v_cash_debit<=0 OR v_cash_credit<>0 OR v_equity_credit<>v_cash_debit THEN
      RAISE EXCEPTION 'Insurance seed must debit cash and credit fund equity for the same amount'
        USING ERRCODE='23514';
    END IF;
  ELSIF v_event_type='insurance_payout' THEN
    IF v_cash_credit<=0 OR v_cash_debit<>0 OR v_loss_debit<>v_cash_credit THEN
      RAISE EXCEPTION 'Insurance payout must debit loss expense and credit cash for the same amount'
        USING ERRCODE='23514';
    END IF;
  ELSIF v_event_type='insurance_recovery' THEN
    IF v_cash_debit<=0 OR v_cash_credit<>0 OR v_recovery_credit<>v_cash_debit THEN
      RAISE EXCEPTION 'Insurance recovery must debit cash and credit recovery income for the same amount'
        USING ERRCODE='23514';
    END IF;
  END IF;

  SELECT COALESCE(sum(debit_amount-credit_amount),0)
    INTO v_balance FROM private.demo_platform_ledger_entries
   WHERE account_code='insurance_cash_usdt';
  IF v_balance < 0 THEN
    RAISE EXCEPTION 'Insurance payout exceeds available platform insurance cash'
      USING ERRCODE='23514';
  END IF;
  RETURN NULL;
END;
$function$;

CREATE FUNCTION private.prevent_demo_platform_ledger_mutation()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $function$
BEGIN
  RAISE EXCEPTION 'Platform ledger records are immutable; use compensating transactions'
    USING ERRCODE='55000';
END;
$function$;

CREATE TRIGGER demo_platform_ledger_cash_lock
 BEFORE INSERT ON private.demo_platform_ledger_transactions
 FOR EACH ROW EXECUTE FUNCTION private.guard_demo_platform_ledger_transaction();
CREATE TRIGGER demo_platform_ledger_entries_no_late_append
 BEFORE INSERT ON private.demo_platform_ledger_entries
 FOR EACH ROW EXECUTE FUNCTION private.prevent_demo_platform_ledger_append();
CREATE CONSTRAINT TRIGGER demo_platform_ledger_entries_balanced
 AFTER INSERT OR UPDATE OR DELETE ON private.demo_platform_ledger_entries
 DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
 EXECUTE FUNCTION private.validate_demo_platform_ledger_group();
CREATE CONSTRAINT TRIGGER demo_platform_ledger_header_balanced
 AFTER INSERT ON private.demo_platform_ledger_transactions
 DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
 EXECUTE FUNCTION private.validate_demo_platform_ledger_group();
CREATE TRIGGER demo_platform_ledger_entries_immutable
 BEFORE UPDATE OR DELETE ON private.demo_platform_ledger_entries
 FOR EACH ROW EXECUTE FUNCTION private.prevent_demo_platform_ledger_mutation();
CREATE TRIGGER demo_platform_ledger_transactions_immutable
 BEFORE UPDATE OR DELETE ON private.demo_platform_ledger_transactions
 FOR EACH ROW EXECUTE FUNCTION private.prevent_demo_platform_ledger_mutation();
CREATE TRIGGER demo_platform_ledger_accounts_immutable
 BEFORE UPDATE OR DELETE ON private.demo_platform_ledger_accounts
 FOR EACH ROW EXECUTE FUNCTION private.prevent_demo_platform_ledger_mutation();

CREATE TABLE private.demo_derivative_deficit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  idempotency_key text NOT NULL UNIQUE CHECK (length(idempotency_key) BETWEEN 1 AND 200),
  payload_hash text NOT NULL CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  source_liquidation_event_id uuid NOT NULL,
  account_id uuid NOT NULL,
  position_id uuid,
  risk_event_id uuid,
  event_type text NOT NULL CHECK (event_type IN (
    'deficit_opened','insurance_applied','recovery_received'
  )),
  asset text NOT NULL DEFAULT 'USDT' CHECK (asset='USDT'),
  amount_usdt numeric(38,18) NOT NULL CHECK (amount_usdt > 0),
  platform_ledger_transaction_id uuid UNIQUE
    REFERENCES private.demo_platform_ledger_transactions(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (
    (event_type='deficit_opened' AND platform_ledger_transaction_id IS NULL)
    OR
    (event_type IN ('insurance_applied','recovery_received')
      AND platform_ledger_transaction_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX demo_derivative_deficit_one_open_idx
 ON private.demo_derivative_deficit_events(source_liquidation_event_id)
 WHERE event_type='deficit_opened';
CREATE INDEX demo_derivative_deficit_source_idx
 ON private.demo_derivative_deficit_events(source_liquidation_event_id,created_at,id);

CREATE FUNCTION private.validate_demo_derivative_deficit_event()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $function$
DECLARE
  v_opened numeric(38,18);
  v_applied numeric(38,18);
  v_recovered numeric(38,18);
  v_tx_type text;
  v_cash_amount numeric(38,18);
  v_counter_amount numeric(38,18);
BEGIN
  -- Serialize all events for a single liquidation deficit before checking its
  -- cumulative coverage; concurrent recovery/insurance events cannot over-apply.
  PERFORM pg_advisory_xact_lock(hashtextextended(NEW.source_liquidation_event_id::text,0));

  IF NEW.event_type='deficit_opened' THEN
    IF EXISTS (SELECT 1 FROM private.demo_derivative_deficit_events
      WHERE source_liquidation_event_id=NEW.source_liquidation_event_id) THEN
      RAISE EXCEPTION 'Deficit must be opened before any coverage or only once'
        USING ERRCODE='23514';
    END IF;
    RETURN NEW;
  END IF;

  SELECT amount_usdt INTO v_opened
    FROM private.demo_derivative_deficit_events
   WHERE source_liquidation_event_id=NEW.source_liquidation_event_id
     AND event_type='deficit_opened';
  IF v_opened IS NULL THEN
    RAISE EXCEPTION 'Deficit coverage requires an existing opening event'
      USING ERRCODE='23514';
  END IF;

  SELECT event_type INTO v_tx_type
    FROM private.demo_platform_ledger_transactions
   WHERE id=NEW.platform_ledger_transaction_id;
  IF (NEW.event_type='insurance_applied' AND v_tx_type<>'insurance_payout')
     OR (NEW.event_type='recovery_received' AND v_tx_type<>'insurance_recovery') THEN
    RAISE EXCEPTION 'Deficit event does not match its platform ledger transaction type'
      USING ERRCODE='23514';
  END IF;

  IF NEW.event_type='insurance_applied' THEN
    SELECT COALESCE(sum(credit_amount-debit_amount),0)
      INTO v_cash_amount FROM private.demo_platform_ledger_entries
     WHERE transaction_id=NEW.platform_ledger_transaction_id
       AND account_code='insurance_cash_usdt';
    SELECT COALESCE(sum(debit_amount-credit_amount),0)
      INTO v_counter_amount FROM private.demo_platform_ledger_entries
     WHERE transaction_id=NEW.platform_ledger_transaction_id
       AND account_code='liquidation_loss_expense_usdt';
  ELSE
    SELECT COALESCE(sum(debit_amount-credit_amount),0)
      INTO v_cash_amount FROM private.demo_platform_ledger_entries
     WHERE transaction_id=NEW.platform_ledger_transaction_id
       AND account_code='insurance_cash_usdt';
    SELECT COALESCE(sum(credit_amount-debit_amount),0)
      INTO v_counter_amount FROM private.demo_platform_ledger_entries
     WHERE transaction_id=NEW.platform_ledger_transaction_id
       AND account_code='insurance_recovery_income_usdt';
  END IF;
  IF v_cash_amount<>NEW.amount_usdt OR v_counter_amount<>NEW.amount_usdt THEN
    RAISE EXCEPTION 'Deficit event amount must exactly match its platform ledger movement'
      USING ERRCODE='23514';
  END IF;

  SELECT COALESCE(sum(amount_usdt) FILTER (WHERE event_type='insurance_applied'),0),
         COALESCE(sum(amount_usdt) FILTER (WHERE event_type='recovery_received'),0)
    INTO v_applied,v_recovered
    FROM private.demo_derivative_deficit_events
   WHERE source_liquidation_event_id=NEW.source_liquidation_event_id;
  IF v_applied+v_recovered+NEW.amount_usdt > v_opened THEN
    RAISE EXCEPTION 'Insurance and recovery events exceed the opened deficit'
      USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE FUNCTION private.prevent_demo_derivative_deficit_mutation()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $function$
BEGIN
  RAISE EXCEPTION 'Deficit events are immutable; append a compensating event under an approved policy'
    USING ERRCODE='55000';
END;
$function$;

CREATE TRIGGER demo_derivative_deficit_event_validate
 BEFORE INSERT ON private.demo_derivative_deficit_events
 FOR EACH ROW EXECUTE FUNCTION private.validate_demo_derivative_deficit_event();
CREATE TRIGGER demo_derivative_deficit_events_immutable
 BEFORE UPDATE OR DELETE ON private.demo_derivative_deficit_events
 FOR EACH ROW EXECUTE FUNCTION private.prevent_demo_derivative_deficit_mutation();

CREATE VIEW private.demo_derivative_deficit_exposure AS
SELECT source_liquidation_event_id,
       (array_agg(account_id))[1] AS account_id,
       max(asset) AS asset,
       sum(amount_usdt) FILTER (WHERE event_type='deficit_opened') AS opened_usdt,
       COALESCE(sum(amount_usdt) FILTER (WHERE event_type='insurance_applied'),0) AS insurance_applied_usdt,
       COALESCE(sum(amount_usdt) FILTER (WHERE event_type='recovery_received'),0) AS recovered_usdt,
       sum(amount_usdt) FILTER (WHERE event_type='deficit_opened')
         - COALESCE(sum(amount_usdt) FILTER (WHERE event_type='insurance_applied'),0)
         - COALESCE(sum(amount_usdt) FILTER (WHERE event_type='recovery_received'),0) AS remaining_deficit_usdt
FROM private.demo_derivative_deficit_events
GROUP BY source_liquidation_event_id;

REVOKE ALL ON ALL TABLES IN SCHEMA private FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA private FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON SCHEMA private FROM PUBLIC,anon,authenticated,service_role;

COMMIT;

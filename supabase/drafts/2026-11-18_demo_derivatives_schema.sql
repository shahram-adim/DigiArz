-- DRAFT ONLY: isolated demo derivatives schema.
-- Do not apply to Supabase Production until migration reconciliation and explicit release approval.
BEGIN;

CREATE TABLE public.demo_derivative_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  futures_cash_usdt numeric(38,18) NOT NULL DEFAULT 0 CHECK (futures_cash_usdt >= 0),
  margin_cash_usdt numeric(38,18) NOT NULL DEFAULT 0 CHECK (margin_cash_usdt >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,user_id)
);

CREATE TABLE public.demo_derivative_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id uuid NOT NULL,
  product_type text NOT NULL CHECK (product_type IN ('futures','margin')),
  symbol text NOT NULL CHECK (symbol ~ '^[A-Z0-9]{2,15}USDT$'),
  position_side text NOT NULL CHECK (position_side IN ('long','short')),
  order_type text NOT NULL CHECK (order_type IN ('market','limit')),
  quantity numeric(38,18) NOT NULL CHECK (quantity > 0),
  limit_price numeric(38,18),
  leverage integer NOT NULL DEFAULT 1 CHECK (leverage BETWEEN 1 AND 125),
  margin_mode text NOT NULL CHECK (margin_mode IN ('isolated','cross')),
  reduce_only boolean NOT NULL DEFAULT false,
  filled_quantity numeric(38,18) NOT NULL DEFAULT 0 CHECK (filled_quantity >= 0),
  remaining_quantity numeric(38,18) NOT NULL,
  average_fill_price numeric(38,18),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','partially_filled','filled','cancelled','rejected','expired')),
  client_request_id uuid NOT NULL,
  rejection_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,user_id),
  UNIQUE (id,account_id,user_id,symbol,position_side),
  UNIQUE (user_id,client_request_id),
  FOREIGN KEY (account_id,user_id)
    REFERENCES public.demo_derivative_accounts(id,user_id) ON DELETE CASCADE,
  CHECK (remaining_quantity >= 0 AND filled_quantity + remaining_quantity = quantity),
  CHECK ((order_type='market' AND limit_price IS NULL) OR (order_type='limit' AND limit_price > 0)),
  CHECK (average_fill_price IS NULL OR average_fill_price > 0),
  CHECK (filled_quantity <= quantity),
  CHECK ((status='filled' AND remaining_quantity=0) OR status<>'filled')
);

CREATE TABLE public.demo_derivative_positions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id uuid NOT NULL,
  product_type text NOT NULL CHECK (product_type IN ('futures','margin')),
  symbol text NOT NULL CHECK (symbol ~ '^[A-Z0-9]{2,15}USDT$'),
  position_side text NOT NULL CHECK (position_side IN ('long','short')),
  margin_mode text NOT NULL CHECK (margin_mode IN ('isolated','cross')),
  leverage integer NOT NULL CHECK (leverage BETWEEN 1 AND 125),
  quantity numeric(38,18) NOT NULL CHECK (quantity >= 0),
  entry_price numeric(38,18) NOT NULL CHECK (entry_price > 0),
  isolated_margin_usdt numeric(38,18) NOT NULL DEFAULT 0 CHECK (isolated_margin_usdt >= 0),
  realized_pnl_usdt numeric(38,18) NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','closed','liquidated')),
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  opened_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,user_id),
  UNIQUE (id,account_id,user_id,symbol,position_side),
  FOREIGN KEY (account_id,user_id)
    REFERENCES public.demo_derivative_accounts(id,user_id) ON DELETE CASCADE,
  CHECK (
    (status='open' AND quantity>0 AND closed_at IS NULL)
    OR (status IN ('closed','liquidated') AND quantity=0 AND closed_at IS NOT NULL)
  ),
  CHECK (
    (margin_mode='isolated' AND (status<>'open' OR isolated_margin_usdt>0))
    OR (margin_mode='cross' AND isolated_margin_usdt=0)
  )
);

CREATE TABLE public.demo_derivative_fills (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id uuid NOT NULL,
  order_id uuid NOT NULL,
  position_id uuid NOT NULL,
  fill_sequence integer NOT NULL CHECK (fill_sequence > 0),
  symbol text NOT NULL CHECK (symbol ~ '^[A-Z0-9]{2,15}USDT$'),
  position_side text NOT NULL CHECK (position_side IN ('long','short')),
  quantity numeric(38,18) NOT NULL CHECK (quantity > 0),
  price numeric(38,18) NOT NULL CHECK (price > 0),
  fee_usdt numeric(38,18) NOT NULL DEFAULT 0 CHECK (fee_usdt >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (account_id,user_id)
    REFERENCES public.demo_derivative_accounts(id,user_id) ON DELETE CASCADE,
  FOREIGN KEY (order_id,account_id,user_id,symbol,position_side)
    REFERENCES public.demo_derivative_orders(id,account_id,user_id,symbol,position_side) ON DELETE RESTRICT,
  FOREIGN KEY (position_id,account_id,user_id,symbol,position_side)
    REFERENCES public.demo_derivative_positions(id,account_id,user_id,symbol,position_side) ON DELETE RESTRICT,
  UNIQUE (order_id,fill_sequence)
);

CREATE TABLE public.demo_margin_loans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id uuid NOT NULL,
  position_id uuid,
  loan_asset text NOT NULL CHECK (loan_asset ~ '^[A-Z0-9]{2,20}$'),
  principal numeric(38,18) NOT NULL CHECK (principal > 0),
  repaid_amount numeric(38,18) NOT NULL DEFAULT 0 CHECK (repaid_amount >= 0),
  accrued_interest numeric(38,18) NOT NULL DEFAULT 0 CHECK (accrued_interest >= 0),
  interest_rate_per_hour numeric(20,18) NOT NULL DEFAULT 0 CHECK (interest_rate_per_hour >= 0),
  collateral_mode text NOT NULL CHECK (collateral_mode IN ('isolated','cross')),
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','repaid','liquidated')),
  last_interest_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  outstanding_amount numeric(38,18)
    GENERATED ALWAYS AS (principal + accrued_interest - repaid_amount) STORED,
  FOREIGN KEY (account_id,user_id)
    REFERENCES public.demo_derivative_accounts(id,user_id) ON DELETE CASCADE,
  FOREIGN KEY (position_id,account_id,user_id)
    REFERENCES public.demo_derivative_positions(id,account_id,user_id) ON DELETE RESTRICT,
  CHECK (repaid_amount <= principal + accrued_interest),
  CHECK ((status='open' AND principal + accrued_interest > repaid_amount) OR status<>'open'),
  CHECK ((status='repaid' AND principal + accrued_interest = repaid_amount) OR status<>'repaid')
);

CREATE TABLE public.demo_derivative_funding_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id uuid NOT NULL,
  position_id uuid NOT NULL,
  interval_start timestamptz NOT NULL,
  interval_end timestamptz NOT NULL,
  funding_rate numeric(20,18) NOT NULL,
  mark_price numeric(38,18) NOT NULL CHECK (mark_price > 0),
  position_notional_usdt numeric(38,18) NOT NULL CHECK (position_notional_usdt > 0),
  amount_usdt numeric(38,18) NOT NULL,
  settled_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (account_id,user_id)
    REFERENCES public.demo_derivative_accounts(id,user_id) ON DELETE CASCADE,
  FOREIGN KEY (position_id,account_id,user_id)
    REFERENCES public.demo_derivative_positions(id,account_id,user_id) ON DELETE RESTRICT,
  CHECK (interval_end > interval_start),
  UNIQUE (position_id,interval_start)
);

CREATE TABLE public.demo_derivative_risk_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id uuid NOT NULL,
  position_id uuid,
  event_type text NOT NULL CHECK (event_type IN (
    'margin_warning','liquidation_started','partial_liquidation','liquidated',
    'stale_price_block','risk_limit_block','margin_added','margin_released'
  )),
  snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (account_id,user_id)
    REFERENCES public.demo_derivative_accounts(id,user_id) ON DELETE CASCADE,
  FOREIGN KEY (position_id,account_id,user_id)
    REFERENCES public.demo_derivative_positions(id,account_id,user_id) ON DELETE RESTRICT
);

CREATE TABLE public.demo_derivative_ledger_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  idempotency_key uuid NOT NULL,
  created_xid xid8 NOT NULL DEFAULT pg_current_xact_id(),
  event_type text NOT NULL CHECK (event_type IN (
    'spot_transfer','futures_transfer','margin_transfer','order_fee','realized_pnl',
    'funding','borrow','repayment','interest','liquidation','adjustment'
  )),
  reference_id uuid,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id,idempotency_key),
  UNIQUE (id,user_id)
);

CREATE TABLE public.demo_derivative_ledger_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  asset text NOT NULL CHECK (asset ~ '^[A-Z0-9]{2,20}$'),
  account_bucket text NOT NULL CHECK (account_bucket IN (
    'spot_wallet','futures_cash','margin_cash','isolated_margin','margin_debt',
    'position_pnl','fee_revenue','funding','interest','system_clearing'
  )),
  debit_amount numeric(38,18) NOT NULL DEFAULT 0 CHECK (debit_amount >= 0),
  credit_amount numeric(38,18) NOT NULL DEFAULT 0 CHECK (credit_amount >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (transaction_id,user_id)
    REFERENCES public.demo_derivative_ledger_transactions(id,user_id) ON DELETE RESTRICT,
  CHECK (
    (debit_amount > 0 AND credit_amount = 0)
    OR (credit_amount > 0 AND debit_amount = 0)
  )
);

CREATE INDEX demo_derivative_orders_user_status_created_idx
  ON public.demo_derivative_orders(user_id,status,created_at DESC);
CREATE INDEX demo_derivative_orders_pair_status_idx
  ON public.demo_derivative_orders(symbol,status,created_at);
CREATE INDEX demo_derivative_positions_user_status_idx
  ON public.demo_derivative_positions(user_id,status,updated_at DESC);
CREATE INDEX demo_derivative_positions_pair_status_idx
  ON public.demo_derivative_positions(symbol,status);
CREATE INDEX demo_derivative_fills_user_created_idx
  ON public.demo_derivative_fills(user_id,created_at DESC);
CREATE INDEX demo_margin_loans_user_status_idx
  ON public.demo_margin_loans(user_id,status,updated_at DESC);
CREATE INDEX demo_derivative_funding_user_created_idx
  ON public.demo_derivative_funding_events(user_id,settled_at DESC);
CREATE INDEX demo_derivative_risk_user_created_idx
  ON public.demo_derivative_risk_events(user_id,created_at DESC);
CREATE INDEX demo_derivative_ledger_entries_user_created_idx
  ON public.demo_derivative_ledger_entries(user_id,created_at DESC);
CREATE INDEX demo_derivative_ledger_entries_transaction_idx
  ON public.demo_derivative_ledger_entries(transaction_id,asset);

CREATE FUNCTION public.validate_demo_derivative_ledger_group()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_transaction_id uuid;
  v_line_count integer;
BEGIN
  IF TG_TABLE_NAME='demo_derivative_ledger_transactions' THEN
    v_transaction_id := NEW.id;
  ELSE
    v_transaction_id := COALESCE(NEW.transaction_id,OLD.transaction_id);
  END IF;
  SELECT count(*) INTO v_line_count
  FROM public.demo_derivative_ledger_entries
  WHERE transaction_id=v_transaction_id;
  IF v_line_count < 2 THEN
    RAISE EXCEPTION 'A derivative ledger transaction requires at least two entries'
      USING ERRCODE='23514';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM public.demo_derivative_ledger_entries
    WHERE transaction_id=v_transaction_id
    GROUP BY asset
    HAVING sum(debit_amount) <> sum(credit_amount)
  ) THEN
    RAISE EXCEPTION 'Derivative ledger transaction is not balanced per asset'
      USING ERRCODE='23514';
  END IF;
  RETURN NULL;
END;
$function$;

CREATE FUNCTION public.prevent_demo_derivative_ledger_append()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_created_xid xid8;
BEGIN
  SELECT created_xid INTO v_created_xid
  FROM public.demo_derivative_ledger_transactions
  WHERE id=NEW.transaction_id AND user_id=NEW.user_id
  FOR KEY SHARE;
  IF v_created_xid IS NULL OR v_created_xid <> pg_current_xact_id() THEN
    RAISE EXCEPTION 'Derivative ledger transaction is finalized; append is forbidden'
      USING ERRCODE='55000';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE FUNCTION public.prevent_demo_derivative_ledger_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
  RAISE EXCEPTION 'Derivative ledger records are immutable; use compensating entries'
    USING ERRCODE='55000';
END;
$function$;

CREATE CONSTRAINT TRIGGER demo_derivative_ledger_entries_balanced
AFTER INSERT OR UPDATE OR DELETE ON public.demo_derivative_ledger_entries
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION public.validate_demo_derivative_ledger_group();

CREATE CONSTRAINT TRIGGER demo_derivative_ledger_header_balanced
AFTER INSERT ON public.demo_derivative_ledger_transactions
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION public.validate_demo_derivative_ledger_group();

CREATE TRIGGER demo_derivative_ledger_entries_no_late_append
BEFORE INSERT ON public.demo_derivative_ledger_entries
FOR EACH ROW EXECUTE FUNCTION public.prevent_demo_derivative_ledger_append();

CREATE TRIGGER demo_derivative_ledger_entries_immutable
BEFORE UPDATE OR DELETE ON public.demo_derivative_ledger_entries
FOR EACH ROW EXECUTE FUNCTION public.prevent_demo_derivative_ledger_mutation();

CREATE TRIGGER demo_derivative_ledger_transactions_immutable
BEFORE UPDATE OR DELETE ON public.demo_derivative_ledger_transactions
FOR EACH ROW EXECUTE FUNCTION public.prevent_demo_derivative_ledger_mutation();

DO $rls$
DECLARE
  v_table text;
BEGIN
  FOREACH v_table IN ARRAY ARRAY[
    'demo_derivative_accounts','demo_derivative_orders','demo_derivative_positions',
    'demo_derivative_fills','demo_margin_loans','demo_derivative_funding_events',
    'demo_derivative_risk_events','demo_derivative_ledger_transactions',
    'demo_derivative_ledger_entries'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',v_table);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR SELECT TO authenticated USING (user_id = (SELECT auth.uid()))',
      v_table||'_select_own',v_table
    );
    EXECUTE format('REVOKE ALL ON TABLE public.%I FROM anon,authenticated',v_table);
    EXECUTE format('GRANT SELECT ON TABLE public.%I TO authenticated',v_table);
  END LOOP;
END;
$rls$;

REVOKE ALL ON FUNCTION public.validate_demo_derivative_ledger_group() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.prevent_demo_derivative_ledger_append() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.prevent_demo_derivative_ledger_mutation() FROM PUBLIC,anon,authenticated;

COMMIT;

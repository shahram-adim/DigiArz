-- Disposable PostgreSQL candidate only.
-- Run AFTER authoritative_market_limit_source_parity_setup.sql and the exact
-- authoritative Market/Limit migration. This tests identity-to-legacy-ledger
-- mapping against the existing asset_balances and order_reservations tables;
-- it does not replace them with a parallel balances table.
CREATE TABLE public.canonical_asset_ledger_key_map (
  canonical_asset_id uuid PRIMARY KEY,
  display_symbol text NOT NULL,
  ledger_asset_key text NOT NULL UNIQUE,
  mapping_status text NOT NULL CHECK (
    mapping_status IN ('pending','verified','ambiguous','quarantined')
  ),
  evidence_ref text,
  reviewed_at timestamptz,
  CHECK (
    mapping_status <> 'verified'
    OR (evidence_ref IS NOT NULL AND reviewed_at IS NOT NULL)
  )
);


-- Once the existing ledger has referenced a mapping, its ledger key is immutable.
-- Display metadata may change, but a ticker rename must never move balances or reservations.
CREATE OR REPLACE FUNCTION public.prevent_referenced_ledger_key_reassignment()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO ''
AS $function$
BEGIN
  IF NEW.ledger_asset_key IS DISTINCT FROM OLD.ledger_asset_key
     AND (
       EXISTS (SELECT 1 FROM public.asset_balances AS b WHERE b.asset = OLD.ledger_asset_key)
       OR EXISTS (SELECT 1 FROM public.order_reservations AS r WHERE r.asset = OLD.ledger_asset_key)
     ) THEN
    RAISE EXCEPTION 'Ledger asset key is immutable after financial use'
      USING ERRCODE = '23514';
  END IF;
  IF TG_OP = 'DELETE' THEN
    IF EXISTS (
      SELECT 1 FROM public.asset_balances AS b
      WHERE b.asset = OLD.ledger_asset_key
    ) OR EXISTS (
      SELECT 1 FROM public.order_reservations AS r
      WHERE r.asset = OLD.ledger_asset_key
    ) THEN
      RAISE EXCEPTION 'Ledger asset mapping cannot be deleted after financial use'
        USING ERRCODE = '23514';
    END IF;
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$function$;

CREATE TRIGGER canonical_asset_ledger_key_immutable
BEFORE UPDATE OF ledger_asset_key ON public.canonical_asset_ledger_key_map
FOR EACH ROW EXECUTE FUNCTION public.prevent_referenced_ledger_key_reassignment();

CREATE TRIGGER canonical_asset_ledger_mapping_no_delete
BEFORE DELETE ON public.canonical_asset_ledger_key_map
FOR EACH ROW EXECUTE FUNCTION public.prevent_referenced_ledger_key_reassignment();

CREATE OR REPLACE FUNCTION public.resolve_canonical_ledger_asset_key(p_asset_id uuid)
RETURNS text
LANGUAGE plpgsql
STABLE
SET search_path TO ''
AS $function$
DECLARE
  v_key text;
BEGIN
  SELECT m.ledger_asset_key
  INTO v_key
  FROM public.canonical_asset_ledger_key_map AS m
  WHERE m.canonical_asset_id = p_asset_id
    AND m.mapping_status = 'verified';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Canonical asset ledger mapping is not verified'
      USING ERRCODE = '23514';
  END IF;

  RETURN v_key;
END;
$function$;

DO $test$
DECLARE
  v_user uuid := '22000000-0000-0000-0000-000000000001';
  v_asset_a uuid := '22000000-0000-0000-0000-0000000000a1';
  v_asset_b uuid := '22000000-0000-0000-0000-0000000000b2';
  v_asset_ambiguous uuid := '22000000-0000-0000-0000-0000000000c3';
  v_key_a text := 'asset:22000000-0000-0000-0000-0000000000a1';
  v_key_b text := 'asset:22000000-0000-0000-0000-0000000000b2';
  v_resolved text;
  v_balance_a numeric;
  v_balance_b numeric;
  v_reserved_a numeric;
  v_reserved_b numeric;
BEGIN
  INSERT INTO public.canonical_asset_ledger_key_map(
    canonical_asset_id,display_symbol,ledger_asset_key,mapping_status,evidence_ref,reviewed_at
  ) VALUES
    (v_asset_a,'ABC',v_key_a,'verified','test:provider-a',clock_timestamp()),
    (v_asset_b,'ABC',v_key_b,'verified','test:provider-b',clock_timestamp()),
    (v_asset_ambiguous,'ABC','asset:22000000-0000-0000-0000-0000000000c3','ambiguous',NULL,NULL);

  IF public.resolve_canonical_ledger_asset_key(v_asset_a) <> v_key_a
     OR public.resolve_canonical_ledger_asset_key(v_asset_b) <> v_key_b THEN
    RAISE EXCEPTION 'same display ticker did not resolve to two distinct ledger keys';
  END IF;

  -- A canonical ID may not claim a ledger key already owned by another ID.
  BEGIN
    INSERT INTO public.canonical_asset_ledger_key_map(
      canonical_asset_id,display_symbol,ledger_asset_key,mapping_status,evidence_ref,reviewed_at
    ) VALUES (
      '22000000-0000-0000-0000-0000000000d4','ABC',v_key_a,
      'verified','test:duplicate-key',clock_timestamp()
    );
    RAISE EXCEPTION 'duplicate ledger key unexpectedly accepted';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;

  -- Ambiguous/unreviewed mappings must fail closed before financial access.
  BEGIN
    PERFORM public.resolve_canonical_ledger_asset_key(v_asset_ambiguous);
    RAISE EXCEPTION 'ambiguous mapping unexpectedly resolved';
  EXCEPTION WHEN SQLSTATE '23514' THEN
    IF SQLERRM NOT LIKE '%mapping is not verified%' THEN RAISE; END IF;
  END;

  -- Use the authoritative legacy ledger tables, not a parallel balances table.
  INSERT INTO public.asset_balances(user_id,asset,balance)
  VALUES (v_user,v_key_a,12),(v_user,v_key_b,29);

  INSERT INTO public.order_reservations(
    order_id,user_id,asset,reserved_amount,consumed_amount,released_amount,status
  ) VALUES
    ('22000000-0000-0000-0000-0000000000e1',v_user,v_key_a,5,1,1,'reserved'),
    ('22000000-0000-0000-0000-0000000000e2',v_user,v_key_b,7,2,1,'reserved');

  SELECT balance INTO v_balance_a
  FROM public.asset_balances WHERE user_id=v_user AND asset=v_key_a;
  SELECT balance INTO v_balance_b
  FROM public.asset_balances WHERE user_id=v_user AND asset=v_key_b;

  SELECT COALESCE(sum(reserved_amount-consumed_amount-released_amount),0)
  INTO v_reserved_a FROM public.order_reservations
  WHERE user_id=v_user AND asset=v_key_a AND status='reserved';
  SELECT COALESCE(sum(reserved_amount-consumed_amount-released_amount),0)
  INTO v_reserved_b FROM public.order_reservations
  WHERE user_id=v_user AND asset=v_key_b AND status='reserved';

  IF v_balance_a <> 12 OR v_balance_b <> 29 THEN
    RAISE EXCEPTION 'duplicate ticker balances collided: A %, B %',v_balance_a,v_balance_b;
  END IF;
  IF v_reserved_a <> 3 OR v_reserved_b <> 4 THEN
    RAISE EXCEPTION 'duplicate ticker reservations collided: A %, B %',v_reserved_a,v_reserved_b;
  END IF;
  IF v_balance_a-v_reserved_a <> 9 OR v_balance_b-v_reserved_b <> 25 THEN
    RAISE EXCEPTION 'available balance calculation crossed canonical ledger keys';
  END IF;

  -- A display-symbol rename must not change the financial ledger key.
  UPDATE public.canonical_asset_ledger_key_map
  SET display_symbol='ABC-NEW' WHERE canonical_asset_id=v_asset_a;
  IF public.resolve_canonical_ledger_asset_key(v_asset_a) <> v_key_a THEN
    RAISE EXCEPTION 'display rename changed the resolved ledger key';
  END IF;

  -- Once financial rows reference a key, reassignment must fail closed.
  BEGIN
    UPDATE public.canonical_asset_ledger_key_map
    SET ledger_asset_key='asset:22000000-0000-0000-0000-0000000000f5'
    WHERE canonical_asset_id=v_asset_a;
    RAISE EXCEPTION 'referenced ledger key reassignment unexpectedly accepted';
  EXCEPTION WHEN SQLSTATE '23514' THEN
    IF SQLERRM NOT LIKE '%immutable after financial use%' THEN RAISE; END IF;
  END;

  IF public.resolve_canonical_ledger_asset_key(v_asset_a) <> v_key_a THEN
    RAISE EXCEPTION 'failed reassignment changed the canonical ledger mapping';
  END IF;

  -- A mapping cannot be deleted while balances or reservations still refer to it.
  BEGIN
    DELETE FROM public.canonical_asset_ledger_key_map
    WHERE canonical_asset_id=v_asset_a;
    RAISE EXCEPTION 'referenced ledger mapping deletion unexpectedly accepted';
  EXCEPTION WHEN SQLSTATE '23514' THEN
    IF SQLERRM NOT LIKE '%cannot be deleted after financial use%' THEN RAISE; END IF;
  END;

  IF public.resolve_canonical_ledger_asset_key(v_asset_a) <> v_key_a THEN
    RAISE EXCEPTION 'failed deletion changed the canonical ledger mapping';
  END IF;
END;
$test$;

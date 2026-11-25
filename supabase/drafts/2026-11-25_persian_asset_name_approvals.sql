-- DigiArz: proposed Persian asset-name approval storage and admin RPC
-- STATUS: REVIEW-ONLY DRAFT. This file is intentionally under supabase/drafts/,
-- not supabase/migrations/. It is NOT picked up by Supabase migration push.
-- DO NOT execute on Production or any connected database without explicit approval.
--
-- Live audit facts (read-only, 2026-11-25):
--   * public.exchange_asset_observations has 13 columns, 5 constraints,
--     4 indexes, one trigger, RLS enabled, no policies.
--   * anon/authenticated have no table privileges; service_role has DML.
--   * 4,970 observations exist; 0 contain the new candidate envelope.
--   * Existing trigger private.auto_list_verified_exchange_asset() inserts into
--     admin_market_listings only when an observation becomes matched+active.
--     This approval table is deliberately NOT wired to that trigger.
--   * The historical create_exchange_asset_observations migration is recorded
--     in Supabase's ledger but its SQL file is absent from the inspected branch
--     and no Git commit history for that exact path was found.
--
-- Compatibility contract with src/persian-asset-names.mjs:
--   { coingecko_id, status: "approved", approved_by, approved_at, name_fa }
-- One current approved Persian display name per exact CoinGecko asset identity.
--
-- Security design:
--   * No direct anon/authenticated table access.
--   * Authenticated caller can invoke only admin read/write RPCs.
--   * RPCs check private.is_current_user_super_admin(); write RPC derives
--     approved_by from auth.uid(); caller cannot nominate another approver.
--   * service_role remains trusted backend-only access, not an end-user route.

BEGIN;

CREATE TABLE public.crypto_asset_persian_name_approvals (
  coingecko_id text PRIMARY KEY
    REFERENCES public.crypto_assets (coingecko_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  name_fa text NOT NULL
    CHECK (char_length(btrim(name_fa)) BETWEEN 1 AND 80)
    CHECK (name_fa ~ '[ء-ی]'),
  status text NOT NULL DEFAULT 'approved'
    CHECK (status = 'approved'),
  approved_by uuid NOT NULL
    REFERENCES auth.users (id)
    ON DELETE RESTRICT,
  approved_at timestamptz NOT NULL DEFAULT now(),
  source_snapshot jsonb NOT NULL DEFAULT '[]'::jsonb
    CHECK (jsonb_typeof(source_snapshot) = 'array'),
  approval_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.crypto_asset_persian_name_approvals IS
  'Explicitly approved Persian display names; consensus candidates are never approvals.';
COMMENT ON COLUMN public.crypto_asset_persian_name_approvals.source_snapshot IS
  'Approval-time evidence snapshot: source exchange, source key, spelling and source URL.';
COMMENT ON COLUMN public.crypto_asset_persian_name_approvals.approved_by IS
  'Auth user UUID derived from auth.uid() by the administrator-only RPC.';

ALTER TABLE public.crypto_asset_persian_name_approvals ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.crypto_asset_persian_name_approvals FROM PUBLIC;
REVOKE ALL ON TABLE public.crypto_asset_persian_name_approvals FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.crypto_asset_persian_name_approvals
  TO service_role;

-- Do not expose a generic write path. The application uses the guarded RPCs.
CREATE OR REPLACE FUNCTION public.admin_approve_persian_asset_name(
  p_coingecko_id text,
  p_name_fa text,
  p_source_snapshot jsonb DEFAULT '[]'::jsonb,
  p_approval_note text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_actor uuid := auth.uid();
BEGIN
  IF v_actor IS NULL OR NOT coalesce(private.is_current_user_super_admin(), false) THEN
    RAISE EXCEPTION 'Super administrator access required'
      USING ERRCODE = '42501';
  END IF;

  IF nullif(btrim(p_coingecko_id), '') IS NULL THEN
    RAISE EXCEPTION 'CoinGecko ID is required' USING ERRCODE = '22023';
  END IF;

  IF p_name_fa IS NULL
     OR char_length(btrim(p_name_fa)) NOT BETWEEN 1 AND 80
     OR p_name_fa !~ '[ء-ی]' THEN
    RAISE EXCEPTION 'A valid Persian display name is required'
      USING ERRCODE = '22023';
  END IF;

  IF p_source_snapshot IS NULL OR jsonb_typeof(p_source_snapshot) <> 'array' THEN
    RAISE EXCEPTION 'Source snapshot must be a JSON array'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.crypto_asset_persian_name_approvals (
    coingecko_id, name_fa, status, approved_by, approved_at,
    source_snapshot, approval_note, updated_at
  )
  VALUES (
    btrim(p_coingecko_id), btrim(p_name_fa), 'approved', v_actor, now(),
    p_source_snapshot, nullif(btrim(p_approval_note), ''), now()
  )
  ON CONFLICT (coingecko_id) DO UPDATE
  SET name_fa = EXCLUDED.name_fa,
      status = 'approved',
      approved_by = EXCLUDED.approved_by,
      approved_at = EXCLUDED.approved_at,
      source_snapshot = EXCLUDED.source_snapshot,
      approval_note = EXCLUDED.approval_note,
      updated_at = now();
END;
$function$;

-- The admin UI needs a read path too. Direct SELECT remains revoked; this
-- paginated RPC exposes approved rows only after the same super-admin check.
CREATE OR REPLACE FUNCTION public.admin_list_persian_asset_name_approvals(
  p_limit integer DEFAULT 200,
  p_offset integer DEFAULT 0
)
RETURNS TABLE (
  coingecko_id text,
  name_fa text,
  approved_by uuid,
  approved_at timestamptz,
  source_snapshot jsonb,
  approval_note text,
  updated_at timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF auth.uid() IS NULL OR NOT coalesce(private.is_current_user_super_admin(), false) THEN
    RAISE EXCEPTION 'Super administrator access required'
      USING ERRCODE = '42501';
  END IF;

  IF p_limit IS NULL OR p_limit NOT BETWEEN 1 AND 500
     OR p_offset IS NULL OR p_offset < 0 THEN
    RAISE EXCEPTION 'Invalid pagination arguments'
      USING ERRCODE = '22023';
  END IF;

  RETURN QUERY
  SELECT a.coingecko_id, a.name_fa, a.approved_by, a.approved_at,
         a.source_snapshot, a.approval_note, a.updated_at
  FROM public.crypto_asset_persian_name_approvals AS a
  ORDER BY a.updated_at DESC, a.coingecko_id
  LIMIT p_limit OFFSET p_offset;
END;
$function$;

REVOKE ALL ON FUNCTION public.admin_approve_persian_asset_name(text, text, jsonb, text)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.admin_approve_persian_asset_name(text, text, jsonb, text)
  TO authenticated;

REVOKE ALL ON FUNCTION public.admin_list_persian_asset_name_approvals(integer, integer)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.admin_list_persian_asset_name_approvals(integer, integer)
  TO authenticated;

-- Review checklist before this draft can become an executable migration:
-- [ ] Verify both function owners are trusted migration owners (normally postgres).
-- [ ] Confirm authenticated has USAGE on public and private, and EXECUTE on the
--     existing private.is_current_user_super_admin() predicate.
-- [ ] Add regression tests: anon denied; non-admin authenticated denied;
--     admin can list and approve; approved_by always equals auth.uid(); invalid
--     names/snapshots/pagination rejected; duplicate approvals update only through
--     the guarded RPCs; direct table SELECT/INSERT/UPDATE/DELETE denied.
-- [ ] Decide and enforce a source_snapshot schema and maximum serialized size.
-- [ ] Ensure the UI reads this approved table through the admin list RPC, never
--     from consensus candidates or direct table access.
-- [ ] Reconcile the missing historical create_exchange_asset_observations SQL
--     source and migration-ledger drift before any db push.
-- [ ] Verify on a disposable PostgreSQL/Supabase test project.
-- [ ] Obtain explicit owner approval before converting this draft into a migration
--     or applying it to any database.

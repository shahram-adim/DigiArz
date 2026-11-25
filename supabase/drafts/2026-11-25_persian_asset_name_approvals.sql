-- DigiArz: proposed Persian asset-name approval storage
-- STATUS: REVIEW-ONLY DRAFT. This file is intentionally under supabase/drafts/,
-- not supabase/migrations/. It is NOT picked up by Supabase migration push.
-- DO NOT execute on Production or any connected database without explicit approval.
--
-- Rationale:
--   * exchange_asset_observations already stores raw source payloads and remains
--     service_role-only; no direct anon/authenticated table grants or RLS policies.
--   * Candidate extraction currently embeds a candidate envelope in source_payload.
--     A live read-only count found 0/4,970 observations with that envelope, so this
--     table must not be populated until an explicitly authorized future sync.
--   * Consensus is not approval. Only a separately reviewed administrator action
--     may insert/update an approved name.
--
-- Compatibility contract with src/persian-asset-names.mjs:
--   { coingecko_id, status: "approved", approved_by, approved_at, name_fa }
--
-- Proposed object: public.crypto_asset_persian_name_approvals
-- One current approved Persian display name per exact CoinGecko asset identity.

BEGIN;

CREATE TABLE public.crypto_asset_persian_name_approvals (
  coingecko_id text PRIMARY KEY
    REFERENCES public.crypto_assets (coingecko_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  name_fa text NOT NULL
    CHECK (char_length(btrim(name_fa)) BETWEEN 1 AND 80),
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
  'Immutable-at-approval evidence snapshot with source exchange, source key, spelling and source URL.';
COMMENT ON COLUMN public.crypto_asset_persian_name_approvals.approved_by IS
  'Auth user UUID of the administrator who explicitly approved this display name.';

-- Match the existing observation-table access model: RLS on, no policies,
-- no direct application-role table grants; only the trusted service role gets DML.
ALTER TABLE public.crypto_asset_persian_name_approvals ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.crypto_asset_persian_name_approvals FROM PUBLIC;
REVOKE ALL ON TABLE public.crypto_asset_persian_name_approvals FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.crypto_asset_persian_name_approvals
  TO service_role;

COMMIT;

-- Review checklist before this draft can become an executable migration:
-- [ ] Confirm an approved-name write endpoint verifies private.is_super_admin()
--     from the authenticated caller; never trust caller-supplied approved_by.
-- [ ] Ensure that endpoint snapshots only source-attributed evidence and never
--     converts consensus_candidate/single_source/review_required into approval.
-- [ ] Add regression tests for anon/authenticated denial and service-role access.
-- [ ] Verify the target PostgreSQL version and schema state in a disposable DB.
-- [ ] Reconcile the missing historical create_exchange_asset_observations SQL
--     source and the Supabase migration-ledger drift before any db push.
-- [ ] Obtain explicit owner approval before converting this draft into a migration
--     or applying it to any database.

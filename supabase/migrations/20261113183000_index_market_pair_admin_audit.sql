CREATE INDEX IF NOT EXISTS market_pair_admin_audit_admin_user_idx
  ON private.market_pair_admin_audit(admin_user_id)
  WHERE admin_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS admin_market_listings_added_by_idx
  ON public.admin_market_listings(added_by)
  WHERE added_by IS NOT NULL;
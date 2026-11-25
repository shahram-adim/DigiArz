-- RECOVERED HISTORICAL PRODUCTION MIGRATION SOURCE
-- Migration version: 20261113154750
-- Name: add_admin_role_probe
-- Source: Production supabase_migrations.schema_migrations.statements (read-only retrieval, 2026-11-25).
-- STATUS: REVIEW-ONLY / HISTORICAL REFERENCE. NOT AN EXECUTABLE MIGRATION.
-- This file is intentionally under supabase/drafts/, not supabase/migrations/.
-- Do NOT run, replay, or copy into a migration directory without separate review
-- and explicit owner approval. This migration is already recorded as applied in Production.

create or replace function public.is_current_user_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null and private.is_super_admin();
$$;
revoke all on function public.is_current_user_super_admin() from public, anon;
grant execute on function public.is_current_user_super_admin() to authenticated;
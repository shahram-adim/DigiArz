-- RECOVERED HISTORICAL PRODUCTION MIGRATION SOURCE
-- Migration version: 20261115105956
-- Name: restrict_exchange_sync_worker_execution
-- Source: Production supabase_migrations.schema_migrations.statements (read-only retrieval, 2026-11-25).
-- STATUS: REVIEW-ONLY / HISTORICAL REFERENCE. NOT AN EXECUTABLE MIGRATION.
-- This file is intentionally under supabase/drafts/, not supabase/migrations/.
-- Do NOT run, replay, or copy into a migration directory without separate review
-- and explicit owner approval. This migration is already recorded as applied in Production.


revoke all on function public.request_iran_exchange_asset_sync() from public, anon, authenticated;
revoke all on function public.request_bit24_exchange_sync() from public, anon, authenticated;
revoke all on function public.process_iran_exchange_asset_sync() from public, anon, authenticated;
revoke all on function public.process_bit24_exchange_sync() from public, anon, authenticated;

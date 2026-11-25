-- RECOVERED HISTORICAL PRODUCTION MIGRATION SOURCE
-- Migration version: 20261115101709
-- Name: create_exchange_asset_observations
-- Source: Production supabase_migrations.schema_migrations.statements (read-only retrieval, 2026-11-25).
-- STATUS: REVIEW-ONLY / HISTORICAL REFERENCE. NOT AN EXECUTABLE MIGRATION.
-- This file is intentionally under supabase/drafts/, not supabase/migrations/.
-- Do NOT run, replay, or copy into a migration directory without separate review
-- and explicit owner approval. This migration is already recorded as applied in Production.

create table if not exists public.exchange_asset_observations (
  id bigint generated always as identity primary key,
  exchange text not null check (exchange in ('nobitex','wallex','bitpin','ramzinex','tabdeal','ompfinex','exir','bit24','balinex','abantether','okex','tetherland','kifpool')),
  market_symbol text not null,
  base_symbol text,
  quote_symbol text,
  asset_name text,
  coingecko_id text references public.crypto_assets(coingecko_id) on update cascade on delete set null,
  match_status text not null default 'pending' check (match_status in ('pending','matched','ambiguous','unmatched')),
  source_url text not null,
  source_payload jsonb,
  is_active boolean not null default true,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  unique(exchange, market_symbol)
);
create index if not exists exchange_asset_observations_symbol_idx
  on public.exchange_asset_observations (upper(base_symbol));
create index if not exists exchange_asset_observations_match_idx
  on public.exchange_asset_observations (match_status, last_seen_at desc);
alter table public.exchange_asset_observations enable row level security;
revoke all on public.exchange_asset_observations from anon, authenticated;
grant all on public.exchange_asset_observations to service_role;
comment on table public.exchange_asset_observations is 'Read-only exchange listing evidence. Never enables demo trading pairs; unmatched/ambiguous assets remain staged for review.';
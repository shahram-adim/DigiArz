-- RECOVERED HISTORICAL PRODUCTION MIGRATION SOURCE
-- Migration version: 20261113154323
-- Name: assign_confirmed_super_admin
-- Source: Production supabase_migrations.schema_migrations.statements (read-only retrieval, 2026-11-25).
-- STATUS: REVIEW-ONLY / HISTORICAL REFERENCE. NOT AN EXECUTABLE MIGRATION.
-- This file is intentionally under supabase/drafts/, not supabase/migrations/.
-- Do NOT run, replay, or copy into a migration directory without separate review
-- and explicit owner approval. This migration is already recorded as applied in Production.

begin;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create table if not exists private.admin_users (
  user_id uuid primary key references auth.users(id) on delete restrict,
  role text not null check (role = 'super_admin'),
  granted_at timestamptz not null default now(),
  granted_by uuid references auth.users(id) on delete restrict
);
alter table private.admin_users enable row level security;
revoke all on table private.admin_users from public, anon, authenticated;
create or replace function private.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from private.admin_users a
    where a.user_id = (select auth.uid())
      and a.role = 'super_admin'
  );
$$;
revoke all on function private.is_super_admin() from public, anon, authenticated;
insert into private.admin_users (user_id, role, granted_by)
select p.id, 'super_admin', p.id
from public.profiles p
where p.id = 'a9daf990-bd7f-4af8-a2cd-bff176688771'::uuid
  and p.is_active = true
  and (select count(*) from public.profiles) = 1
on conflict (user_id) do update set role = excluded.role;
commit;
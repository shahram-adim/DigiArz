-- DigiArz daily image advertisements
-- REVIEW ONLY: keep this under supabase/drafts until explicitly approved.
-- Do not apply to Production without a separate release approval.

create table if not exists public.daily_ads (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 1 and 90),
  body text not null check (char_length(btrim(body)) between 1 and 400),
  image_path text not null check (image_path like 'daily-ads/%'),
  is_active boolean not null default false,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_by uuid not null default auth.uid() references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint daily_ads_valid_window check (ends_at is null or ends_at > starts_at)
);

create index if not exists daily_ads_public_schedule_idx
  on public.daily_ads (starts_at desc)
  where is_active = true;

alter table public.daily_ads enable row level security;

drop policy if exists daily_ads_public_active_read on public.daily_ads;
create policy daily_ads_public_active_read
  on public.daily_ads
  for select
  to anon, authenticated
  using (
    is_active = true
    and starts_at <= now()
    and (ends_at is null or ends_at > now())
  );

drop policy if exists daily_ads_super_admin_manage on public.daily_ads;
create policy daily_ads_super_admin_manage
  on public.daily_ads
  for all
  to authenticated
  using (public.is_current_user_super_admin())
  with check (public.is_current_user_super_admin());

-- Supabase's 2026 Data API exposure defaults require explicit table grants.
grant select on public.daily_ads to anon, authenticated;
grant insert, update, delete on public.daily_ads to authenticated;

-- Public bucket: images are publicly viewable, but only super-admins can upload/delete.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'daily-ad-images',
  'daily-ad-images',
  true,
  3145728,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists daily_ad_images_super_admin_upload on storage.objects;
create policy daily_ad_images_super_admin_upload
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'daily-ad-images'
    and public.is_current_user_super_admin()
  );

drop policy if exists daily_ad_images_super_admin_delete on storage.objects;
create policy daily_ad_images_super_admin_delete
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'daily-ad-images'
    and public.is_current_user_super_admin()
  );

comment on table public.daily_ads is
  'Admin-managed DigiArz daily advertisements. Public can read only active ads within their schedule; only super-admins can manage rows.';

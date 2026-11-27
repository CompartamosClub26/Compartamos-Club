-- Compartamos Club · MVP Pareja Bogotá
-- Migration 0001: private member data, consent and role separation.
begin;

create schema if not exists private;

create table if not exists public.member_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null check (char_length(trim(nickname)) between 2 and 40),
  city text not null default 'Bogotá' check (city = 'Bogotá'),
  birth_date date not null,
  bio text null check (bio is null or char_length(bio) <= 500),
  interests text[] not null default '{}',
  seeking text not null default 'pareja' check (seeking = 'pareja'),
  review_status text not null default 'pending' check (review_status in ('pending','approved','rejected','suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint member_is_adult check (birth_date <= (current_date - interval '18 years')::date)
);

create table if not exists private.staff_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('director','technical_admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.member_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  consent_type text not null check (consent_type in ('terms','privacy','community_safety','profile_visibility')),
  version text not null,
  accepted boolean not null,
  accepted_at timestamptz not null default now()
);

create table if not exists private.audit_events (
  id bigint generated always as identity primary key,
  actor_user_id uuid null,
  event_type text not null,
  subject_user_id uuid null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function private.is_director()
returns boolean language sql stable security definer
set search_path = '' as $$
  select exists (
    select 1 from private.staff_roles r
    where r.user_id = (select auth.uid()) and r.role = 'director'
  );
$$;

create or replace function private.prevent_profile_privilege_escalation()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.user_id <> old.user_id
     or new.review_status <> old.review_status
     or new.created_at <> old.created_at then
    raise exception 'Los campos protegidos solo pueden modificarse mediante revisión del Director';
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists protect_member_profile_fields on public.member_profiles;
create trigger protect_member_profile_fields
before update on public.member_profiles
for each row execute function private.prevent_profile_privilege_escalation();

alter table public.member_profiles enable row level security;
alter table public.member_consents enable row level security;
alter table private.staff_roles enable row level security;
alter table private.audit_events enable row level security;

drop policy if exists "members read own profile" on public.member_profiles;
create policy "members read own profile" on public.member_profiles
for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "director reads profiles" on public.member_profiles;
create policy "director reads profiles" on public.member_profiles
for select to authenticated using (private.is_director());

drop policy if exists "members create own pending profile" on public.member_profiles;
create policy "members create own pending profile" on public.member_profiles
for insert to authenticated with check (
  user_id = (select auth.uid()) and review_status = 'pending' and city = 'Bogotá' and seeking = 'pareja'
  and birth_date <= (current_date - interval '18 years')::date
);

drop policy if exists "members update own profile" on public.member_profiles;
create policy "members update own profile" on public.member_profiles
for update to authenticated using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists "director updates review status" on public.member_profiles;
create policy "director updates review status" on public.member_profiles
for update to authenticated using (private.is_director()) with check (private.is_director());

drop policy if exists "members read own consents" on public.member_consents;
create policy "members read own consents" on public.member_consents
for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "members record own consents" on public.member_consents;
create policy "members record own consents" on public.member_consents
for insert to authenticated with check (user_id = (select auth.uid()));

-- Staff roles and audit events are intentionally inaccessible to ordinary clients.
revoke all on schema private from public, anon, authenticated;
revoke all on all tables in schema private from public, anon, authenticated;
grant usage on schema private to authenticated;
grant execute on function private.is_director() to authenticated;

grant select, insert, update on public.member_profiles to authenticated;
grant select, insert on public.member_consents to authenticated;
revoke all on public.member_profiles from anon;
revoke all on public.member_consents from anon;

commit;

-- Compartamos Club · Módulo 1 · MVP Buscar pareja Bogotá
-- Esquema alineado con el diseño técnico aprobado del 14-11-2026.
-- No ejecutar hasta confirmar el proyecto Supabase destino y revisar los textos legales.
begin;

create extension if not exists pgcrypto;
create schema if not exists private;

do $$ begin
  create type public.profile_status as enum
    ('borrador','pendiente','aprobado','rechazado','suspendido','baja_solicitada');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.staff_role as enum ('director','admin_tecnico');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.consent_type as enum
    ('condiciones','convivencia','privacidad','mayoria_edad','contacto','foto');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.verification_method as enum ('manual','sms');
exception when duplicate_object then null; end $$;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  alias text not null check (char_length(trim(alias)) between 2 and 40),
  ciudad text not null default 'Bogotá' check (ciudad = 'Bogotá'),
  rango_edad text not null check (rango_edad in ('18–24','25–34','35–44','45–54','55 o más')),
  estado public.profile_status not null default 'borrador',
  motivo_estado text,
  telefono_verificado_en timestamptz,
  metodo_verificacion public.verification_method,
  enviado_en timestamptz,
  revisado_por uuid,
  revisado_en timestamptz,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  constraint verification_pair check (
    (telefono_verificado_en is null and metodo_verificacion is null)
    or (telefono_verificado_en is not null and metodo_verificacion is not null)
  )
);
create index if not exists profiles_review_queue_idx
  on public.profiles (estado, enviado_en) where estado = 'pendiente';

create table if not exists public.profile_interests (
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  interes text not null check (interes in (
    'Senderismo','Café y conversación','Fútbol','Cerámica y arte','Juegos de mesa',
    'Fotografía','Baile','Lectura','Cocina','Ciclismo','Idiomas','Voluntariado','Yoga','Cine'
  )),
  primary key (user_id, interes)
);

create table if not exists public.profile_goals (
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  objetivo text not null check (objetivo = 'pareja'),
  primary key (user_id, objetivo)
);

create table if not exists public.consent_documents (
  id uuid primary key default gen_random_uuid(),
  tipo public.consent_type not null,
  version text not null,
  sha256 text not null check (sha256 ~ '^[a-f0-9]{64}$'),
  vigente_desde timestamptz not null default now(),
  unique (tipo, version)
);

create table if not exists public.user_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  document_id uuid not null references public.consent_documents(id),
  aceptado_en timestamptz not null default now(),
  retirado_en timestamptz,
  unique (user_id, document_id)
);
create index if not exists user_consents_user_idx on public.user_consents(user_id);

create table if not exists private.user_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.staff_role not null,
  created_at timestamptz not null default now(),
  primary key (user_id, role)
);

create table if not exists private.audit_log (
  id bigint generated always as identity primary key,
  actor_id uuid,
  accion text not null,
  entidad text not null,
  entidad_id uuid,
  campos text[] not null default '{}',
  estado_antes text,
  estado_despues text,
  en timestamptz not null default now()
);

create or replace function private.has_role(p_user uuid, p_role public.staff_role)
returns boolean language sql stable security definer
set search_path = ''
as $$
  select exists(select 1 from private.user_roles r where r.user_id = p_user and r.role = p_role);
$$;

create or replace function private.is_director()
returns boolean language sql stable security definer
set search_path = ''
as $$ select private.has_role((select auth.uid()), 'director'::public.staff_role); $$;

create or replace function private.guard_profile_update()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if (select auth.uid()) is distinct from old.user_id and not private.is_director() then
    raise exception 'Acceso denegado';
  end if;
  if not private.is_director() and (
    new.estado is distinct from old.estado
    or new.motivo_estado is distinct from old.motivo_estado
    or new.telefono_verificado_en is distinct from old.telefono_verificado_en
    or new.metodo_verificacion is distinct from old.metodo_verificacion
    or new.revisado_por is distinct from old.revisado_por
    or new.revisado_en is distinct from old.revisado_en
    or new.enviado_en is distinct from old.enviado_en
    or new.user_id is distinct from old.user_id
  ) then
    raise exception 'Los campos de revisión solo los modifica el Director';
  end if;
  if not private.is_director() and (
    new.alias is distinct from old.alias
    or new.ciudad is distinct from old.ciudad
    or new.rango_edad is distinct from old.rango_edad
  ) and old.estado = 'aprobado' then
    new.estado := 'pendiente';
    new.enviado_en := now();
    new.revisado_por := null;
    new.revisado_en := null;
  end if;
  new.actualizado_en := now();
  return new;
end;
$$;
drop trigger if exists profiles_guard_update on public.profiles;
create trigger profiles_guard_update before update on public.profiles
for each row execute function private.guard_profile_update();

create or replace function private.audit_profile_status()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if old.estado is distinct from new.estado then
    insert into private.audit_log(actor_id, accion, entidad, entidad_id, campos, estado_antes, estado_despues)
    values ((select auth.uid()), 'cambio_estado', 'profiles', new.user_id, array['estado'], old.estado::text, new.estado::text);
  end if;
  return new;
end;
$$;
drop trigger if exists profiles_audit_status on public.profiles;
create trigger profiles_audit_status after update on public.profiles
for each row execute function private.audit_profile_status();

create or replace function public.moderacion_cola()
returns table (
  user_id uuid, alias text, ciudad text, rango_edad text, estado public.profile_status,
  enviado_en timestamptz, telefono_verificado boolean
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not private.is_director() then raise exception 'Acceso denegado'; end if;
  return query
    select p.user_id, p.alias, p.ciudad, p.rango_edad, p.estado, p.enviado_en,
           (p.telefono_verificado_en is not null)
    from public.profiles p where p.estado = 'pendiente'
    order by p.enviado_en nulls last;
end;
$$;

create or replace function public.enviar_revision()
returns void language plpgsql security definer set search_path = ''
as $
declare v_user uuid := (select auth.uid());
begin
  if v_user is null then raise exception 'Autenticación requerida'; end if;
  if not exists (select 1 from public.profiles p where p.user_id = v_user and p.estado in ('borrador','rechazado')) then
    raise exception 'Perfil no disponible para enviar';
  end if;
  if not exists (select 1 from public.profile_interests i where i.user_id = v_user)
     or not exists (select 1 from public.profile_goals g where g.user_id = v_user and g.objetivo = 'pareja') then
    raise exception 'Completa intereses y objetivo Buscar pareja';
  end if;
  if (
    select count(distinct cd.tipo)
    from public.user_consents uc
    join public.consent_documents cd on cd.id = uc.document_id
    where uc.user_id = v_user and uc.retirado_en is null
      and cd.tipo in ('condiciones','convivencia','privacidad','mayoria_edad')
      and cd.vigente_desde <= now()
  ) <> 4 then
    raise exception 'Faltan consentimientos vigentes obligatorios';
  end if;
  update public.profiles set estado = 'pendiente', enviado_en = now(), motivo_estado = null
  where user_id = v_user;
end;
$;

create or replace function public.marcar_telefono_verificado(p_user_id uuid, p_metodo public.verification_method)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if not private.is_director() or p_user_id = (select auth.uid()) then raise exception 'Acceso denegado'; end if;
  update public.profiles set telefono_verificado_en = now(), metodo_verificacion = p_metodo
  where user_id = p_user_id and estado = 'pendiente';
  if not found then raise exception 'Perfil no disponible para verificación'; end if;
  insert into private.audit_log(actor_id, accion, entidad, entidad_id, campos)
  values ((select auth.uid()), 'telefono_verificado', 'profiles', p_user_id, array['telefono_verificado_en','metodo_verificacion']);
end;
$$;

create or replace function public.resolver_revision(p_user_id uuid, p_estado public.profile_status, p_motivo text default null)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if not private.is_director() or p_user_id = (select auth.uid()) then raise exception 'Acceso denegado'; end if;
  if p_estado not in ('aprobado','rechazado','suspendido') then raise exception 'Transición no permitida'; end if;
  if p_estado = 'aprobado' and not exists (
    select 1 from public.profiles p where p.user_id = p_user_id
      and p.estado = 'pendiente' and p.telefono_verificado_en is not null
      and (select count(distinct cd.tipo)
        from public.user_consents uc join public.consent_documents cd on cd.id = uc.document_id
        where uc.user_id = p_user_id and uc.retirado_en is null
          and cd.tipo in ('condiciones','convivencia','privacidad','mayoria_edad')
          and cd.vigente_desde <= now()) = 4
  ) then raise exception 'Faltan verificación telefónica o consentimientos vigentes'; end if;
  update public.profiles set estado = p_estado, motivo_estado = p_motivo,
    revisado_por = (select auth.uid()), revisado_en = now()
  where user_id = p_user_id
    and ((p_estado in ('aprobado','rechazado') and estado = 'pendiente')
      or (p_estado = 'suspendido' and estado = 'aprobado'));
  if not found then raise exception 'Transición de estado no permitida'; end if;
end;
$$;

alter table public.profiles enable row level security;
alter table public.profile_interests enable row level security;
alter table public.profile_goals enable row level security;
alter table public.consent_documents enable row level security;
alter table public.user_consents enable row level security;
alter table private.user_roles enable row level security;
alter table private.audit_log enable row level security;

drop policy if exists profiles_self_select on public.profiles;
create policy profiles_self_select on public.profiles for select to authenticated
using (user_id = (select auth.uid()));
drop policy if exists profiles_self_insert on public.profiles;
create policy profiles_self_insert on public.profiles for insert to authenticated
with check (
  user_id = (select auth.uid()) and estado = 'borrador' and ciudad = 'Bogotá'
  and motivo_estado is null and telefono_verificado_en is null
  and metodo_verificacion is null and enviado_en is null
  and revisado_por is null and revisado_en is null
);
drop policy if exists profiles_self_update on public.profiles;
create policy profiles_self_update on public.profiles for update to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists interests_self_all on public.profile_interests;
create policy interests_self_all on public.profile_interests for all to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists goals_self_all on public.profile_goals;
create policy goals_self_all on public.profile_goals for all to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists consents_self_select on public.user_consents;
create policy consents_self_select on public.user_consents for select to authenticated
using (user_id = (select auth.uid()));
drop policy if exists consents_self_insert on public.user_consents;
create policy consents_self_insert on public.user_consents for insert to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists documents_read on public.consent_documents;
create policy documents_read on public.consent_documents for select to anon, authenticated using (true);

revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;
revoke all on all tables in schema private from public, anon, authenticated;
revoke all on function private.has_role(uuid, public.staff_role) from public, anon, authenticated;
revoke all on function private.is_director() from public, anon;
grant execute on function private.is_director() to authenticated;
revoke all on function public.moderacion_cola() from public, anon;
revoke all on function public.enviar_revision() from public, anon;
revoke all on function public.marcar_telefono_verificado(uuid, public.verification_method) from public, anon;
revoke all on function public.resolver_revision(uuid, public.profile_status, text) from public, anon;
grant execute on function public.moderacion_cola() to authenticated;
grant execute on function public.enviar_revision() to authenticated;
grant execute on function public.marcar_telefono_verificado(uuid, public.verification_method) to authenticated;
grant execute on function public.resolver_revision(uuid, public.profile_status, text) to authenticated;

grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.profile_interests to authenticated;
grant select, insert, update, delete on public.profile_goals to authenticated;
grant select on public.consent_documents to anon, authenticated;
grant select, insert on public.user_consents to authenticated;
revoke all on public.profiles, public.profile_interests, public.profile_goals, public.user_consents from anon;

-- No roles are seeded. The first Director must be provisioned by the project owner
-- through a controlled SQL operation after identity verification.
commit;

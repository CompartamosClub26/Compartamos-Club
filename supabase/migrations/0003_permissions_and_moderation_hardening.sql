-- Compartamos Club · Módulo 1 · Endurecimiento de permisos y moderación
-- Aplicar después de 0002_profile_insert_hardening.sql.
-- No crea usuarios, roles ni documentos legales.

begin;

-- Intereses y objetivos: lectura propia; escritura solo mientras el perfil
-- puede editarse. Un perfil pendiente no puede cambiar sus datos mientras espera.
drop policy if exists interests_self_all on public.profile_interests;
drop policy if exists interests_self_select on public.profile_interests;
drop policy if exists interests_self_insert on public.profile_interests;
drop policy if exists interests_self_update on public.profile_interests;
drop policy if exists interests_self_delete on public.profile_interests;

create policy interests_self_select on public.profile_interests
for select to authenticated using (user_id = (select auth.uid()));
create policy interests_self_insert on public.profile_interests
for insert to authenticated with check (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.user_id = (select auth.uid())
      and p.estado in ('borrador','rechazado','aprobado')
  )
);
create policy interests_self_update on public.profile_interests
for update to authenticated using (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.user_id = (select auth.uid())
      and p.estado in ('borrador','rechazado','aprobado')
  )
) with check (user_id = (select auth.uid()));
create policy interests_self_delete on public.profile_interests
for delete to authenticated using (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.user_id = (select auth.uid())
      and p.estado in ('borrador','rechazado','aprobado')
  )
);

drop policy if exists goals_self_all on public.profile_goals;
drop policy if exists goals_self_select on public.profile_goals;
drop policy if exists goals_self_insert on public.profile_goals;
drop policy if exists goals_self_update on public.profile_goals;
drop policy if exists goals_self_delete on public.profile_goals;

create policy goals_self_select on public.profile_goals
for select to authenticated using (user_id = (select auth.uid()));
create policy goals_self_insert on public.profile_goals
for insert to authenticated with check (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.user_id = (select auth.uid())
      and p.estado in ('borrador','rechazado','aprobado')
  )
);
create policy goals_self_update on public.profile_goals
for update to authenticated using (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.user_id = (select auth.uid())
      and p.estado in ('borrador','rechazado','aprobado')
  )
) with check (user_id = (select auth.uid()));
create policy goals_self_delete on public.profile_goals
for delete to authenticated using (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.user_id = (select auth.uid())
      and p.estado in ('borrador','rechazado','aprobado')
  )
);

-- Consentimientos: el miembro solo puede consultar, aceptar y retirar;
-- no puede borrar ni reescribir la fecha/documento de una aceptación.
drop policy if exists consents_self_select on public.user_consents;
drop policy if exists consents_self_insert on public.user_consents;
drop policy if exists consents_self_update on public.user_consents;
create policy consents_self_select on public.user_consents
for select to authenticated using (user_id = (select auth.uid()));
create policy consents_self_insert on public.user_consents
for insert to authenticated with check (user_id = (select auth.uid()));
create policy consents_self_update on public.user_consents
for update to authenticated using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));
revoke delete on public.user_consents from authenticated;
revoke update on public.user_consents from authenticated;
grant update (retirado_en) on public.user_consents to authenticated;

-- El miembro puede saber si su propia cuenta tiene un rol interno,
-- pero nunca puede asignarse ni modificar roles.
drop policy if exists user_roles_self_select on private.user_roles;
create policy user_roles_self_select on private.user_roles
for select to authenticated using (user_id = (select auth.uid()));
revoke all on table private.user_roles from public, anon, authenticated;
grant select on table private.user_roles to authenticated;

-- El registro de auditoría permanece inaccesible directamente desde el cliente.
revoke all on table private.audit_log from public, anon, authenticated;

-- Cola del Director: devuelve solo los campos mínimos previstos para revisar
-- una solicitud, incluyendo intereses y objetivo; nunca correo/teléfono/fotos.
drop function if exists public.moderacion_cola();
create function public.moderacion_cola()
returns table (
  user_id uuid,
  alias text,
  ciudad text,
  rango_edad text,
  intereses text[],
  objetivos text[],
  estado public.profile_status,
  enviado_en timestamptz,
  telefono_verificado boolean
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not private.is_director() then raise exception 'Acceso denegado'; end if;
  return query
    select p.user_id, p.alias, p.ciudad, p.rango_edad,
      coalesce((select array_agg(i.interes order by i.interes)
        from public.profile_interests i where i.user_id = p.user_id), '{}'::text[]),
      coalesce((select array_agg(g.objetivo order by g.objetivo)
        from public.profile_goals g where g.user_id = p.user_id), '{}'::text[]),
      p.estado, p.enviado_en, (p.telefono_verificado_en is not null)
    from public.profiles p
    where p.estado = 'pendiente'
    order by p.enviado_en nulls last;
end;
$$;
revoke all on function public.moderacion_cola() from public, anon;
grant execute on function public.moderacion_cola() to authenticated;

commit;

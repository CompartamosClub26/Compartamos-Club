-- Compartamos Club · Reparación de la función de envío a revisión.
-- Aplicar en bases donde 0001 ya fue ejecutada antes de corregir su archivo fuente.
begin;

create or replace function public.enviar_revision()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
begin
  if v_user is null then
    raise exception 'Autenticación requerida';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.user_id = v_user and p.estado in ('borrador','rechazado')
  ) then
    raise exception 'Perfil no disponible para enviar';
  end if;

  if not exists (
    select 1 from public.profile_interests i where i.user_id = v_user
  ) or not exists (
    select 1 from public.profile_goals g
    where g.user_id = v_user and g.objetivo = 'pareja'
  ) then
    raise exception 'Completa intereses y objetivo Buscar pareja';
  end if;

  if (
    select count(distinct cd.tipo)
    from public.user_consents uc
    join public.consent_documents cd on cd.id = uc.document_id
    where uc.user_id = v_user
      and uc.retirado_en is null
      and cd.tipo in ('condiciones','convivencia','privacidad','mayoria_edad')
      and cd.vigente_desde <= now()
  ) <> 4 then
    raise exception 'Faltan consentimientos vigentes obligatorios';
  end if;

  update public.profiles
  set estado = 'pendiente', enviado_en = now(), motivo_estado = null
  where user_id = v_user;
end;
$$;

revoke all on function public.enviar_revision() from public, anon;
grant execute on function public.enviar_revision() to authenticated;

commit;

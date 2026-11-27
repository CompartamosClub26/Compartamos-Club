-- Compartamos Club · Módulo 1 · Retiro seguro de consentimientos
-- Reemplaza la actualización directa de retirado_en por una operación de servidor.
begin;

drop policy if exists consents_self_update on public.user_consents;
revoke update on public.user_consents from public, anon, authenticated;

create or replace function public.retirar_consentimiento(p_consent_id uuid)
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

  update public.user_consents
     set retirado_en = now()
   where id = p_consent_id
     and user_id = v_user
     and retirado_en is null;

  if not found then
    raise exception 'Consentimiento no disponible o ya retirado';
  end if;
end;
$$;

revoke all on function public.retirar_consentimiento(uuid) from public, anon;
grant execute on function public.retirar_consentimiento(uuid) to authenticated;

commit;

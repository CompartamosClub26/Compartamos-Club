-- Apply after 0001. Client cannot forge review/verification fields.
begin;

drop policy if exists profiles_self_insert on public.profiles;
create policy profiles_self_insert on public.profiles
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and estado = 'borrador'
  and ciudad = 'Bogotá'
  and motivo_estado is null
  and telefono_verificado_en is null
  and metodo_verificacion is null
  and enviado_en is null
  and revisado_por is null
  and revisado_en is null
);
revoke delete on public.profiles from authenticated;
revoke all on table private.user_roles from public, anon, authenticated;
revoke all on table private.audit_log from public, anon, authenticated;

create or replace function public.crear_perfil(
  p_alias text,
  p_rango_edad text,
  p_intereses text[],
  p_consent_document_ids uuid[]
) returns uuid
language plpgsql
security invoker
set search_path = ''
as $func$
declare v_user uuid := (select auth.uid());
begin
  if v_user is null then raise exception 'Autenticación requerida'; end if;
  if char_length(trim(p_alias)) not between 2 and 40 then raise exception 'Alias inválido'; end if;
  if p_rango_edad not in ('18–24','25–34','35–44','45–54','55 o más') then raise exception 'Rango de edad inválido'; end if;
  if coalesce(array_length(p_intereses,1),0) < 1 then raise exception 'Selecciona al menos un interés'; end if;
  if coalesce(array_length(p_consent_document_ids,1),0) <> 4 then raise exception 'Se requieren cuatro consentimientos'; end if;
  if exists (select 1 from public.profiles p where p.user_id = v_user) then raise exception 'Ya existe un perfil para esta cuenta'; end if;
  if (select count(distinct d.tipo) from public.consent_documents d
      where d.id = any(p_consent_document_ids)
        and d.tipo in ('condiciones','convivencia','privacidad','mayoria_edad')
        and d.vigente_desde <= now()) <> 4 then
    raise exception 'Los documentos de consentimiento no son válidos o no están vigentes';
  end if;

  insert into public.profiles(user_id, alias, ciudad, rango_edad, estado)
  values (v_user, trim(p_alias), 'Bogotá', p_rango_edad, 'borrador');

  insert into public.profile_interests(user_id, interes)
  select v_user, unnest(p_intereses);

  insert into public.profile_goals(user_id, objetivo) values (v_user, 'pareja');

  insert into public.user_consents(user_id, document_id)
  select v_user, unnest(p_consent_document_ids);

  return v_user;
end;
$func$;

revoke all on function public.crear_perfil(text,text,text[],uuid[]) from public, anon;
grant execute on function public.crear_perfil(text,text,text[],uuid[]) to authenticated;

commit;

-- Compartamos Club · Permitir envío seguro a revisión sin abrir cambios de estado.
-- La transición del titular solo se acepta desde borrador/rechazado y si cumple
-- los mismos requisitos de enviar_revision(). El trigger vuelve a validar todo.

begin;

create or replace function private.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_is_director boolean := private.is_director();
  v_submission boolean := false;
  v_personal_changed boolean := false;
begin
  if (select auth.uid()) is distinct from old.user_id and not v_is_director then
    raise exception 'Acceso denegado';
  end if;

  if new.creado_en is distinct from old.creado_en then
    raise exception 'La fecha de creación es inmutable';
  end if;

  v_personal_changed :=
    new.alias is distinct from old.alias
    or new.ciudad is distinct from old.ciudad
    or new.rango_edad is distinct from old.rango_edad;

  if v_is_director
     and (select auth.uid()) is not distinct from old.user_id
     and v_personal_changed then
    raise exception 'El Director no puede editar su propio perfil';
  end if;

  if not v_is_director then
    -- Única transición de estado permitida al titular: enviar a revisión.
    if new.estado is distinct from old.estado then
      if old.estado not in ('borrador','rechazado') or new.estado <> 'pendiente' then
        raise exception 'Transición de estado no permitida para el miembro';
      end if;

      if not exists (
        select 1 from public.profile_interests i where i.user_id = old.user_id
      ) or not exists (
        select 1 from public.profile_goals g
        where g.user_id = old.user_id and g.objetivo = 'pareja'
      ) then
        raise exception 'Completa intereses y objetivo Buscar pareja';
      end if;

      if (
        select count(distinct cd.tipo)
        from public.user_consents uc
        join public.consent_documents cd on cd.id = uc.document_id
        where uc.user_id = old.user_id
          and uc.retirado_en is null
          and cd.tipo in ('condiciones','convivencia','privacidad','mayoria_edad')
          and cd.vigente_desde <= now()
      ) <> 4 then
        raise exception 'Faltan consentimientos vigentes obligatorios';
      end if;

      v_submission := true;
      -- Los datos de revisión los controla el servidor, nunca el cliente.
      new.motivo_estado := null;
      new.revisado_por := null;
      new.revisado_en := null;
      new.enviado_en := now();
    end if;

    if new.telefono_verificado_en is distinct from old.telefono_verificado_en
       or new.metodo_verificacion is distinct from old.metodo_verificacion
       or new.user_id is distinct from old.user_id then
      raise exception 'Los campos de verificación y titularidad solo los modifica el Director';
    end if;

    if not v_submission and (
      new.estado is distinct from old.estado
      or new.motivo_estado is distinct from old.motivo_estado
      or new.revisado_por is distinct from old.revisado_por
      or new.revisado_en is distinct from old.revisado_en
      or new.enviado_en is distinct from old.enviado_en
    ) then
      raise exception 'Los campos de revisión solo los modifica el servidor';
    end if;

    if old.estado in ('pendiente','suspendido','baja_solicitada') and v_personal_changed then
      raise exception 'El perfil no puede modificarse en su estado actual';
    end if;

    if old.estado = 'aprobado' and v_personal_changed then
      new.estado := 'pendiente';
      new.enviado_en := now();
      new.motivo_estado := null;
      new.revisado_por := null;
      new.revisado_en := null;
    end if;
  end if;

  new.actualizado_en := now();
  return new;
end;
$$;

commit;

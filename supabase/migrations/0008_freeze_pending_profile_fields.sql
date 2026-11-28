-- Compartamos Club · Evitar cambios del titular mientras su perfil está pendiente.
-- El Director conserva sus operaciones de moderación; el miembro no puede alterar
-- alias, ciudad o rango de edad durante la revisión.

begin;

create or replace function private.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
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

  if not private.is_director() and old.estado = 'pendiente' and (
    new.alias is distinct from old.alias
    or new.ciudad is distinct from old.ciudad
    or new.rango_edad is distinct from old.rango_edad
  ) then
    raise exception 'El perfil no puede modificarse mientras está en revisión';
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

commit;

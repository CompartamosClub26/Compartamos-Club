-- Compartamos Club · Reducir privilegios directos sobre perfiles.
-- El cliente solo puede insertar los campos básicos del borrador y actualizar
-- alias/ciudad/rango. Estados, verificación, revisión y marcas de tiempo quedan
-- reservados a las funciones SECURITY DEFINER.

begin;

revoke insert, update on table public.profiles from public, anon, authenticated;

grant insert (user_id, alias, ciudad, rango_edad, estado)
  on table public.profiles to authenticated;

grant update (alias, ciudad, rango_edad)
  on table public.profiles to authenticated;

commit;

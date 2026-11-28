-- Compartamos Club · Excluir al propio Director de su cola de moderación.
-- Las funciones de resolución ya impiden autoaprobación; esta migración también
-- evita que el Director reciba su propio perfil como solicitud revisable.

begin;

create or replace function public.moderacion_cola()
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
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.is_director() then
    raise exception 'Acceso denegado';
  end if;

  return query
    select p.user_id, p.alias, p.ciudad, p.rango_edad,
      coalesce((select array_agg(i.interes order by i.interes)
        from public.profile_interests i where i.user_id = p.user_id), '{}'::text[]),
      coalesce((select array_agg(g.objetivo order by g.objetivo)
        from public.profile_goals g where g.user_id = p.user_id), '{}'::text[]),
      p.estado, p.enviado_en, (p.telefono_verificado_en is not null)
    from public.profiles p
    where p.estado = 'pendiente'
      and p.user_id <> (select auth.uid())
    order by p.enviado_en nulls last;
end;
$$;

revoke all on function public.moderacion_cola() from public, anon;
grant execute on function public.moderacion_cola() to authenticated;

commit;

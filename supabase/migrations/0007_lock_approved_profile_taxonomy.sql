-- Compartamos Club · Congelar intereses y objetivos al aprobar el perfil.
-- Solo borradores y perfiles rechazados pueden modificar la taxonomía.
-- Los perfiles aprobados, pendientes o suspendidos quedan congelados.

begin;

-- Retirar las políticas permisivas heredadas de 0001. PostgreSQL combina
-- políticas permisivas con OR; dejarlas activas anularía estas restricciones.
drop policy if exists interests_self_all on public.profile_interests;
drop policy if exists goals_self_all on public.profile_goals;

drop policy if exists interests_self_insert on public.profile_interests;
create policy interests_self_insert on public.profile_interests
for insert to authenticated with check (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.user_id = (select auth.uid())
      and p.estado in ('borrador','rechazado')
  )
);

drop policy if exists interests_self_update on public.profile_interests;
create policy interests_self_update on public.profile_interests
for update to authenticated using (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.user_id = (select auth.uid())
      and p.estado in ('borrador','rechazado')
  )
) with check (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.user_id = (select auth.uid())
      and p.estado in ('borrador','rechazado')
  )
);

drop policy if exists interests_self_delete on public.profile_interests;
create policy interests_self_delete on public.profile_interests
for delete to authenticated using (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.user_id = (select auth.uid())
      and p.estado in ('borrador','rechazado')
  )
);

drop policy if exists goals_self_insert on public.profile_goals;
create policy goals_self_insert on public.profile_goals
for insert to authenticated with check (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.user_id = (select auth.uid())
      and p.estado in ('borrador','rechazado')
  )
);

drop policy if exists goals_self_update on public.profile_goals;
create policy goals_self_update on public.profile_goals
for update to authenticated using (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.user_id = (select auth.uid())
      and p.estado in ('borrador','rechazado')
  )
) with check (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.user_id = (select auth.uid())
      and p.estado in ('borrador','rechazado')
  )
);

drop policy if exists goals_self_delete on public.profile_goals;
create policy goals_self_delete on public.profile_goals
for delete to authenticated using (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.user_id = (select auth.uid())
      and p.estado in ('borrador','rechazado')
  )
);

commit;

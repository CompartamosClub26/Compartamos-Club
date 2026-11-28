\set ON_ERROR_STOP on

begin;

insert into auth.users(id) values
  ('11111111-1111-4111-8111-111111111111'),
  ('22222222-2222-4222-8222-222222222222'),
  ('33333333-3333-4333-8333-333333333333'),
  ('44444444-4444-4444-8444-444444444444');

insert into public.consent_documents(id, tipo, version, sha256, vigente_desde) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1', 'condiciones', 'test-v1', repeat('a', 64), now() - interval '1 day'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2', 'convivencia', 'test-v1', repeat('b', 64), now() - interval '1 day'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3', 'privacidad', 'test-v1', repeat('c', 64), now() - interval '1 day'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa4', 'mayoria_edad', 'test-v1', repeat('d', 64), now() - interval '1 day');

insert into private.user_roles(user_id, role) values
  ('33333333-3333-4333-8333-333333333333', 'director'),
  ('44444444-4444-4444-8444-444444444444', 'admin_tecnico');

create or replace function public.test_assert_true(p_condition boolean, p_message text)
returns void
language plpgsql
as $$
begin
  if not coalesce(p_condition, false) then
    raise exception 'ASSERTION FAILED: %', p_message;
  end if;
end;
$$;

create or replace function public.test_expect_error(p_sql text, p_fragment text)
returns void
language plpgsql
as $$
declare
  v_message text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics v_message = message_text;
    if position(p_fragment in v_message) = 0 then
      raise exception 'Expected error containing "%", got "%"', p_fragment, v_message;
    end if;
    return;
  end;
  raise exception 'ASSERTION FAILED: expected error containing "%"', p_fragment;
end;
$$;

-- Member A creates a complete profile and submits it for review.
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
set local role authenticated;

select public.crear_perfil(
  'Miembro A',
  '35–44',
  array['Senderismo','Café y conversación'],
  array[
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'::uuid,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2'::uuid,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3'::uuid,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa4'::uuid
  ]
);

select public.enviar_revision();

select public.test_assert_true(
  (select estado::text = 'pendiente' from public.profiles where user_id = '11111111-1111-4111-8111-111111111111'),
  'enviar_revision debe llevar un perfil completo a pendiente'
);

-- Regression: the permissive legacy ALL policies must not survive migration 0007.
select public.test_assert_true(
  not exists (
    select 1 from pg_catalog.pg_policies
    where schemaname = 'public'
      and policyname in ('interests_self_all','goals_self_all')
  ),
  'las políticas permisivas heredadas de intereses y objetivos deben eliminarse'
);

-- A pending member must not insert, update or delete interests/goals.
do $pending_taxonomy$
declare
  v_rows integer;
begin
  insert into public.profile_interests(user_id, interes)
  values ('11111111-1111-4111-8111-111111111111', 'Fotografía');
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'ASSERTION FAILED: pending member inserted an interest';
  end if;

  update public.profile_interests set interes = 'Fotografía'
   where user_id = '11111111-1111-4111-8111-111111111111'
     and interes = 'Senderismo';
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'ASSERTION FAILED: pending member updated an interest';
  end if;

  delete from public.profile_interests
   where user_id = '11111111-1111-4111-8111-111111111111'
     and interes = 'Senderismo';
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'ASSERTION FAILED: pending member deleted an interest';
  end if;

  insert into public.profile_goals(user_id, objetivo)
  values ('11111111-1111-4111-8111-111111111111', 'pareja');
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'ASSERTION FAILED: pending member inserted a goal';
  end if;

  delete from public.profile_goals
   where user_id = '11111111-1111-4111-8111-111111111111'
     and objetivo = 'pareja';
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'ASSERTION FAILED: pending member deleted a goal';
  end if;
end;
$pending_taxonomy$;

select public.test_expect_error(
  $$update public.profiles set estado = 'aprobado' where user_id = '11111111-1111-4111-8111-111111111111'$$,
  'permission denied'
);

select public.test_expect_error(
  $$update public.profiles set alias = 'Cambio indebido' where user_id = '11111111-1111-4111-8111-111111111111'$$,
  'El perfil no puede modificarse en su estado actual'
);

select public.test_expect_error(
  $$update public.user_consents set aceptado_en = now() where user_id = '11111111-1111-4111-8111-111111111111'$$,
  'permission denied'
);

-- A member cannot see another member's profile.
select set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
select public.crear_perfil(
  'Miembro B',
  '45–54',
  array['Lectura'],
  array[
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'::uuid,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2'::uuid,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3'::uuid,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa4'::uuid
  ]
);
select public.test_assert_true(
  (select count(*) = 0 from public.profiles where user_id = '11111111-1111-4111-8111-111111111111'),
  'un miembro no debe leer el perfil de otro miembro'
);

-- The Director sees the minimum moderation queue, verifies A and approves A.
reset role;
select set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
set local role authenticated;

select public.test_assert_true(
  (select count(*) = 1 from public.moderacion_cola()),
  'el Director debe ver solo la solicitud pendiente de A'
);
select public.marcar_telefono_verificado('11111111-1111-4111-8111-111111111111', 'manual');
select public.resolver_revision('11111111-1111-4111-8111-111111111111', 'aprobado', null);
reset role;
select public.test_assert_true(
  (select estado::text = 'aprobado' from public.profiles where user_id = '11111111-1111-4111-8111-111111111111'),
  'el Director debe poder aprobar un perfil verificado con cuatro consentimientos'
);

-- A Director may not self-moderate or change their own profile status directly.
select set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
set local role authenticated;
select public.crear_perfil(
  'Director prueba',
  '55 o más',
  array['Lectura'],
  array[
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'::uuid,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2'::uuid,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3'::uuid,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa4'::uuid
  ]
);
select public.enviar_revision();
select public.test_expect_error(
  $$select public.resolver_revision('33333333-3333-4333-8333-333333333333', 'aprobado', null)$$,
  'Acceso denegado'
);
select public.test_expect_error(
  $$update public.profiles set estado = 'aprobado' where user_id = '33333333-3333-4333-8333-333333333333'$$,
  'permission denied'
);
select public.test_assert_true(
  (select count(*) = 0 from public.moderacion_cola()),
  'la cola del Director debe excluir su propio perfil'
);

-- Admin técnico cannot inspect profiles or call the Director queue.
reset role;
select set_config('request.jwt.claim.sub', '44444444-4444-4444-8444-444444444444', true);
set local role authenticated;

select public.test_assert_true(
  (select count(*) = 0 from public.profiles where user_id = '11111111-1111-4111-8111-111111111111'),
  'el administrador técnico no debe leer perfiles ajenos'
);
select public.test_expect_error(
  $$select * from public.moderacion_cola()$$,
  'Acceso denegado'
);

-- B submits without phone verification; the Director must not approve B.
reset role;
select set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
set local role authenticated;
select public.enviar_revision();

reset role;
select set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
set local role authenticated;
select public.test_expect_error(
  $$select public.resolver_revision('22222222-2222-4222-8222-222222222222', 'aprobado', null)$$,
  'Faltan verificación telefónica o consentimientos vigentes'
);

-- A's approved profile becomes pending when A edits a personal field.
reset role;
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
set local role authenticated;

do $$
declare
  v_rows integer;
begin
  update public.profile_interests
     set interes = 'Fotografía'
   where user_id = '11111111-1111-4111-8111-111111111111'
     and interes = 'Senderismo';
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'ASSERTION FAILED: approved interests must be frozen';
  end if;
end;
$$;

update public.profiles
   set alias = 'Miembro A actualizado'
 where user_id = '11111111-1111-4111-8111-111111111111';

select public.test_assert_true(
  (select estado::text = 'pendiente' from public.profiles where user_id = '11111111-1111-4111-8111-111111111111'),
  'editar datos personales de un perfil aprobado debe devolverlo a pendiente'
);

-- Consent retirement works once, is server-timestamped, and cannot be repeated.
select public.retirar_consentimiento((select id from public.user_consents where user_id = '11111111-1111-4111-8111-111111111111' and document_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'));
select public.test_expect_error(
  $$select public.retirar_consentimiento((select id from public.user_consents where user_id = '11111111-1111-4111-8111-111111111111' and document_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'))$$,
  'Consentimiento no disponible o ya retirado'
);
select public.test_expect_error(
  $$update public.user_consents set retirado_en = null where user_id = '11111111-1111-4111-8111-111111111111'$$,
  'permission denied'
);

reset role;
rollback;

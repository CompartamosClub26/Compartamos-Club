-- Compartamos Club · Consentimientos: retiro irreversible
-- Reubicada como 0006 para conservar la migración 0005 de retiro por RPC.
-- El miembro puede retirar una aceptación, pero no reactivarla ni alterar su historial.

begin;

create or replace function private.guard_consent_retirement()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if (select auth.uid()) is distinct from old.user_id then
    raise exception 'Solo el titular puede retirar su consentimiento';
  end if;

  if new.user_id is distinct from old.user_id
     or new.document_id is distinct from old.document_id
     or new.aceptado_en is distinct from old.aceptado_en then
    raise exception 'El historial de aceptación es inmutable';
  end if;

  if old.retirado_en is not null then
    raise exception 'Un consentimiento retirado no puede reactivarse ni modificarse';
  end if;

  if new.retirado_en is null then
    raise exception 'La operación debe registrar el retiro del consentimiento';
  end if;

  -- El servidor fija el momento del retiro; no acepta fechas enviadas por el cliente.
  new.retirado_en := now();
  return new;
end;
$$;

drop trigger if exists user_consents_guard_retirement on public.user_consents;
create trigger user_consents_guard_retirement
before update on public.user_consents
for each row execute function private.guard_consent_retirement();

revoke all on function private.guard_consent_retirement() from public, anon, authenticated;

commit;

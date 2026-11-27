import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const migration = (name: string) =>
  readFileSync(join(process.cwd(), "supabase", "migrations", name), "utf8");

describe("Hardening SQL · consentimiento", () => {
  it("revokes direct updates and uses server time for withdrawal", () => {
    const sql = migration("0005_secure_consent_withdrawal.sql");
    expect(sql).toMatch(/revoke update on public\.user_consents from public, anon, authenticated/i);
    expect(sql).toMatch(/revoke update \(retirado_en\) on public\.user_consents from public, anon, authenticated/i);
    expect(sql).toMatch(/set retirado_en = now\(\)/i);
    expect(sql).toMatch(/and user_id = v_user/i);
    expect(sql).toMatch(/and retirado_en is null/i);
    expect(sql).toMatch(/revoke all on function public\.retirar_consentimiento\(uuid\) from public, anon/i);
    expect(sql).toMatch(/grant execute on function public\.retirar_consentimiento\(uuid\) to authenticated/i);
  });

  it("does not grant the client a direct path to alter the withdrawal timestamp", () => {
    const sql = migration("0005_secure_consent_withdrawal.sql");
    expect(sql).not.toMatch(/grant update\s*\(\s*retirado_en\s*\)/i);
    expect(sql).not.toMatch(/create policy consents_self_update/i);
  });

  it("makes consent retirement irreversible and preserves the acceptance record", () => {
    const sql = migration("0006_consent_retirement_one_way.sql");
    expect(sql).toMatch(/auth\.uid\(\)\) is distinct from old\.user_id/i);
    expect(sql).toMatch(/new\.document_id is distinct from old\.document_id/i);
    expect(sql).toMatch(/new\.aceptado_en is distinct from old\.aceptado_en/i);
    expect(sql).toMatch(/old\.retirado_en is not null/i);
    expect(sql).toMatch(/new\.retirado_en := now\(\)/i);
    expect(sql).toMatch(/before update on public\.user_consents/i);
  });
});

describe("Hardening SQL · estados del perfil", () => {
  it("allows only the documented moderation transitions", () => {
    const sql = migration("0001_mvp_profiles_consents.sql");
    expect(sql).toMatch(/p_estado not in \('aprobado','rechazado','suspendido'\)/i);
    expect(sql).toMatch(/estado = 'pendiente'/i);
    expect(sql).toMatch(/estado = 'aprobado'/i);
    expect(sql).toMatch(/transición de estado no permitida/i);
  });

  it("requires phone verification and all four current consents before approval", () => {
    const sql = migration("0001_mvp_profiles_consents.sql");
    expect(sql).toMatch(/p\.telefono_verificado_en is not null/i);
    expect(sql).toMatch(/count\(distinct cd\.tipo\)/i);
    expect(sql).toMatch(/<> 4/i);
  });

  it("allows resubmission only from draft or rejected profiles", () => {
    const sql = migration("0004_fix_enviar_revision_function.sql");
    expect(sql).toMatch(/estado in \('borrador','rechazado'\)/i);
    expect(sql).toMatch(/objetivo = 'pareja'/i);
  });

  it("freezes interests and goals outside draft and rejected states", () => {
    const sql = migration("0007_lock_approved_profile_taxonomy.sql");
    expect(sql).toMatch(/interests_self_insert[\s\S]*?estado in \('borrador','rechazado'\)/i);
    expect(sql).toMatch(/interests_self_update[\s\S]*?estado in \('borrador','rechazado'\)/i);
    expect(sql).toMatch(/interests_self_delete[\s\S]*?estado in \('borrador','rechazado'\)/i);
    expect(sql).toMatch(/goals_self_insert[\s\S]*?estado in \('borrador','rechazado'\)/i);
    expect(sql).toMatch(/goals_self_update[\s\S]*?estado in \('borrador','rechazado'\)/i);
    expect(sql).toMatch(/goals_self_delete[\s\S]*?estado in \('borrador','rechazado'\)/i);
  });

  it("blocks member edits to personal fields while moderation is pending", () => {
    const sql = migration("0008_freeze_pending_profile_fields.sql");
    expect(sql).toMatch(/old\.estado = 'pendiente'[\s\S]*?new\.alias is distinct from old\.alias/i);
    expect(sql).toMatch(/new\.ciudad is distinct from old\.ciudad/i);
    expect(sql).toMatch(/new\.rango_edad is distinct from old\.rango_edad/i);
    expect(sql).toMatch(/el perfil no puede modificarse mientras está en revisión/i);
  });
});

describe("Hardening SQL · roles y cola", () => {
  it("protects the Director queue with an explicit role check", () => {
    const sql = migration("0003_permissions_and_moderation_hardening.sql");
    expect(sql).toMatch(/if not private\.is_director\(\) then raise exception 'Acceso denegado'/i);
    expect(sql).toMatch(/security definer set search_path = ''/i);
  });

  it("keeps technical admin separate from personal profile access", () => {
    const sql = migration("0001_mvp_profiles_consents.sql");
    expect(sql).toMatch(/create type public\.staff_role as enum \('director','admin_tecnico'\)/i);
    expect(sql).toMatch(/using \(user_id = \(select auth\.uid\(\)\)\)/i);
    expect(sql).toMatch(/revoke all on schema private from public, anon, authenticated/i);
  });
});

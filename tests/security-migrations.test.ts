import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const migration = (name: string) =>
  readFileSync(join(process.cwd(), "supabase", "migrations", name), "utf8");

describe("Hardening SQL · consentimiento", () => {
  it("revokes direct updates and uses server time for withdrawal", () => {
    const sql = migration("0005_secure_consent_withdrawal.sql");
    expect(sql).toMatch(/revoke update on public\.user_consents from public, anon, authenticated/i);
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

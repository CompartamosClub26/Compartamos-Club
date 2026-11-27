import { describe, expect, it } from "vitest";
import { profileInputSchema } from "../src/lib/perfil";

const valid = {
  alias: "Luz",
  ciudad: "Bogotá",
  rangoEdad: "35–44",
  intereses: ["Café y conversación"],
  consentDocumentIds: [
    "00000000-0000-4000-8000-000000000001",
    "00000000-0000-4000-8000-000000000002",
    "00000000-0000-4000-8000-000000000003",
    "00000000-0000-4000-8000-000000000004"
  ]
};

describe("profileInputSchema · MVP Bogotá", () => {
  it("accepts a valid Bogotá couple profile", () => {
    expect(profileInputSchema.safeParse(valid).success).toBe(true);
  });

  it("rejects another city", () => {
    expect(profileInputSchema.safeParse({ ...valid, ciudad: "Medellín" }).success).toBe(false);
  });

  it("rejects an empty interests list", () => {
    expect(profileInputSchema.safeParse({ ...valid, intereses: [] }).success).toBe(false);
  });

  it("requires exactly four consent document IDs", () => {
    expect(profileInputSchema.safeParse({ ...valid, consentDocumentIds: valid.consentDocumentIds.slice(0, 3) }).success).toBe(false);
  });

  it("rejects invalid aliases", () => {
    expect(profileInputSchema.safeParse({ ...valid, alias: "x" }).success).toBe(false);
  });
});

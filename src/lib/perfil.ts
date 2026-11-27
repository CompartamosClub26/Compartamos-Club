import { z } from "zod";
import { getSupabase } from "./supabase";

const ageRanges = ["18–24", "25–34", "35–44", "45–54", "55 o más"] as const;
const interests = [
  "Senderismo", "Café y conversación", "Fútbol", "Cerámica y arte",
  "Juegos de mesa", "Fotografía", "Baile", "Lectura", "Cocina",
  "Ciclismo", "Idiomas", "Voluntariado", "Yoga", "Cine",
] as const;

export const profileInputSchema = z.object({
  alias: z.string().trim().min(2).max(40),
  ciudad: z.literal("Bogotá"),
  rangoEdad: z.enum(ageRanges),
  intereses: z.array(z.enum(interests)).min(1).max(interests.length),
  consentDocumentIds: z.array(z.string().uuid()).length(4),
});
export type ProfileInput = z.infer<typeof profileInputSchema>;

export async function createPendingProfile(input: ProfileInput) {
  const parsed = profileInputSchema.parse(input);
  const supabase = getSupabase();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError) throw authError;
  if (!authData.user) throw new Error("Inicia sesión para crear tu perfil.");

  const { data, error } = await supabase.rpc("crear_perfil", {
    p_alias: parsed.alias,
    p_rango_edad: parsed.rangoEdad,
    p_intereses: parsed.intereses,
    p_consent_document_ids: parsed.consentDocumentIds,
  });
  if (error) throw error;
  return { userId: data as string, status: "borrador" as const };
}

export async function submitProfileForReview() {
  const { error } = await getSupabase().rpc("enviar_revision");
  if (error) throw error;
}

export async function getMyProfile() {
  const supabase = getSupabase();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError) throw authError;
  if (!authData.user) return null;
  const { data, error } = await supabase.from("profiles")
    .select("user_id, alias, ciudad, rango_edad, estado, motivo_estado, creado_en, actualizado_en")
    .eq("user_id", authData.user.id).maybeSingle();
  if (error) throw error;
  return data;
}

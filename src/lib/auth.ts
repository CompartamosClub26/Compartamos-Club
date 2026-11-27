import { z } from "zod";
import { getSupabase } from "./supabase";

const emailSchema = z.string().trim().email("Escribe un correo válido.");

/** Solicita un código de un solo uso. La respuesta no revela si el correo existe. */
export async function requestEmailCode(emailInput: string) {
  const email = emailSchema.parse(emailInput);
  const { error } = await getSupabase().auth.signInWithOtp({
    email,
    options: { shouldCreateUser: true },
  });
  if (error) throw error;
  return { message: "Si el correo puede recibir el código, te lo enviaremos." };
}

/** Verifica el OTP de correo y devuelve la sesión autenticada. */
export async function verifyEmailCode(input: { email: string; token: string }) {
  const email = emailSchema.parse(input.email);
  const token = z.string().trim().min(6).max(8).parse(input.token);
  const { data, error } = await getSupabase().auth.verifyOtp({
    email,
    token,
    type: "email",
  });
  if (error) throw error;
  return data;
}

export async function signOut() {
  const { error } = await getSupabase().auth.signOut();
  if (error) throw error;
}

export async function getCurrentUser() {
  const { data, error } = await getSupabase().auth.getUser();
  if (error) throw error;
  return data.user;
}

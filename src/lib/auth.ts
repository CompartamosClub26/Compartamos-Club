import { z } from "zod";
import { getSupabase } from "./supabase";

const emailSchema = z.string().trim().email("Escribe un correo válido.");
const passwordSchema = z.string().min(10, "La contraseña debe tener al menos 10 caracteres.");

export async function registerWithEmail(input: { email: string; password: string }) {
  const email = emailSchema.parse(input.email);
  const password = passwordSchema.parse(input.password);
  const { data, error } = await getSupabase().auth.signUp({
    email,
    password,
    options: { emailRedirectTo: `${window.location.origin}/auth/callback` },
  });
  if (error) throw error;
  return {
    user: data.user,
    session: data.session,
    confirmationRequired: !data.session,
  };
}

export async function signInWithEmail(input: { email: string; password: string }) {
  const email = emailSchema.parse(input.email);
  const password = passwordSchema.parse(input.password);
  const { data, error } = await getSupabase().auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

export async function signOut() {
  const { error } = await getSupabase().auth.signOut();
  if (error) throw error;
}

export async function requestPasswordReset(emailInput: string) {
  const email = emailSchema.parse(emailInput);
  const { error } = await getSupabase().auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}/auth/reset-password`,
  });
  if (error) throw error;
}

export async function updatePassword(passwordInput: string) {
  const password = passwordSchema.parse(passwordInput);
  const { error } = await getSupabase().auth.updateUser({ password });
  if (error) throw error;
}

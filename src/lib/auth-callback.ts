import { getSupabase } from "./supabase";

/** Exchange the one-time email confirmation code for a Supabase session. */
export async function completeEmailConfirmation(search: URLSearchParams) {
  const code = search.get("code");
  if (!code) throw new Error("El enlace de confirmación no contiene un código válido.");
  const { data, error } = await getSupabase().auth.exchangeCodeForSession(code);
  if (error) throw error;
  return data;
}

/** Read and validate the current authenticated session. */
export async function requireAuthenticatedUser() {
  const { data, error } = await getSupabase().auth.getUser();
  if (error) throw error;
  if (!data.user) throw new Error("Tu sesión no está activa. Inicia sesión nuevamente.");
  return data.user;
}

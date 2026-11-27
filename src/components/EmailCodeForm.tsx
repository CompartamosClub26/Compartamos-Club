import { useState, type FormEvent } from "react";
import { requestEmailCode, verifyEmailCode } from "../lib/auth";

type Props = {
  onAuthenticated?: () => void;
};

export function EmailCodeForm({ onAuthenticated }: Props) {
  const [email, setEmail] = useState("");
  const [token, setToken] = useState("");
  const [step, setStep] = useState<"email" | "code">("email");
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");
  const [error, setError] = useState("");

  async function submitEmail(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError("");
    setNotice("");
    try {
      const result = await requestEmailCode(email);
      setNotice(result.message);
      setStep("code");
    } catch {
      setError("No fue posible procesar la solicitud. Revisa el correo e inténtalo más tarde.");
    } finally {
      setBusy(false);
    }
  }

  async function submitCode(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError("");
    try {
      await verifyEmailCode({ email, token });
      setNotice("Correo verificado. Tu sesión está activa.");
      onAuthenticated?.();
    } catch {
      setError("El código no es válido o venció. Solicita uno nuevo e inténtalo otra vez.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <section aria-labelledby="access-title" className="mx-auto w-full max-w-md rounded-3xl border p-6">
      <h1 id="access-title" className="text-2xl font-semibold">Acceso a Compartamos Club</h1>
      <p className="mt-2 text-sm text-muted-foreground">
        Te enviaremos un código de un solo uso a tu correo. No necesitas contraseña.
      </p>

      {step === "email" ? (
        <form onSubmit={submitEmail} className="mt-6 grid gap-4">
          <label className="grid gap-2 text-sm font-medium">
            Correo electrónico
            <input
              type="email"
              autoComplete="email"
              required
              maxLength={254}
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              className="h-12 rounded-xl border bg-background px-3"
            />
          </label>
          <button disabled={busy} className="h-12 rounded-xl bg-primary px-4 font-semibold text-primary-foreground disabled:opacity-50">
            {busy ? "Enviando…" : "Enviar código"}
          </button>
        </form>
      ) : (
        <form onSubmit={submitCode} className="mt-6 grid gap-4">
          <p className="text-sm">Introduce el código enviado a <strong>{email}</strong>.</p>
          <label className="grid gap-2 text-sm font-medium">
            Código de verificación
            <input
              inputMode="numeric"
              autoComplete="one-time-code"
              required
              minLength={6}
              maxLength={8}
              value={token}
              onChange={(event) => setToken(event.target.value.replace(/\D/g, ""))}
              className="h-12 rounded-xl border bg-background px-3 tracking-[0.3em]"
            />
          </label>
          <button disabled={busy} className="h-12 rounded-xl bg-primary px-4 font-semibold text-primary-foreground disabled:opacity-50">
            {busy ? "Verificando…" : "Verificar y entrar"}
          </button>
          <button type="button" disabled={busy} onClick={() => { setStep("email"); setToken(""); }} className="text-sm underline">
            Cambiar correo
          </button>
        </form>
      )}

      {notice && <p role="status" className="mt-4 text-sm">{notice}</p>}
      {error && <p role="alert" className="mt-4 text-sm text-destructive">{error}</p>}
    </section>
  );
}

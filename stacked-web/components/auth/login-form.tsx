"use client";

import { FormEvent, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { AppIcon } from "@/components/ui/app-icon";
import { ViewIcon, ViewOffIcon } from "@/lib/icons/nav-icons";

export function LoginForm() {
  const router = useRouter();
  const params = useSearchParams();
  const next = params.get("next") || "/home";
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isLogin, setIsLogin] = useState(true);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(
    params.get("error") === "auth" ? "Não foi possível autenticar. Tente novamente." : null,
  );

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const supabase = createClient();

    try {
      if (isLogin) {
        const { error: err } = await supabase.auth.signInWithPassword({ email, password });
        if (err) throw err;
      } else {
        const { error: err } = await supabase.auth.signUp({ email, password });
        if (err) throw err;
      }
      router.replace(next);
      router.refresh();
    } catch (err) {
      setError(friendlyError(String(err)));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-dvh items-center justify-center bg-[var(--color-bg)] p-6">
      <div className="w-full max-w-sm">
        <div className="mb-8 text-center">
          <div className="mx-auto mb-4 flex h-10 w-10 items-center justify-center rounded-[var(--radius-sm)] bg-[var(--color-accent)] text-sm font-extrabold text-[var(--color-accent-text)]">
            S
          </div>
          <h1 className="text-2xl font-extrabold tracking-tight">Stacked</h1>
          <p className="mt-1 text-sm text-[var(--color-text-secondary)]">
            {isLogin ? "Entre na sua conta" : "Crie sua conta"}
          </p>
        </div>

        <form onSubmit={onSubmit} className="space-y-3">
          <div>
            <label htmlFor="email" className="mb-1 block text-xs font-medium text-[var(--color-text-secondary)]">
              E-mail
            </label>
            <input
              id="email"
              type="email"
              required
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] px-3.5 py-2.5 text-sm outline-none focus:border-white/25"
            />
          </div>
          <div>
            <label htmlFor="password" className="mb-1 block text-xs font-medium text-[var(--color-text-secondary)]">
              Senha
            </label>
            <div className="relative">
              <input
                id="password"
                type={showPassword ? "text" : "password"}
                required
                minLength={6}
                autoComplete={isLogin ? "current-password" : "new-password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] px-3.5 py-2.5 pr-10 text-sm outline-none focus:border-white/25"
              />
              <button
                type="button"
                onClick={() => setShowPassword((v) => !v)}
                className="absolute right-2 top-1/2 -translate-y-1/2 p-1 text-[var(--color-text-tertiary)] hover:text-[var(--color-text-secondary)]"
                aria-label={showPassword ? "Ocultar senha" : "Mostrar senha"}
              >
                <AppIcon icon={showPassword ? ViewOffIcon : ViewIcon} size={18} />
              </button>
            </div>
          </div>
          {error && <p className="text-sm text-[var(--color-overdue)]" role="alert">{error}</p>}
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-[var(--radius-md)] bg-[var(--color-accent)] py-2.5 text-sm font-semibold text-[var(--color-accent-text)] hover:brightness-105 disabled:opacity-60"
          >
            {loading ? "Aguarde…" : isLogin ? "Entrar" : "Cadastrar"}
          </button>
        </form>

        <button
          type="button"
          onClick={() => setIsLogin((v) => !v)}
          className="mt-4 w-full text-center text-sm text-[var(--color-text-secondary)] hover:text-[var(--color-text)]"
        >
          {isLogin ? "Não tem conta? Cadastre-se" : "Já tem conta? Entrar"}
        </button>
      </div>
    </div>
  );
}

function friendlyError(raw: string): string {
  if (raw.includes("Invalid login credentials")) return "E-mail ou senha incorretos.";
  if (raw.includes("Email not confirmed")) return "Confirme seu e-mail antes de entrar.";
  if (raw.includes("User already registered")) return "Este e-mail já está cadastrado.";
  return "Algo deu errado. Tente novamente.";
}

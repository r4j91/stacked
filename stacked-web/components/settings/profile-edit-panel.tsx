"use client";

import { useEffect, useRef, useState } from "react";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AnchoredPopover } from "@/components/ui/anchored-popover";
import { UserAvatar } from "@/components/ui/user-avatar";
import { AppIcon } from "@/components/ui/app-icon";
import { Cancel01Icon } from "@/lib/icons/nav-icons";
import {
  profileFromUser,
  sendPasswordResetEmail,
  updateProfileMetadata,
  uploadAvatar,
} from "@/lib/services/profile-service";
import { createClient } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";

export function ProfileEditPanel() {
  const { profileOpen, profileAnchor, closeProfile, refreshUserProfile, userProfile } = useWorkbench();
  const [nome, setNome] = useState("");
  const [apelido, setApelido] = useState("");
  const [email, setEmail] = useState("");
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!profileOpen) return;
    setNome(userProfile.nome ?? "");
    setApelido(userProfile.apelido ?? "");
    setEmail(userProfile.email);
    setAvatarUrl(userProfile.avatarUrl ?? null);
    setMessage(null);
  }, [profileOpen, userProfile]);

  async function save() {
    setSaving(true);
    setMessage(null);
    try {
      await updateProfileMetadata({ nome: nome.trim(), apelido: apelido.trim(), avatar_url: avatarUrl });
      await refreshUserProfile();
      setMessage("Perfil atualizado");
    } catch (e) {
      setMessage(e instanceof Error ? e.message : "Erro ao salvar");
    } finally {
      setSaving(false);
    }
  }

  async function onPickFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setUploading(true);
    setMessage(null);
    try {
      const url = await uploadAvatar(file);
      setAvatarUrl(url);
      await updateProfileMetadata({ avatar_url: url });
      await refreshUserProfile();
    } catch (err) {
      setMessage(err instanceof Error ? err.message : "Erro ao enviar foto");
    } finally {
      setUploading(false);
    }
  }

  async function removeAvatar() {
    setAvatarUrl(null);
    await updateProfileMetadata({ avatar_url: null });
    await refreshUserProfile();
  }

  async function resetPassword() {
    if (!email) return;
    try {
      await sendPasswordResetEmail(email);
      setMessage("E-mail de redefinição enviado");
    } catch (e) {
      setMessage(e instanceof Error ? e.message : "Erro ao enviar e-mail");
    }
  }

  const displayName = apelido.trim() || (nome.trim() ? nome.trim().split(" ")[0] : userProfile.name);

  return (
    <AnchoredPopover
      open={profileOpen}
      onClose={closeProfile}
      anchorRect={profileAnchor}
      width={360}
      preferSide="right"
      className="max-h-[min(85vh,520px)] p-0"
      labelledBy="profile-sheet-title"
    >
      <div className="flex items-center justify-between border-b border-[var(--color-border)] px-4 py-3">
        <h2 id="profile-sheet-title" className="text-base font-bold">Perfil</h2>
        <div className="flex items-center gap-1">
          <button
            type="button"
            disabled={saving}
            onClick={() => void save()}
            className="rounded-[var(--radius-sm)] px-2.5 py-1 text-xs font-semibold text-[var(--color-text)] hover:bg-[var(--color-hover-overlay)] disabled:opacity-50"
          >
            {saving ? "Salvando…" : "Salvar"}
          </button>
          <button
            type="button"
            onClick={closeProfile}
            className="flex h-8 w-8 items-center justify-center rounded-full text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)]"
            aria-label="Fechar"
          >
            <AppIcon icon={Cancel01Icon} size={16} />
          </button>
        </div>
      </div>

      <div className="scroll-thin space-y-4 overflow-y-auto px-4 py-4">
        <div className="flex flex-col items-center gap-2">
          <button
            type="button"
            disabled={uploading || !isSupabaseConfigured()}
            onClick={() => fileRef.current?.click()}
            className="relative"
          >
            <UserAvatar name={displayName} email={email} avatarUrl={avatarUrl} size={72} />
            <span className="mt-2 block text-xs text-[var(--color-text-secondary)]">
              {uploading ? "Enviando…" : "Alterar foto"}
            </span>
          </button>
          <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={(e) => void onPickFile(e)} />
          {avatarUrl && (
            <button type="button" onClick={() => void removeAvatar()} className="text-xs text-[var(--color-overdue)]">
              Remover foto
            </button>
          )}
        </div>

        <Field label="Nome completo" value={nome} onChange={setNome} placeholder="Seu nome" />
        <Field label="Apelido" value={apelido} onChange={setApelido} placeholder="Como aparece no app" />
        <div>
          <label className="mb-1 block text-xs text-[var(--color-text-tertiary)]">E-mail</label>
          <p className="rounded-[var(--radius-sm)] bg-[var(--color-surface-variant)] px-3 py-2 text-sm text-[var(--color-text-secondary)]">
            {email || "—"}
          </p>
        </div>

        <button
          type="button"
          disabled={!email || !isSupabaseConfigured()}
          onClick={() => void resetPassword()}
          className="w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] px-3 py-2 text-left text-sm text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)] disabled:opacity-50"
        >
          Alterar senha por e-mail
        </button>

        {message && (
          <p className="text-center text-xs text-[var(--color-text-secondary)]">{message}</p>
        )}
      </div>
    </AnchoredPopover>
  );
}

function Field({
  label,
  value,
  onChange,
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
}) {
  return (
    <div>
      <label className="mb-1 block text-xs text-[var(--color-text-tertiary)]">{label}</label>
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-bg)] px-3 py-2 text-sm outline-none focus:border-[var(--color-border-strong)]"
      />
    </div>
  );
}

export async function loadCurrentProfile() {
  if (!isSupabaseConfigured()) return null;
  const {
    data: { user },
  } = await createClient().auth.getUser();
  return user ? profileFromUser(user) : null;
}

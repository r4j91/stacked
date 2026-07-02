import type { User } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/client";
import type { UserProfile } from "@/lib/types/user-profile";

export function profileFromUser(user: User | null): UserProfile {
  if (!user) return { name: "", email: "", avatarUrl: null, apelido: "", nome: "" };
  const meta = user.user_metadata as Record<string, unknown> | undefined;
  const apelido = typeof meta?.apelido === "string" ? meta.apelido.trim() : "";
  const nome = typeof meta?.nome === "string" ? meta.nome.trim() : typeof meta?.name === "string" ? meta.name.trim() : "";
  const avatarRaw = typeof meta?.avatar_url === "string" ? meta.avatar_url : null;
  const avatarUrl = avatarRaw?.startsWith("http") ? avatarRaw : null;
  const display =
    apelido ||
    (nome ? nome.split(" ")[0] : "") ||
    user.email?.split("@")[0] ||
    "";
  return { name: display, email: user.email ?? "", avatarUrl, apelido, nome };
}

export async function updateProfileMetadata(data: {
  nome?: string;
  apelido?: string;
  avatar_url?: string | null;
}) {
  const client = createClient();
  const { error } = await client.auth.updateUser({ data });
  if (error) throw error;
}

export async function uploadAvatar(file: File): Promise<string> {
  const client = createClient();
  const {
    data: { user },
  } = await client.auth.getUser();
  if (!user) throw new Error("Não autenticado");

  const path = `${user.id}/avatar.jpg`;
  const { error } = await client.storage.from("avatars").upload(path, file, {
    upsert: true,
    contentType: file.type || "image/jpeg",
  });
  if (error) throw error;

  const { data } = client.storage.from("avatars").getPublicUrl(path);
  return `${data.publicUrl}?t=${Date.now()}`;
}

export async function sendPasswordResetEmail(email: string) {
  const client = createClient();
  const { error } = await client.auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}/login`,
  });
  if (error) throw error;
}

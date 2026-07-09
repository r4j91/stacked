import type { SupabaseClient } from "@supabase/supabase-js";

/** RLS em várias tabelas exige auth.uid() = user_id no INSERT. */
export async function requireAuthUserId(client: SupabaseClient): Promise<string> {
  const {
    data: { user },
  } = await client.auth.getUser();
  if (!user?.id) throw new Error("Usuário não autenticado");
  return user.id;
}

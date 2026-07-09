import type { SupabaseClient } from "@supabase/supabase-js"
import { requireAuthUserId } from "@/lib/supabase/require-auth-user"

export type Comment = {
  id: string
  text: string
  createdAt: string
  userId?: string
}

export class CommentRepository {
  constructor(private client: SupabaseClient) {}

  async fetchComments(taskId: string): Promise<Comment[]> {
    const { data, error } = await this.client
      .from("task_comments")
      .select("id, conteudo, created_at, user_id")
      .eq("task_id", taskId)
      .order("created_at", { ascending: true })
    if (error) throw error
    return (data ?? []).map((row) => ({
      id: String(row.id),
      text: String(row.conteudo ?? ""),
      createdAt: String(row.created_at ?? ""),
      userId: row.user_id != null ? String(row.user_id) : undefined,
    }))
  }

  async addComment(taskId: string, text: string): Promise<void> {
    const trimmed = text.trim()
    if (!trimmed) return
    const userId = await requireAuthUserId(this.client)
    const { error } = await this.client.from("task_comments").insert({
      task_id: taskId,
      conteudo: trimmed,
      user_id: userId,
    })
    if (error) throw error
  }
}

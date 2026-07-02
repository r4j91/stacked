import type { SupabaseClient } from "@supabase/supabase-js"

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
    const {
      data: { user },
    } = await this.client.auth.getUser()
    const { error } = await this.client.from("task_comments").insert({
      task_id: taskId,
      conteudo: trimmed,
      ...(user?.id ? { user_id: user.id } : {}),
    })
    if (error) throw error
  }
}

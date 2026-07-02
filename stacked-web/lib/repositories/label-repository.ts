import type { SupabaseClient } from "@supabase/supabase-js"
import type { Label } from "@/lib/types/label"

const DEFAULT_COLOR = "#9296A0"

function parseColor(hex: unknown): string {
  if (typeof hex !== "string" || !hex) return DEFAULT_COLOR
  return hex.startsWith("#") ? hex : `#${hex}`
}

function mapLabel(row: Record<string, unknown>): Label {
  return {
    id: String(row.id),
    name: String(row.nome ?? ""),
    color: parseColor(row.cor),
  }
}

export class LabelRepository {
  constructor(private client: SupabaseClient) {}

  async fetchLabels(): Promise<Label[]> {
    const { data, error } = await this.client
      .from("labels")
      .select("id, nome, cor")
      .order("nome", { ascending: true })
    if (error) throw error
    return (data ?? []).map((row) => mapLabel(row as Record<string, unknown>))
  }

  async createLabel(name: string, color: string): Promise<void> {
    const { error } = await this.client.from("labels").insert({
      nome: name.trim(),
      cor: color,
    })
    if (error) throw error
  }

  async updateLabel(id: string, patch: { name?: string; color?: string }): Promise<void> {
    const update: Record<string, string> = {}
    if (patch.name != null) update.nome = patch.name.trim()
    if (patch.color != null) update.cor = patch.color
    if (Object.keys(update).length === 0) return
    const { error } = await this.client.from("labels").update(update).eq("id", id)
    if (error) throw error
  }

  async deleteLabel(id: string): Promise<void> {
    const { error } = await this.client.from("labels").delete().eq("id", id)
    if (error) throw error
  }

  async setTaskLabels(taskId: string, labelIds: string[]): Promise<void> {
    const { error: deleteError } = await this.client
      .from("task_labels")
      .delete()
      .eq("task_id", taskId)
    if (deleteError) throw deleteError
    if (labelIds.length === 0) return
    const { error } = await this.client.from("task_labels").insert(
      labelIds.map((labelId) => ({ task_id: taskId, label_id: labelId })),
    )
    if (error) throw error
  }
}

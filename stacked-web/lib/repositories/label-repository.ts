import type { SupabaseClient } from "@supabase/supabase-js"
import type { Label } from "@/lib/types/label"
import { requireAuthUserId } from "@/lib/supabase/require-auth-user"

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
    sortOrder: typeof row.sort_order === "number" ? row.sort_order : 0,
  }
}

export class LabelRepository {
  constructor(private client: SupabaseClient) {}

  async fetchLabels(): Promise<Label[]> {
    const { data, error } = await this.client
      .from("labels")
      .select("id, nome, cor, sort_order")
      .order("sort_order", { ascending: true })
      .order("nome", { ascending: true })
    if (error) throw error
    return (data ?? []).map((row) => mapLabel(row as Record<string, unknown>))
  }

  async createLabel(name: string, color: string): Promise<void> {
    const userId = await requireAuthUserId(this.client);

    const { data: last } = await this.client
      .from("labels")
      .select("sort_order")
      .order("sort_order", { ascending: false })
      .limit(1)
      .maybeSingle();

    const sortOrder = (typeof last?.sort_order === "number" ? last.sort_order : -1) + 1;

    const { error } = await this.client.from("labels").insert({
      nome: name.trim(),
      cor: color,
      user_id: userId,
      sort_order: sortOrder,
    });
    if (error) throw error;
  }

  async reorderLabels(orderedIds: string[]): Promise<void> {
    if (!orderedIds.length) return;
    const results = await Promise.all(
      orderedIds.map((id, index) =>
        this.client.from("labels").update({ sort_order: index }).eq("id", id),
      ),
    );
    const failed = results.find((r) => r.error);
    if (failed?.error) throw failed.error;
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

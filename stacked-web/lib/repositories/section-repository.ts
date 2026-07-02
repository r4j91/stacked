import type { SupabaseClient } from "@supabase/supabase-js";
import type { Section } from "@/lib/types/project";

function mapSection(row: Record<string, unknown>): Section {
  return {
    id: String(row.id),
    projectId: String(row.project_id),
    name: String(row.name ?? ""),
    order: Number(row.order) || 0,
    createdAt: String(row.created_at ?? new Date().toISOString()),
  };
}

export class SectionRepository {
  constructor(private client: SupabaseClient) {}

  async getSectionsForProject(projectId: string): Promise<Section[]> {
    const { data, error } = await this.client
      .from("sections")
      .select("id, project_id, name, order, created_at")
      .eq("project_id", projectId)
      .order("order", { ascending: true });
    if (error) throw error;
    return (data ?? []).map((row) => mapSection(row as Record<string, unknown>));
  }

  async createSection(projectId: string, name: string): Promise<Section> {
    const { data, error } = await this.client
      .from("sections")
      .insert({ project_id: projectId, name: name.trim() })
      .select("id, project_id, name, order, created_at")
      .single();
    if (error) throw error;
    return mapSection(data as Record<string, unknown>);
  }

  async updateSection(sectionId: string, patch: { name?: string; order?: number }): Promise<void> {
    const { error } = await this.client.from("sections").update(patch).eq("id", sectionId);
    if (error) throw error;
  }

  async deleteSection(sectionId: string): Promise<void> {
    await this.client.from("tasks").update({ section_id: null }).eq("section_id", sectionId);
    const { error } = await this.client.from("sections").delete().eq("id", sectionId);
    if (error) throw error;
  }
}

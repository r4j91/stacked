import type { FilterCriteria, SavedFilter, SavedFilterWithCount } from "@/lib/types/saved-filter";
import { normalizeFilterCriteria } from "@/lib/types/saved-filter";
import type { SupabaseClient } from "@supabase/supabase-js";
import { TaskRepository } from "@/lib/repositories/task-repository";

type SavedFilterRow = {
  id: string;
  name: string;
  color: string | null;
  criteria: unknown;
  sort_order: number;
};

function mapRow(row: SavedFilterRow): SavedFilter {
  return {
    id: row.id,
    name: row.name,
    color: row.color,
    criteria: normalizeFilterCriteria(row.criteria),
    sortOrder: row.sort_order,
  };
}

export class SavedFilterRepository {
  constructor(private client: SupabaseClient) {}

  private async getUserId(): Promise<string> {
    const {
      data: { user },
    } = await this.client.auth.getUser();
    if (!user?.id) throw new Error("Não autenticado");
    return user.id;
  }

  async fetchSavedFilters(): Promise<SavedFilter[]> {
    const { data, error } = await this.client
      .from("saved_filters")
      .select("id, name, color, criteria, sort_order")
      .order("sort_order", { ascending: true })
      .order("created_at", { ascending: true });
    if (error) throw error;
    return (data as SavedFilterRow[]).map(mapRow);
  }

  async fetchSavedFiltersWithCounts(now = new Date()): Promise<SavedFilterWithCount[]> {
    const filters = await this.fetchSavedFilters();
    const taskRepo = new TaskRepository(this.client);
    const counts = await Promise.all(
      filters.map(async (f) => {
        const { pending } = await taskRepo.fetchFilterResults(f.criteria, now);
        return { ...f, pendingCount: pending.length };
      }),
    );
    return counts;
  }

  async createSavedFilter(input: {
    name: string;
    color: string | null;
    criteria: FilterCriteria;
  }): Promise<SavedFilter> {
    const userId = await this.getUserId();
    const { data, error } = await this.client
      .from("saved_filters")
      .insert({
        user_id: userId,
        name: input.name.trim(),
        color: input.color,
        criteria: input.criteria,
      })
      .select("id, name, color, criteria, sort_order")
      .single();
    if (error) throw error;
    return mapRow(data as SavedFilterRow);
  }

  async updateSavedFilter(
    id: string,
    input: { name: string; color: string | null; criteria: FilterCriteria },
  ): Promise<SavedFilter> {
    const { data, error } = await this.client
      .from("saved_filters")
      .update({
        name: input.name.trim(),
        color: input.color,
        criteria: input.criteria,
      })
      .eq("id", id)
      .select("id, name, color, criteria, sort_order")
      .single();
    if (error) throw error;
    return mapRow(data as SavedFilterRow);
  }

  async deleteSavedFilter(id: string): Promise<void> {
    const { error } = await this.client.from("saved_filters").delete().eq("id", id);
    if (error) throw error;
  }

  async fetchSavedFilterById(id: string): Promise<SavedFilter | null> {
    const { data, error } = await this.client
      .from("saved_filters")
      .select("id, name, color, criteria, sort_order")
      .eq("id", id)
      .maybeSingle();
    if (error) throw error;
    return data ? mapRow(data as SavedFilterRow) : null;
  }
}

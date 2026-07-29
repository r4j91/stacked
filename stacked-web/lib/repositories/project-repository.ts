import type { SupabaseClient } from "@supabase/supabase-js";
import type { Project } from "@/lib/types/project";
import { DEFAULT_PROJECT_ICON } from "@/lib/icons/project-icons";
import { requireAuthUserId } from "@/lib/supabase/require-auth-user";

const DEFAULT_COLOR = "#E8E8EC";

function parseColor(hex: unknown): string {
  if (typeof hex !== "string" || !hex) return DEFAULT_COLOR;
  return hex.startsWith("#") ? hex : `#${hex}`;
}

function mapProjectRow(
  row: Record<string, unknown>,
  pendingCount: number,
): Project {
  return {
    id: String(row.id),
    name: String(row.nome ?? ""),
    color: parseColor(row.cor),
    icon: row.icone != null && String(row.icone).trim() ? String(row.icone) : null,
    pendingCount,
  };
}

async function fetchProjectRows(
  client: SupabaseClient,
): Promise<Record<string, unknown>[]> {
  const withSort = await client
    .from("projects")
    .select("id, nome, cor, icone, sort_order")
    .order("sort_order", { ascending: true })
    .order("nome", { ascending: true });
  if (!withSort.error) return (withSort.data ?? []) as Record<string, unknown>[];

  const msg = String(withSort.error.message);
  if (!msg.includes("sort_order") && !msg.includes("icone")) throw withSort.error;

  if (msg.includes("sort_order")) {
    const withIcon = await client
      .from("projects")
      .select("id, nome, cor, icone")
      .order("nome", { ascending: true });
    if (!withIcon.error) return (withIcon.data ?? []) as Record<string, unknown>[];
    if (!String(withIcon.error.message).includes("icone")) throw withIcon.error;
  }

  const fallback = await client
    .from("projects")
    .select("id, nome, cor")
    .order("nome", { ascending: true });
  if (fallback.error) throw fallback.error;
  return (fallback.data ?? []) as Record<string, unknown>[];
}

export type ProjectWithStats = Project & { totalCount: number };

export class ProjectRepository {
  constructor(private client: SupabaseClient) {}

  async fetchProjects(): Promise<Project[]> {
    const rows = await fetchProjectRows(this.client);

    const { data: pendingRows, error: pendingError } = await this.client
      .from("tasks")
      .select("project_id")
      .eq("concluida", false);
    if (pendingError) throw pendingError;

    const counts = new Map<string, number>();
    for (const row of pendingRows ?? []) {
      const pid = row.project_id != null ? String(row.project_id) : null;
      if (!pid) continue;
      counts.set(pid, (counts.get(pid) ?? 0) + 1);
    }

    return rows.map((row) => mapProjectRow(row, counts.get(String(row.id)) ?? 0));
  }

  async fetchProjectById(id: string): Promise<Project | null> {
    let row: Record<string, unknown> | null = null;
    const withIcon = await this.client
      .from("projects")
      .select("id, nome, cor, icone")
      .eq("id", id)
      .maybeSingle();
    if (!withIcon.error) {
      row = withIcon.data as Record<string, unknown> | null;
    } else if (String(withIcon.error.message).includes("icone")) {
      const fallback = await this.client
        .from("projects")
        .select("id, nome, cor")
        .eq("id", id)
        .maybeSingle();
      if (fallback.error) throw fallback.error;
      row = fallback.data as Record<string, unknown> | null;
    } else {
      throw withIcon.error;
    }
    if (!row) return null;

    const { count } = await this.client
      .from("tasks")
      .select("id", { count: "exact", head: true })
      .eq("project_id", id)
      .eq("concluida", false);

    return mapProjectRow(row, count ?? 0);
  }

  async createProject(input: {
    name: string;
    color: string;
    icon?: string;
    description?: string;
  }): Promise<string> {
    const userId = await requireAuthUserId(this.client);
    let sortOrder = 0;
    const { data: lastRows, error: orderError } = await this.client
      .from("projects")
      .select("sort_order")
      .order("sort_order", { ascending: false })
      .limit(1);
    if (!orderError) {
      const last = lastRows?.[0] as { sort_order?: number } | undefined;
      sortOrder = (typeof last?.sort_order === "number" ? last.sort_order : -1) + 1;
    }

    const payload: Record<string, unknown> = {
      nome: input.name.trim(),
      cor: input.color,
      icone: input.icon ?? DEFAULT_PROJECT_ICON,
      user_id: userId,
      sort_order: sortOrder,
      ...(input.description?.trim() ? { descricao: input.description.trim() } : {}),
    };
    const { data, error } = await this.client
      .from("projects")
      .insert(payload)
      .select("id")
      .single();
    if (error) {
      const msg = String(error.message);
      if (msg.includes("sort_order")) delete payload.sort_order;
      if (msg.includes("icone")) delete payload.icone;
      if (msg.includes("sort_order") || msg.includes("icone")) {
        const retry = await this.client.from("projects").insert(payload).select("id").single();
        if (retry.error) throw retry.error;
        return String(retry.data.id);
      }
      throw error;
    }
    return String(data.id);
  }

  async updateProject(
    id: string,
    patch: { name?: string; color?: string; icon?: string },
  ): Promise<void> {
    const update: Record<string, string> = {};
    if (patch.name != null) update.nome = patch.name.trim();
    if (patch.color != null) update.cor = patch.color;
    if (patch.icon != null) update.icone = patch.icon;
    if (Object.keys(update).length === 0) return;
    const { error } = await this.client.from("projects").update(update).eq("id", id);
    if (error) {
      if (patch.icon != null && String(error.message).includes("icone")) {
        const { icon: _icon, ...rest } = update;
        if (Object.keys(rest).length === 0) return;
        const retry = await this.client.from("projects").update(rest).eq("id", id);
        if (retry.error) throw retry.error;
        return;
      }
      throw error;
    }
  }

  async deleteProject(id: string): Promise<void> {
    const { error } = await this.client.from("projects").delete().eq("id", id);
    if (error) throw error;
  }

  async reorderProjects(orderedIds: string[]): Promise<void> {
    await Promise.all(
      orderedIds.map((id, index) =>
        this.client.from("projects").update({ sort_order: index }).eq("id", id),
      ),
    );
  }

  async fetchProjectsWithTaskStats(): Promise<ProjectWithStats[]> {
    let data: Record<string, unknown>[] | null = null;
    const withSort = await this.client
      .from("projects")
      .select("id, nome, cor, icone, tasks(concluida)")
      .order("sort_order", { ascending: true })
      .order("nome", { ascending: true });
    if (!withSort.error) {
      data = withSort.data as Record<string, unknown>[];
    } else if (String(withSort.error.message).includes("sort_order")) {
      const withIcon = await this.client
        .from("projects")
        .select("id, nome, cor, icone, tasks(concluida)")
        .order("nome", { ascending: true });
      if (!withIcon.error) {
        data = withIcon.data as Record<string, unknown>[];
      } else if (String(withIcon.error.message).includes("icone")) {
        const fallback = await this.client
          .from("projects")
          .select("id, nome, cor, tasks(concluida)")
          .order("nome", { ascending: true });
        if (fallback.error) throw fallback.error;
        data = fallback.data as Record<string, unknown>[];
      } else {
        throw withIcon.error;
      }
    } else if (String(withSort.error.message).includes("icone")) {
      const fallback = await this.client
        .from("projects")
        .select("id, nome, cor, tasks(concluida)")
        .order("sort_order", { ascending: true })
        .order("nome", { ascending: true });
      if (fallback.error) throw fallback.error;
      data = fallback.data as Record<string, unknown>[];
    } else {
      throw withSort.error;
    }

    return (data ?? []).map((row) => {
      const tasks = (row.tasks as { concluida: boolean }[] | null) ?? [];
      const pending = tasks.filter((t) => !t.concluida).length;
      return {
        ...mapProjectRow(row, pending),
        totalCount: tasks.length,
      };
    });
  }
}

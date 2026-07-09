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
  const withIcon = await client
    .from("projects")
    .select("id, nome, cor, icone")
    .order("nome", { ascending: true });
  if (!withIcon.error) return (withIcon.data ?? []) as Record<string, unknown>[];

  if (!String(withIcon.error.message).includes("icone")) throw withIcon.error;

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
    const payload: Record<string, unknown> = {
      nome: input.name.trim(),
      cor: input.color,
      icone: input.icon ?? DEFAULT_PROJECT_ICON,
      user_id: userId,
      ...(input.description?.trim() ? { descricao: input.description.trim() } : {}),
    };
    const { data, error } = await this.client
      .from("projects")
      .insert(payload)
      .select("id")
      .single();
    if (error) {
      if (String(error.message).includes("icone")) {
        delete payload.icone;
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

  async fetchProjectsWithTaskStats(): Promise<ProjectWithStats[]> {
    let data: Record<string, unknown>[] | null = null;
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

import type { Project, Section } from "@/lib/types/project";
import type { ViewTasks } from "@/lib/types/task";
import { createClient } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { ProjectRepository } from "@/lib/repositories/project-repository";
import { SectionRepository } from "@/lib/repositories/section-repository";
import { TaskRepository } from "@/lib/repositories/task-repository";

export type ProjectDetailSnapshot = {
  project: Project | null;
  sections: Section[];
  viewTasks: ViewTasks;
  fetchedAt: number;
};

class ProjectDetailCache {
  private cache = new Map<string, ProjectDetailSnapshot>();
  private inflight = new Map<string, Promise<ProjectDetailSnapshot>>();

  snapshot(projectId: string): ProjectDetailSnapshot | null {
    return this.cache.get(projectId) ?? null;
  }

  prefetch(projectId: string): void {
    if (!isSupabaseConfigured()) return;
    if (this.cache.has(projectId) || this.inflight.has(projectId)) return;
    const promise = this.load(projectId);
    this.inflight.set(projectId, promise);
    void promise.finally(() => {
      this.inflight.delete(projectId);
    });
  }

  async load(projectId: string): Promise<ProjectDetailSnapshot> {
    const hit = this.cache.get(projectId);
    if (hit) return hit;

    const existing = this.inflight.get(projectId);
    if (existing) return existing;

    const promise = (async () => {
      const client = createClient();
      const taskRepo = new TaskRepository(client);
      const [viewTasks, project, sections] = await Promise.all([
        taskRepo.fetchProjectTasks(projectId),
        new ProjectRepository(client).fetchProjectById(projectId),
        new SectionRepository(client).getSectionsForProject(projectId),
      ]);
      const snapshot: ProjectDetailSnapshot = {
        project: project ?? null,
        sections,
        viewTasks,
        fetchedAt: Date.now(),
      };
      this.cache.set(projectId, snapshot);
      return snapshot;
    })();

    this.inflight.set(projectId, promise);
    try {
      return await promise;
    } finally {
      this.inflight.delete(projectId);
    }
  }

  invalidate(projectId?: string): void {
    if (projectId) {
      this.cache.delete(projectId);
      this.inflight.delete(projectId);
    } else {
      this.cache.clear();
      this.inflight.clear();
    }
  }

  upsert(
    projectId: string,
    snapshot: Omit<ProjectDetailSnapshot, "fetchedAt">,
  ): void {
    this.cache.set(projectId, { ...snapshot, fetchedAt: Date.now() });
  }

  patchViewTasks(projectId: string, viewTasks: ViewTasks): void {
    const hit = this.cache.get(projectId);
    if (!hit) return;
    this.cache.set(projectId, { ...hit, viewTasks, fetchedAt: Date.now() });
  }
}

export const projectDetailCache = new ProjectDetailCache();

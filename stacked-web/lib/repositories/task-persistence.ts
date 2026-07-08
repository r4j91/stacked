import type { SupabaseClient } from "@supabase/supabase-js";
import type { Priority } from "@/lib/types/task";
import { toDbPriority } from "@/lib/utils/priority";

export class TaskPersistence {
  constructor(private client: SupabaseClient) {}

  async autosaveTaskTitle(taskId: string, title: string): Promise<void> {
    const trimmed = title.trim();
    if (!trimmed) return;
    const { error } = await this.client.from("tasks").update({ titulo: trimmed }).eq("id", taskId);
    if (error) throw error;
  }

  async autosaveTaskDescription(taskId: string, description: string): Promise<void> {
    const trimmed = description.trim();
    const { error } = await this.client
      .from("tasks")
      .update({ descricao: trimmed || null })
      .eq("id", taskId);
    if (error) throw error;
  }

  async autosaveSubtaskTitle(subtaskId: string, title: string): Promise<void> {
    const trimmed = title.trim();
    if (!trimmed) return;
    const { error } = await this.client
      .from("subtasks")
      .update({ titulo: trimmed })
      .eq("id", subtaskId);
    if (error) throw error;
  }

  async autosaveSubtaskDescription(subtaskId: string, description: string): Promise<void> {
    const trimmed = description.trim();
    const { error } = await this.client
      .from("subtasks")
      .update({ descricao: trimmed || null })
      .eq("id", subtaskId);
    if (error) throw error;
  }

  async updateTaskPriority(taskId: string, priority: Priority | null): Promise<void> {
    const { error } = await this.client
      .from("tasks")
      .update({ prioridade: toDbPriority(priority) })
      .eq("id", taskId);
    if (error) throw error;
  }

  async updateTaskDueDate(taskId: string, dueDate: string | null): Promise<void> {
    const { error } = await this.client
      .from("tasks")
      .update({ data_vencimento: dueDate })
      .eq("id", taskId);
    if (error) throw error;
  }

  async updateTaskProject(taskId: string, projectId: string | null): Promise<void> {
    const { error } = await this.client
      .from("tasks")
      .update({ project_id: projectId })
      .eq("id", taskId);
    if (error) throw error;
  }

  async updateTaskRecurrence(taskId: string, recurrence: string | null): Promise<void> {
    const { error } = await this.client
      .from("tasks")
      .update({ recorrencia: recurrence })
      .eq("id", taskId);
    if (error) throw error;
  }

  async updateSubtaskPriority(subtaskId: string, priority: Priority | null): Promise<void> {
    const { error } = await this.client
      .from("subtasks")
      .update({ prioridade: toDbPriority(priority) })
      .eq("id", subtaskId);
    if (error) throw error;
  }

  async updateSubtaskDueDate(subtaskId: string, dueDate: string | null): Promise<void> {
    const { error } = await this.client
      .from("subtasks")
      .update({ data_vencimento: dueDate })
      .eq("id", subtaskId);
    if (error) throw error;
  }

  async updateSubtaskTime(subtaskId: string, time: string | null): Promise<void> {
    const { error } = await this.client
      .from("subtasks")
      .update({ hora: time })
      .eq("id", subtaskId);
    if (error) throw error;
  }

  async updateSubtaskLabelIds(subtaskId: string, labelIds: string[]): Promise<void> {
    const { error } = await this.client
      .from("subtasks")
      .update({ label_ids: labelIds.length ? labelIds : null })
      .eq("id", subtaskId);
    if (error) throw error;
  }
}

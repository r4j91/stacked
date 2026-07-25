import type { SupabaseClient } from "@supabase/supabase-js";
import {
  ATTACHMENT_MAX_BYTES,
  isAllowedAttachmentMime,
  type TaskAttachment,
} from "@/lib/types/attachment";

type DbRow = {
  id: string;
  task_id: string;
  subtask_id: string | null;
  file_name: string;
  mime_type: string;
  size_bytes: number;
  storage_path: string;
  created_at: string;
};

function mapRow(row: DbRow): TaskAttachment {
  return {
    id: row.id,
    taskId: row.task_id,
    subtaskId: row.subtask_id,
    fileName: row.file_name,
    mimeType: row.mime_type,
    sizeBytes: Number(row.size_bytes),
    storagePath: row.storage_path,
    createdAt: row.created_at,
  };
}

function sanitizeFileName(name: string): string {
  return name.replace(/[^\w.\-()+ ]+/g, "_").slice(0, 180) || "arquivo";
}

export class AttachmentRepository {
  constructor(private client: SupabaseClient) {}

  async listForTask(taskId: string): Promise<TaskAttachment[]> {
    const { data, error } = await this.client
      .from("task_attachments")
      .select("id, task_id, subtask_id, file_name, mime_type, size_bytes, storage_path, created_at")
      .eq("task_id", taskId)
      .is("subtask_id", null)
      .order("created_at", { ascending: true });
    if (error) throw error;
    return (data as DbRow[] | null)?.map(mapRow) ?? [];
  }

  async listForSubtask(subtaskId: string): Promise<TaskAttachment[]> {
    const { data, error } = await this.client
      .from("task_attachments")
      .select("id, task_id, subtask_id, file_name, mime_type, size_bytes, storage_path, created_at")
      .eq("subtask_id", subtaskId)
      .order("created_at", { ascending: true });
    if (error) throw error;
    return (data as DbRow[] | null)?.map(mapRow) ?? [];
  }

  async upload(input: {
    taskId: string;
    subtaskId?: string | null;
    file: File;
  }): Promise<TaskAttachment> {
    const {
      data: { user },
    } = await this.client.auth.getUser();
    if (!user) throw new Error("Não autenticado");

    const mime = input.file.type || "application/octet-stream";
    if (!isAllowedAttachmentMime(mime)) {
      throw new Error("Só imagens ou PDF");
    }
    if (input.file.size <= 0 || input.file.size > ATTACHMENT_MAX_BYTES) {
      throw new Error("Arquivo deve ter no máximo 20 MB");
    }

    const id = crypto.randomUUID();
    const safeName = sanitizeFileName(input.file.name);
    const path = `${user.id}/${id}/${safeName}`;

    const { error: uploadError } = await this.client.storage
      .from("attachments")
      .upload(path, input.file, { contentType: mime, upsert: false });
    if (uploadError) throw uploadError;

    const { data, error } = await this.client
      .from("task_attachments")
      .insert({
        id,
        user_id: user.id,
        task_id: input.taskId,
        subtask_id: input.subtaskId ?? null,
        storage_path: path,
        file_name: safeName,
        mime_type: mime,
        size_bytes: input.file.size,
      })
      .select("id, task_id, subtask_id, file_name, mime_type, size_bytes, storage_path, created_at")
      .single();

    if (error) {
      await this.client.storage.from("attachments").remove([path]);
      throw error;
    }
    return mapRow(data as DbRow);
  }

  async createSignedUrl(storagePath: string, expiresIn = 3600): Promise<string> {
    const { data, error } = await this.client.storage
      .from("attachments")
      .createSignedUrl(storagePath, expiresIn);
    if (error) throw error;
    return data.signedUrl;
  }

  async remove(attachment: TaskAttachment): Promise<void> {
    const { error } = await this.client.from("task_attachments").delete().eq("id", attachment.id);
    if (error) throw error;
    await this.client.storage.from("attachments").remove([attachment.storagePath]);
  }
}

export type TaskAttachment = {
  id: string;
  taskId: string;
  subtaskId: string | null;
  fileName: string;
  mimeType: string;
  sizeBytes: number;
  storagePath: string;
  createdAt: string;
};

export const ATTACHMENT_MAX_BYTES = 20 * 1024 * 1024;

export function isAllowedAttachmentMime(mime: string): boolean {
  return mime.startsWith("image/") || mime === "application/pdf";
}

export function formatAttachmentSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

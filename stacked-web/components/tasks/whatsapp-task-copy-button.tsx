"use client";

import { useState } from "react";
import type { Task } from "@/lib/types/task";
import { AppIcon } from "@/components/ui/app-icon";
import { Copy01Icon } from "@/lib/icons/nav-icons";
import {
  buildWhatsAppRoutineMessage,
  taskShowsWhatsAppCopy,
} from "@/lib/utils/whatsapp-routine-message";
import { WhatsAppCopyPreviewSheet } from "@/components/tasks/whatsapp-copy-preview-sheet";

type WhatsAppTaskCopyButtonProps = {
  task: Task;
  className?: string;
};

export function WhatsAppTaskCopyButton({ task, className }: WhatsAppTaskCopyButtonProps) {
  const [open, setOpen] = useState(false);

  if (!taskShowsWhatsAppCopy(task)) return null;

  return (
    <>
      <button
        type="button"
        onClick={(e) => {
          e.stopPropagation();
          setOpen(true);
        }}
        className={
          className ??
          "mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-accent)] hover:bg-[var(--color-hover-overlay)]"
        }
        aria-label="Copiar mensagem para WhatsApp"
      >
        <AppIcon icon={Copy01Icon} size={16} />
      </button>
      <WhatsAppCopyPreviewSheet
        open={open}
        onClose={() => setOpen(false)}
        taskTitle={task.title}
        message={buildWhatsAppRoutineMessage(task)}
      />
    </>
  );
}

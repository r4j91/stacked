"use client";

import { useEffect, useState } from "react";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AnchoredPopover } from "@/components/ui/anchored-popover";
import { AppIcon } from "@/components/ui/app-icon";
import {
  Calendar03Icon,
  Cancel01Icon,
  Logout01Icon,
} from "@/lib/icons/nav-icons";
import {
  connectGoogleCalendarUrl,
  disconnectGoogleCalendar,
  setGoogleCalendarImport,
} from "@/lib/services/google-calendar-client";

export function CalendarSettingsSheet() {
  const {
    calendarOpen,
    calendarAnchor,
    closeCalendar,
    googleCalendar,
    refreshGoogleCalendar,
    refreshTasks,
  } = useWorkbench();
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    if (calendarOpen) setMessage(null);
  }, [calendarOpen]);

  async function toggleImport(next: boolean) {
    setBusy(true);
    setMessage(null);
    try {
      await setGoogleCalendarImport(next);
      await refreshGoogleCalendar();
      await refreshTasks();
    } catch {
      setMessage("Não foi possível atualizar a preferência.");
    } finally {
      setBusy(false);
    }
  }

  async function disconnect() {
    setBusy(true);
    setMessage(null);
    try {
      await disconnectGoogleCalendar();
      await refreshGoogleCalendar();
      await refreshTasks();
    } catch {
      setMessage("Não foi possível desconectar.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <AnchoredPopover
      open={calendarOpen}
      onClose={closeCalendar}
      anchorRect={calendarAnchor}
      width={320}
      preferSide="right"
      verticalAlign="end"
      className="max-h-[min(85vh,520px)] p-0"
      labelledBy="calendar-settings-title"
    >
      <div className="flex items-center justify-between border-b border-[var(--color-border)] px-4 py-3">
        <h2 id="calendar-settings-title" className="text-base font-bold">
          Google Calendar
        </h2>
        <button
          type="button"
          onClick={closeCalendar}
          className="flex h-8 w-8 items-center justify-center rounded-full text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)]"
          aria-label="Fechar"
        >
          <AppIcon icon={Cancel01Icon} size={16} />
        </button>
      </div>

      <div className="scroll-thin space-y-4 overflow-y-auto px-4 py-4">
        {!googleCalendar.configured ? (
          <p className="text-sm text-[var(--color-text-secondary)]">
            Integração não configurada no servidor. Adicione{" "}
            <code className="text-xs">GOOGLE_CLIENT_ID</code>,{" "}
            <code className="text-xs">GOOGLE_CLIENT_SECRET</code> e{" "}
            <code className="text-xs">SUPABASE_SERVICE_ROLE_KEY</code> nas variáveis de ambiente.
          </p>
        ) : !googleCalendar.connected ? (
          <>
            <p className="text-sm text-[var(--color-text-secondary)]">
              Conecte sua conta Google para ver compromissos em <strong>Hoje</strong> e{" "}
              <strong>Em breve</strong>, junto com suas tarefas.
            </p>
            <a
              href={connectGoogleCalendarUrl()}
              className="btn-primary inline-flex w-full items-center justify-center gap-2 rounded-[var(--radius-sm)] px-4 py-2.5 text-sm font-semibold"
            >
              <AppIcon icon={Calendar03Icon} size={16} />
              Conectar Google Calendar
            </a>
          </>
        ) : (
          <>
            <div className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-variant)]/50 px-3 py-2.5">
              <p className="text-xs text-[var(--color-text-tertiary)]">Conta conectada</p>
              <p className="truncate text-sm font-semibold text-[var(--color-text)]">
                {googleCalendar.email ?? "Google Calendar"}
              </p>
            </div>

            <label className="flex items-center justify-between gap-3 rounded-[var(--radius-sm)] py-1">
              <span className="text-sm text-[var(--color-text)]">Importar compromissos</span>
              <input
                type="checkbox"
                checked={googleCalendar.importEnabled}
                disabled={busy}
                onChange={(e) => void toggleImport(e.target.checked)}
                className="h-4 w-4 accent-[var(--color-accent)]"
              />
            </label>
            <p className="text-xs text-[var(--color-text-tertiary)]">
              Compromissos aparecem somente leitura — não viram tarefas Stacked.
            </p>

            <button
              type="button"
              disabled={busy}
              onClick={() => void disconnect()}
              className="inline-flex w-full items-center justify-center gap-2 rounded-[var(--radius-sm)] border border-[var(--color-border)] px-3 py-2 text-sm text-[var(--color-overdue)] hover:bg-[var(--color-hover-overlay)] disabled:opacity-60"
            >
              <AppIcon icon={Logout01Icon} size={16} />
              Desconectar
            </button>
          </>
        )}

        {message && <p className="text-sm text-[var(--color-overdue)]">{message}</p>}
      </div>
    </AnchoredPopover>
  );
}

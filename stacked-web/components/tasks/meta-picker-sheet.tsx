"use client";

import type { Priority } from "@/lib/types/task";
import type { Label } from "@/lib/types/label";
import type { Project } from "@/lib/types/project";
import { AppIcon } from "@/components/ui/app-icon";
import { ProjectIcon } from "@/components/ui/project-icon";
import { CalendarGrid } from "@/components/tasks/calendar-grid";
import {
  Cancel01Icon,
  Flag01Icon,
  Folder01Icon,
  Tag01Icon,
  Calendar03Icon,
  RepeatIcon,
  InboxIcon,
  Tick01Icon,
} from "@/lib/icons/nav-icons";
import { addDays, toDateStr, startOfDay } from "@/lib/utils/date";
import type { Recurrence, RecurrenceType } from "@/lib/utils/recurrence";
import { parseRecurrence, recurrenceLabel, recurrenceToJson } from "@/lib/utils/recurrence";
import type { Home01Icon } from "@hugeicons/core-free-icons";
import { AnchoredPopover, type AnchorRect } from "@/components/ui/anchored-popover";

type SheetShellProps = {
  open: boolean;
  onClose: () => void;
  title: string;
  icon?: typeof Calendar03Icon;
  children: React.ReactNode;
  anchorRect?: AnchorRect | null;
};

function SheetShell({ open, onClose, title, icon, children, anchorRect }: SheetShellProps) {
  if (!open) return null;

  const header = (
  <>
      <div className="mb-3 flex items-center gap-2">
        {icon && <AppIcon icon={icon} size={18} className="text-[var(--color-text-secondary)]" />}
        <h2 className="flex-1 text-base font-bold">{title}</h2>
        <button
          type="button"
          onClick={onClose}
          className="flex h-8 w-8 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)]"
          aria-label="Fechar"
        >
          <AppIcon icon={Cancel01Icon} size={18} />
        </button>
      </div>
      {children}
    </>
  );

  if (anchorRect) {
    return (
      <AnchoredPopover open={open} onClose={onClose} anchorRect={anchorRect} width={300} preferSide="left">
        {header}
      </AnchoredPopover>
    );
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 sm:items-center sm:p-4"
      onClick={onClose}
      role="presentation"
    >
      <div
        className="w-full max-w-sm rounded-t-[var(--radius-lg)] bg-[var(--color-surface)] p-4 shadow-xl sm:rounded-[var(--radius-lg)]"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
      >
        {header}
      </div>
    </div>
  );
}

type PickerBaseProps = {
  anchorRect?: AnchorRect | null;
};
type DatePickerProps = PickerBaseProps & {
  open: boolean;
  onClose: () => void;
  value?: string | null;
  onChange: (date: string | null) => void;
};

export function DatePicker({ open, onClose, value, onChange, anchorRect }: DatePickerProps) {
  const today = startOfDay(new Date());

  function pick(offsetDays: number | null) {
    if (offsetDays === null) {
      onChange(null);
    } else {
      onChange(toDateStr(addDays(today, offsetDays)));
    }
    onClose();
  }

  return (
    <SheetShell open={open} onClose={onClose} title="Data" icon={Calendar03Icon} anchorRect={anchorRect}>
      <div className="flex flex-col gap-1">
        <PickerButton
          label="Hoje"
          icon={Calendar03Icon}
          active={value === toDateStr(today)}
          onClick={() => pick(0)}
        />
        <PickerButton label="Amanhã" icon={Calendar03Icon} onClick={() => pick(1)} />
        <PickerButton label="+7 dias" icon={Calendar03Icon} onClick={() => pick(7)} />
        <PickerButton label="Limpar data" icon={Cancel01Icon} muted onClick={() => pick(null)} />
      </div>
      <div className="mt-3">
        <p className="mb-2 text-xs font-medium text-[var(--color-text-tertiary)]">Escolher data</p>
        <CalendarGrid
          value={value}
          onChange={(date) => {
            onChange(date);
            onClose();
          }}
        />
      </div>
    </SheetShell>
  );
}

type PriorityPickerProps = PickerBaseProps & {
  open: boolean;
  onClose: () => void;
  value?: Priority | null;
  onChange: (priority: Priority | null) => void;
};

const PRIORITIES: { id: Priority; label: string; color: string }[] = [
  { id: "P1", label: "Prioridade 1", color: "var(--color-p1)" },
  { id: "P2", label: "Prioridade 2", color: "var(--color-p2)" },
  { id: "P3", label: "Prioridade 3", color: "var(--color-p3)" },
];

export function PriorityPicker({ open, onClose, value, onChange, anchorRect }: PriorityPickerProps) {
  return (
    <SheetShell open={open} onClose={onClose} title="Prioridade" icon={Flag01Icon} anchorRect={anchorRect}>
      <div className="flex flex-col gap-1">
        {PRIORITIES.map((p) => (
          <PickerButton
            key={p.id}
            label={p.label}
            icon={Flag01Icon}
            iconColor={p.color}
            active={value === p.id}
            onClick={() => {
              onChange(p.id);
              onClose();
            }}
          />
        ))}
        <PickerButton
          label="Sem prioridade"
          icon={Flag01Icon}
          muted
          active={!value}
          onClick={() => {
            onChange(null);
            onClose();
          }}
        />
      </div>
    </SheetShell>
  );
}

type ProjectPickerProps = PickerBaseProps & {
  open: boolean;
  onClose: () => void;
  value?: string | null;
  projects: Project[];
  onChange: (projectId: string | null) => void;
};

export function ProjectPicker({ open, onClose, value, projects, onChange, anchorRect }: ProjectPickerProps) {
  return (
    <SheetShell open={open} onClose={onClose} title="Projeto" icon={Folder01Icon} anchorRect={anchorRect}>
      <div className="flex max-h-64 flex-col gap-1 overflow-y-auto scroll-thin">
        <PickerButton
          label="Inbox"
          icon={InboxIcon}
          active={!value}
          onClick={() => {
            onChange(null);
            onClose();
          }}
        />
        {projects.map((p) => (
          <PickerButton
            key={p.id}
            label={p.name}
            projectIcon={p.icon}
            dot={p.color}
            active={value === p.id}
            onClick={() => {
              onChange(p.id);
              onClose();
            }}
          />
        ))}
      </div>
    </SheetShell>
  );
}

type RecurrencePickerProps = PickerBaseProps & {
  open: boolean;
  onClose: () => void;
  value?: string | null;
  onChange: (recurrence: string | null) => void;
};

const RECURRENCE_OPTIONS: { type: RecurrenceType; label: string }[] = [
  { type: "daily", label: "Todo dia" },
  { type: "weekly", label: "Toda semana" },
  { type: "monthly", label: "Todo mês" },
  { type: "yearly", label: "Todo ano" },
];

export function RecurrencePicker({ open, onClose, value, onChange, anchorRect }: RecurrencePickerProps) {
  const current = parseRecurrence(value);

  function pick(type: RecurrenceType | null) {
    if (!type) {
      onChange(null);
    } else {
      const recurrence: Recurrence = { type };
      onChange(recurrenceToJson(recurrence));
    }
    onClose();
  }

  return (
    <SheetShell open={open} onClose={onClose} title="Repetir" icon={RepeatIcon} anchorRect={anchorRect}>
      <div className="flex flex-col gap-1">
        {RECURRENCE_OPTIONS.map((opt) => (
          <PickerButton
            key={opt.type}
            label={opt.label}
            icon={RepeatIcon}
            active={current?.type === opt.type}
            onClick={() => pick(opt.type)}
          />
        ))}
        <PickerButton
          label="Sem repetição"
          icon={Cancel01Icon}
          muted
          active={!current}
          onClick={() => pick(null)}
        />
        {current && (
          <p className="mt-2 px-2 text-xs text-[var(--color-text-tertiary)]">
            Atual: {recurrenceLabel(current)}
          </p>
        )}
      </div>
    </SheetShell>
  );
}

type LabelsPickerProps = PickerBaseProps & {
  open: boolean;
  onClose: () => void;
  value: string[];
  labels: Label[];
  onChange: (labelIds: string[]) => void;
};

export function LabelsPicker({ open, onClose, value, labels, onChange, anchorRect }: LabelsPickerProps) {
  const selected = new Set(value);

  function toggle(id: string) {
    const next = new Set(selected);
    if (next.has(id)) next.delete(id);
    else next.add(id);
    onChange([...next]);
  }

  return (
    <SheetShell open={open} onClose={onClose} title="Etiquetas" icon={Tag01Icon} anchorRect={anchorRect}>
      <div className="flex max-h-64 flex-col gap-1 overflow-y-auto scroll-thin">
        {labels.length === 0 && (
          <p className="px-2 py-3 text-sm text-[var(--color-text-tertiary)]">Nenhuma etiqueta criada.</p>
        )}
        {labels.map((l) => (
          <button
            key={l.id}
            type="button"
            onClick={() => toggle(l.id)}
            className={`flex items-center gap-2.5 rounded-[var(--radius-sm)] px-3 py-2 text-left text-sm hover:bg-[var(--color-surface-variant)] ${
              selected.has(l.id) ? "bg-[var(--color-surface-variant)] font-semibold" : ""
            }`}
          >
            <span style={{ color: l.color }}>
              <AppIcon icon={Tag01Icon} size={16} strokeWidth={1.75} />
            </span>
            <span className="flex-1" style={{ color: selected.has(l.id) ? l.color : undefined }}>
              {l.name}
            </span>
            {selected.has(l.id) && (
              <span style={{ color: l.color }}>
                <AppIcon icon={Tick01Icon} size={16} strokeWidth={2.5} />
              </span>
            )}
          </button>
        ))}
      </div>
      <button type="button" onClick={onClose} className="btn-primary mt-3 w-full rounded-[var(--radius-sm)] py-2 text-sm">
        Concluir
      </button>
    </SheetShell>
  );
}

function PickerButton({
  label,
  onClick,
  active,
  muted,
  dot,
  projectIcon,
  icon,
  iconColor,
}: {
  label: string;
  onClick: () => void;
  active?: boolean;
  muted?: boolean;
  dot?: string;
  projectIcon?: string | null;
  icon?: typeof Calendar03Icon;
  iconColor?: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex items-center gap-2.5 rounded-[var(--radius-sm)] px-3 py-2 text-left text-sm hover:bg-[var(--color-surface-variant)] ${
        active ? "bg-[var(--color-surface-variant)] font-semibold" : ""
      } ${muted ? "text-[var(--color-text-tertiary)]" : ""}`}
    >
      {projectIcon != null && dot ? (
        <ProjectIcon iconKey={projectIcon} color={dot} size={18} />
      ) : icon ? (
        <span style={{ color: iconColor ?? "var(--color-text-secondary)" }}>
          <AppIcon icon={icon as typeof Home01Icon} size={16} strokeWidth={1.75} />
        </span>
      ) : (
        dot && <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: dot }} />
      )}
      <span className="flex-1">{label}</span>
    </button>
  );
}

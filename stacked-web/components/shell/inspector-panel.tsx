"use client";

import { useEffect, useState } from "react";
import { useWorkbench, type SubtaskKey } from "./workbench-context";
import type { Subtask, Task } from "@/lib/types/task";
import { parseDueDate, isOverdueDate } from "@/lib/utils/date";
import { AutosaveTextarea } from "@/components/tasks/autosave-textarea";
import { InstallmentGeneratorSheet } from "@/components/tasks/installment-generator-sheet";
import { AppIcon } from "@/components/ui/app-icon";
import {
  Cancel01Icon,
  Flag01Icon,
  Folder01Icon,
  Tag01Icon,
  Calendar03Icon,
  Add01Icon,
  Delete01Icon,
  RepeatIcon,
  ArrowUp01Icon,
} from "@/lib/icons/nav-icons";
import {
  DatePicker,
  PriorityPicker,
  ProjectPicker,
  LabelsPicker,
  RecurrencePicker,
} from "@/components/tasks/meta-picker-sheet";
import { DoneCircle } from "@/components/ui/done-circle";
import { anchorFromElement, type AnchorRect } from "@/components/ui/anchored-popover";
import { priorityLabel, priorityColor } from "@/lib/utils/priority";
import { parseRecurrence, recurrenceLabel } from "@/lib/utils/recurrence";
import { createClient } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { CommentRepository, type Comment } from "@/lib/repositories/comment-repository";

function MetaCard({
  item,
  taskId,
}: {
  item: Task;
  taskId: string;
}) {
  const {
    projects,
    labels,
    updateTaskPriority,
    updateTaskDueDate,
    updateTaskProject,
    updateTaskLabels,
    updateTaskRecurrence,
  } = useWorkbench();

  const [dateOpen, setDateOpen] = useState(false);
  const [priorityOpen, setPriorityOpen] = useState(false);
  const [projectOpen, setProjectOpen] = useState(false);
  const [labelsOpen, setLabelsOpen] = useState(false);
  const [recurrenceOpen, setRecurrenceOpen] = useState(false);
  const [pickerAnchor, setPickerAnchor] = useState<AnchorRect | null>(null);

  function openPicker(e: React.MouseEvent<HTMLButtonElement>, open: () => void) {
    setPickerAnchor(anchorFromElement(e.currentTarget));
    open();
  }

  const project = item.project;
  const projectId = item.projectId;
  const date = item.date;
  const tag = item.tag;
  const priority = item.priority;
  const labelIds = item.labelIds ?? [];
  const recurrenceRaw = item.recurrence;
  const recurrence = parseRecurrence(recurrenceRaw);
  const labelNames = labels
    .filter((l) => labelIds.includes(l.id))
    .map((l) => l.name)
    .join(", ");
  const selectedLabels = labels.filter((l) => labelIds.includes(l.id));
  const tagLabel = tag ? labels.find((l) => l.name === tag) : undefined;
  const labelColor =
    selectedLabels.length === 1
      ? selectedLabels[0].color
      : selectedLabels.length > 1
        ? selectedLabels[0].color
        : tagLabel?.color;
  const overdue = isOverdueDate(parseDueDate(item.dueDate ?? date), Boolean(item.done));
  const projectEntity = projects.find((p) => p.id === projectId);

  return (
    <>
      <div className="divide-y divide-[var(--color-border)] overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)]/60">
        <MetaRow
          icon={Folder01Icon}
          label="Projeto"
          value={project || "Sem projeto"}
          valueColor={projectEntity?.color}
          onClick={(e) => openPicker(e, () => setProjectOpen(true))}
        />
        <MetaRow
          icon={Calendar03Icon}
          label="Data"
          value={date || "Sem data"}
          danger={overdue}
          valueColor={date && !overdue ? "var(--color-text-secondary)" : undefined}
          onClick={(e) => openPicker(e, () => setDateOpen(true))}
        />
        <MetaRow
          icon={Tag01Icon}
          label="Etiquetas"
          value={labelNames || tag || "Nenhuma"}
          valueColor={labelNames || tag ? labelColor : undefined}
          onClick={(e) => openPicker(e, () => setLabelsOpen(true))}
        />
        <MetaRow
          icon={Flag01Icon}
          label="Prioridade"
          value={priority ? priorityLabel(priority) : "Nenhuma"}
          valueColor={priority ? priorityColor(priority) : undefined}
          onClick={(e) => openPicker(e, () => setPriorityOpen(true))}
        />
        <MetaRow
          icon={RepeatIcon}
          label="Repetir"
          value={recurrence ? recurrenceLabel(recurrence) : "Sem repetição"}
          onClick={(e) => openPicker(e, () => setRecurrenceOpen(true))}
        />
      </div>
      <DatePicker
        open={dateOpen}
        onClose={() => setDateOpen(false)}
        value={item.dueDate}
        onChange={(d) => void updateTaskDueDate(taskId, d)}
        anchorRect={pickerAnchor}
      />
      <PriorityPicker
        open={priorityOpen}
        onClose={() => setPriorityOpen(false)}
        value={priority}
        onChange={(p) => void updateTaskPriority(taskId, p)}
        anchorRect={pickerAnchor}
      />
      <ProjectPicker
        open={projectOpen}
        onClose={() => setProjectOpen(false)}
        projects={projects}
        value={projectId}
        onChange={(pid) => void updateTaskProject(taskId, pid)}
        anchorRect={pickerAnchor}
      />
      <LabelsPicker
        open={labelsOpen}
        onClose={() => setLabelsOpen(false)}
        labels={labels}
        value={labelIds}
        onChange={(ids) => void updateTaskLabels(taskId, ids)}
        anchorRect={pickerAnchor}
      />
      <RecurrencePicker
        open={recurrenceOpen}
        onClose={() => setRecurrenceOpen(false)}
        value={recurrenceRaw}
        onChange={(r) => void updateTaskRecurrence(taskId, r)}
        anchorRect={pickerAnchor}
      />
    </>
  );
}

function SubtaskMetaCard({
  subtaskKey,
  sub,
  parentTask,
}: {
  subtaskKey: SubtaskKey;
  sub: Subtask;
  parentTask: Task;
}) {
  const { labels, updateSubtaskPriority, updateSubtaskDueDate, updateSubtaskLabels } = useWorkbench();
  const [dateOpen, setDateOpen] = useState(false);
  const [priorityOpen, setPriorityOpen] = useState(false);
  const [labelsOpen, setLabelsOpen] = useState(false);
  const [pickerAnchor, setPickerAnchor] = useState<AnchorRect | null>(null);

  function openPicker(e: React.MouseEvent<HTMLButtonElement>, open: () => void) {
    setPickerAnchor(anchorFromElement(e.currentTarget));
    open();
  }

  const labelIds = sub.labelIds ?? [];
  const labelNames = labels
    .filter((l) => labelIds.includes(l.id))
    .map((l) => l.name)
    .join(", ");
  const selectedLabels = labels.filter((l) => labelIds.includes(l.id));
  const labelColor = selectedLabels.length > 0 ? selectedLabels[0].color : undefined;
  const overdue = isOverdueDate(parseDueDate(sub.dueDate), Boolean(sub.done));

  return (
    <>
      <div className="divide-y divide-[var(--color-border)] overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)]/60">
        <MetaRow icon={Folder01Icon} label="Projeto" value={parentTask.project || "Sem projeto"} />
        <MetaRow
          icon={Calendar03Icon}
          label="Data"
          value={sub.date || "Sem data"}
          danger={overdue}
          valueColor={sub.date && !overdue ? "var(--color-text-secondary)" : undefined}
          onClick={(e) => openPicker(e, () => setDateOpen(true))}
        />
        <MetaRow
          icon={Tag01Icon}
          label="Etiquetas"
          value={labelNames || "Nenhuma"}
          valueColor={labelNames ? labelColor : undefined}
          onClick={(e) => openPicker(e, () => setLabelsOpen(true))}
        />
        <MetaRow
          icon={Flag01Icon}
          label="Prioridade"
          value={sub.priority ? priorityLabel(sub.priority) : "Nenhuma"}
          valueColor={sub.priority ? priorityColor(sub.priority) : undefined}
          onClick={(e) => openPicker(e, () => setPriorityOpen(true))}
        />
      </div>
      <DatePicker
        open={dateOpen}
        onClose={() => setDateOpen(false)}
        value={sub.dueDate}
        onChange={(d) => void updateSubtaskDueDate(subtaskKey, d)}
        anchorRect={pickerAnchor}
      />
      <PriorityPicker
        open={priorityOpen}
        onClose={() => setPriorityOpen(false)}
        value={sub.priority}
        onChange={(p) => void updateSubtaskPriority(subtaskKey, p)}
        anchorRect={pickerAnchor}
      />
      <LabelsPicker
        open={labelsOpen}
        onClose={() => setLabelsOpen(false)}
        labels={labels}
        value={labelIds}
        onChange={(ids) => void updateSubtaskLabels(subtaskKey, ids)}
        anchorRect={pickerAnchor}
      />
    </>
  );
}

function MetaRow({
  icon,
  label,
  value,
  danger,
  valueColor,
  onClick,
}: {
  icon: typeof Folder01Icon;
  label: string;
  value: string;
  danger?: boolean;
  valueColor?: string;
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
}) {
  const valueStyle = danger
    ? "text-[var(--color-overdue)]"
    : valueColor
      ? undefined
      : "text-[var(--color-text)]";

  const inner = (
    <>
      <AppIcon icon={icon} size={16} className="shrink-0 text-[var(--color-text-secondary)]" />
      <span className="w-14 shrink-0 text-xs text-[var(--color-text-secondary)]">{label}</span>
      <span
        className={`min-w-0 flex-1 text-sm font-medium ${valueStyle}`}
        style={!danger && valueColor ? { color: valueColor } : undefined}
      >
        {value}
      </span>
      {onClick && <span className="text-[var(--color-text-tertiary)]">›</span>}
    </>
  );

  if (onClick) {
    return (
      <button
        type="button"
        onClick={onClick}
        className="flex w-full items-center gap-3 px-4 py-2.5 text-left hover:bg-[var(--color-hover-overlay)]"
      >
        {inner}
      </button>
    );
  }

  return (
    <div className={`flex items-center gap-3 px-4 py-2.5 ${onClick ? "" : ""}`}>
      {inner}
    </div>
  );
}

function SubtasksCard({ task }: { task: Task }) {
  const { selectedSubtaskKey, selectSubtask, toggleSubtaskDone, createSubtask, deleteSubtask, refreshTasks } =
    useWorkbench();
  const subs = task.subtasks ?? [];
  const [newSub, setNewSub] = useState("");
  const [installmentOpen, setInstallmentOpen] = useState(false);

  if (!subs.length) {
    return (
      <>
        <div className="overflow-hidden rounded-[var(--radius-md)] bg-[var(--color-surface-variant)] p-4">
          <div className="mb-2 flex items-center justify-between gap-2">
            <p className="text-sm font-semibold">Subtarefas</p>
            <button
              type="button"
              onClick={() => setInstallmentOpen(true)}
              className="rounded-[var(--radius-sm)] px-2 py-1 text-xs font-medium text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)]"
            >
              Parcelas
            </button>
          </div>
        <form
          onSubmit={(e) => {
            e.preventDefault();
            const t = newSub.trim();
            if (!t) return;
            void createSubtask(task.id, t);
            setNewSub("");
          }}
          className="flex gap-2"
        >
          <input
            value={newSub}
            onChange={(e) => setNewSub(e.target.value)}
            placeholder="Nova subtarefa…"
            className="flex-1 rounded-[var(--radius-sm)] bg-[var(--color-bg)] px-3 py-2 text-sm outline-none placeholder:text-[var(--color-placeholder)] focus:ring-1 focus:ring-[var(--color-focus-ring)]"
          />
          <button type="submit" className="btn-primary rounded-[var(--radius-sm)] px-3 py-2">
            <AppIcon icon={Add01Icon} size={16} />
          </button>
        </form>
        </div>
        <InstallmentGeneratorSheet
          open={installmentOpen}
          onClose={() => setInstallmentOpen(false)}
          taskId={task.id}
          taskTitle={task.title}
          onGenerated={() => void refreshTasks()}
        />
      </>
    );
  }

  const done = subs.filter((s) => s.done).length;
  const pct = Math.round((done / subs.length) * 100);

  return (
    <>
    <div className="overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)]/60">
      <div className="flex items-center gap-2.5 px-4 py-3.5">
        <span className="flex-1 text-sm font-semibold">Subtarefas</span>
        <button
          type="button"
          onClick={() => setInstallmentOpen(true)}
          className="rounded-[var(--radius-sm)] px-2 py-1 text-xs font-medium text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)]"
        >
          Parcelas
        </button>
        <div className="h-0.5 max-w-20 flex-1 overflow-hidden rounded bg-white/10">
          <div className="h-full rounded bg-[var(--color-done)]" style={{ width: `${pct}%` }} />
        </div>
        <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">
          {done}/{subs.length}
        </span>
      </div>
      {subs.map((s, i) => {
        const key = `${task.id}:${i}` as SubtaskKey;
        const selected = selectedSubtaskKey === key;
        return (
          <div
            key={key}
            className={`flex items-center gap-2.5 border-t border-[var(--color-border)] px-4 py-2.5 ${
              selected ? "bg-[var(--color-hover-overlay-strong)]" : "hover:bg-[var(--color-hover-overlay)]"
            }`}
          >
            <DoneCircle
              small
              done={s.done}
              priority={s.priority}
              label={s.done ? "Marcar pendente" : "Marcar concluída"}
              onClick={() => toggleSubtaskDone(key)}
            />
            <button
              type="button"
              onClick={() => selectSubtask(task.id, i)}
              className={`min-w-0 flex-1 truncate text-left text-sm font-medium ${s.done ? "text-[var(--color-text-tertiary)] line-through" : ""}`}
            >
              {s.name}
            </button>
            {s.id && (
              <button
                type="button"
                onClick={() => void deleteSubtask(key)}
                className="text-[var(--color-text-tertiary)] hover:text-[var(--color-overdue)]"
                aria-label="Excluir subtarefa"
              >
                <AppIcon icon={Delete01Icon} size={14} />
              </button>
            )}
          </div>
        );
      })}
      <form
        onSubmit={(e) => {
          e.preventDefault();
          const t = newSub.trim();
          if (!t) return;
          void createSubtask(task.id, t);
          setNewSub("");
        }}
        className="flex gap-2 border-t border-[var(--color-border)] p-3"
      >
        <input
          value={newSub}
          onChange={(e) => setNewSub(e.target.value)}
          placeholder="Adicionar subtarefa…"
          className="flex-1 rounded-[var(--radius-sm)] bg-[var(--color-bg)] px-3 py-2 text-sm outline-none"
        />
        <button type="submit" className="rounded-[var(--radius-sm)] bg-[var(--color-surface)] px-3 py-2">
          <AppIcon icon={Add01Icon} size={16} />
        </button>
      </form>
    </div>
    <InstallmentGeneratorSheet
      open={installmentOpen}
      onClose={() => setInstallmentOpen(false)}
      taskId={task.id}
      taskTitle={task.title}
      onGenerated={() => void refreshTasks()}
    />
    </>
  );
}

function CommentsSection({ taskId }: { taskId: string }) {
  const { addComment } = useWorkbench();
  const [comments, setComments] = useState<Comment[]>([]);
  const [draft, setDraft] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isSupabaseConfigured()) {
      setLoading(false);
      return;
    }
    void new CommentRepository(createClient())
      .fetchComments(taskId)
      .then(setComments)
      .finally(() => setLoading(false));
  }, [taskId]);

  async function submit() {
    const text = draft.trim();
    if (!text) return;
    await addComment(taskId, text);
    setDraft("");
    if (isSupabaseConfigured()) {
      const next = await new CommentRepository(createClient()).fetchComments(taskId);
      setComments(next);
    }
  }

  return (
    <div className="mt-4">
      <h3 className="mb-2 text-sm font-semibold">Comentários</h3>
      {loading ? (
        <p className="text-xs text-[var(--color-text-tertiary)]">Carregando…</p>
      ) : comments.length ? (
        <ul className="mb-3 space-y-2">
          {comments.map((c) => (
            <li key={c.id} className="rounded-[var(--radius-sm)] bg-[var(--color-surface-variant)] px-3 py-2 text-sm">
              {c.text}
            </li>
          ))}
        </ul>
      ) : (
        <p className="mb-3 text-xs text-[var(--color-text-tertiary)]">Nenhum comentário ainda.</p>
      )}
      <div className="flex gap-2">
        <input
          type="text"
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") void submit();
          }}
          placeholder="Adicionar comentário…"
          className="flex-1 rounded-[var(--radius-md)] border border-transparent bg-[var(--color-surface-variant)] px-3.5 py-2.5 text-sm outline-none input-focus"
        />
        <button
          type="button"
          onClick={() => void submit()}
          className="flex h-[38px] w-[38px] shrink-0 items-center justify-center rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-variant)] text-[var(--color-text)] hover:border-[var(--color-border-strong)] hover:bg-[var(--color-hover-overlay-strong)]"
          aria-label="Enviar comentário"
        >
          <AppIcon icon={ArrowUp01Icon} size={18} strokeWidth={2} />
        </button>
      </div>
    </div>
  );
}

export function InspectorPanel() {
  const {
    inspectorOpen,
    closeInspector,
    selectedTask,
    selectedTaskId,
    selectedSubtaskKey,
    getSubtaskContext,
    selectTask,
    toggleTaskDone,
    toggleSubtaskDone,
    autosaveTaskTitle,
    autosaveTaskNotes,
    autosaveSubtaskTitle,
    autosaveSubtaskNotes,
  } = useWorkbench();

  const subCtx = getSubtaskContext();
  const isSub = Boolean(subCtx);

  const [title, setTitle] = useState("");
  const [notes, setNotes] = useState("");

  useEffect(() => {
    // Só reseta campos ao trocar seleção — não quando autosave atualiza sub.name/notes
    // (evita apagar edição em progresso no outro campo).
    if (selectedSubtaskKey) {
      const ctx = getSubtaskContext(selectedSubtaskKey);
      if (ctx) {
        setTitle(ctx.sub.name);
        setNotes(ctx.sub.notes ?? "");
      }
      return;
    }
    if (selectedTaskId && selectedTask) {
      setTitle(selectedTask.title);
      setNotes(selectedTask.notes ?? "");
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps -- sync only on selection change
  }, [selectedSubtaskKey, selectedTaskId]);

  if (!inspectorOpen || !selectedTask) return null;

  const task = selectedTask;

  function handleClose() {
    if (isSub && subCtx && selectedSubtaskKey) {
      void autosaveSubtaskTitle(selectedSubtaskKey, title);
      void autosaveSubtaskNotes(selectedSubtaskKey, notes);
    } else {
      void autosaveTaskTitle(task.id, title);
      void autosaveTaskNotes(task.id, notes);
    }
    closeInspector();
  }

  return (
    <>
      <div
        className="fixed inset-0 z-[var(--z-backdrop)] bg-black/30 lg:hidden"
        onClick={handleClose}
        aria-hidden
      />
      <aside
        className="fixed inset-y-0 right-0 z-[var(--z-panel)] flex w-full max-w-[var(--inspector-width)] flex-col overflow-hidden border-l border-[var(--color-border)] bg-[var(--color-inspector-bg)] shadow-xl lg:relative lg:inset-auto lg:z-auto lg:w-[var(--inspector-width)] lg:max-w-none lg:shrink-0 lg:shadow-none"
        aria-label="Detalhe da tarefa"
      >
        <header className="flex shrink-0 items-center gap-2 border-b border-[var(--color-border)] px-4 py-3.5 pt-[max(0.875rem,env(safe-area-inset-top))] lg:pt-3.5">
          <div className="min-w-0 flex-1 truncate text-xs text-[var(--color-text-tertiary)]">
            {isSub && subCtx ? (
              <>
                {subCtx.task.project && (
                  <span className="text-[var(--color-text-secondary)]">{subCtx.task.project} › </span>
                )}
                <button
                  type="button"
                  className="text-[var(--color-text-secondary)] hover:text-[var(--color-text)] hover:underline"
                  onClick={() => selectTask(subCtx.task.id)}
                >
                  {subCtx.task.title}
                </button>
                {" › "}
                {subCtx.sub.name}
              </>
            ) : selectedTask.project ? (
              <>
                <span className="text-[var(--color-text-secondary)]">{selectedTask.project}</span>
                {" › "}
                {selectedTask.title}
              </>
            ) : (
              selectedTask.title
            )}
          </div>
          <button
            type="button"
            onClick={handleClose}
            className="flex h-8 w-8 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)]"
            aria-label="Fechar"
          >
            <AppIcon icon={Cancel01Icon} size={18} />
          </button>
        </header>

        <div className="scroll-thin flex-1 overflow-y-auto p-4">
          {isSub && subCtx && selectedSubtaskKey ? (
            <>
              <div className="mb-4 flex items-start gap-3">
                <DoneCircle
                  done={subCtx.sub.done}
                  priority={subCtx.sub.priority}
                  label={subCtx.sub.done ? "Marcar pendente" : "Marcar concluída"}
                  onClick={() => toggleSubtaskDone(selectedSubtaskKey!)}
                />
                <AutosaveTextarea
                  className="min-h-[36px] flex-1 resize-none bg-transparent text-lg font-bold leading-tight outline-none"
                  aria-label="Título da subtarefa"
                  rows={1}
                  value={title}
                  onChange={setTitle}
                  onSave={(v) => autosaveSubtaskTitle(selectedSubtaskKey, v)}
                />
              </div>
              <AutosaveTextarea
                className="input-focus mb-4 w-full resize-none rounded-[var(--radius-md)] border border-transparent bg-[var(--color-surface-variant)] px-3 py-2.5 text-sm text-[var(--color-text-secondary)] outline-none placeholder:text-[var(--color-text-tertiary)]"
                placeholder="Adicionar notas…"
                rows={3}
                value={notes}
                onChange={setNotes}
                onSave={(v) => autosaveSubtaskNotes(selectedSubtaskKey, v)}
              />
              <SubtaskMetaCard subtaskKey={selectedSubtaskKey!} sub={subCtx.sub} parentTask={subCtx.task} />
            </>
          ) : (
            <>
              <div className="mb-4 flex items-start gap-3">
                <DoneCircle
                  done={selectedTask.done}
                  priority={selectedTask.priority}
                  label={selectedTask.done ? "Marcar pendente" : "Marcar concluída"}
                  onClick={() => toggleTaskDone(selectedTask.id)}
                />
                <AutosaveTextarea
                  className="min-h-[36px] flex-1 resize-none bg-transparent text-lg font-bold leading-tight outline-none"
                  aria-label="Título da tarefa"
                  rows={1}
                  value={title}
                  onChange={setTitle}
                  onSave={(v) => autosaveTaskTitle(selectedTask.id, v)}
                />
              </div>
              <AutosaveTextarea
                className="input-focus mb-4 w-full resize-none rounded-[var(--radius-md)] border border-transparent bg-[var(--color-surface-variant)] px-3 py-2.5 text-sm text-[var(--color-text-secondary)] outline-none placeholder:text-[var(--color-text-tertiary)]"
                placeholder="Adicionar notas…"
                rows={3}
                value={notes}
                onChange={setNotes}
                onSave={(v) => autosaveTaskNotes(selectedTask.id, v)}
              />
              <div className="space-y-4">
                <MetaCard item={selectedTask} taskId={selectedTask.id} />
                <SubtasksCard task={selectedTask} />
                <CommentsSection taskId={selectedTask.id} />
              </div>
            </>
          )}
        </div>
      </aside>
    </>
  );
}

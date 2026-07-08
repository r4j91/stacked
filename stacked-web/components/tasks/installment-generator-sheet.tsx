"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import { AppIcon } from "@/components/ui/app-icon";
import { Cancel01Icon } from "@/lib/icons/nav-icons";
import { Money01Icon } from "@hugeicons/core-free-icons";
import { createClient } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { TaskRepository } from "@/lib/repositories/task-repository";
import { toDateStr } from "@/lib/utils/date";
import {
  INSTALLMENT_FREQUENCY_OPTIONS,
  formatInstallmentDate,
  generateInstallmentDates,
  parseInstallmentValor,
  type InstallmentFrequency,
} from "@/lib/utils/installment-generator";

type InstallmentGeneratorSheetProps = {
  open: boolean;
  onClose: () => void;
  taskId: string;
  taskTitle: string;
  onGenerated: () => void;
};

export function InstallmentGeneratorSheet({
  open,
  onClose,
  taskId,
  taskTitle,
  onGenerated,
}: InstallmentGeneratorSheetProps) {
  const [nameBase, setNameBase] = useState(taskTitle);
  const [valorText, setValorText] = useState("");
  const [quantity, setQuantity] = useState(12);
  const [firstDueDate, setFirstDueDate] = useState(() => toDateStr(new Date()));
  const [frequency, setFrequency] = useState<InstallmentFrequency>("monthly");
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (open) {
      setNameBase(taskTitle);
      setValorText("");
      setQuantity(12);
      setFirstDueDate(toDateStr(new Date()));
      setFrequency("monthly");
      setError(null);
    }
  }, [open, taskTitle]);

  const previewDates = useMemo(() => {
    const base = new Date(`${firstDueDate}T12:00:00`);
    if (Number.isNaN(base.getTime())) return [];
    return generateInstallmentDates(Math.min(Math.max(quantity, 1), 60), base, frequency);
  }, [firstDueDate, frequency, quantity]);

  const effectiveName = nameBase.trim() || "Parcela";
  const canGenerate = effectiveName.length > 0 && quantity >= 1 && !generating;

  if (!open) return null;

  async function handleGenerate(e: FormEvent) {
    e.preventDefault();
    if (!canGenerate) return;
    setGenerating(true);
    setError(null);

    try {
      if (!isSupabaseConfigured()) {
        onGenerated();
        onClose();
        return;
      }

      const valor = parseInstallmentValor(valorText);
      const rows = previewDates.map((date, index) => ({
        task_id: taskId,
        titulo: `${effectiveName} / Parcela ${index + 1}`,
        data_vencimento: toDateStr(date),
        concluida: false,
        ordem: index,
        ...(valor != null ? { valor } : {}),
      }));

      await new TaskRepository(createClient()).createSubtasksBatch(rows);
      onGenerated();
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro ao gerar parcelas");
    } finally {
      setGenerating(false);
    }
  }

  return (
    <div
      className="fixed inset-0 z-[var(--z-panel)] flex items-end justify-center bg-black/40 sm:items-center sm:p-4"
      onClick={onClose}
      role="presentation"
    >
      <form
        className="scroll-thin flex max-h-[min(90dvh,720px)] w-full max-w-md flex-col rounded-t-[var(--radius-lg)] bg-[var(--color-surface)] shadow-lg sm:rounded-[var(--radius-lg)]"
        onClick={(e) => e.stopPropagation()}
        onSubmit={(e) => void handleGenerate(e)}
        role="dialog"
        aria-modal="true"
        aria-labelledby="installment-generator-title"
      >
        <div className="shrink-0 border-b border-[var(--color-border)] p-4">
          <div className="mb-3 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="flex h-9 w-9 items-center justify-center rounded-[var(--radius-sm)] bg-[var(--color-accent)]/15 text-[var(--color-accent)]">
                <AppIcon icon={Money01Icon} size={18} />
              </span>
              <div>
                <h2 id="installment-generator-title" className="text-base font-bold">
                  Gerar parcelas
                </h2>
                <p className="text-xs text-[var(--color-text-tertiary)]">
                  {quantity} subtarefas com vencimentos automáticos
                </p>
              </div>
            </div>
            <button
              type="button"
              onClick={onClose}
              className="flex h-8 w-8 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)]"
              aria-label="Fechar"
            >
              <AppIcon icon={Cancel01Icon} size={18} />
            </button>
          </div>
        </div>

        <div className="scroll-thin min-h-0 flex-1 space-y-4 overflow-y-auto p-4">
          <label className="block text-xs font-medium text-[var(--color-text-secondary)]">
            Nome base
            <input
              type="text"
              value={nameBase}
              onChange={(e) => setNameBase(e.target.value)}
              className="mt-1 w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface-variant)] px-3 py-2 text-sm outline-none focus:border-[var(--color-border-strong)]"
            />
          </label>

          <div className="grid grid-cols-2 gap-3">
            <label className="block text-xs font-medium text-[var(--color-text-secondary)]">
              Quantidade
              <input
                type="number"
                min={1}
                max={60}
                value={quantity}
                onChange={(e) => setQuantity(Math.min(60, Math.max(1, Number(e.target.value) || 1)))}
                className="mt-1 w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface-variant)] px-3 py-2 text-sm outline-none focus:border-[var(--color-border-strong)]"
              />
            </label>
            <label className="block text-xs font-medium text-[var(--color-text-secondary)]">
              Valor (opcional)
              <input
                type="text"
                inputMode="decimal"
                placeholder="0,00"
                value={valorText}
                onChange={(e) => setValorText(e.target.value)}
                className="mt-1 w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface-variant)] px-3 py-2 text-sm outline-none focus:border-[var(--color-border-strong)]"
              />
            </label>
          </div>

          <label className="block text-xs font-medium text-[var(--color-text-secondary)]">
            Primeiro vencimento
            <input
              type="date"
              value={firstDueDate}
              onChange={(e) => setFirstDueDate(e.target.value)}
              className="mt-1 w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface-variant)] px-3 py-2 text-sm outline-none focus:border-[var(--color-border-strong)]"
            />
          </label>

          <div>
            <p className="mb-2 text-xs font-medium text-[var(--color-text-secondary)]">Frequência</p>
            <div className="flex flex-wrap gap-2">
              {INSTALLMENT_FREQUENCY_OPTIONS.map((opt) => (
                <button
                  key={opt.value}
                  type="button"
                  onClick={() => setFrequency(opt.value)}
                  className={`rounded-full px-3 py-1.5 text-xs font-medium transition-colors ${
                    frequency === opt.value
                      ? "bg-[var(--color-accent)] text-[var(--color-on-accent)]"
                      : "bg-[var(--color-surface-variant)] text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)]"
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

          {previewDates.length > 0 && (
            <div className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-variant)]/60 p-3">
              <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
                Preview
              </p>
              <ul className="max-h-36 space-y-1 overflow-y-auto text-xs text-[var(--color-text-secondary)]">
                {previewDates.slice(0, 6).map((date, i) => (
                  <li key={i}>
                    {effectiveName} / Parcela {i + 1} — {formatInstallmentDate(date)}
                  </li>
                ))}
                {previewDates.length > 6 && (
                  <li className="text-[var(--color-text-tertiary)]">
                    +{previewDates.length - 6} parcelas…
                  </li>
                )}
              </ul>
            </div>
          )}

          {error && (
            <p className="text-sm text-[var(--color-overdue)]" role="alert">
              {error}
            </p>
          )}
        </div>

        <div className="shrink-0 flex justify-end gap-2 border-t border-[var(--color-border)] p-4">
          <button
            type="button"
            onClick={onClose}
            className="rounded-[var(--radius-sm)] px-3 py-1.5 text-sm text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)]"
          >
            Cancelar
          </button>
          <button
            type="submit"
            disabled={!canGenerate}
            className="btn-primary rounded-[var(--radius-sm)] px-4 py-1.5 text-sm disabled:opacity-50"
          >
            {generating ? "Gerando…" : `Gerar ${quantity} parcelas`}
          </button>
        </div>
      </form>
    </div>
  );
}

/**
 * Paridade iOS InstallmentProgress — detecta `… / Parcela N` e resume progresso + valor restante.
 */

import type { Subtask } from "@/lib/types/task";
import { formatInstallmentValor } from "@/lib/utils/installment-generator";

export const INSTALLMENT_TITLE_MARKER = " / Parcela ";

export type InstallmentProgressSnapshot = {
  done: number;
  total: number;
  /** Soma do valor das parcelas ainda não pagas. null se nenhuma tem valor. */
  remainingValor: number | null;
  fraction: number;
  label: string;
};

export function isInstallmentTitle(title: string): boolean {
  return title.includes(INSTALLMENT_TITLE_MARKER);
}

function installmentLabel(
  done: number,
  total: number,
  remainingValor: number | null,
): string {
  const count = `${done}/${total} pagas`;
  if (remainingValor == null) return count;
  if (remainingValor <= 0) {
    return done >= total ? `${done}/${total} pagas` : count;
  }
  return `${count} · ${formatInstallmentValor(remainingValor)} restante`;
}

/** null se a tarefa não parece parcelamento (≥2 subtarefas com o marcador). */
export function installmentProgressSnapshot(
  subtasks: Subtask[] | undefined | null,
): InstallmentProgressSnapshot | null {
  if (!subtasks?.length) return null;
  const parcels = subtasks.filter((s) => isInstallmentTitle(s.name));
  if (parcels.length < 2) return null;

  let done = 0;
  const unpaidValores: number[] = [];
  let anyValor = false;

  for (const sub of parcels) {
    if (sub.done) done += 1;
    if (sub.valor != null && Number.isFinite(sub.valor)) {
      anyValor = true;
      if (!sub.done) unpaidValores.push(sub.valor);
    }
  }

  const remainingValor = anyValor
    ? unpaidValores.reduce((sum, v) => sum + v, 0)
    : null;
  const total = parcels.length;
  const fraction = total > 0 ? done / total : 0;

  return {
    done,
    total,
    remainingValor,
    fraction,
    label: installmentLabel(done, total, remainingValor),
  };
}

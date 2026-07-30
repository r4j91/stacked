/** Ordem de etiquetas no card: última tocada/aplicada primeiro (MRU). */

/** Liga → início; desliga → remove. Demais mantêm ordem relativa. */
export function toggleLabelIdOrder(ids: string[], id: string): string[] {
  if (ids.includes(id)) return ids.filter((x) => x !== id);
  return [id, ...ids.filter((x) => x !== id)];
}

/** Resolve catálogo na ordem dos ids. */
export function resolveLabelsByIds<T extends { id: string }>(
  ids: string[],
  catalog: T[],
): T[] {
  return ids
    .map((id) => catalog.find((l) => l.id === id))
    .filter((l): l is T => Boolean(l));
}

/** Paridade iOS SubtaskProgressRingStorage — anel no lugar do chevron. */
export const SUBTASK_PROGRESS_RING_KEY = "appearance.subtaskProgressRing";
export const SUBTASK_PROGRESS_RING_EVENT = "stacked:subtask-progress-ring";
export const DEFAULT_SUBTASK_PROGRESS_RING = true;

export function readSubtaskProgressRing(): boolean {
  if (typeof window === "undefined") return DEFAULT_SUBTASK_PROGRESS_RING;
  const raw = window.localStorage.getItem(SUBTASK_PROGRESS_RING_KEY);
  if (raw === null) return DEFAULT_SUBTASK_PROGRESS_RING;
  return raw === "1" || raw === "true";
}

export function writeSubtaskProgressRing(enabled: boolean) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(SUBTASK_PROGRESS_RING_KEY, enabled ? "1" : "0");
  window.dispatchEvent(new Event(SUBTASK_PROGRESS_RING_EVENT));
}

export function subscribeSubtaskProgressRing(onStoreChange: () => void) {
  if (typeof window === "undefined") return () => {};
  const handler = () => onStoreChange();
  window.addEventListener(SUBTASK_PROGRESS_RING_EVENT, handler);
  window.addEventListener("storage", handler);
  return () => {
    window.removeEventListener(SUBTASK_PROGRESS_RING_EVENT, handler);
    window.removeEventListener("storage", handler);
  };
}

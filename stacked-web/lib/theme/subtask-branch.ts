/** Paridade iOS SubtaskBranchStorage — trilho/galho na lista expandida. */
export const SUBTASK_BRANCH_KEY = "appearance.subtaskBranch";
export const SUBTASK_BRANCH_EVENT = "stacked:subtask-branch";
export const DEFAULT_SUBTASK_BRANCH = false;

export function readSubtaskBranch(): boolean {
  if (typeof window === "undefined") return DEFAULT_SUBTASK_BRANCH;
  const raw = window.localStorage.getItem(SUBTASK_BRANCH_KEY);
  if (raw === null) return DEFAULT_SUBTASK_BRANCH;
  return raw === "1" || raw === "true";
}

export function writeSubtaskBranch(enabled: boolean) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(SUBTASK_BRANCH_KEY, enabled ? "1" : "0");
  window.dispatchEvent(new Event(SUBTASK_BRANCH_EVENT));
}

export function subscribeSubtaskBranch(onStoreChange: () => void) {
  if (typeof window === "undefined") return () => {};
  const handler = () => onStoreChange();
  window.addEventListener(SUBTASK_BRANCH_EVENT, handler);
  window.addEventListener("storage", handler);
  return () => {
    window.removeEventListener(SUBTASK_BRANCH_EVENT, handler);
    window.removeEventListener("storage", handler);
  };
}

const COLLAPSED_SECTIONS_PREFIX = "proj_detail_collapsed_sections_";
const COMPLETED_EXPANDED_PREFIX = "proj_detail_completed_expanded_";

function collapsedSectionsKey(projectId: string): string {
  return `${COLLAPSED_SECTIONS_PREFIX}${projectId}`;
}

function completedExpandedKey(projectId: string): string {
  return `${COMPLETED_EXPANDED_PREFIX}${projectId}`;
}

export function loadCollapsedSectionIds(projectId: string): Set<string> {
  if (typeof window === "undefined" || !projectId) return new Set();
  try {
    const raw = localStorage.getItem(collapsedSectionsKey(projectId));
    if (!raw) return new Set();
    const parsed = JSON.parse(raw) as unknown;
    if (!Array.isArray(parsed)) return new Set();
    return new Set(parsed.map(String));
  } catch {
    return new Set();
  }
}

export function saveCollapsedSectionIds(projectId: string, ids: Set<string>): void {
  if (typeof window === "undefined" || !projectId) return;
  localStorage.setItem(collapsedSectionsKey(projectId), JSON.stringify([...ids]));
}

export function loadCompletedExpanded(projectId: string, defaultValue = false): boolean {
  if (typeof window === "undefined" || !projectId) return defaultValue;
  try {
    const raw = localStorage.getItem(completedExpandedKey(projectId));
    if (raw == null) return defaultValue;
    return raw === "1" || raw === "true";
  } catch {
    return defaultValue;
  }
}

export function saveCompletedExpanded(projectId: string, value: boolean): void {
  if (typeof window === "undefined" || !projectId) return;
  localStorage.setItem(completedExpandedKey(projectId), value ? "1" : "0");
}

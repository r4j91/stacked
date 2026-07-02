import type { Section } from "@/lib/types/project";
import type { Task } from "@/lib/types/task";

export type ProjectListItem =
  | { kind: "task"; task: Task }
  | { kind: "separator" }
  | { kind: "sectionHeader"; section: Section; count: number }
  | { kind: "completedHeader"; count: number }
  | { kind: "completedTask"; task: Task };

export function computeProjectListItems({
  pending,
  completed,
  sections,
  collapsedSectionIds,
  completedExpanded,
  showCompleted,
}: {
  pending: Task[];
  completed: Task[];
  sections: Section[];
  collapsedSectionIds: Set<string>;
  completedExpanded: boolean;
  showCompleted: boolean;
}): ProjectListItem[] {
  const items: ProjectListItem[] = [];
  const grouped = new Map<string | null, Task[]>();

  for (const task of pending) {
    const key = task.sectionId ?? null;
    const list = grouped.get(key) ?? [];
    list.push(task);
    grouped.set(key, list);
  }

  const unsectioned = grouped.get(null) ?? [];
  for (let i = 0; i < unsectioned.length; i++) {
    items.push({ kind: "task", task: unsectioned[i] });
    if (i < unsectioned.length - 1) items.push({ kind: "separator" });
  }

  const sortedSections = [...sections].sort((a, b) => a.order - b.order);
  for (const section of sortedSections) {
    const sectionTasks = grouped.get(section.id) ?? [];
    items.push({ kind: "sectionHeader", section, count: sectionTasks.length });
    if (!collapsedSectionIds.has(section.id)) {
      for (let i = 0; i < sectionTasks.length; i++) {
        items.push({ kind: "task", task: sectionTasks[i] });
        if (i < sectionTasks.length - 1) items.push({ kind: "separator" });
      }
    }
  }

  if (showCompleted && completed.length) {
    items.push({ kind: "completedHeader", count: completed.length });
    if (completedExpanded) {
      for (const task of completed) {
        items.push({ kind: "completedTask", task });
      }
    }
  }

  return items;
}

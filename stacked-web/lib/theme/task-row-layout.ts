export type TaskRowLayout = "default" | "f2" | "x2";

export const TASK_ROW_LAYOUT_KEY = "stacked.taskRowLayout";
export const TASK_ROW_LAYOUT_EVENT = "stacked:task-row-layout";
export const DEFAULT_TASK_ROW_LAYOUT: TaskRowLayout = "default";

export const TASK_ROW_LAYOUTS: {
  id: TaskRowLayout;
  name: string;
  subtitle: string;
}[] = [
  {
    id: "default",
    name: "Atual",
    subtitle: "Título + meta em linha (projeto, hora, data, etiquetas)",
  },
  {
    id: "f2",
    name: "Eyebrow",
    subtitle: "Projeto · prioridade acima; agenda fundida plana na meta",
  },
  {
    id: "x2",
    name: "Híbrida",
    subtitle: "Projeto acima; prioridade + agenda fundida plana na meta",
  },
];

export function parseTaskRowLayout(raw: string | null | undefined): TaskRowLayout {
  if (raw === "f2" || raw === "x2" || raw === "default") return raw;
  return DEFAULT_TASK_ROW_LAYOUT;
}

export function readTaskRowLayout(): TaskRowLayout {
  if (typeof window === "undefined") return DEFAULT_TASK_ROW_LAYOUT;
  return parseTaskRowLayout(window.localStorage.getItem(TASK_ROW_LAYOUT_KEY));
}

export function writeTaskRowLayout(layout: TaskRowLayout) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(TASK_ROW_LAYOUT_KEY, layout);
  window.dispatchEvent(new Event(TASK_ROW_LAYOUT_EVENT));
}

export function subscribeTaskRowLayout(onStoreChange: () => void) {
  if (typeof window === "undefined") return () => {};
  const handler = () => onStoreChange();
  window.addEventListener(TASK_ROW_LAYOUT_EVENT, handler);
  window.addEventListener("storage", handler);
  return () => {
    window.removeEventListener(TASK_ROW_LAYOUT_EVENT, handler);
    window.removeEventListener("storage", handler);
  };
}

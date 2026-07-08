/** Paridade stacked-ios/ProjectDisplayMode.swift + lib/theme/project_display_mode.dart */

export type ProjectDisplayMode = "cards" | "cardsRefined" | "list";

export const PROJECT_DISPLAY_MODE_KEY = "display_mode";

export const PROJECT_DISPLAY_MODES: {
  value: ProjectDisplayMode;
  label: string;
  description: string;
}[] = [
  { value: "cards", label: "Balões", description: "Cards com painel de subtarefas" },
  { value: "cardsRefined", label: "Balões+", description: "Card sem painel escuro" },
  { value: "list", label: "Lista", description: "Lista plana com indent" },
];

export function projectDisplayModeFromStorage(raw: string | null): ProjectDisplayMode {
  switch (raw) {
    case "list":
    case "listRefined":
      return "list";
    case "cardsRefined":
      return "cardsRefined";
    case "cards":
      return "cards";
    case "folders":
    case "hybrid":
      return "cards";
    default:
      return "cards";
  }
}

export function usesCardStyle(mode: ProjectDisplayMode): boolean {
  return mode === "cards" || mode === "cardsRefined";
}

export function flatSubtaskPanel(mode: ProjectDisplayMode): boolean {
  return mode === "cardsRefined";
}

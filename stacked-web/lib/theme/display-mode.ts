/** Paridade iOS ProjectDisplayMode: list | listComfort (Lista+) | cardsLight (Halo) | cardsRefined (Balões+). */
export type DisplayMode = "list" | "listPlus" | "halo" | "balloons";

export const DISPLAY_MODE_KEY = "stacked.displayMode";
export const DISPLAY_MODE_EVENT = "stacked:display-mode";
export const DEFAULT_DISPLAY_MODE: DisplayMode = "list";

export const DISPLAY_MODES: {
  id: DisplayMode;
  name: string;
  subtitle: string;
}[] = [
  {
    id: "list",
    name: "Lista",
    subtitle: "Compacta, sem contorno",
  },
  {
    id: "listPlus",
    name: "Lista+",
    subtitle: "Gutter confortável, hairline sob cabeçalhos (paridade iOS listComfort)",
  },
  {
    id: "halo",
    name: "Halo",
    subtitle: "Card translúcido com contorno suave (paridade iOS)",
  },
  {
    id: "balloons",
    name: "Balões+",
    subtitle: "Card sólido por tarefa (paridade iOS cardsRefined)",
  },
];

/** Card family: cada tarefa vira um balão fechado (translúcido ou sólido). */
export function isCardDisplayMode(mode: DisplayMode): boolean {
  return mode === "halo" || mode === "balloons";
}

export function parseDisplayMode(raw: string | null | undefined): DisplayMode {
  if (raw === "halo" || raw === "cardsLight") return "halo";
  if (raw === "balloons" || raw === "cardsRefined" || raw === "cards") return "balloons";
  if (raw === "listPlus" || raw === "listComfort") return "listPlus";
  if (raw === "list") return "list";
  return DEFAULT_DISPLAY_MODE;
}

export function readDisplayMode(): DisplayMode {
  if (typeof window === "undefined") return DEFAULT_DISPLAY_MODE;
  return parseDisplayMode(window.localStorage.getItem(DISPLAY_MODE_KEY));
}

export function writeDisplayMode(mode: DisplayMode) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(DISPLAY_MODE_KEY, mode);
  window.dispatchEvent(new Event(DISPLAY_MODE_EVENT));
}

export function subscribeDisplayMode(onStoreChange: () => void) {
  if (typeof window === "undefined") return () => {};
  const handler = () => onStoreChange();
  window.addEventListener(DISPLAY_MODE_EVENT, handler);
  window.addEventListener("storage", handler);
  return () => {
    window.removeEventListener(DISPLAY_MODE_EVENT, handler);
    window.removeEventListener("storage", handler);
  };
}

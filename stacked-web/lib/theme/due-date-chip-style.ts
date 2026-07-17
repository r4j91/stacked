export type DueDateChipStyle = "soft" | "flat" | "plain" | "day" | "outline";

export const DUE_DATE_CHIP_STYLE_KEY = "stacked.dueDateChipStyle";
export const DUE_DATE_CHIP_STYLE_EVENT = "stacked:due-date-chip-style";
export const DEFAULT_DUE_DATE_CHIP_STYLE: DueDateChipStyle = "soft";

export const DUE_DATE_CHIP_STYLES: {
  id: DueDateChipStyle;
  name: string;
  subtitle: string;
}[] = [
  { id: "soft", name: "Suave", subtitle: "Fundo translúcido, borda e calendário (atual)" },
  { id: "flat", name: "Plano", subtitle: "Calendário + texto na cor, sem container" },
  { id: "plain", name: "Texto", subtitle: "Só o texto colorido, sem ícone" },
  { id: "day", name: "Dia", subtitle: "Número do dia real + rótulo ao lado" },
  { id: "outline", name: "Traço", subtitle: "Contorno fino, sem preenchimento" },
];

export function parseDueDateChipStyle(raw: string | null | undefined): DueDateChipStyle {
  if (
    raw === "flat" ||
    raw === "plain" ||
    raw === "day" ||
    raw === "outline" ||
    raw === "soft"
  ) {
    return raw;
  }
  return DEFAULT_DUE_DATE_CHIP_STYLE;
}

export function readDueDateChipStyle(): DueDateChipStyle {
  if (typeof window === "undefined") return DEFAULT_DUE_DATE_CHIP_STYLE;
  return parseDueDateChipStyle(window.localStorage.getItem(DUE_DATE_CHIP_STYLE_KEY));
}

export function writeDueDateChipStyle(style: DueDateChipStyle) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(DUE_DATE_CHIP_STYLE_KEY, style);
  window.dispatchEvent(new Event(DUE_DATE_CHIP_STYLE_EVENT));
}

export function subscribeDueDateChipStyle(onStoreChange: () => void) {
  if (typeof window === "undefined") return () => {};
  const handler = () => onStoreChange();
  window.addEventListener(DUE_DATE_CHIP_STYLE_EVENT, handler);
  window.addEventListener("storage", handler);
  return () => {
    window.removeEventListener(DUE_DATE_CHIP_STYLE_EVENT, handler);
    window.removeEventListener("storage", handler);
  };
}

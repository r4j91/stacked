export type LabelChipStyle = "soft" | "flat" | "dot" | "ink" | "outline";

export const LABEL_CHIP_STYLE_KEY = "stacked.labelChipStyle";
export const LABEL_CHIP_STYLE_EVENT = "stacked:label-chip-style";
export const DEFAULT_LABEL_CHIP_STYLE: LabelChipStyle = "soft";

export const LABEL_CHIP_STYLES: {
  id: LabelChipStyle;
  name: string;
  subtitle: string;
}[] = [
  { id: "soft", name: "Suave", subtitle: "Fundo translúcido e borda (atual)" },
  { id: "flat", name: "Plano", subtitle: "Só ícone e texto na cor da etiqueta" },
  { id: "dot", name: "Ponto", subtitle: "Bolinha colorida e nome em cinza" },
  { id: "ink", name: "Ícone", subtitle: "Ícone colorido e texto secundário" },
  { id: "outline", name: "Traço", subtitle: "Contorno fino, sem preenchimento" },
];

export function parseLabelChipStyle(raw: string | null | undefined): LabelChipStyle {
  if (raw === "flat" || raw === "dot" || raw === "ink" || raw === "outline" || raw === "soft") {
    return raw;
  }
  return DEFAULT_LABEL_CHIP_STYLE;
}

export function readLabelChipStyle(): LabelChipStyle {
  if (typeof window === "undefined") return DEFAULT_LABEL_CHIP_STYLE;
  return parseLabelChipStyle(window.localStorage.getItem(LABEL_CHIP_STYLE_KEY));
}

export function writeLabelChipStyle(style: LabelChipStyle) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(LABEL_CHIP_STYLE_KEY, style);
  window.dispatchEvent(new Event(LABEL_CHIP_STYLE_EVENT));
}

export function subscribeLabelChipStyle(onStoreChange: () => void) {
  if (typeof window === "undefined") return () => {};
  const handler = () => onStoreChange();
  window.addEventListener(LABEL_CHIP_STYLE_EVENT, handler);
  window.addEventListener("storage", handler);
  return () => {
    window.removeEventListener(LABEL_CHIP_STYLE_EVENT, handler);
    window.removeEventListener("storage", handler);
  };
}

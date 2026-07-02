/** Paleta unificada — paridade com Flutter `lib/theme/palette_colors.dart` */
export const PALETTE_HEX = [
  // Tons suaves
  "#63C7D8",
  "#6F8FB8",
  "#84B98E",
  "#789C6B",
  "#C58D97",
  "#C58A72",
  "#A496C8",
  "#6F79B6",
  "#C7B38A",
  "#D3B36A",
  "#7F99A8",
  "#9CA3AF",
  // Tons fortes (design system)
  "#5FD3DC",
  "#4D9FEC",
  "#B18CF5",
  "#8FD46B",
  "#F5A623",
  "#EF5A5F",
  "#FF85A1",
  "#64D8A0",
  "#FFD166",
  "#E07B54",
  // Vibrantes
  "#F43F5E",
  "#EC4899",
  "#D946EF",
  "#06B6D4",
  "#10B981",
  "#84CC16",
  "#F59E0B",
  "#F97316",
  // Variantes escuras
  "#0E7490",
  "#1D4ED8",
  "#6D28D9",
  "#15803D",
  "#B45309",
  "#B91C1C",
  "#BE185D",
  "#047857",
  "#0F766E",
  "#1E40AF",
  "#5B21B6",
  "#166534",
  "#92400E",
  "#7F1D1D",
  "#831843",
  "#134E4A",
] as const;

/** Primeiras 12 cores — preview compacto no seletor */
export const PALETTE_PREVIEW_HEX = PALETTE_HEX.slice(0, 12);

export const DEFAULT_PALETTE_HEX = PALETTE_HEX[0];

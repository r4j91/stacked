import SwiftUI

// Paridade stacked-web/lib/theme/palette-colors.ts
// Ordem: famílias por matiz (claro → médio → saturado → escuro), depois neon.
enum PaletteColors {
  static let projectHex: [String] = [
    // Vermelhos
    "#FDA4AF", "#F87171", "#EF5A5F", "#F43F5E", "#EF4444",
    "#DC2626", "#BE123C", "#B91C1C", "#7F1D1D",
    // Laranjas / âmbar
    "#FCD34D", "#FBBF24", "#FFD166", "#F5A623", "#F59E0B",
    "#FB923C", "#F97316", "#E07B54", "#C58A72", "#EA580C",
    "#B45309", "#92400E", "#7C2D12",
    // Amarelos / lima
    "#D3B36A", "#C7B38A", "#84CC16", "#365314",
    // Verdes
    "#86EFAC", "#4ADE80", "#8FD46B", "#34D399", "#64D8A0",
    "#22C55E", "#10B981", "#84B98E", "#82B392", "#6D9E82",
    "#7FA88E", "#93A882", "#5F9688", "#6B8F7A", "#5B8A70",
    "#789C6B", "#4A7359", "#15803D", "#047857", "#166534",
    // Teals / cianos
    "#63C7D8", "#5FD3DC", "#06B6D4", "#0E7490", "#0F766E", "#134E4A",
    // Azuis
    "#93C5FD", "#60A5FA", "#9CB8D4", "#8DB4CC", "#4D9FEC",
    "#3B82F6", "#7A9BB8", "#6A8FAE", "#6F8FB8", "#5E89A8",
    "#7F99A8", "#4B7294", "#556B8A", "#3E6582", "#2563EB",
    "#1D4ED8", "#1E40AF",
    // Índigos / roxos
    "#E9D5FF", "#DDD6FE", "#C4B5FD", "#A496C8", "#B18CF5",
    "#A78BFA", "#8B5CF6", "#6F79B6", "#7C3AED", "#6D28D9",
    "#D946EF", "#5B21B6", "#312E81",
    // Rosas / magenta
    "#F9A8D4", "#F0ABFC", "#FF85A1", "#FB7185", "#F472B6",
    "#E879F9", "#EC4899", "#C58D97", "#DB2777", "#BE185D",
    "#831843", "#701A75",
    // Cinzas
    "#D1D5DB", "#B8BCC4", "#A3A9B2", "#9CA3AF", "#949BA6",
    "#8A9099", "#727884", "#6E737C", "#565C66", "#4B5563", "#374151",
    // Neon / elétrico
    "#FF073A", "#FF5E00", "#FFFF33", "#CCFF00", "#BFFF00",
    "#39FF14", "#00FF9F", "#00F5D4", "#0AFFEF", "#00E5FF",
    "#7DF9FF", "#BF00FF", "#FF10F0", "#FE019A", "#FF6EC7", "#1B03A3",
  ]

  static var projectColors: [Color] {
    projectHex.map { AppColors.parseHex($0) }
  }

  static let defaultHex = "#63C7D8"
}

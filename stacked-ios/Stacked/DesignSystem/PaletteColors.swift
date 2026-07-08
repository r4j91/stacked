import SwiftUI

// Paridade stacked-web/lib/theme/palette-colors.ts
enum PaletteColors {
  static let projectHex: [String] = [
    // Tons suaves
    "#63C7D8", "#6F8FB8", "#84B98E", "#789C6B", "#C58D97", "#C58A72",
    "#A496C8", "#6F79B6", "#C7B38A", "#D3B36A", "#7F99A8", "#9CA3AF",
    // Azuis
    "#7A9BB8", "#5E89A8", "#4B7294", "#8DB4CC", "#6A8FAE", "#3E6582",
    "#9CB8D4", "#556B8A",
    // Verdes
    "#6D9E82", "#5B8A70", "#82B392", "#4A7359", "#7FA88E", "#93A882",
    "#5F9688", "#6B8F7A",
    // Cinzas
    "#8A9099", "#6E737C", "#A3A9B2", "#565C66", "#949BA6", "#727884",
    // Tons fortes
    "#5FD3DC", "#4D9FEC", "#B18CF5", "#8FD46B", "#F5A623", "#EF5A5F",
    "#FF85A1", "#64D8A0", "#FFD166", "#E07B54",
    // Vibrantes
    "#F43F5E", "#EC4899", "#D946EF", "#06B6D4", "#10B981", "#84CC16",
    "#F59E0B", "#F97316",
    // Variantes escuras
    "#0E7490", "#1D4ED8", "#6D28D9", "#15803D", "#B45309", "#B91C1C",
    "#BE185D", "#047857", "#0F766E", "#1E40AF", "#5B21B6", "#166534",
    "#92400E", "#7F1D1D", "#831843", "#134E4A",
  ]

  static var projectColors: [Color] {
    projectHex.map { AppColors.parseHex($0) }
  }

  static let defaultHex = "#63C7D8"
}

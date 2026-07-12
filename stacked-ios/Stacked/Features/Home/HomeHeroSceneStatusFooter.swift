import SwiftUI

/// Rodapé em pill integrado sobre cenas ilustradas (Jornada, Clima cena).
enum HomeHeroSceneStatusFooter {
  private static let overdueAccent = Color(hex: 0x9B6FD4)

  @ViewBuilder
  static func pill(
    colors: AppThemeColors,
    isOverdue: Bool,
    overdueCount: Int,
    onOpenFilter: (() -> Void)?
  ) -> some View {
    if isOverdue, let onOpenFilter {
      Button(action: onOpenFilter) {
        overduePill(colors: colors, overdueCount: overdueCount)
      }
      .buttonStyle(.plain)
      .accessibilityHint("Abre tarefas atrasadas")
    } else {
      clearPill(colors: colors)
    }
  }

  static func clearPill(colors c: AppThemeColors) -> some View {
    HStack(spacing: 8) {
      Image(systemName: "figure.walk")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(AppColors.tagGreen.opacity(0.9))
      Text("Tudo em dia")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(AppColors.tagGreen.opacity(0.88))
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(c.surface.opacity(0.72))
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .strokeBorder(AppColors.tagGreen.opacity(0.12), lineWidth: 1)
    }
  }

  static func overduePill(colors c: AppThemeColors, overdueCount: Int) -> some View {
    HStack(spacing: 8) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(overdueAccent)
      Text("Ver atrasados")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(overdueAccent)
      Spacer(minLength: 0)
      Text(pendingLabel(count: overdueCount))
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(c.textTertiary)
      DisclosureChevron(color: c.textTertiary)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(c.surface.opacity(0.78))
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .strokeBorder(overdueAccent.opacity(0.22), lineWidth: 1)
    }
  }

  private static func pendingLabel(count: Int) -> String {
    if count == 1 { return "1 pendência" }
    return "\(count) pendências"
  }
}

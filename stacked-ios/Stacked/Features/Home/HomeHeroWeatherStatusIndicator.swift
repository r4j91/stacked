import SwiftUI

enum HomeHeroWeatherChrome {
  static func greetingPhraseColor(colors: AppThemeColors) -> Color {
    colors.accent.opacity(colors.isDark ? 0.82 : 0.74)
  }
}

/// Indicador de status integrado nos cards de clima — cápsula sutil com tom do clima.
struct HomeHeroWeatherStatusIndicator: View {
  @Environment(ThemeManager.self) private var theme

  let isOverdue: Bool
  let statusLabel: String
  let clearTone: Color
  var onOpenFilter: (() -> Void)?

  private let overdueTone = Color(hex: 0xD49A6A)

  var body: some View {
    let c = theme.colors

    if isOverdue, let onOpenFilter {
      Button(action: onOpenFilter) {
        indicatorContent(
          colors: c,
          dotColor: overdueTone,
          label: statusLabel,
          showsChevron: true
        )
        .overlay {
          Capsule()
            .strokeBorder(overdueTone.opacity(c.isDark ? 0.28 : 0.22), lineWidth: 1)
        }
      }
      .buttonStyle(.plain)
      .accessibilityHint("Abre tarefas atrasadas")
    } else {
      indicatorContent(
        colors: c,
        dotColor: clearTone,
        label: "Tudo em dia",
        showsChevron: false
      )
      .overlay {
        Capsule()
          .strokeBorder(clearTone.opacity(c.isDark ? 0.2 : 0.14), lineWidth: 1)
      }
    }
  }

  private func indicatorContent(
    colors c: AppThemeColors,
    dotColor: Color,
    label: String,
    showsChevron: Bool
  ) -> some View {
    HStack(spacing: 7) {
      statusDot(color: dotColor)
      Text(label)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(isOverdue ? c.textPrimary.opacity(0.88) : c.textSecondary)
        .lineLimit(1)
      Spacer(minLength: 0)
      if showsChevron {
        Image(systemName: "chevron.right")
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(c.textTertiary)
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
    .background(c.surfaceVariant.opacity(isOverdue ? 0.7 : 0.55))
    .clipShape(Capsule())
  }

  private func statusDot(color: Color) -> some View {
    ZStack {
      Circle()
        .fill(color.opacity(0.35))
        .frame(width: 12, height: 12)
        .blur(radius: 3)
      Circle()
        .fill(color.opacity(0.92))
        .frame(width: 6, height: 6)
    }
    .frame(width: 12, height: 12)
    .accessibilityHidden(true)
  }
}

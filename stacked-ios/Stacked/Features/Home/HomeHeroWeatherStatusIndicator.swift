import SwiftUI

/// Tokens compartilhados dos heroes ilustrados e de clima.
enum HomeHeroLayout {
  static let sceneCardHeight: CGFloat = 176
  static let weatherCardHeight: CGFloat = 188
  static let cornerRadius: CGFloat = 16
  static let scenePaddingH: CGFloat = AppSpacing.lg
  static let scenePaddingV: CGFloat = 14
  static let statusPillRadius: CGFloat = AppSpacing.md
}

enum HomeHeroWeatherChrome {
  static func greetingPhraseColor(colors: AppThemeColors) -> Color {
    colors.accent.opacity(colors.isDark ? 0.82 : 0.74)
  }
}

enum HomeHeroStatusPresentation {
  /// Cápsula sobre fundo de card/surface (clima).
  case inline
  /// Pill retangular sobre cena ilustrada (jornada, aurora).
  case scene
}

/// Indicador de status unificado para todos os heroes.
struct HomeHeroStatusFooter: View {
  @Environment(ThemeManager.self) private var theme

  let presentation: HomeHeroStatusPresentation
  let isOverdue: Bool
  let statusLabel: String
  var clearTone: Color = AppColors.tagGreen
  var onOpenFilter: (() -> Void)?

  var body: some View {
    let c = theme.colors

    if isOverdue, let onOpenFilter {
      Button(action: onOpenFilter) {
        footerContent(colors: c, showsChevron: true)
      }
      .buttonStyle(.plain)
      .accessibilityHint("Abre tarefas atrasadas")
    } else {
      footerContent(colors: c, showsChevron: false)
    }
  }

  private var overdueTone: Color { AppColors.overdue }

  private var clearColor: Color {
    presentation == .inline ? clearTone : AppColors.tagGreen
  }

  @ViewBuilder
  private func footerContent(colors c: AppThemeColors, showsChevron: Bool) -> some View {
    let content = HStack(spacing: AppSpacing.sm - 1) {
      statusDot(color: isOverdue ? overdueTone : clearColor)
      Text(isOverdue ? statusLabel : "Tudo em dia")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(isOverdue ? c.textPrimary.opacity(0.88) : c.textSecondary)
        .lineLimit(1)
      Spacer(minLength: 0)
      if showsChevron {
        DisclosureChevron(color: c.textTertiary)
      }
    }
    .padding(.horizontal, presentation == .scene ? AppSpacing.md : 10)
    .padding(.vertical, presentation == .scene ? 10 : 7)

    switch presentation {
    case .inline:
      content
        .background(c.surfaceVariant.opacity(isOverdue ? 0.7 : 0.55))
        .clipShape(Capsule())
        .overlay {
          Capsule()
            .strokeBorder(
              (isOverdue ? overdueTone : clearColor).opacity(c.isDark ? 0.22 : 0.16),
              lineWidth: 1
            )
        }
    case .scene:
      content
        .background(c.surface.opacity(isOverdue ? 0.78 : 0.72))
        .clipShape(RoundedRectangle(cornerRadius: HomeHeroLayout.statusPillRadius, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: HomeHeroLayout.statusPillRadius, style: .continuous)
            .strokeBorder(
              (isOverdue ? overdueTone : clearColor).opacity(isOverdue ? 0.22 : 0.12),
              lineWidth: 1
            )
        }
    }
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

/// Compat: cards de clima usam footer inline.
struct HomeHeroWeatherStatusIndicator: View {
  let isOverdue: Bool
  let statusLabel: String
  let clearTone: Color
  var onOpenFilter: (() -> Void)?

  var body: some View {
    HomeHeroStatusFooter(
      presentation: .inline,
      isOverdue: isOverdue,
      statusLabel: statusLabel,
      clearTone: clearTone,
      onOpenFilter: onOpenFilter
    )
  }
}

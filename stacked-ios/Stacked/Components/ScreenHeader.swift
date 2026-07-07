import SwiftUI

// Paridade lib/widgets/screen_header.dart
struct ScreenHeader: View {
  let title: String
  var subtitle: String?

  var body: some View {
    ScreenHeaderChrome(title: title, subtitle: subtitle) {
      EmptyView()
    }
  }
}

struct SectionLabel: View {
  @Environment(ThemeManager.self) private var theme
  let text: String

  var body: some View {
    Text(text)
      .font(AppTypography.sectionLabel)
      .foregroundStyle(theme.colors.textTertiary)
      .tracking(0.6)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, ScreenHeaderMetrics.horizontalPadding)
      .padding(.top, 12)
      .padding(.bottom, 6)
  }
}

struct EmptyStateView: View {
  @Environment(ThemeManager.self) private var theme
  var illustration: EmptyStateIllustrationKind?
  var icon: StackedIconKey?
  let title: String
  let subtitle: String

  init(
    illustration: EmptyStateIllustrationKind,
    title: String,
    subtitle: String
  ) {
    self.illustration = illustration
    self.icon = nil
    self.title = title
    self.subtitle = subtitle
  }

  init(icon: StackedIconKey, title: String, subtitle: String) {
    self.illustration = nil
    self.icon = icon
    self.title = title
    self.subtitle = subtitle
  }

  var body: some View {
    let c = theme.colors
    VStack(spacing: illustration != nil ? 18 : 10) {
      if let illustration {
        EmptyStateIllustration(kind: illustration)
      } else if let icon {
        ZStack {
          Circle()
            .fill(c.surfaceVariant.opacity(c.isDark ? 0.55 : 0.85))
            .frame(width: 80, height: 80)
          StackedIcons.image(icon)
            .font(.system(size: 32, weight: .regular))
            .foregroundStyle(c.textTertiary.opacity(0.85))
        }
      }

      VStack(spacing: 6) {
        Text(title)
          .font(AppTypography.emptyStateTitle)
          .foregroundStyle(c.textPrimary)
          .multilineTextAlignment(.center)
        Text(subtitle)
          .font(AppTypography.emptyStateSubtitle)
          .foregroundStyle(c.textSecondary)
          .multilineTextAlignment(.center)
          .lineSpacing(2)
          .frame(maxWidth: 280)
      }
    }
    .padding(.horizontal, 32)
    .padding(.vertical, 24)
    .frame(maxWidth: .infinity)
  }
}

extension View {
  /// Centraliza empty state dentro de `List` — evita texto colado no topo.
  func stackedListEmptyStateRow() -> some View {
    self
      .listRowInsets(EdgeInsets())
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
      .frame(maxWidth: .infinity, alignment: .center)
      .containerRelativeFrame(.vertical) { length, _ in
        max(length * 0.50, 280)
      }
  }

  /// Empty state fora de lista (ex.: Logbook) — ocupa área visível.
  func stackedStandaloneEmptyState() -> some View {
    frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
  }
}

struct LoadErrorView: View {
  @Environment(ThemeManager.self) private var theme
  let message: String
  let onRetry: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      Text("Não foi possível carregar")
        .font(AppTypography.emptyStateTitle)
        .foregroundStyle(theme.colors.textPrimary)
      Text(message)
        .font(AppTypography.meta)
        .foregroundStyle(theme.colors.textSecondary)
        .multilineTextAlignment(.center)
      Button("Tentar novamente", action: onRetry)
        .font(AppTypography.bodySemibold)
        .foregroundStyle(theme.colors.accent)
    }
    .padding(32)
    .frame(maxWidth: .infinity)
  }
}

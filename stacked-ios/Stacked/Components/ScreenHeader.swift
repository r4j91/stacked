import SwiftUI

// Paridade lib/widgets/screen_header.dart
struct ScreenHeader: View {
  @Environment(ThemeManager.self) private var theme
  let title: String
  var subtitle: String?

  var body: some View {
    let c = theme.colors
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(AppTypography.screenTitle)
        .foregroundStyle(c.textPrimary)
        .tracking(-0.5)
      if let subtitle {
        Text(subtitle)
          .font(.system(size: 12.5))
          .foregroundStyle(c.textSecondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 20)
    .padding(.top, 20)
    .padding(.bottom, 8)
  }
}

struct SectionLabel: View {
  @Environment(ThemeManager.self) private var theme
  let text: String

  var body: some View {
    Text(text)
      .font(.system(size: 11, weight: .semibold))
      .foregroundStyle(theme.colors.textSecondary)
      .tracking(0.8)
      .padding(.horizontal, 20)
      .padding(.top, 12)
      .padding(.bottom, 6)
  }
}

struct EmptyStateView: View {
  @Environment(ThemeManager.self) private var theme
  let icon: StackedIconKey
  let title: String
  let subtitle: String

  var body: some View {
    let c = theme.colors
    VStack(spacing: 10) {
      StackedIcons.image(icon)
        .font(.system(size: 36))
        .foregroundStyle(c.textTertiary)
      Text(title)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(c.textPrimary)
      Text(subtitle)
        .font(AppTypography.taskPreview)
        .foregroundStyle(c.textSecondary)
        .multilineTextAlignment(.center)
    }
    .padding(.horizontal, 32)
    .padding(.vertical, 48)
    .frame(maxWidth: .infinity)
  }
}

struct LoadErrorView: View {
  @Environment(ThemeManager.self) private var theme
  let message: String
  let onRetry: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      Text("Não foi possível carregar")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(theme.colors.textPrimary)
      Text(message)
        .font(AppTypography.meta)
        .foregroundStyle(theme.colors.textSecondary)
        .multilineTextAlignment(.center)
      Button("Tentar novamente", action: onRetry)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(theme.colors.accent)
    }
    .padding(32)
    .frame(maxWidth: .infinity)
  }
}

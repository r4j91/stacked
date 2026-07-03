import SwiftUI

// Paridade lib/screens/appearance_screen.dart
struct AppearanceView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  var body: some View {
    let c = theme.colors
    let themes = AppThemeId.allCases

    List {
      Section {
        SettingsCardSurface {
          VStack(spacing: 0) {
            ForEach(Array(themes.enumerated()), id: \.element) { index, themeId in
              themeRow(themeId)
              if index < themes.count - 1 {
                SettingsCardDivider(leadingPadding: 56)
              }
            }
          }
        }
        .settingsListCardRow(top: 8)
      }
    }
    .settingsDrillDownList(background: c.background)
    .navigationTitle("Aparência")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func themeRow(_ themeId: AppThemeId) -> some View {
    let c = theme.colors

    return Button {
      HapticService.selection()
      theme.setTheme(themeId)
    } label: {
      HStack(spacing: 14) {
        themeSwatch(themeId.colors)
        VStack(alignment: .leading, spacing: 3) {
          Text(themeId.displayName)
            .font(AppTypography.settingsTitle)
            .foregroundStyle(c.textPrimary)
          Text(themeId.subtitle)
            .font(AppTypography.taskPreview)
            .foregroundStyle(c.textSecondary)
        }
        Spacer()
        if theme.currentId == themeId {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(c.accent)
        }
      }
      .padding(.horizontal, SettingsChrome.rowPaddingH)
      .padding(.vertical, SettingsChrome.rowPaddingV)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private func themeSwatch(_ colors: AppThemeColors) -> some View {
    HStack(spacing: 0) {
      colors.background.frame(width: 14)
      colors.surface.frame(width: 14)
      colors.accent.frame(width: 14)
    }
    .frame(height: 36)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08)))
  }
}

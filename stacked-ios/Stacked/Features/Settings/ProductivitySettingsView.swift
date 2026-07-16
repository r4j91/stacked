import SwiftUI

struct ProductivitySettingsView: View {
  @Environment(ThemeManager.self) private var theme
  @State private var quickAddDescription = ProductivityPreferences.quickAddDescriptionEnabled

  var body: some View {
    let c = theme.colors

    List {
      Section {
        SettingsCardSurface {
          HStack(spacing: 12) {
            settingsLabel(
              icon: "text.alignleft",
              title: "Descrição ao criar",
              subtitle: "Campo de notas abaixo do título ao criar tarefas"
            )
            Spacer(minLength: 8)
            SettingsSwitchToggle(
              isOn: Binding(
                get: { quickAddDescription },
                set: { newValue in
                  quickAddDescription = newValue
                  ProductivityPreferences.quickAddDescriptionEnabled = newValue
                  HapticService.selection()
                }
              ),
              tint: c.actionAccent
            )
          }
          .padding(.horizontal, SettingsChrome.rowPaddingH)
          .padding(.vertical, SettingsChrome.rowPaddingV)
        }
        .settingsListCardRow(top: 8, bottom: 8)
      }
    }
    .settingsDrillDownList(background: c.background)
    .navigationTitle("Captura rápida")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func settingsLabel(icon: String, title: String, subtitle: String? = nil) -> some View {
    let c = theme.colors
    return HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 18))
        .foregroundStyle(c.textSecondary)
        .frame(width: 24)
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(AppTypography.settingsTitle)
          .foregroundStyle(c.textPrimary)
        if let subtitle {
          Text(subtitle)
            .font(AppTypography.meta)
            .foregroundStyle(c.textTertiary)
        }
      }
    }
  }
}

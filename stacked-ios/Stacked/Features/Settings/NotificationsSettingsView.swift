import SwiftUI

// Paridade lib/screens/notifications_settings_screen.dart
enum NotificationPreferences {
  static let enabledKey = "notifications_enabled"
  static let dailySummaryKey = "notifications_daily_summary"

  static var enabled: Bool {
    get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
    set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
  }

  static var dailySummary: Bool {
    get { UserDefaults.standard.object(forKey: dailySummaryKey) as? Bool ?? true }
    set { UserDefaults.standard.set(newValue, forKey: dailySummaryKey) }
  }
}

struct NotificationsSettingsView: View {
  @Environment(ThemeManager.self) private var theme

  @State private var enabled = NotificationPreferences.enabled
  @State private var dailySummary = NotificationPreferences.dailySummary
  @State private var loading = true
  @State private var togglesReady = false

  var body: some View {
    let c = theme.colors

    Group {
      if loading {
        ProgressView().tint(c.accent)
      } else {
        List {
          Section {
            SettingsCardSurface {
              VStack(spacing: 0) {
                notificationToggleRow(
                  isOn: $enabled,
                  icon: "bell",
                  title: "Ativar notificações"
                )

                if enabled {
                  SettingsCardDivider(leadingPadding: 14)
                  notificationToggleRow(
                    isOn: Binding(
                      get: { dailySummary },
                      set: { newValue in
                        _Concurrency.Task { await toggleDailySummary(newValue) }
                      }
                    ),
                    icon: "sun.max",
                    title: "Resumo diário",
                    subtitle: "Tarefas do dia às 8h"
                  )
                }
              }
            }
            .settingsListCardRow(top: 8)
          }

          if enabled {
            Section {
              Text("Alerta na hora da tarefa. Sem hora, sem notificação.")
                .font(AppTypography.metaSmall)
                .foregroundStyle(c.textTertiary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .settingsListCardRow(top: 0, bottom: 8)
                .listRowBackground(Color.clear)
            }
          }
        }
        .settingsDrillDownList(background: c.background)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(c.background)
    .navigationTitle("Notificações")
    .navigationBarTitleDisplayMode(.inline)
    .task { await load() }
    .onChange(of: enabled) { _, newValue in
      guard togglesReady else { return }
      _Concurrency.Task { await toggleEnabled(newValue) }
    }
  }

  private func notificationToggleRow(
    isOn: Binding<Bool>,
    icon: String,
    title: String,
    subtitle: String? = nil
  ) -> some View {
    HStack(spacing: 12) {
      settingsLabel(icon: icon, title: title, subtitle: subtitle)
      Spacer(minLength: 8)
      SettingsSwitchToggle(isOn: isOn, tint: theme.colors.actionAccent)
    }
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
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

  private func load() async {
    let userWants = NotificationPreferences.enabled
    if userWants {
      enabled = await NotificationService.shared.hasSystemPermission()
      if !enabled {
        NotificationPreferences.enabled = false
      }
    } else {
      enabled = false
    }
    dailySummary = NotificationPreferences.dailySummary
    loading = false
    togglesReady = true
  }

  private func toggleEnabled(_ value: Bool) async {
    if value {
      let granted = await NotificationService.shared.requestPermission()
      NotificationPreferences.enabled = granted
      if !granted {
        enabled = false
      } else {
        await NotificationService.shared.rescheduleAllPending()
        HapticService.success()
      }
    } else {
      await NotificationService.shared.setEnabled(false)
      HapticService.selection()
    }
  }

  private func toggleDailySummary(_ value: Bool) async {
    NotificationPreferences.dailySummary = value
    dailySummary = value
    HapticService.selection()
    await NotificationService.shared.setDailySummaryEnabled(value)
  }
}

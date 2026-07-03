import SwiftUI
import UserNotifications

// Paridade lib/screens/notifications_settings_screen.dart
enum NotificationPreferences {
  static let enabledKey = "notifications_enabled"
  static let dailySummaryKey = "notifications_daily_summary"

  static var enabled: Bool {
    get { UserDefaults.standard.bool(forKey: enabledKey) }
    set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
  }

  static var dailySummary: Bool {
    get { UserDefaults.standard.bool(forKey: dailySummaryKey) }
    set { UserDefaults.standard.set(newValue, forKey: dailySummaryKey) }
  }
}

struct NotificationsSettingsView: View {
  @Environment(ThemeManager.self) private var theme

  @State private var enabled = false
  @State private var dailySummary = false
  @State private var loading = true

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
                  isOn: Binding(
                    get: { enabled },
                    set: { newValue in _Concurrency.Task { await toggleEnabled(newValue) } }
                  ),
                  icon: "bell",
                  title: "Ativar notificações"
                )

                if enabled {
                  SettingsCardDivider(leadingPadding: 14)
                  notificationToggleRow(
                    isOn: Binding(
                      get: { dailySummary },
                      set: { newValue in
                        NotificationPreferences.dailySummary = newValue
                        dailySummary = newValue
                        HapticService.selection()
                      }
                    ),
                    icon: "sun.max",
                    title: "Resumo diário",
                    subtitle: "Resumo das tarefas do dia às 8h da manhã"
                  )
                }
              }
            }
            .settingsListCardRow(top: 8)
          }

          if enabled {
            Section {
              Text("Você recebe um alerta na hora definida na tarefa. Tarefas só com data, sem hora, não disparam notificação.")
                .font(AppTypography.taskPreview)
                .foregroundStyle(c.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .settingsListCardRow(top: 0, bottom: 8)
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
      StackedSwitchControl(isOn: isOn, colors: theme.colors)
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
    enabled = NotificationPreferences.enabled
    dailySummary = NotificationPreferences.dailySummary
    loading = false
  }

  private func toggleEnabled(_ value: Bool) async {
    if value {
      let granted = await requestPermission()
      NotificationPreferences.enabled = granted
      enabled = granted
      if granted { HapticService.success() }
    } else {
      NotificationPreferences.enabled = false
      enabled = false
      HapticService.selection()
    }
  }

  private func requestPermission() async -> Bool {
    await withCheckedContinuation { continuation in
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
        continuation.resume(returning: granted)
      }
    }
  }
}

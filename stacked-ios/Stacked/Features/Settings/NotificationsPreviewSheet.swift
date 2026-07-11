import SwiftUI

// Paridade lib/widgets/settings/notifications_sheet.dart
struct NotificationsPreviewSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL
  @Environment(ThemeManager.self) private var theme

  @State private var items: [NotificationService.SchedulableNotificationItem] = []
  @State private var diagnostics = NotificationService.NotificationDiagnostics(
    userEnabled: false,
    systemAuthorized: false,
    pendingScheduledCount: 0,
    totalWithTime: 0,
    schedulingCap: 60
  )
  @State private var loading = true
  @State private var rescheduling = false
  @State private var rescheduleFeedback: String?
  @State private var showInAppSettings = false

  private var hasActionableUnregisteredItems: Bool {
    items.contains { $0.isWithinSchedulingCap && !$0.isRegisteredWithSystem }
  }

  var body: some View {
    let c = theme.colors

    NavigationStack {
      Group {
        if loading && items.isEmpty {
          ProgressView().tint(c.accent)
            .frame(maxWidth: .infinity, minHeight: 220)
        } else if items.isEmpty {
          EmptyStateView(
            icon: .notifications,
            title: "Nenhuma notificação agendada",
            subtitle: "Tarefas e subtarefas com data e hora futuras aparecem aqui"
          )
          .stackedStandaloneEmptyState()
        } else {
          List {
            if hasActionableUnregisteredItems || !diagnostics.canSchedule {
              registrationHelpSection(colors: c)
            } else if diagnostics.totalWithTime > diagnostics.schedulingCap {
              Text("O iPhone limita a 64 alertas pendentes. Os \(diagnostics.schedulingCap) mais próximos ficam no iOS; os demais entram na fila automaticamente quando os anteriores disparam.")
                .font(.system(size: 13))
                .foregroundStyle(c.textSecondary)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if let rescheduleFeedback {
              Text(rescheduleFeedback)
                .font(.system(size: 13))
                .foregroundStyle(c.textSecondary)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if diagnostics.canSchedule {
              Text(statusSummary)
                .font(.system(size: 12))
                .foregroundStyle(c.textTertiary)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(items) { item in
              HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName(for: item))
                  .font(.system(size: 16))
                  .foregroundStyle(iconColor(for: item, colors: c))
                  .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                  Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(c.textPrimary)
                  if let parent = item.parentTitle {
                    Text(parent)
                      .font(.system(size: 12))
                      .foregroundStyle(c.textTertiary)
                      .lineLimit(1)
                  }
                  if let label = dueLabel(item.dueDate, time: item.time), !label.isEmpty {
                    Text(label)
                      .font(.system(size: 13))
                      .foregroundStyle(c.textSecondary)
                  }
                  if !item.isWithinSchedulingCap {
                    Text("Na fila — entra quando alertas mais próximos dispararem")
                      .font(.system(size: 11))
                      .foregroundStyle(c.textTertiary)
                  }
                }
              }
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
          .opacity(loading ? 0.72 : 1)
        }
      }
      .background(c.background)
      .navigationTitle("Próximas")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
              .foregroundStyle(c.textSecondary)
          }
        }
      }
      .task { await load() }
      .sheet(isPresented: $showInAppSettings) {
        NavigationStack {
          NotificationsSettingsView()
            .environment(theme)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  private var statusSummary: String {
    let registeredInList = items.filter(\.isRegisteredWithSystem).count
    if diagnostics.totalWithTime > diagnostics.schedulingCap {
      return "\(diagnostics.pendingScheduledCount) no iOS agora · \(diagnostics.totalWithTime) com horário no total"
    }
    return "\(registeredInList) de \(items.count) nesta lista registrados no iOS"
  }

  private func iconName(for item: NotificationService.SchedulableNotificationItem) -> String {
    if item.isRegisteredWithSystem { return "bell.fill" }
    if item.isWithinSchedulingCap { return "bell.slash" }
    return "clock"
  }

  private func iconColor(
    for item: NotificationService.SchedulableNotificationItem,
    colors c: AppThemeColors
  ) -> Color {
    if item.isRegisteredWithSystem { return c.accent }
    if item.isWithinSchedulingCap { return AppColors.priorityMedium }
    return c.textTertiary
  }

  @ViewBuilder
  private func registrationHelpSection(colors c: AppThemeColors) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(helpMessage)
        .font(.system(size: 13))
        .foregroundStyle(AppColors.priorityMedium)
        .fixedSize(horizontal: false, vertical: true)

      HStack(spacing: 10) {
        if !diagnostics.userEnabled {
          Button("Ativar no Stacked") {
            showInAppSettings = true
          }
          .buttonStyle(.borderedProminent)
          .tint(c.accent)
        } else if !diagnostics.systemAuthorized {
          Button("Permitir no iPhone") {
            _Concurrency.Task { await requestPermissionAndReload() }
          }
          .buttonStyle(.borderedProminent)
          .tint(c.accent)
          .disabled(rescheduling)
        } else if hasActionableUnregisteredItems {
          Button(rescheduling ? "Reagendando…" : "Reagendar agora") {
            _Concurrency.Task { await rescheduleAndReload() }
          }
          .buttonStyle(.borderedProminent)
          .tint(c.accent)
          .disabled(rescheduling)
        }

        if !diagnostics.systemAuthorized {
          Button("Ajustes do iOS") {
            if let url = URL(string: UIApplication.openSettingsURLString) {
              openURL(url)
            }
          }
          .buttonStyle(.bordered)
          .tint(c.textSecondary)
        }
      }
    }
    .padding(.vertical, 4)
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)
  }

  private var helpMessage: String {
    if !diagnostics.userEnabled {
      return "Notificações estão desligadas no Stacked. Ative em Ajustes → Notificações para agendar alertas no iPhone."
    }
    if !diagnostics.systemAuthorized {
      return "O Stacked não tem permissão do iPhone para enviar alertas. Toque em \"Permitir no iPhone\" ou abra Ajustes do iOS."
    }
    if hasActionableUnregisteredItems {
      return "Alguns alertas próximos ainda não estão no iOS. Toque em \"Reagendar agora\"."
    }
    return ""
  }

  private func dueLabel(_ date: Date?, time: String?) -> String? {
    guard let date, let time, !time.isEmpty else { return nil }
    guard TaskMapper.combinedDateTime(dueDate: date, time: time) != nil else { return nil }
    let today = Calendar.current.startOfDay(for: Date())
    let due = Calendar.current.startOfDay(for: date)
    let diff = Calendar.current.dateComponents([.day], from: today, to: due).day ?? 0
    let timeLabel = TaskMapper.formatTimeDisplay(time)
    switch diff {
    case 0: return "Hoje às \(timeLabel)"
    case 1: return "Amanhã às \(timeLabel)"
    default: return "Em \(diff) dias às \(timeLabel)"
    }
  }

  private func load() async {
    if let cached = NotificationService.shared.cachedPreview {
      items = cached.items
      diagnostics = cached.diagnostics
      loading = false
    }
    let needsNetwork = NotificationService.shared.cachedPreview == nil
    await refresh(forceRefreshData: needsNetwork)
    loading = false
  }

  private func rescheduleAndReload() async {
    rescheduling = true
    rescheduleFeedback = nil
    defer { rescheduling = false }
    let result = await NotificationService.shared.rescheduleAllPending()
    await refresh(forceRefreshData: true)
    if let reason = result.failureReason {
      rescheduleFeedback = reason
    } else if result.registered > 0 {
      if result.totalEligible > result.scheduled {
        rescheduleFeedback = "\(result.registered) alertas no iOS (os \(result.scheduled) mais próximos de \(result.totalEligible) com horário)."
      } else {
        rescheduleFeedback = "\(result.registered) alerta(s) registrado(s) no iOS."
      }
    } else {
      rescheduleFeedback = "Nada para agendar."
    }
  }

  private func requestPermissionAndReload() async {
    rescheduling = true
    rescheduleFeedback = nil
    defer { rescheduling = false }
    let granted = await NotificationService.shared.requestPermissionAndReschedule()
    await refresh(forceRefreshData: true)
    rescheduleFeedback = granted
      ? "Permissão concedida. Verifique os sinos na lista."
      : "Permissão negada. Abra Ajustes do iOS → Notificações → Stacked."
  }

  private func refresh(forceRefreshData: Bool) async {
    let snapshot = await NotificationService.shared.fetchPreviewSnapshot(forceRefreshData: forceRefreshData)
    items = snapshot.items
    diagnostics = snapshot.diagnostics
  }
}

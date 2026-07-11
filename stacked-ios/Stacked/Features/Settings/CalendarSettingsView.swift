import EventKit
import SwiftUI

struct CalendarSettingsView: View {
  @Environment(ThemeManager.self) private var theme
  private let calendarService = EventKitCalendarService.shared

  @State private var importEnabled = CalendarPreferences.importEnabled
  @State private var exportEnabled = CalendarPreferences.exportEnabled
  @State private var exportAsAllDay = CalendarPreferences.exportAsAllDay
  @State private var loading = true
  @State private var togglesReady = false
  @State private var needsPermissionHint = false
  @State private var selectedIDs: Set<String> = CalendarPreferences.selectedCalendarIDs

  var body: some View {
    let c = theme.colors

    Group {
      if loading {
        ProgressView().tint(c.accent)
      } else {
        List {
          if importEnabled && !calendarService.authorizationGranted {
            Section {
              SettingsCardSurface {
                VStack(alignment: .leading, spacing: 8) {
                  Text("Ative o acesso ao Calendário para ver compromissos em Hoje e Em breve.")
                    .font(AppTypography.taskPreview)
                    .foregroundStyle(c.textSecondary)
                  Button("Permitir acesso ao Calendário") {
                    _Concurrency.Task { await requestAccess() }
                  }
                  .font(AppTypography.bodySemibold)
                  .foregroundStyle(c.accent)
                  if needsPermissionHint {
                    Text("Se o diálogo não aparecer, abra Ajustes → Privacidade → Calendários e permita o Stacked.")
                      .font(AppTypography.metaSmall)
                      .foregroundStyle(c.textTertiary)
                  }
                }
                .padding(.horizontal, SettingsChrome.rowPaddingH)
                .padding(.vertical, SettingsChrome.rowPaddingV)
              }
              .settingsListCardRow(top: 8, bottom: 8)
            }
          }

          Section {
            SettingsCardSurface {
              VStack(spacing: 0) {
                calendarToggle(
                  isOn: $importEnabled,
                  icon: "calendar.badge.clock",
                  title: "Mostrar compromissos",
                  subtitle: "Exibe eventos do Calendário em Hoje e Em breve"
                )

                if calendarService.authorizationGranted && importEnabled {
                  SettingsCardDivider(leadingPadding: 14)
                  calendarToggle(
                    isOn: $exportEnabled,
                    icon: "square.and.arrow.up",
                    title: "Exportar tarefas",
                    subtitle: calendarService.isExportSyncing
                      ? "Atualizando eventos no Calendário…"
                      : "Envia tarefas e subtarefas com data para o calendário \"Stacked\""
                  )
                  .disabled(calendarService.isExportSyncing)
                  .opacity(calendarService.isExportSyncing ? 0.6 : 1)

                  if exportEnabled {
                    SettingsCardDivider(leadingPadding: 14)
                    calendarToggle(
                      isOn: $exportAsAllDay,
                      icon: "text.alignleft",
                      title: "Só título (sem horário)",
                      subtitle: exportSyncSubtitle
                    )
                    .disabled(calendarService.isExportSyncing)
                    .opacity(calendarService.isExportSyncing ? 0.6 : 1)
                  }
                } else if importEnabled {
                  SettingsCardDivider(leadingPadding: 14)
                  HStack(spacing: 12) {
                    Image(systemName: "info.circle")
                      .font(.system(size: 18))
                      .foregroundStyle(theme.colors.textTertiary)
                      .frame(width: 24)
                    Text("Permita o acesso ao Calendário acima para exportar tarefas.")
                      .font(AppTypography.meta)
                      .foregroundStyle(theme.colors.textTertiary)
                  }
                  .padding(.horizontal, SettingsChrome.rowPaddingH)
                  .padding(.vertical, SettingsChrome.rowPaddingV)
                }
              }
            }
            .settingsListCardRow(top: 8)
          } header: {
            SettingsSectionHeader(text: "Sincronização")
          }

          if calendarService.authorizationGranted && importEnabled {
            Section {
              SettingsCardSurface {
                VStack(spacing: 0) {
                  if calendarService.importableCalendars.isEmpty {
                    Text("Nenhum calendário encontrado nesta conta.")
                      .font(AppTypography.taskPreview)
                      .foregroundStyle(c.textTertiary)
                      .padding(.horizontal, SettingsChrome.rowPaddingH)
                      .padding(.vertical, SettingsChrome.rowPaddingV)
                  } else {
                    ForEach(Array(importableCalendarsForUI.enumerated()), id: \.element.calendarIdentifier) { index, cal in
                      if index > 0 { SettingsCardDivider(leadingPadding: 14) }
                      calendarSelectionRow(cal)
                    }
                  }
                }
              }
              .settingsListCardRow(top: 0, bottom: 4)
            } header: {
              SettingsSectionHeader(text: "Calendários para importar")
            }

            Section {
              Text("Não marque \"Stacked\" aqui — é só para exportar tarefas do app. Para ver no app Calendário do iPhone, abra Calendário → Calendários e ative \"Stacked\".")
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
    .navigationTitle("Calendário")
    .navigationBarTitleDisplayMode(.inline)
    .task { await load() }
    .onChange(of: importEnabled) { _, newValue in
      guard togglesReady else { return }
      _Concurrency.Task { await applyImportPreference(newValue) }
    }
    .onChange(of: exportEnabled) { _, newValue in
      guard togglesReady else { return }
      _Concurrency.Task { await applyExportPreference(newValue) }
    }
    .onChange(of: exportAsAllDay) { _, newValue in
      guard togglesReady else { return }
      _Concurrency.Task { await applyExportAsAllDayPreference(newValue) }
    }
  }

  private var exportSyncSubtitle: String {
    if calendarService.isExportSyncing {
      return "Atualizando eventos no Calendário…"
    }
    return "Bloco de 30 min no Calendário — título legível, sem faixa de 1 hora"
  }

  private var importableCalendarsForUI: [EKCalendar] {
    calendarService.calendarsAvailableForImport
  }

  private func calendarToggle(
    isOn: Binding<Bool>,
    icon: String,
    title: String,
    subtitle: String
  ) -> some View {
    HStack(spacing: 12) {
      settingsLabel(icon: icon, title: title, subtitle: subtitle)
      Spacer(minLength: 8)
      SettingsSwitchToggle(isOn: isOn, tint: theme.colors.accent)
    }
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
  }

  private func calendarSelectionRow(_ cal: EKCalendar) -> some View {
    let c = theme.colors
    let selected = selectedIDs.isEmpty || selectedIDs.contains(cal.calendarIdentifier)

    return Button {
      toggleCalendar(cal.calendarIdentifier)
    } label: {
      HStack(spacing: 12) {
        Circle()
          .fill(Color(uiColor: UIColor(cgColor: cal.cgColor)))
          .frame(width: 10, height: 10)
        Text(cal.title)
          .font(AppTypography.settingsTitle)
          .foregroundStyle(c.textPrimary)
        Spacer(minLength: 0)
        if selected {
          Image(systemName: "checkmark")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(c.accent)
        }
      }
      .padding(.horizontal, SettingsChrome.rowPaddingH)
      .padding(.vertical, SettingsChrome.rowPaddingV)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private func settingsLabel(icon: String, title: String, subtitle: String) -> some View {
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
        Text(subtitle)
          .font(AppTypography.meta)
          .foregroundStyle(c.textTertiary)
      }
    }
  }

  private func load() async {
    calendarService.refreshAuthorizationState()
    selectedIDs = CalendarPreferences.selectedCalendarIDs
    loading = false
    togglesReady = true
  }

  private func requestAccess() async {
    let granted = await calendarService.requestAccess()
    calendarService.refreshAuthorizationState()
    needsPermissionHint = !granted
    if granted {
      if selectedIDs.isEmpty {
        selectedIDs = Set(calendarService.importableCalendars.map(\.calendarIdentifier))
        CalendarPreferences.selectedCalendarIDs = selectedIDs
      }
      await TaskStore.shared.reloadCalendarEvents()
      await UpcomingStore.shared.reloadCalendarEvents()
      HapticService.success()
    }
  }

  /// Preferência do usuário — não reverte o toggle se permissão falhar (simulador costuma negar).
  private func applyImportPreference(_ enabled: Bool) async {
    CalendarPreferences.importEnabled = enabled
    needsPermissionHint = false

    if enabled {
      if !calendarService.authorizationGranted {
        let granted = await calendarService.requestAccess()
        calendarService.refreshAuthorizationState()
        needsPermissionHint = !granted
      }
      if calendarService.authorizationGranted && selectedIDs.isEmpty {
        selectedIDs = Set(calendarService.importableCalendars.map(\.calendarIdentifier))
        CalendarPreferences.selectedCalendarIDs = selectedIDs
      }
      await TaskStore.shared.reloadCalendarEvents()
      await UpcomingStore.shared.reloadCalendarEvents()
      HapticService.success()
    } else {
      await TaskStore.shared.reloadCalendarEvents()
      await UpcomingStore.shared.reloadCalendarEvents()
      HapticService.selection()
    }
  }

  private func applyExportPreference(_ enabled: Bool) async {
    CalendarPreferences.exportEnabled = enabled
    if enabled {
      if !calendarService.authorizationGranted {
        let granted = await calendarService.requestAccess()
        calendarService.refreshAuthorizationState()
        needsPermissionHint = !granted
      }
      if calendarService.authorizationGranted {
        await calendarService.syncAllExportableTasks(runGlobalDedupe: false)
      }
      HapticService.success()
    } else {
      HapticService.selection()
    }
  }

  private func applyExportAsAllDayPreference(_ enabled: Bool) async {
    CalendarPreferences.exportAsAllDay = enabled
    guard CalendarPreferences.exportEnabled, calendarService.authorizationGranted else {
      HapticService.selection()
      return
    }
    await calendarService.syncAllExportableTasks(runGlobalDedupe: false)
    HapticService.success()
  }

  private func toggleCalendar(_ id: String) {
    var ids = selectedIDs
    if ids.isEmpty {
      ids = Set(calendarService.importableCalendars.map(\.calendarIdentifier))
    }
    if ids.contains(id) {
      ids.remove(id)
    } else {
      ids.insert(id)
    }
    selectedIDs = ids
    CalendarPreferences.selectedCalendarIDs = ids
    HapticService.selection()
    _Concurrency.Task {
      await TaskStore.shared.reloadCalendarEvents()
      await UpcomingStore.shared.reloadCalendarEvents()
    }
  }
}

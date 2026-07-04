import SwiftUI
import Hugeicons

// Paridade lib/widgets/task_detail/sheets/task_date_picker_sheet.dart
struct TaskDatePickerSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var initialDate: Date?
  var initialTime: Date?
  var showRecurrence: Bool
  var onChanged: (Date?, Date?) -> Void
  var onClose: (() -> Void)?

  @State private var selectedDate: Date?
  @State private var selectedTime: Date
  @State private var hasTime = false
  @State private var timeExpanded = false
  @State private var displayedMonth: Date

  init(
    initialDate: Date?,
    initialTime: Date? = nil,
    showRecurrence: Bool = true,
    onClose: (() -> Void)? = nil,
    onChanged: @escaping (Date?, Date?) -> Void
  ) {
    self.initialDate = initialDate
    self.initialTime = initialTime
    self.showRecurrence = showRecurrence
    self.onClose = onClose
    self.onChanged = onChanged
    _selectedDate = State(initialValue: initialDate)
    _selectedTime = State(initialValue: initialTime ?? Date())
    _hasTime = State(initialValue: initialTime != nil)
    _timeExpanded = State(initialValue: initialTime != nil)
    _displayedMonth = State(initialValue: initialDate ?? Date())
  }

  var body: some View {
    let c = theme.colors

    NavigationStack {
      VStack(spacing: 0) {
        shortcutsSection

        Divider().overlay(c.surfaceVariant.opacity(0.55))

        ScrollView {
          calendarSection
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        timeSection
      }
      .navigationTitle("Data")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(c.background, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button { confirmAndDismiss() } label: {
            StackedIcons.image(.close)
              .font(.system(size: 16))
              .foregroundStyle(c.textSecondary)
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          if selectedDate != nil {
            Button("Limpar") { clearDate() }
              .font(.system(size: 14))
              .foregroundStyle(c.textTertiary)
          }
        }
      }
    }
    .background(c.background.ignoresSafeArea())
    .presentationDragIndicator(.visible)
    .presentationBackground(c.background)
    .presentationSizing(.form)
  }

  // MARK: - Sections

  private var shortcutsSection: some View {
    let c = theme.colors

    return VStack(spacing: 0) {
      ForEach(shortcuts, id: \.label) { shortcut in
        Button { applyShortcut(shortcut.date) } label: {
          HStack(spacing: 14) {
            StackedIcons.image(shortcut.icon)
              .font(.system(size: 20))
              .foregroundStyle(shortcut.color)
              .frame(width: 24)
            Text(shortcut.label)
              .font(.system(size: 15, weight: .semibold))
              .foregroundStyle(isSameDay(selectedDate, shortcut.date) ? shortcut.color : c.textPrimary)
            Spacer()
            Text(weekdayAbbr(shortcut.date))
              .font(.system(size: 13))
              .foregroundStyle(c.textTertiary)
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 11)
          .background(isSameDay(selectedDate, shortcut.date) ? shortcut.color.opacity(0.10) : Color.clear)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.bottom, 2)
  }

  private var calendarSection: some View {
    let c = theme.colors

    return DatePicker(
      "",
      selection: Binding(
        get: { selectedDate ?? Date() },
        set: { newDate in
          selectedDate = Calendar.current.startOfDay(for: newDate)
          displayedMonth = newDate
          HapticService.selection()
          confirmChange()
        }
      ),
      displayedComponents: .date
    )
    .datePickerStyle(.graphical)
    .fixedSize(horizontal: false, vertical: true)
    .tint(c.accent)
    .padding(.horizontal, 8)
  }

  private var timeSection: some View {
    let c = theme.colors

    return VStack(spacing: 0) {
      Divider().overlay(c.surfaceVariant.opacity(0.55))

      Button {
        AppMotion.animate(AppMotion.smooth, reduceMotion: reduceMotion) {
          timeExpanded.toggle()
          if timeExpanded { hasTime = true }
        }
      } label: {
        HStack(spacing: 14) {
          StackedIcons.image(.clock)
            .font(.system(size: 20))
            .foregroundStyle(hasTime ? c.accent : c.textSecondary)
          Text("Hora")
            .font(.system(size: 15))
            .foregroundStyle(c.textPrimary)
          Spacer()
          Text(timeLabel)
            .font(.system(size: 14, weight: hasTime ? .semibold : .regular))
            .foregroundStyle(hasTime ? c.accent : c.textTertiary)
          StackedIcons.image(.chevronRight)
            .font(.system(size: 14))
            .foregroundStyle(c.textTertiary)
            .rotationEffect(.degrees(timeExpanded ? 90 : 0))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
      }
      .buttonStyle(.plain)

      if timeExpanded {
        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
          .datePickerStyle(.wheel)
          .labelsHidden()
          .frame(height: 140)
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .onChange(of: selectedTime) { _, _ in
            hasTime = true
            confirmChange()
          }
      }
    }
    .background(c.background)
  }

  private var shortcuts: [(label: String, icon: StackedIconKey, color: Color, date: Date)] {
    let today = Calendar.current.startOfDay(for: Date())
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
    let weekend = nextWeekday(7)
    let nextMonday = nextWeekday(1)
    return [
      ("Hoje", .calendar, AppColors.dateDueToday, today),
      ("Amanhã", .sun, AppColors.priorityMedium, tomorrow),
      ("Este fim de semana", .navUpcoming, AppColors.priorityLow, weekend),
      ("Próxima semana", .chevronRight, AppColors.tagPurple, nextMonday),
    ]
  }

  private var timeLabel: String {
    guard hasTime else { return "Nenhum" }
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f.string(from: selectedTime)
  }

  private func weekdayAbbr(_ date: Date) -> String {
    let labels = ["dom.", "seg.", "ter.", "qua.", "qui.", "sex.", "sáb."]
    let idx = Calendar.current.component(.weekday, from: date) - 1
    return labels[idx]
  }

  private func nextWeekday(_ weekday: Int) -> Date {
    let today = Calendar.current.startOfDay(for: Date())
    var d = Calendar.current.date(byAdding: .day, value: 1, to: today)!
    while Calendar.current.component(.weekday, from: d) != weekday {
      d = Calendar.current.date(byAdding: .day, value: 1, to: d)!
    }
    return d
  }

  private func isSameDay(_ a: Date?, _ b: Date) -> Bool {
    guard let a else { return false }
    return Calendar.current.isDate(a, inSameDayAs: b)
  }

  private func applyShortcut(_ date: Date) {
    HapticService.selection()
    selectedDate = date
    displayedMonth = date
    confirmChange()
    closePanel()
  }

  private func clearDate() {
    selectedDate = nil
    hasTime = false
    timeExpanded = false
    confirmChange()
    closePanel()
  }

  private func confirmChange() {
    onChanged(selectedDate, hasTime ? selectedTime : nil)
  }

  private func confirmAndDismiss() {
    confirmChange()
    closePanel()
  }

  private func closePanel() {
    if let onClose { onClose() } else { dismiss() }
  }
}

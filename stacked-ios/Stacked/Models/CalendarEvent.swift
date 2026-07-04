import Foundation

/// Compromisso importado do Calendário do iPhone (EventKit).
struct CalendarEvent: Identifiable, Equatable {
  let id: String
  let title: String
  let startDate: Date
  let endDate: Date
  let isAllDay: Bool
  let calendarTitle: String
  let calendarColorHex: UInt32?

  var timeDisplay: String? {
    guard !isAllDay else { return nil }
    return TaskMapper.formatTimeDisplay(timeString(from: startDate))
  }

  var day: Date {
    TaskMapper.startOfDay(startDate)
  }

  private func timeString(from date: Date) -> String {
    let cal = Calendar.current
    let h = cal.component(.hour, from: date)
    let m = cal.component(.minute, from: date)
    return String(format: "%02d:%02d", h, m)
  }
}

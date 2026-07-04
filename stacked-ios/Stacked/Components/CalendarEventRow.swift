import SwiftUI

struct CalendarEventRow: View {
  @Environment(ThemeManager.self) private var theme

  let event: CalendarEvent
  var onTap: (() -> Void)?

  var body: some View {
    let c = theme.colors
    let accent = event.calendarColorHex.map { Color(hex: $0) } ?? c.accent

    Button {
      onTap?()
    } label: {
      HStack(alignment: .center, spacing: 10) {
        RoundedRectangle(cornerRadius: 2)
          .fill(accent)
          .frame(width: 3, height: 32)

        Image(systemName: "calendar")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(accent)
          .frame(width: 28, height: 28)
          .background(accent.opacity(0.12))
          .clipShape(RoundedRectangle(cornerRadius: 7))

        VStack(alignment: .leading, spacing: 2) {
          Text(event.title)
            .font(AppTypography.taskTitle)
            .foregroundStyle(c.textPrimary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)

          Text(subtitle)
            .font(AppTypography.taskPreview)
            .foregroundStyle(c.textTertiary)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if let time = event.timeDisplay {
          Text(time)
            .font(AppTypography.meta.weight(.semibold))
            .foregroundStyle(c.textSecondary)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .frame(minHeight: AppLayout.taskRowHeight - 8)
      .background(c.surface)
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(event.title), compromisso do calendário, \(subtitle)")
  }

  private var subtitle: String {
    if event.isAllDay { return "Dia inteiro · \(event.calendarTitle)" }
    return event.calendarTitle
  }
}

import SwiftUI

// Apresentação padrão do seletor de data (paridade quick_add + task_detail)
extension View {
  func stackedTaskDatePickerSheet(
    isPresented: Binding<Bool>,
    initialDate: Date?,
    initialTime: Date? = nil,
    showRecurrence: Bool = false,
    showsTime: Bool = true,
    title: String = "Data",
    onChanged: @escaping (Date?, Date?) -> Void
  ) -> some View {
    sheet(isPresented: isPresented) {
      TaskDatePickerSheet(
        initialDate: initialDate,
        initialTime: initialTime,
        showRecurrence: showRecurrence,
        showsTime: showsTime,
        title: title,
        onChanged: onChanged
      )
      .environment(ThemeManager.shared)
    }
  }
}

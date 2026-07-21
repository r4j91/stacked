import SwiftUI

struct KeyboardHeightObserver: ViewModifier {
  @Binding var height: CGFloat

  func body(content: Content) -> some View {
    content
      .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let screenH = DisplayScreen.bounds.height
        height = max(0, screenH - frame.origin.y)
      }
  }
}

extension View {
  func observeKeyboardHeight(_ height: Binding<CGFloat>) -> some View {
    modifier(KeyboardHeightObserver(height: height))
  }
}

private struct SheetHeightKey: PreferenceKey {
  static var defaultValue: CGFloat = 280
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

extension View {
  func reportSheetHeight(_ height: Binding<CGFloat>) -> some View {
    background(
      GeometryReader { geo in
        Color.clear.preference(key: SheetHeightKey.self, value: geo.size.height)
      }
    )
    .onPreferenceChange(SheetHeightKey.self) { h in
      guard h > 1 else { return }
      height.wrappedValue = h
    }
  }
}

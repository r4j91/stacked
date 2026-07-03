import SwiftUI

/// Quick Add flutuante — sem `.sheet` nativo (evita container retangular do sistema).
struct QuickAddFloatingPresentation: ViewModifier {
  @Binding var isPresented: Bool
  var initialProjectId: String?
  var initialSectionId: String?
  var onSaved: () -> Void

  private let horizontalInset: CGFloat = 12
  /// Folga entre a borda inferior da cápsula e o topo do teclado.
  private let gapAboveKeyboard: CGFloat = 4

  func body(content: Content) -> some View {
    content
      .overlay {
        if isPresented {
          Color.clear
            .ignoresSafeArea(edges: [.top, .horizontal])
            .contentShape(Rectangle())
            .onTapGesture { dismiss() }
            .transition(.opacity)
        }
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        if isPresented {
          QuickAddTaskView(
            initialProjectId: initialProjectId,
            initialSectionId: initialSectionId,
            onSaved: onSaved,
            onDismiss: { dismiss() }
          )
          .environment(ThemeManager.shared)
          .padding(.horizontal, horizontalInset)
          .padding(.bottom, gapAboveKeyboard)
          .background(Color.clear)
          .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
  }

  private func dismiss() {
    PopoverPresenter.shared.dismiss()
    isPresented = false
  }
}

extension View {
  func quickAddFloating(
    isPresented: Binding<Bool>,
    initialProjectId: String? = nil,
    initialSectionId: String? = nil,
    onSaved: @escaping () -> Void = {}
  ) -> some View {
    modifier(
      QuickAddFloatingPresentation(
        isPresented: isPresented,
        initialProjectId: initialProjectId,
        initialSectionId: initialSectionId,
        onSaved: onSaved
      )
    )
  }
}

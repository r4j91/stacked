import SwiftUI

/// Novo projeto flutuante — mesmo host do Quick Add (keyboardLayoutGuide + fill nos cantos).
struct NewProjectFloatingPresentation: ViewModifier {
  @Environment(ThemeManager.self) private var theme
  @Binding var isPresented: Bool
  var onCreated: () -> Void

  private let horizontalInset: CGFloat = 12
  private let gapAboveKeyboard: CGFloat = 4

  func body(content: Content) -> some View {
    content
      .ignoresSafeArea(.keyboard, edges: .bottom)
      .overlay {
        if isPresented {
          Color.clear
            .ignoresSafeArea(edges: [.top, .horizontal])
            .contentShape(Rectangle())
            .onTapGesture { dismiss() }
            .transition(.opacity)
        }
      }
      .overlay {
        if isPresented {
          QuickAddKeyboardAnchorHost(
            backdropColor: theme.colors.background,
            gapAboveKeyboard: gapAboveKeyboard,
            horizontalInset: horizontalInset,
            content: AnyView(
              NewProjectSheetView(
                onCreated: onCreated,
                onDismiss: { dismiss() }
              )
              .environment(ThemeManager.shared)
            )
          )
          .ignoresSafeArea()
          .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
  }

  private func dismiss() {
    ColorGridPopoverPresenter.shared.dismiss()
    PopoverPresenter.shared.dismiss()
    isPresented = false
  }
}

extension View {
  func newProjectFloating(isPresented: Binding<Bool>, onCreated: @escaping () -> Void = {}) -> some View {
    modifier(NewProjectFloatingPresentation(isPresented: isPresented, onCreated: onCreated))
  }
}

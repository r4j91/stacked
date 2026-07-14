import SwiftUI

// Fase 4C — zoom transition nativo entre TaskRow e TaskDetailView.
enum TaskDetailZoom {
  static func source<ID: Hashable>(id: ID, namespace: Namespace.ID) -> some ViewModifier {
    MatchedTransitionSourceModifier(id: id, namespace: namespace)
  }

  @ViewBuilder
  static func cover<Content: View>(
    route: TaskDetailRoute,
    namespace: Namespace.ID,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    TaskDetailCover(route: route, namespace: namespace, content: content)
  }
}

/// Fundo opaco + zoom só com reduce motion desligado — evita piscada preta na transição.
private struct TaskDetailCover<Content: View>: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(ThemeManager.self) private var theme

  let route: TaskDetailRoute
  let namespace: Namespace.ID
  let content: () -> Content

  var body: some View {
    let base = content()
      .background(theme.colors.background.ignoresSafeArea())

    if reduceMotion {
      base
    } else {
      base.navigationTransition(.zoom(sourceID: route.taskId, in: namespace))
    }
  }
}

private struct MatchedTransitionSourceModifier<ID: Hashable>: ViewModifier {
  let id: ID
  let namespace: Namespace.ID

  func body(content: Content) -> some View {
    content.matchedTransitionSource(id: id, in: namespace) { config in
      // Clip estável no source — evita o sistema re-medir o texto da row no morph.
      config.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
  }
}

extension View {
  /// Zoom source só na row que abre o detalhe.
  /// Registrar em todas as cells idle faz o List deslocar o texto no 1º frame do scroll.
  @ViewBuilder
  func taskDetailZoomSource(id: String, namespace: Namespace.ID, active: Bool = true) -> some View {
    if active {
      modifier(TaskDetailZoom.source(id: id, namespace: namespace))
    } else {
      self
    }
  }
}

// SUBSTITUIDO_FASE4C: fullScreenCover sem navigationTransition(.zoom)
// .fullScreenCover(item: $detailRoute) { route in
//   TaskDetailView(taskId: route.taskId) { ... }
// }

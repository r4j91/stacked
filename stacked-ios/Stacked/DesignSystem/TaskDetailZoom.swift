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
    @ViewBuilder content: () -> Content
  ) -> some View {
    content()
      .navigationTransition(.zoom(sourceID: route.taskId, in: namespace))
  }
}

private struct MatchedTransitionSourceModifier<ID: Hashable>: ViewModifier {
  let id: ID
  let namespace: Namespace.ID

  func body(content: Content) -> some View {
    content.matchedTransitionSource(id: id, in: namespace)
  }
}

extension View {
  func taskDetailZoomSource(id: String, namespace: Namespace.ID) -> some View {
    modifier(TaskDetailZoom.source(id: id, namespace: namespace))
  }
}

// SUBSTITUIDO_FASE4C: fullScreenCover sem navigationTransition(.zoom)
// .fullScreenCover(item: $detailRoute) { route in
//   TaskDetailView(taskId: route.taskId) { ... }
// }

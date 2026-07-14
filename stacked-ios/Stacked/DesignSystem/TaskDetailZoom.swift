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
      // Um único fundo de apresentação — double background + zoom gerava “ghost” no dismiss.
      .presentationBackground(theme.colors.background)

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

/// Source só na row armada (idle sem custo).
///
/// Não desmonta no dismiss — o detach tardio (~480ms) era o “ghost” rápido ao fechar.
/// Limpa só quando a cell sai da hierarquia (`onDisappear`) e não está ativa.
private struct StickyTaskDetailZoomSourceModifier: ViewModifier {
  let id: String
  let namespace: Namespace.ID
  let active: Bool

  @State private var attached = false

  func body(content: Content) -> some View {
    Group {
      if attached {
        content.modifier(TaskDetailZoom.source(id: id, namespace: namespace))
      } else {
        content
      }
    }
    .onAppear {
      if active { attached = true }
    }
    .onChange(of: active) { _, isActive in
      if isActive {
        attached = true
      }
      // active == false no dismiss: mantém `attached` para o morph terminar limpo.
    }
    .onDisappear {
      guard !active else { return }
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        attached = false
      }
    }
  }
}

extension View {
  /// Source do zoom na TaskRow.
  ///
  /// `active: true` na row que abre o detalhe. Idle = sem source (scroll mais leve).
  /// Após abrir, o source fica até a cell sair da tela — evita ghost no fechar.
  func taskDetailZoomSource(id: String, namespace: Namespace.ID, active: Bool = true) -> some View {
    modifier(StickyTaskDetailZoomSourceModifier(id: id, namespace: namespace, active: active))
  }
}

// SUBSTITUIDO_FASE4C: fullScreenCover sem navigationTransition(.zoom)
// .fullScreenCover(item: $detailRoute) { route in
//   TaskDetailView(taskId: route.taskId) { ... }
// }

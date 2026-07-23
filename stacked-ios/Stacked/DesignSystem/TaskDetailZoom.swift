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

/// Aparência — detalhe da tarefa como sheet (de baixo), em vez de zoom em tela cheia.
enum TaskDetailSheetPresentationStorage {
  static let key = "appearance.taskDetailAsSheet"
  static let defaultEnabled = false

  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? defaultEnabled
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

/// Zoom em tela cheia (padrão) ou sheet de baixo — paridade com SubtaskDetail.
private struct TaskDetailPresentationModifier<Detail: View>: ViewModifier {
  @Environment(ThemeManager.self) private var theme
  @AppStorage(TaskDetailSheetPresentationStorage.key)
  private var presentAsSheet = TaskDetailSheetPresentationStorage.defaultEnabled

  @Binding var item: TaskDetailRoute?
  let namespace: Namespace.ID
  let onDismiss: (() -> Void)?
  let detail: (TaskDetailRoute) -> Detail

  private var sheetItem: Binding<TaskDetailRoute?> {
    Binding(
      get: { presentAsSheet ? item : nil },
      set: { item = $0 }
    )
  }

  private var coverItem: Binding<TaskDetailRoute?> {
    Binding(
      get: { presentAsSheet ? nil : item },
      set: { item = $0 }
    )
  }

  func body(content: Content) -> some View {
    content
      .sheet(item: sheetItem, onDismiss: onDismiss) { route in
        detail(route)
          .presentationBackground(theme.colors.background)
          .presentationDragIndicator(.visible)
          .presentationDetents([.large])
      }
      .fullScreenCover(item: coverItem, onDismiss: onDismiss) { route in
        TaskDetailZoom.cover(route: route, namespace: namespace) {
          detail(route)
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

  /// Apresenta `TaskDetailView` em zoom (padrão) ou sheet, conforme Aparência.
  func taskDetailCover(
    item: Binding<TaskDetailRoute?>,
    namespace: Namespace.ID,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping (TaskDetailRoute) -> some View
  ) -> some View {
    modifier(
      TaskDetailPresentationModifier(
        item: item,
        namespace: namespace,
        onDismiss: onDismiss,
        detail: content
      )
    )
  }
}

// SUBSTITUIDO_FASE4C: fullScreenCover sem navigationTransition(.zoom)
// .fullScreenCover(item: $detailRoute) { route in
//   TaskDetailView(taskId: route.taskId, seed: route.seed) { ... }
// }

import SwiftUI

/// PERF_ROW_APPEARANCE — preferências de aparência da linha resolvidas num ponto só.
///
/// Antes cada `TaskRow` declarava 3 `@AppStorage` e a `TaskMetaLine` aninhada mais 3,
/// somando 6 por linha visível. Cada `@AppStorage` registra um observer de
/// `UserDefaults` amarrado ao ciclo de vida da view, e o `List` cria e destrói views
/// de linha o tempo todo no scroll — o custo caía justamente no primeiro impulso do
/// fling. Agora um único observador injeta o valor e a linha só lê do environment.
struct TaskRowAppearance: Equatable {
  var layout: TaskRowLayout
  var subtaskProgressRing: Bool
  var subtaskBranch: Bool
  var installmentProgressOnCard: Bool
  var labelChipStyle: LabelChipStyle
  var dueDateChipStyle: DueDateChipStyle

  /// Leitura direta do `UserDefaults`. `TaskRowAppearance.current` cobre hosts que
  /// não herdam o environment da tela (mesmo padrão do `ThemeManager.shared`).
  static var current: TaskRowAppearance {
    TaskRowAppearance(
      layout: TaskRowLayoutStorage.current,
      subtaskProgressRing: SubtaskProgressRingStorage.isEnabled,
      subtaskBranch: SubtaskBranchStorage.isEnabled,
      installmentProgressOnCard: InstallmentProgressStorage.isEnabled,
      labelChipStyle: LabelChipStyleStorage.current,
      dueDateChipStyle: DueDateChipStyleStorage.current
    )
  }
}

private struct TaskRowAppearanceKey: EnvironmentKey {
  static var defaultValue: TaskRowAppearance { .current }
}

extension EnvironmentValues {
  var taskRowAppearance: TaskRowAppearance {
    get { self[TaskRowAppearanceKey.self] }
    set { self[TaskRowAppearanceKey.self] = newValue }
  }
}

/// Único observador das preferências de linha — aplicar na raiz do app.
/// Sheets e covers herdam o environment, então cobre TaskDetail e SubtaskDetail.
private struct TaskRowAppearanceSource: ViewModifier {
  @AppStorage(TaskRowLayoutStorage.key) private var layoutRaw = TaskRowLayoutStorage.defaultRawValue
  @AppStorage(SubtaskProgressRingStorage.key) private var subtaskProgressRing = SubtaskProgressRingStorage.defaultEnabled
  @AppStorage(SubtaskBranchStorage.key) private var subtaskBranch = SubtaskBranchStorage.defaultEnabled
  @AppStorage(InstallmentProgressStorage.key) private var installmentProgressOnCard = InstallmentProgressStorage.defaultEnabled
  @AppStorage(LabelChipStyleStorage.key) private var labelChipStyleRaw = LabelChipStyleStorage.defaultRawValue
  @AppStorage(DueDateChipStyleStorage.key) private var dueDateChipStyleRaw = DueDateChipStyleStorage.defaultRawValue

  func body(content: Content) -> some View {
    content.environment(
      \.taskRowAppearance,
      TaskRowAppearance(
        layout: TaskRowLayoutStorage.layout(from: layoutRaw),
        subtaskProgressRing: subtaskProgressRing,
        subtaskBranch: subtaskBranch,
        installmentProgressOnCard: installmentProgressOnCard,
        labelChipStyle: LabelChipStyleStorage.style(from: labelChipStyleRaw),
        dueDateChipStyle: DueDateChipStyleStorage.style(from: dueDateChipStyleRaw)
      )
    )
  }
}

extension View {
  func taskRowAppearanceSource() -> some View {
    modifier(TaskRowAppearanceSource())
  }
}

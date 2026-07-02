import UIKit

// Paridade lib/services/haptic_service.dart
@MainActor
enum HapticService {
  private static let lightGen = UIImpactFeedbackGenerator(style: .light)
  private static let mediumGen = UIImpactFeedbackGenerator(style: .medium)
  private static let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
  private static let selectionGen = UISelectionFeedbackGenerator()
  private static let notificationGen = UINotificationFeedbackGenerator()

  static func prepare() {
    lightGen.prepare()
    mediumGen.prepare()
    heavyGen.prepare()
    selectionGen.prepare()
    notificationGen.prepare()
  }

  /// Touch-down no check de tarefa — latência zero no impact do frame 0.
  static func prepareTaskComplete() {
    lightGen.prepare()
    mediumGen.prepare()
    heavyGen.prepare()
  }

  /// FASE5: touch-down antes de trocar aba.
  static func prepareTabChange() {
    selectionGen.prepare()
  }

  /// FASE5: touch-down antes de abrir FAB.
  static func prepareFabOpen() {
    lightGen.prepare()
  }

  /// FASE5: touch-down no início do long-press do menu de contexto.
  static func prepareContextMenu() {
    mediumGen.prepare()
  }

  static func selection() {
    selectionGen.selectionChanged()
  }

  static func light() {
    lightGen.impactOccurred()
  }

  static func medium() {
    mediumGen.impactOccurred()
  }

  static func heavy() {
    heavyGen.impactOccurred()
  }

  static func success() {
    notificationGen.notificationOccurred(.success)
  }

  static func warning() {
    notificationGen.notificationOccurred(.warning)
  }

  static func error() {
    // SUBSTITUIDO_FASE5: double heavy assíncrono com sleep
    // _Concurrency.Task { @MainActor in
    //   heavyGen.impactOccurred()
    //   try? await _Concurrency.Task.sleep(for: .milliseconds(100))
    //   heavyGen.impactOccurred()
    // }
    heavyGen.impactOccurred()
  }

  static func taskCompleted() {
    // Frame 0 — síncrono com o início do preenchimento visual.
    lightGen.impactOccurred()
    // SUBSTITUIDO_FASE3A: sequência inteira assíncrona (primeiro impact atrasado ~1 frame)
    // _Concurrency.Task { @MainActor in
    //   lightGen.impactOccurred()
    //   try? await _Concurrency.Task.sleep(for: .milliseconds(80))
    // SUBSTITUIDO_FASE5: follow-ups medium/heavy com sleeps dessincronizados
    // _Concurrency.Task { @MainActor in
    //   try? await _Concurrency.Task.sleep(for: .milliseconds(80))
    //   mediumGen.impactOccurred()
    //   try? await _Concurrency.Task.sleep(for: .milliseconds(80))
    //   heavyGen.impactOccurred()
    // }
  }

  static func taskCreated() {
    // SUBSTITUIDO_FASE5: light + medium com sleep
    // _Concurrency.Task { @MainActor in
    //   lightGen.impactOccurred()
    //   try? await _Concurrency.Task.sleep(for: .milliseconds(60))
    //   mediumGen.impactOccurred()
    // }
    mediumGen.impactOccurred()
  }

  static func taskDeleted() {
    // SUBSTITUIDO_FASE5: heavy + medium com sleep
    // _Concurrency.Task { @MainActor in
    //   heavyGen.impactOccurred()
    //   try? await _Concurrency.Task.sleep(for: .milliseconds(50))
    //   mediumGen.impactOccurred()
    // }
    heavyGen.impactOccurred()
  }

  static func tabChanged() {
    selectionGen.selectionChanged()
  }

  static func fabOpened() {
    lightGen.impactOccurred()
  }

  // SUBSTITUIDO_FASE4B: 3 impacts assíncronos com sleeps
  // _Concurrency.Task { @MainActor in
  //   lightGen.impactOccurred()
  //   try? await _Concurrency.Task.sleep(for: .milliseconds(60))
  //   lightGen.impactOccurred()
  //   try? await _Concurrency.Task.sleep(for: .milliseconds(60))
  //   mediumGen.impactOccurred()
  // }

  static func dateSelected() {
    lightGen.impactOccurred()
  }

  static func saved() {
    mediumGen.impactOccurred()
  }
}

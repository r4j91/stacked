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
    _Concurrency.Task { @MainActor in
      heavyGen.impactOccurred()
      try? await _Concurrency.Task.sleep(for: .milliseconds(100))
      heavyGen.impactOccurred()
    }
  }

  static func taskCompleted() {
    // Frame 0 — síncrono com o início do preenchimento visual.
    lightGen.impactOccurred()
    // SUBSTITUIDO_FASE3A: sequência inteira assíncrona (primeiro impact atrasado ~1 frame)
    // _Concurrency.Task { @MainActor in
    //   lightGen.impactOccurred()
    //   try? await _Concurrency.Task.sleep(for: .milliseconds(80))
    _Concurrency.Task { @MainActor in
      try? await _Concurrency.Task.sleep(for: .milliseconds(80))
      mediumGen.impactOccurred()
      try? await _Concurrency.Task.sleep(for: .milliseconds(80))
      heavyGen.impactOccurred()
    }
  }

  static func taskCreated() {
    _Concurrency.Task { @MainActor in
      lightGen.impactOccurred()
      try? await _Concurrency.Task.sleep(for: .milliseconds(60))
      mediumGen.impactOccurred()
    }
  }

  static func taskDeleted() {
    _Concurrency.Task { @MainActor in
      heavyGen.impactOccurred()
      try? await _Concurrency.Task.sleep(for: .milliseconds(50))
      mediumGen.impactOccurred()
    }
  }

  static func tabChanged() {
    selectionGen.selectionChanged()
  }

  static func fabOpened() {
    _Concurrency.Task { @MainActor in
      lightGen.impactOccurred()
      try? await _Concurrency.Task.sleep(for: .milliseconds(60))
      lightGen.impactOccurred()
      try? await _Concurrency.Task.sleep(for: .milliseconds(60))
      mediumGen.impactOccurred()
    }
  }

  static func dateSelected() {
    lightGen.impactOccurred()
  }

  static func saved() {
    mediumGen.impactOccurred()
  }
}

import Foundation

/// PERF_FASEB3_3A — gate de duas fases para freeze do glass sem teardown no arranque.
enum DockGlassFreezePhase {
  /// Fase 1: `false` — layer frozen montado sob o live (opacity 0), troca ainda via switch legado.
  /// Fase 2: `true` — flip de opacity live↔frozen (zero remoção de glassEffect no gesto).
  // PERF_FASEB3_3A_FASE1: static let opacityFlipEnabled = false
  static let opacityFlipEnabled = true
}

/// Toggle interno (NetLog) — força o switch legado live/frozen para A/B e rollback.
enum DockGlassFreezeLegacyStorage {
  static let key = "perf.b3.3a.legacySwitch"

  static var useLegacySwitch: Bool {
    UserDefaults.standard.bool(forKey: key)
  }
}

import Foundation

/// PERF_FASEB3_3A — gate do path de freeze do dock.
enum DockGlassFreezePhase {
  /// `true` (ativo): frozen fill + live montado só em `.live` (teardown no scroll).
  /// `false`: mesma troca via switch legado explícito.
  /// Histórico: um dia live ficava em opacity 0 (custo GPU sem ver).
  static let opacityFlipEnabled = true
}

/// Toggle interno (NetLog) — força o switch legado live/frozen para A/B e rollback.
enum DockGlassFreezeLegacyStorage {
  static let key = "perf.b3.3a.legacySwitch"

  static var useLegacySwitch: Bool {
    UserDefaults.standard.bool(forKey: key)
  }
}

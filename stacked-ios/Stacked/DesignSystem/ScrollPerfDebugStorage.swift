import Foundation

/// PERF_FASEB3_ETAPA2 — toggles de isolamento (debug).
/// PERF_FASEB3_3A — T1–T3 desligados do path ativo após o fix; keys preservadas para rollback.
enum ScrollPerfDebugStorage {
  static let t1ChromeStaticKey = "perf.b3.t1.chromeStatic"
  static let t2RowsPlaceholderKey = "perf.b3.t2.rowsPlaceholder"
  static let t3ChromeHiddenKey = "perf.b3.t3.chromeHidden"

  /// T1 — ignora fase de scroll; dock não troca live↔frozen.
  // PERF_FASEB3_3A: static var t1ChromeStatic: Bool { UserDefaults.standard.bool(forKey: t1ChromeStaticKey) }
  static var t1ChromeStatic: Bool { false }

  /// T2 — linhas como retângulo estático (mesma altura, sem gestos/menu/chips).
  // PERF_FASEB3_3A: static var t2RowsPlaceholder: Bool { UserDefaults.standard.bool(forKey: t2RowsPlaceholderKey) }
  static var t2RowsPlaceholder: Bool { false }

  /// T3 — chrome glass em opacity 0 (hierarquia intacta).
  // PERF_FASEB3_3A: static var t3ChromeHidden: Bool { UserDefaults.standard.bool(forKey: t3ChromeHiddenKey) }
  static var t3ChromeHidden: Bool { false }
}

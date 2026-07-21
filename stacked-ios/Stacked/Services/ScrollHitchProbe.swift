import Foundation
import QuartzCore
import UIKit

/// PERF_FASEB3_ETAPA1 — conta hitches nos primeiros 500ms após o scroll sair de idle.
@MainActor
enum ScrollHitchProbe {
  struct Sample: Identifiable, Equatable {
    let id: UUID
    let at: Date
    let scenario: String
    let screen: String
    let hitchCount: Int
    let worstMs: Double
    let frameBudgetMs: Double

    init(
      scenario: String,
      screen: String,
      hitchCount: Int,
      worstMs: Double,
      frameBudgetMs: Double
    ) {
      self.id = UUID()
      self.at = Date()
      self.scenario = scenario
      self.screen = screen
      self.hitchCount = hitchCount
      self.worstMs = worstMs
      self.frameBudgetMs = frameBudgetMs
    }
  }

  private static var link: CADisplayLink?
  private static var windowStarted: CFTimeInterval?
  private static var lastTimestamp: CFTimeInterval?
  private static var hitchCount = 0
  private static var worstMs: Double = 0
  private static var pendingScreen = "—"
  private(set) static var samples: [Sample] = []

  static var scenarioLabel: String {
    let t0 = FreezeDockGlassWhileScrollingStorage.isEnabled ? "T0ON" : "T0OFF"
    let t1 = ScrollPerfDebugStorage.t1ChromeStatic ? "+T1" : ""
    let t2 = ScrollPerfDebugStorage.t2RowsPlaceholder ? "+T2" : ""
    let t3 = ScrollPerfDebugStorage.t3ChromeHidden ? "+T3" : ""
    return "\(t0)\(t1)\(t2)\(t3)"
  }

  static func noteScreen(_ name: String) {
    pendingScreen = name
  }

  static func clear() {
    samples.removeAll()
  }

  /// PERF_FASEB3 — agregação fixa: mediana de TODOS os gestos (inclui zeros) + quantos tiveram hitch.
  static func summary(forScreen screen: String, scenario: String) -> String? {
    let matching = samples.filter { $0.screen == screen && $0.scenario == scenario }
    guard !matching.isEmpty else { return nil }
    let counts = matching.map(\.hitchCount).sorted()
    let median = medianOf(counts)
    let withHitch = matching.filter { $0.hitchCount > 0 }.count
    let worst = matching.map(\.worstMs).max() ?? 0
    return String(
      format: "%@ · %@: mediana %.1f hitches/500ms · %d de %d com hitch · pior %.1fms",
      screen,
      scenario,
      median,
      withHitch,
      matching.count,
      worst
    )
  }

  private static func medianOf(_ values: [Int]) -> Double {
    guard !values.isEmpty else { return 0 }
    let mid = values.count / 2
    if values.count.isMultiple(of: 2) {
      return Double(values[mid - 1] + values[mid]) / 2
    }
    return Double(values[mid])
  }

  /// Chamar a partir de `onScrollPhaseChange` quando `phase != .idle`.
  static func scrollBecameActive() {
    guard link == nil else { return }
    hitchCount = 0
    worstMs = 0
    lastTimestamp = nil
    windowStarted = CACurrentMediaTime()

    let target = TickTarget.shared
    let displayLink = CADisplayLink(target: target, selector: #selector(TickTarget.tick(_:)))
    displayLink.add(to: .main, forMode: .common)
    link = displayLink
  }

  fileprivate static func handle(link: CADisplayLink) {
    let now = link.timestamp
    defer { lastTimestamp = now }

    guard let started = windowStarted else { return }
    let elapsed = now - started
    if elapsed > 0.5 {
      finish()
      return
    }

    guard let previous = lastTimestamp else { return }
    let deltaMs = (now - previous) * 1000
    // Orçamento do display nativo (120Hz ≈ 8.33ms; 60Hz ≈ 16.67ms) + folga 50%.
    let budgetMs = max(link.duration * 1000, 1) * 1.5
    if deltaMs > budgetMs {
      hitchCount += 1
      worstMs = max(worstMs, deltaMs)
    }
  }

  private static func finish() {
    link?.invalidate()
    link = nil
    windowStarted = nil
    lastTimestamp = nil
    let fps = max(DisplayScreen.maximumFramesPerSecond, 60)
    let budget = 1000.0 / Double(fps)
    let sample = Sample(
      scenario: scenarioLabel,
      screen: pendingScreen,
      hitchCount: hitchCount,
      worstMs: worstMs,
      frameBudgetMs: budget
    )
    samples.append(sample)
    if samples.count > 40 {
      samples.removeFirst(samples.count - 40)
    }
  }
}

private final class TickTarget: NSObject {
  static let shared = TickTarget()

  @objc func tick(_ link: CADisplayLink) {
    DispatchQueue.main.async {
      ScrollHitchProbe.handle(link: link)
    }
  }
}

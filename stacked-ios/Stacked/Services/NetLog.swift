import Foundation
import UIKit

/// NET_FASEC_ETAPA1 — ring buffer de rede (Release-on) para diagnosticar saves aleatórios.
enum NetLog {
  enum ChainStep: String, Sendable {
    case insertTask = "insert_task"
    case insertLabels = "insert_labels"
    case updateTask = "update_task"
    case updateLabels = "update_labels"
    case selectVerify = "select_verify"
    case notif = "notif"
    case calendar = "calendar"
    case reload = "reload"
    case authRefresh = "auth_refresh"
    case flowSave = "flow_save"
    case other = "other"
  }

  enum ResultKind: String, Sendable {
    case success
    case timeout
    case noNetwork
    case auth
    case server
    case decode
    case cancelled
    case unknown
  }

  struct Entry: Identifiable, Sendable {
    let id: UUID
    let at: Date
    let msSinceForeground: Int
    let operation: String
    let step: ChainStep
    let durationMs: Int
    let result: ResultKind
    let detail: String?
  }

  private static let capacity = 200
  private static var buffer: [Entry] = []
  private static var lastForegroundAt = Date()
  private static let lock = NSLock()

  @MainActor
  static func markForeground() {
    lastForegroundAt = Date()
    record(
      operation: "app.foreground",
      step: .authRefresh,
      durationMs: 0,
      result: .success,
      detail: nil
    )
  }

  static var msSinceForeground: Int {
    lock.lock()
    defer { lock.unlock() }
    return Int(Date().timeIntervalSince(lastForegroundAt) * 1000)
  }

  static func record(
    operation: String,
    step: ChainStep,
    durationMs: Int,
    result: ResultKind,
    detail: String? = nil
  ) {
    let entry = Entry(
      id: UUID(),
      at: Date(),
      msSinceForeground: msSinceForeground,
      operation: operation,
      step: step,
      durationMs: durationMs,
      result: result,
      detail: detail.map { String($0.prefix(240)) }
    )
    lock.lock()
    buffer.append(entry)
    if buffer.count > capacity {
      buffer.removeFirst(buffer.count - capacity)
    }
    lock.unlock()
  }

  nonisolated static func classify(_ error: Error) -> ResultKind {
    if error is CancellationError { return .cancelled }
    let ns = error as NSError
    if ns.domain == NSURLErrorDomain {
      switch ns.code {
      case NSURLErrorTimedOut: return .timeout
      case NSURLErrorNotConnectedToInternet,
           NSURLErrorNetworkConnectionLost,
           NSURLErrorDataNotAllowed:
        return .noNetwork
      default: break
      }
    }
    let text = error.localizedDescription.lowercased()
    if text.contains("timed out") || text.contains("timeout") { return .timeout }
    if text.contains("offline") || text.contains("internet") || text.contains("network") {
      return .noNetwork
    }
    if text.contains("jwt") || text.contains("401") || text.contains("403")
      || text.contains("auth") || text.contains("não autenticado") {
      return .auth
    }
    if text.contains("decode") || text.contains("corrupted") { return .decode }
    if text.contains("500") || text.contains("502") || text.contains("503")
      || text.contains("server") || text.contains("rls") {
      return .server
    }
    return .unknown
  }

  @discardableResult
  static func timed<T>(
    _ operation: String,
    step: ChainStep,
    work: () async throws -> T
  ) async rethrows -> T {
    let start = Date()
    do {
      let value = try await work()
      let ms = Int(Date().timeIntervalSince(start) * 1000)
      record(operation: operation, step: step, durationMs: ms, result: .success)
      return value
    } catch {
      let ms = Int(Date().timeIntervalSince(start) * 1000)
      record(
        operation: operation,
        step: step,
        durationMs: ms,
        result: classify(error),
        detail: error.localizedDescription
      )
      throw error
    }
  }

  @MainActor
  static func entries() -> [Entry] {
    lock.lock()
    defer { lock.unlock() }
    return buffer
  }

  @MainActor
  static func exportText() -> String {
    lock.lock()
    let snapshot = buffer
    let fg = Int(Date().timeIntervalSince(lastForegroundAt) * 1000)
    lock.unlock()
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    var lines: [String] = [
      "Stacked NetLog export",
      "count=\(snapshot.count) capacity=\(capacity)",
      "ms_since_fg=\(fg)",
      "---",
    ]
    for e in snapshot {
      let detail = e.detail.map { " |\($0)" } ?? ""
      lines.append(
        "\(formatter.string(from: e.at)) fg+\(e.msSinceForeground)ms [\(e.step.rawValue)] \(e.operation) \(e.durationMs)ms \(e.result.rawValue)\(detail)"
      )
    }
    return lines.joined(separator: "\n")
  }

  @MainActor
  @discardableResult
  static func copyToPasteboard() -> Bool {
    let text = exportText()
    UIPasteboard.general.string = text
    return !text.isEmpty
  }

  @MainActor
  static func clear() {
    lock.lock()
    buffer.removeAll(keepingCapacity: true)
    lock.unlock()
  }
}

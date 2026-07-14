import Foundation
import SwiftUI

/// NET_FASEC_ETAPA2/4 — toast discreto de sync + retry manual.
@MainActor
@Observable
final class SyncFeedback {
  static let shared = SyncFeedback()

  struct Banner: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let taskId: String?
    let retry: (() -> Void)?

    static func == (lhs: Banner, rhs: Banner) -> Bool {
      lhs.id == rhs.id
    }
  }

  private(set) var banner: Banner?

  private init() {}

  func show(_ error: SyncError, taskId: String? = nil, retry: (() -> Void)? = nil) {
    guard error.shouldShowToast, let message = error.userMessage else { return }
    banner = Banner(message: message, taskId: taskId, retry: retry)
  }

  func showMessage(_ message: String, taskId: String? = nil, retry: (() -> Void)? = nil) {
    banner = Banner(message: message, taskId: taskId, retry: retry)
  }

  /// Descarta toast se a sync do mesmo id concluiu depois (falso positivo).
  func clearSuccess(for taskId: String) {
    guard banner?.taskId == taskId else { return }
    banner = nil
  }

  func dismiss() {
    banner = nil
  }

  func invokeRetry() {
    let action = banner?.retry
    banner = nil
    action?()
  }
}

struct SyncToastBanner: View {
  @Environment(ThemeManager.self) private var theme
  let banner: SyncFeedback.Banner

  var body: some View {
    let c = theme.colors
    Button {
      if banner.retry != nil {
        SyncFeedback.shared.invokeRetry()
      } else {
        SyncFeedback.shared.dismiss()
      }
    } label: {
      HStack(spacing: 10) {
        Text(banner.message)
          .font(AppTypography.meta)
          .foregroundStyle(c.textPrimary)
          .multilineTextAlignment(.leading)
        Spacer(minLength: 0)
        if banner.retry != nil {
          Text("Tentar")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(c.accent)
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(c.surface)
          .shadow(color: .black.opacity(0.28), radius: 12, y: 4)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .stroke(c.textTertiary.opacity(0.18), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
    .padding(.horizontal, 16)
    .padding(.bottom, 12)
    .transition(.move(edge: .bottom).combined(with: .opacity))
  }
}

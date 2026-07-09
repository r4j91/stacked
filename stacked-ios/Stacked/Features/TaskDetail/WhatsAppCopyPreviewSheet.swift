import SwiftUI
import UIKit

struct WhatsAppCopyPreviewSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  let taskTitle: String
  let message: String

  @State private var copied = false

  var body: some View {
    let c = theme.colors

    NavigationStack {
      ScrollView {
        Text(message)
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textPrimary)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(16)
          .background(c.surfaceVariant)
          .clipShape(RoundedRectangle(cornerRadius: 14))
          .overlay(RoundedRectangle(cornerRadius: 14).stroke(c.textPrimary.opacity(0.06)))
          .padding(.horizontal, 16)
          .padding(.top, 8)
      }
      .background(c.background.ignoresSafeArea())
      .navigationTitle(sheetTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Fechar") { dismiss() }
            .foregroundStyle(c.textSecondary)
        }
      }
      .safeAreaInset(edge: .bottom) {
        PrimaryButton(title: copied ? "Copiado!" : "Copiar mensagem") {
          copyMessage()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
      }
    }
  }

  private var sheetTitle: String {
    let trimmed = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.count <= 18 { return "Mensagem · \(trimmed)" }
    return "Mensagem · \(String(trimmed.prefix(18)))…"
  }

  private func copyMessage() {
    UIPasteboard.general.string = message
    HapticService.saved()
    copied = true
  }
}

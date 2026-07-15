import SwiftUI

/// CTA primário — actionAccent + onActionAccent (Fase B / TEMAS_JADE).
struct PrimaryButton: View {
  let title: String
  let action: () -> Void

  var colors: AppThemeColors?
  var isLoading: Bool = false
  var isEnabled: Bool = true
  var height: CGFloat = 50
  var cornerRadius: CGFloat = 12
  var font: Font = .system(size: 15, weight: .bold)

  @Environment(ThemeManager.self) private var theme

  private var palette: AppThemeColors {
    colors ?? theme.colors
  }

  private var active: Bool {
    isEnabled && !isLoading
  }

  var body: some View {
    Button(action: action) {
      Group {
        if isLoading {
          // SUBSTITUIDO_TEMAS_JADE: .tint(palette.onAccent)
          ProgressView()
            .tint(palette.onActionAccent)
        } else {
          Text(title)
            .font(font)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: height)
    }
    .buttonStyle(.plain)
    // SUBSTITUIDO_TEMAS_JADE: background(active ? palette.accent : ...) / foregroundStyle(... palette.onAccent ...)
    .background(active ? palette.actionAccent : palette.surfaceVariant)
    .foregroundStyle(active ? palette.onActionAccent : palette.textSecondary.opacity(0.5))
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    .disabled(!active)
  }
}

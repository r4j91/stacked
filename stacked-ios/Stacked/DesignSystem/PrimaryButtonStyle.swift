import SwiftUI

/// CTA primário — accent + onAccent semânticos (Fase B).
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
          ProgressView()
            .tint(palette.onAccent)
        } else {
          Text(title)
            .font(font)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: height)
    }
    .buttonStyle(.plain)
    .background(active ? palette.accent : palette.surfaceVariant)
    .foregroundStyle(active ? palette.onAccent : palette.textSecondary.opacity(0.5))
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    .disabled(!active)
  }
}

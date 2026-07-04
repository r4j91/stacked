import SwiftUI

/// Switch customizado — Button puro (Toggle dentro de List costuma engolir toques).
struct StackedSwitchControl: View {
  @Binding var isOn: Bool
  var onTrack: Color
  var offTrack: Color

  private let width: CGFloat = 51
  private let height: CGFloat = 31

  var body: some View {
    Button {
      isOn.toggle()
      HapticService.selection()
    } label: {
      ZStack(alignment: isOn ? .trailing : .leading) {
        Capsule()
          .fill(isOn ? onTrack : offTrack)
          .frame(width: width, height: height)

        Circle()
          .fill(Color.white)
          .shadow(color: Color.black.opacity(0.2), radius: 1.5, x: 0, y: 1)
          .frame(width: height - 4, height: height - 4)
          .padding(2)
      }
      .frame(width: width, height: height)
      .animation(.snappy(duration: 0.2), value: isOn)
    }
    .buttonStyle(.plain)
    .frame(minWidth: 44, minHeight: 44)
    .contentShape(Rectangle())
    .accessibilityAddTraits(.isButton)
    .accessibilityValue(isOn ? Text("Ativado") : Text("Desativado"))
  }
}

extension StackedSwitchControl {
  init(isOn: Binding<Bool>, colors: AppThemeColors) {
    self._isOn = isOn
    self.onTrack = Self.resolvedOnTrack(for: colors)
    self.offTrack = colors.isDark
      ? colors.textTertiary.opacity(0.55)
      : colors.textTertiary.opacity(0.35)
  }

  private static func resolvedOnTrack(for colors: AppThemeColors) -> Color {
    if colors.isDark {
      return Color(hex: 0x5FD3DC)
    }
    return colors.accent
  }
}

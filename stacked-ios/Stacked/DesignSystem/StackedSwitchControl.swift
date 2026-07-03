import SwiftUI
import UIKit

/// Switch com cores da paleta — trilho escuro no OFF (evita cinza claro do UISwitch padrão).
struct StackedSwitchControl: UIViewRepresentable {
  @Binding var isOn: Bool
  var accent: Color
  var offTrack: Color

  func makeCoordinator() -> Coordinator {
    Coordinator(isOn: $isOn)
  }

  func makeUIView(context: Context) -> UISwitch {
    let control = UISwitch(frame: .zero)
    control.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
    applyColors(to: control)
    control.isOn = isOn
    return control
  }

  func updateUIView(_ control: UISwitch, context: Context) {
    applyColors(to: control)
    if control.isOn != isOn {
      control.setOn(isOn, animated: true)
    }
  }

  private func applyColors(to control: UISwitch) {
    control.onTintColor = UIColor(accent)
    control.tintColor = UIColor(offTrack)
    control.backgroundColor = UIColor(offTrack)
    let radius = max(control.bounds.height, 31) / 2
    control.layer.cornerRadius = radius
    control.clipsToBounds = true
    control.thumbTintColor = .white
  }

  final class Coordinator: NSObject {
    var isOn: Binding<Bool>

    init(isOn: Binding<Bool>) {
      self.isOn = isOn
    }

    @objc func valueChanged(_ sender: UISwitch) {
      isOn.wrappedValue = sender.isOn
      _Concurrency.Task { @MainActor in HapticService.selection() }
    }
  }
}

extension StackedSwitchControl {
  init(isOn: Binding<Bool>, colors: AppThemeColors) {
    self._isOn = isOn
    self.accent = colors.accent
    self.offTrack = colors.textTertiary.opacity(0.38)
  }
}

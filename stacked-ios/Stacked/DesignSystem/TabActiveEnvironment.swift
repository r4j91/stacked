import SwiftUI

private struct TabActiveKey: EnvironmentKey {
  static let defaultValue = true
}

extension EnvironmentValues {
  var isTabActive: Bool {
    get { self[TabActiveKey.self] }
    set { self[TabActiveKey.self] = newValue }
  }
}

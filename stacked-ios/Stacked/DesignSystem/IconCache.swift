import SwiftUI

// Pré-aquece e cacheia Images do Hugeicons para evitar decode de PDF a cada troca de aba.
// CRIADO_ICONCACHE
@MainActor
final class IconCache {
  static let shared = IconCache()

  private var cache: [StackedIconKey: Image] = [:]

  private init() {}

  func warmUp() {
    let navKeys: [StackedIconKey] = [.navHome, .navInbox, .navToday, .navUpcoming, .navFilters]
    for key in navKeys {
      if cache[key] == nil {
        cache[key] = StackedIcons.image(key)
      }
    }
  }

  func image(for key: StackedIconKey) -> Image {
    if let cached = cache[key] { return cached }
    let img = StackedIcons.image(key)
    cache[key] = img
    return img
  }
}

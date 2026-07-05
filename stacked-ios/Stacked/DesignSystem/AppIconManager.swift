import SwiftUI
import UIKit

// Paridade lib/services/app_icon_service.dart — variantes em assets/stacked-icones-variantes/
enum AppIconId: String, CaseIterable, Identifiable {
  case `default`
  case carvao
  case grafite
  case fosco
  case titanio
  case cinzaEscuro = "cinza_escuro"
  case cinzaMedio = "cinza_medio"
  case azulNevoa = "azul_nevoa"
  case azulOceano = "azul_oceano"

  var id: String { rawValue }

  /// Nome passado a `setAlternateIconName`; nil = ícone primário (AppIcon).
  var alternateIconName: String? {
    switch self {
    case .default: nil
    default: rawValue
    }
  }

  var displayName: String {
    switch self {
    case .default: "Padrão"
    case .carvao: "Carvão"
    case .grafite: "Grafite"
    case .fosco: "Fosco"
    case .titanio: "Titânio"
    case .cinzaEscuro: "Cinza Escuro"
    case .cinzaMedio: "Cinza Médio"
    case .azulNevoa: "Azul Névoa"
    case .azulOceano: "Azul Oceano"
    }
  }

  var subtitle: String {
    switch self {
    case .default: "Ícone atual"
    default: "Variante \(displayName)"
    }
  }

  /// Asset catalog para preview na tela de Aparência.
  var previewAssetName: String {
    switch self {
    case .default: "IconPreview-default"
    default: "IconPreview-\(rawValue)"
    }
  }

  static func from(alternateIconName name: String?) -> AppIconId {
    guard let name, let match = AppIconId(rawValue: name) else { return .default }
    return match
  }
}

@Observable
@MainActor
final class AppIconManager {
  static let shared = AppIconManager()

  private static let storageKey = "stacked_app_icon_id"

  private(set) var currentId: AppIconId = .default
  private(set) var isChanging = false

  var isSupported: Bool {
    UIApplication.shared.supportsAlternateIcons
  }

  private init() {
    syncFromSystem()
  }

  func syncFromSystem() {
    currentId = AppIconId.from(alternateIconName: UIApplication.shared.alternateIconName)
    UserDefaults.standard.set(currentId.rawValue, forKey: Self.storageKey)
  }

  func setIcon(_ id: AppIconId) async throws {
    guard isSupported else { return }
    guard id != currentId else { return }

    isChanging = true
    defer { isChanging = false }

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      UIApplication.shared.setAlternateIconName(id.alternateIconName) { error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume()
        }
      }
    }

    currentId = id
    UserDefaults.standard.set(id.rawValue, forKey: Self.storageKey)
  }
}

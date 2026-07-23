import SwiftUI
import UIKit

/// Variantes em `Assets.xcassets/AppIcon*.appiconset` (fonte: stacked-icons).
///
/// Com `INCLUDE_ALL_APPICON_ASSETS`, o build registra cada set como
/// `CFBundleAlternateIcons["AppIcon-<id>"]` com `CFBundleIconName`.
/// Por isso `setAlternateIconName` deve receber `AppIcon-<id>` — não só `<id>`.
///
/// Primário (`nil`) = titânio/azul (perfil atual). Amazonite = variante teal.
enum AppIconId: String, CaseIterable, Identifiable {
  case `default`
  case amazonite
  case cinzaPreto = "cinza_preto"
  case azulAmarelo = "azul_amarelo"
  case cinzaLaranja = "cinza_laranja"

  var id: String { rawValue }

  /// Nome passado a `setAlternateIconName`; nil = ícone primário (`AppIcon`).
  var alternateIconName: String? {
    switch self {
    case .default: nil
    default: "AppIcon-\(rawValue)"
    }
  }

  var displayName: String {
    switch self {
    case .default: "Padrão"
    case .amazonite: "Amazonite"
    case .cinzaPreto: "Cinza / preto"
    case .azulAmarelo: "Azul / amarelo"
    case .cinzaLaranja: "Cinza / laranja"
    }
  }

  var subtitle: String {
    switch self {
    case .default: "Titânio / azul"
    case .amazonite: "Teal original"
    case .cinzaPreto: "Monocromático"
    case .azulAmarelo: "Navy e âmbar"
    case .cinzaLaranja: "Carvão e terracota"
    }
  }

  /// Asset catalog para preview na tela de Aparência (mesmos pixels do ícone).
  var previewAssetName: String {
    switch self {
    case .default: "IconPreview-default"
    default: "IconPreview-\(rawValue)"
    }
  }

  static func from(alternateIconName name: String?) -> AppIconId {
    guard let name, !name.isEmpty else { return .default }
    // Preferência antiga (antes do primário virar titânio).
    if name == "AppIcon-titanium_azul" || name == "titanium_azul" {
      return .default
    }
    if let match = AppIconId(rawValue: name) { return match }
    let prefix = "AppIcon-"
    if name.hasPrefix(prefix),
       let match = AppIconId(rawValue: String(name.dropFirst(prefix.count))) {
      return match
    }
    return .default
  }
}

enum AppIconError: LocalizedError {
  case notSupported
  case system(Error)

  var errorDescription: String? {
    switch self {
    case .notSupported:
      "Troca de ícone não está disponível neste dispositivo ou instalação."
    case .system(let error):
      error.localizedDescription
    }
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
    guard isSupported else { throw AppIconError.notSupported }
    guard id != currentId else { return }

    isChanging = true
    defer { isChanging = false }

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      UIApplication.shared.setAlternateIconName(id.alternateIconName) { error in
        if let error {
          continuation.resume(throwing: AppIconError.system(error))
        } else {
          continuation.resume()
        }
      }
    }

    currentId = id
    UserDefaults.standard.set(id.rawValue, forKey: Self.storageKey)
  }
}

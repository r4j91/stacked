import SwiftUI
import UIKit

/// Variantes em `Assets.xcassets/AppIcon*.appiconset` (fonte: `assets/icon/abismo_solidos_v1/ia_refinada`).
///
/// Com `INCLUDE_ALL_APPICON_ASSETS`, o build registra cada set como
/// `CFBundleAlternateIcons["AppIcon-<id>"]` com `CFBundleIconName`.
/// Por isso `setAlternateIconName` deve receber `AppIcon-<id>` — não só `<id>`.
///
/// Primário (`nil`) = `01_refinado_liso_teal`.
enum AppIconId: String, CaseIterable, Identifiable {
  case `default`
  case abismoCinzaSolidoAmbar = "abismo_cinza_solido_ambar"
  case abismoCinzaMint = "abismo_cinza_mint"
  case abismoCinzaTeal = "abismo_cinza_teal"
  case abismoCinzaLima = "abismo_cinza_lima"
  case abismoCinzaPetrol = "abismo_cinza_petrol"
  case abismoCinzaSuaveAmbar = "abismo_cinza_suave_ambar"
  case dualCinzaAmbar = "dual_cinza_ambar"
  case dualCinzaMint = "dual_cinza_mint"
  case dualCinzaTeal = "dual_cinza_teal"
  case dualCinzaLima = "dual_cinza_lima"
  case abismoPetrolMint = "abismo_petrol_mint"

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
    case .abismoCinzaSolidoAmbar: "Abismo Âmbar"
    case .abismoCinzaMint: "Abismo Mint"
    case .abismoCinzaTeal: "Abismo Teal"
    case .abismoCinzaLima: "Abismo Lima"
    case .abismoCinzaPetrol: "Abismo Petróleo"
    case .abismoCinzaSuaveAmbar: "Abismo Suave"
    case .dualCinzaAmbar: "Cinza + Âmbar"
    case .dualCinzaMint: "Cinza + Mint"
    case .dualCinzaTeal: "Cinza + Teal"
    case .dualCinzaLima: "Cinza + Lima"
    case .abismoPetrolMint: "Abismo"
    }
  }

  var subtitle: String {
    switch self {
    case .default: "Teal refinado"
    case .abismoCinzaSolidoAmbar: "Cinza sólido · âmbar"
    case .abismoCinzaMint: "Cinza sólido · mint"
    case .abismoCinzaTeal: "Cinza sólido · teal"
    case .abismoCinzaLima: "Cinza sólido · lima"
    case .abismoCinzaPetrol: "Cinza sólido · petróleo"
    case .abismoCinzaSuaveAmbar: "Cinza suave · âmbar"
    case .dualCinzaAmbar: "Dual cinza e âmbar"
    case .dualCinzaMint: "Dual cinza e mint"
    case .dualCinzaTeal: "Dual cinza e teal"
    case .dualCinzaLima: "Dual cinza e lima"
    case .abismoPetrolMint: "Petróleo · mint"
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
    // Preferências antigas (titânio / amazonite / packs anteriores) → padrão novo.
    let legacy: Set<String> = [
      "AppIcon-titanium_azul", "titanium_azul",
      "AppIcon-amazonite", "amazonite",
      "AppIcon-cinza_preto", "cinza_preto",
      "AppIcon-azul_amarelo", "azul_amarelo",
      "AppIcon-cinza_laranja", "cinza_laranja",
    ]
    if legacy.contains(name) { return .default }

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
  /// Primeiro install / clean build — Abismo Lima (setup atual de desenvolvimento).
  private static let preferredDefault: AppIconId = .abismoCinzaLima

  private(set) var currentId: AppIconId = .abismoCinzaLima
  private(set) var isChanging = false

  var isSupported: Bool {
    UIApplication.shared.supportsAlternateIcons
  }

  private init() {
    let hadStoredPreference = UserDefaults.standard.object(forKey: Self.storageKey) != nil
    syncFromSystem()
    // Clean install: sistema volta pro ícone primário; aplica o padrão do produto.
    if !hadStoredPreference, currentId == .default, Self.preferredDefault != .default {
      Swift.Task { try? await setIcon(Self.preferredDefault) }
    }
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

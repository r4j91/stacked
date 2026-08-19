import SwiftUI
import UIKit

/// Variantes em `Assets.xcassets/AppIcon*.appiconset`
/// (check/chevron: `assets/icon/abismo_solidos_v1/premium_v2`;
///  S puro: `assets/icon/s_puro_variantes_v1`;
///  Fita S: `assets/icon/ribbon-s/architectural_v2`;
///  Entrelaçado: `assets/icon/glass_bases_v1`).
///
/// Com `INCLUDE_ALL_APPICON_ASSETS`, o build registra cada set como
/// `CFBundleAlternateIcons["AppIcon-<id>"]` com `CFBundleIconName`.
/// Por isso `setAlternateIconName` deve receber `AppIcon-<id>` — não só `<id>`.
///
/// Primário (`nil`) = `01_refinado_liso_teal` (check/chevron).
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
  // S puro (exploração — não é padrão)
  case sPuroTeal = "s_puro_teal"
  case sPuroAmbar = "s_puro_ambar"
  case sPuroMint = "s_puro_mint"
  case sPuroTealProfundo = "s_puro_teal_profundo"
  case sPuroLima = "s_puro_lima"
  case sPuroAmbarSuave = "s_puro_ambar_suave"
  case sPuroDualCinzaAmbar = "s_puro_dual_cinza_ambar"
  case sPuroDualCinzaMint = "s_puro_dual_cinza_mint"
  case sPuroDualCinzaTeal = "s_puro_dual_cinza_teal"
  case sPuroDualCinzaLima = "s_puro_dual_cinza_lima"
  case sPuroPetrolMint = "s_puro_petrol_mint"
  case sPuroPetrol = "s_puro_petrol"
  // Fita S (glass_bases_v1)
  case fitaSTeal = "fita_s_teal"
  case fitaSAmbar = "fita_s_ambar"
  case fitaSMint = "fita_s_mint"
  case fitaSTealProfundo = "fita_s_teal_profundo"
  case fitaSLima = "fita_s_lima"
  case fitaSPetrol = "fita_s_petrol"
  case fitaSDualCinzaAmbar = "fita_s_dual_cinza_ambar"
  case fitaSDualCinzaMint = "fita_s_dual_cinza_mint"
  case fitaSDualCinzaTeal = "fita_s_dual_cinza_teal"
  case fitaSDualCinzaLima = "fita_s_dual_cinza_lima"
  // Entrelaçado (glass_bases_v1)
  case entrelacadoTeal = "entrelacado_teal"
  case entrelacadoAmbar = "entrelacado_ambar"
  case entrelacadoMint = "entrelacado_mint"
  case entrelacadoTealProfundo = "entrelacado_teal_profundo"
  case entrelacadoLima = "entrelacado_lima"
  case entrelacadoPetrol = "entrelacado_petrol"
  case entrelacadoDualCinzaAmbar = "entrelacado_dual_cinza_ambar"
  case entrelacadoDualCinzaMint = "entrelacado_dual_cinza_mint"
  case entrelacadoDualCinzaTeal = "entrelacado_dual_cinza_teal"
  case entrelacadoDualCinzaLima = "entrelacado_dual_cinza_lima"

  var id: String { rawValue }

  /// Família check/chevron atual (sem S puro / fita / entrelaçado).
  static var classic: [AppIconId] {
    allCases.filter { !$0.isSPuro && !$0.isFitaS && !$0.isEntrelacado }
  }

  static var sPuro: [AppIconId] {
    allCases.filter(\.isSPuro)
  }

  static var fitaS: [AppIconId] {
    allCases.filter(\.isFitaS)
  }

  static var entrelacado: [AppIconId] {
    allCases.filter(\.isEntrelacado)
  }

  var isSPuro: Bool {
    rawValue.hasPrefix("s_puro_")
  }

  var isFitaS: Bool {
    rawValue.hasPrefix("fita_s_")
  }

  var isEntrelacado: Bool {
    rawValue.hasPrefix("entrelacado_")
  }

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
    case .sPuroTeal: "S Teal"
    case .sPuroAmbar: "S Âmbar"
    case .sPuroMint: "S Mint"
    case .sPuroTealProfundo: "S Teal Profundo"
    case .sPuroLima: "S Lima"
    case .sPuroAmbarSuave: "S Âmbar Suave"
    case .sPuroDualCinzaAmbar: "S Cinza + Âmbar"
    case .sPuroDualCinzaMint: "S Cinza + Mint"
    case .sPuroDualCinzaTeal: "S Cinza + Teal"
    case .sPuroDualCinzaLima: "S Cinza + Lima"
    case .sPuroPetrolMint: "S Abismo"
    case .sPuroPetrol: "S Petróleo"
    case .fitaSTeal: "Fita Teal"
    case .fitaSAmbar: "Fita Âmbar"
    case .fitaSMint: "Fita Mint"
    case .fitaSTealProfundo: "Fita Teal Profundo"
    case .fitaSLima: "Fita Lima"
    case .fitaSPetrol: "Fita Petróleo"
    case .fitaSDualCinzaAmbar: "Fita Cinza + Âmbar"
    case .fitaSDualCinzaMint: "Fita Cinza + Mint"
    case .fitaSDualCinzaTeal: "Fita Cinza + Teal"
    case .fitaSDualCinzaLima: "Fita Cinza + Lima"
    case .entrelacadoTeal: "Entrelaçado Teal"
    case .entrelacadoAmbar: "Entrelaçado Âmbar"
    case .entrelacadoMint: "Entrelaçado Mint"
    case .entrelacadoTealProfundo: "Entrelaçado Teal Profundo"
    case .entrelacadoLima: "Entrelaçado Lima"
    case .entrelacadoPetrol: "Entrelaçado Petróleo"
    case .entrelacadoDualCinzaAmbar: "Entrelaçado Cinza + Âmbar"
    case .entrelacadoDualCinzaMint: "Entrelaçado Cinza + Mint"
    case .entrelacadoDualCinzaTeal: "Entrelaçado Cinza + Teal"
    case .entrelacadoDualCinzaLima: "Entrelaçado Cinza + Lima"
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
    case .sPuroTeal: "S puro · teal"
    case .sPuroAmbar: "S puro · âmbar"
    case .sPuroMint: "S puro · mint"
    case .sPuroTealProfundo: "S puro · teal profundo"
    case .sPuroLima: "S puro · lima"
    case .sPuroAmbarSuave: "S puro · âmbar suave"
    case .sPuroDualCinzaAmbar: "S puro · dual cinza e âmbar"
    case .sPuroDualCinzaMint: "S puro · dual cinza e mint"
    case .sPuroDualCinzaTeal: "S puro · dual cinza e teal"
    case .sPuroDualCinzaLima: "S puro · dual cinza e lima"
    case .sPuroPetrolMint: "S puro · petróleo · mint"
    case .sPuroPetrol: "S puro · petróleo"
    case .fitaSTeal: "Fita S · teal"
    case .fitaSAmbar: "Fita S · âmbar"
    case .fitaSMint: "Fita S · mint"
    case .fitaSTealProfundo: "Fita S · teal profundo"
    case .fitaSLima: "Fita S · lima"
    case .fitaSPetrol: "Fita S · petróleo"
    case .fitaSDualCinzaAmbar: "Fita S · dual cinza e âmbar"
    case .fitaSDualCinzaMint: "Fita S · dual cinza e mint"
    case .fitaSDualCinzaTeal: "Fita S · dual cinza e teal"
    case .fitaSDualCinzaLima: "Fita S · dual cinza e lima"
    case .entrelacadoTeal: "Entrelaçado · teal"
    case .entrelacadoAmbar: "Entrelaçado · âmbar"
    case .entrelacadoMint: "Entrelaçado · mint"
    case .entrelacadoTealProfundo: "Entrelaçado · teal profundo"
    case .entrelacadoLima: "Entrelaçado · lima"
    case .entrelacadoPetrol: "Entrelaçado · petróleo"
    case .entrelacadoDualCinzaAmbar: "Entrelaçado · dual cinza e âmbar"
    case .entrelacadoDualCinzaMint: "Entrelaçado · dual cinza e mint"
    case .entrelacadoDualCinzaTeal: "Entrelaçado · dual cinza e teal"
    case .entrelacadoDualCinzaLima: "Entrelaçado · dual cinza e lima"
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

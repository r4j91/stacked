import Foundation

/// NET_FASEC_ETAPA4 — taxonomia honesta de erro de sync (Quick Add + Detail).
enum SyncError: Error, Equatable, Sendable {
  case semConexao
  /// Timeout mas escrita confirmada via select — UI trata como sucesso silencioso.
  case timeoutVerificado
  case falhaServidor(String?)
  case falhaAuth
  case decode

  var userMessage: String? {
    switch self {
    case .semConexao:
      return "Sem internet — vou sincronizar quando voltar"
    case .timeoutVerificado:
      return nil
    case .falhaServidor:
      return "Não foi possível sincronizar — tocar para tentar de novo"
    case .falhaAuth:
      return nil
    case .decode:
      return "Não foi possível sincronizar — tocar para tentar de novo"
    }
  }

  var shouldShowToast: Bool {
    switch self {
    case .timeoutVerificado, .falhaAuth: return false
    case .semConexao, .falhaServidor, .decode: return true
    }
  }

  static func from(_ error: Error, verifiedOnTimeout: Bool = false) -> SyncError {
    let kind = NetLog.classify(error)
    switch kind {
    case .timeout:
      return verifiedOnTimeout ? .timeoutVerificado : .falhaServidor(error.localizedDescription)
    case .noNetwork:
      return .semConexao
    case .auth:
      return .falhaAuth
    case .decode:
      return .decode
    case .server, .unknown, .cancelled, .success:
      return .falhaServidor(error.localizedDescription)
    }
  }
}

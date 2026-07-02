import Foundation
import Supabase

// Paridade lib/services/auth_service.dart
@MainActor
@Observable
final class AuthManager {
  static let shared = AuthManager()

  private(set) var session: Session?
  private(set) var isLoading = true
  private(set) var lastError: String?

  private var listenTask: _Concurrency.Task<Void, Never>?

  private init() {
    session = SupabaseService.client.auth.currentSession
    isLoading = false
    listenTask = _Concurrency.Task { await listenAuthChanges() }
  }

  private func listenAuthChanges() async {
    for await (_, session) in SupabaseService.client.auth.authStateChanges {
      self.session = session
      isLoading = false
    }
  }

  var isAuthenticated: Bool {
    session != nil && SupabaseService.client.auth.currentUser != nil
  }

  func signIn(email: String, password: String) async throws {
    lastError = nil
    try await SupabaseService.client.auth.signIn(email: email, password: password)
  }

  func signUp(email: String, password: String) async throws {
    lastError = nil
    try await SupabaseService.client.auth.signUp(email: email, password: password)
  }

  func signOut() async {
    try? await SupabaseService.client.auth.signOut()
    WidgetSnapshotSync.clear()
  }

  static func friendlyError(_ error: Error) -> String {
    let raw = error.localizedDescription
    if raw.contains("Invalid login credentials") { return "E-mail ou senha incorretos." }
    if raw.contains("Email not confirmed") { return "Confirme seu e-mail antes de entrar." }
    if raw.contains("User already registered") { return "Este e-mail já está cadastrado." }
    if raw.contains("Password should be") { return "A senha deve ter pelo menos 6 caracteres." }
    return "Algo deu errado. Tente novamente."
  }
}

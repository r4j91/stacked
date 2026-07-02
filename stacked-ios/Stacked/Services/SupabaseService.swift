import Foundation
import Supabase

@MainActor
enum SupabaseService {
  static let client: SupabaseClient = {
    SupabaseClient(
      supabaseURL: SupabaseConfig.url,
      supabaseKey: SupabaseConfig.anonKey,
      options: .init(auth: .init(flowType: .pkce, autoRefreshToken: true))
    )
  }()
}

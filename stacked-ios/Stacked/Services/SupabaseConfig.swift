import Foundation

enum SupabaseConfig {
  static var url: URL {
    guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
          let url = URL(string: raw), !raw.isEmpty
    else {
      fatalError("SUPABASE_URL missing — configure Config/Secrets.xcconfig")
    }
    return url
  }

  static var anonKey: String {
    guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
          !key.isEmpty, key != "your-anon-key-here"
    else {
      fatalError("SUPABASE_ANON_KEY missing — configure Config/Secrets.xcconfig")
    }
    return key
  }

  static var isConfigured: Bool {
    guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
          let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
    else { return false }
    return !url.isEmpty && !key.isEmpty && key != "your-anon-key-here"
  }
}

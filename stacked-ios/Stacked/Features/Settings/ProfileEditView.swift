import SwiftUI
import Supabase

// Paridade lib/screens/profile_screen.dart (nome/apelido)
struct ProfileEditView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  @State private var nome = ""
  @State private var apelido = ""
  @State private var loading = true
  @State private var saving = false
  @State private var showError = false
  @State private var errorMessage = ""

  private var client: SupabaseClient { SupabaseService.client }

  var body: some View {
    let c = theme.colors
    let email = client.auth.currentUser?.email ?? ""

    Group {
        if loading {
          ProgressView().tint(c.accent)
        } else {
          List {
            Section {
              profileAvatar(email: email)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Informações") {
              profileField(label: "Nome completo", text: $nome, placeholder: "Seu nome")
              profileField(label: "Apelido", text: $apelido, placeholder: "Como quer ser chamado")
              HStack {
                Text("E-mail")
                  .font(AppTypography.fieldLabel)
                  .foregroundStyle(c.textSecondary)
                  .frame(width: 110, alignment: .leading)
                Text(email)
                  .font(AppTypography.fieldInput)
                  .foregroundStyle(c.textTertiary)
                  .lineLimit(1)
              }
              .padding(.vertical, 6)
            }
            .listRowBackground(c.surface)
          }
          .listStyle(.insetGrouped)
          .scrollContentBackground(.hidden)
        }
      }
      .background(c.background)
      .navigationTitle("Perfil")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Salvar") {
            _Concurrency.Task { await save() }
          }
          .disabled(saving || loading)
          .foregroundStyle(c.accent)
        }
      }
      .task { await load() }
      .alert("Erro", isPresented: $showError) {
        Button("OK") {}
      } message: {
        Text(errorMessage)
      }
  }

  private func profileAvatar(email: String) -> some View {
    let c = theme.colors
    let display = displayName
    let initials = String(display.prefix(2)).uppercased()

    return HStack {
      Spacer()
      ZStack {
        Circle()
          .fill(c.accent.opacity(0.15))
          .frame(width: 88, height: 88)
        Text(initials.isEmpty ? "?" : initials)
          .font(.system(size: 30, weight: .bold))
          .foregroundStyle(c.accent)
      }
      Spacer()
    }
    .padding(.vertical, 24)
  }

  private var displayName: String {
    let a = apelido.trimmingCharacters(in: .whitespacesAndNewlines)
    if !a.isEmpty { return a }
    let n = nome.trimmingCharacters(in: .whitespacesAndNewlines)
    if !n.isEmpty { return n.split(separator: " ").first.map(String.init) ?? n }
    return client.auth.currentUser?.email?.split(separator: "@").first.map(String.init) ?? ""
  }

  private func profileField(label: String, text: Binding<String>, placeholder: String) -> some View {
    let c = theme.colors
    return HStack {
      Text(label)
        .font(AppTypography.fieldLabel)
        .foregroundStyle(c.textSecondary)
        .frame(width: 110, alignment: .leading)
      TextField(placeholder, text: text)
        .font(AppTypography.fieldInput)
        .foregroundStyle(c.textPrimary)
    }
    .padding(.vertical, 4)
  }

  private func load() async {
    loading = true
    defer { loading = false }
    let meta = client.auth.currentUser?.userMetadata ?? [:]
    nome = metadataString(meta["nome"])
    apelido = metadataString(meta["apelido"])
  }

  private func save() async {
    saving = true
    defer { saving = false }
    do {
      try await client.auth.update(
        user: UserAttributes(
          data: [
            "nome": .string(nome.trimmingCharacters(in: .whitespacesAndNewlines)),
            "apelido": .string(apelido.trimmingCharacters(in: .whitespacesAndNewlines)),
          ]
        )
      )
      HapticService.saved()
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
      showError = true
    }
  }

  private func metadataString(_ value: AnyJSON?) -> String {
    guard let value else { return "" }
    if let s = value.stringValue { return s.trimmingCharacters(in: .whitespacesAndNewlines) }
    return String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

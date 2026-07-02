import SwiftUI

// Paridade lib/widgets/settings/settings_sheet.dart
struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme
  @State private var auth = AuthManager.shared

  var body: some View {
    let c = theme.colors

    NavigationStack {
      List {
        Section {
          NavigationLink {
            ProfileEditView().environment(theme)
          } label: {
            profileCard
          }
          .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
          .listRowBackground(Color.clear)
        }

        Section("Preferências") {
          NavigationLink {
            NotificationsSettingsView().environment(theme)
          } label: {
            settingsRow(icon: .notifications, label: "Notificações", subtitle: "Lembretes e resumo")
          }
          NavigationLink {
            AppearanceView().environment(theme)
          } label: {
            settingsRow(icon: .paintbrush, label: "Aparência", subtitle: theme.currentId.displayName)
          }
        }

        Section("Organização") {
          NavigationLink {
            LabelsManagementView().environment(theme)
          } label: {
            settingsRow(icon: .tag, label: "Gerenciar Etiquetas", subtitle: "Criar e editar")
          }
          NavigationLink {
            LogbookView().environment(theme)
          } label: {
            settingsRow(icon: .logbook, label: "Registro", subtitle: "Tarefas concluídas")
          }
        }

        Section {
          Button(role: .destructive) {
            _Concurrency.Task {
              await auth.signOut()
              dismiss()
            }
          } label: {
            HStack {
              StackedIcons.image(.logout)
              Text("Sair da conta")
            }
          }
        }
      }
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)
      .background(c.background)
      .navigationTitle("Configurações")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Fechar") { dismiss() }.foregroundStyle(c.accent)
        }
      }
    }
  }

  private var profileCard: some View {
    let c = theme.colors
    let name = HomeStore.shared.firstName
    let email = auth.session?.user.email ?? ""

    return HStack(spacing: 14) {
      ZStack {
        Circle().fill(c.surfaceVariant).frame(width: 52, height: 52)
        Text(name.prefix(1).uppercased())
          .font(.system(size: 20, weight: .bold)).foregroundStyle(c.accent)
      }
      VStack(alignment: .leading, spacing: 4) {
        Text(name.isEmpty ? "Conta" : name)
          .font(.system(size: 17, weight: .semibold)).foregroundStyle(c.textPrimary)
        if !email.isEmpty {
          Text(email).font(AppTypography.taskPreview).foregroundStyle(c.textSecondary)
        }
      }
      Spacer()
    }
    .padding(14)
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(c.textPrimary.opacity(0.06)))
    .padding(.horizontal, 4)
  }

  private func settingsRow(icon: StackedIconKey, label: String, subtitle: String) -> some View {
    let c = theme.colors
    return HStack(spacing: 12) {
      StackedIcons.image(icon).font(.system(size: 16)).foregroundStyle(c.textSecondary).frame(width: 24)
      VStack(alignment: .leading, spacing: 2) {
        Text(label).foregroundStyle(c.textPrimary)
        Text(subtitle).font(.caption).foregroundStyle(c.textTertiary)
      }
      Spacer()
    }
  }
}

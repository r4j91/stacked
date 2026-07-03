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
          .buttonStyle(.plain)
          .settingsListCardRow(top: 8, bottom: 4)
        }

        Section {
          SettingsCardSurface {
            VStack(spacing: 0) {
              NavigationLink {
                NotificationsSettingsView().environment(theme)
              } label: {
                settingsRow(icon: .notifications, label: "Notificações", subtitle: "Lembretes e resumo")
                  .padding(.horizontal, SettingsChrome.rowPaddingH)
                  .padding(.vertical, SettingsChrome.rowPaddingV)
              }
              .buttonStyle(.plain)

              SettingsCardDivider(leadingPadding: 52)

              NavigationLink {
                AppearanceView().environment(theme)
              } label: {
                settingsRow(icon: .paintbrush, label: "Aparência", subtitle: theme.currentId.displayName)
                  .padding(.horizontal, SettingsChrome.rowPaddingH)
                  .padding(.vertical, SettingsChrome.rowPaddingV)
              }
              .buttonStyle(.plain)
            }
          }
          .settingsListCardRow()
        } header: {
          SettingsSectionHeader(text: "Preferências")
        }

        Section {
          SettingsCardSurface {
            VStack(spacing: 0) {
              NavigationLink {
                LabelsManagementView().environment(theme)
              } label: {
                settingsRow(icon: .tag, label: "Gerenciar Etiquetas", subtitle: "Criar e editar")
                  .padding(.horizontal, SettingsChrome.rowPaddingH)
                  .padding(.vertical, SettingsChrome.rowPaddingV)
              }
              .buttonStyle(.plain)

              SettingsCardDivider(leadingPadding: 52)

              NavigationLink {
                LogbookView().environment(theme)
              } label: {
                settingsRow(icon: .logbook, label: "Registro", subtitle: "Tarefas concluídas")
                  .padding(.horizontal, SettingsChrome.rowPaddingH)
                  .padding(.vertical, SettingsChrome.rowPaddingV)
              }
              .buttonStyle(.plain)
            }
          }
          .settingsListCardRow()
        } header: {
          SettingsSectionHeader(text: "Organização")
        }

        Section {
          SettingsCardSurface {
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
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, SettingsChrome.rowPaddingH)
              .padding(.vertical, SettingsChrome.rowPaddingV)
            }
            .buttonStyle(.plain)
          }
          .settingsListCardRow(top: 4, bottom: 8)
        }
      }
      .settingsDrillDownList(background: c.background)
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
      UserAvatarView(
        url: HomeStore.shared.avatarURL,
        initials: HomeStore.shared.avatarInitials,
        size: 52
      )
      VStack(alignment: .leading, spacing: 4) {
        Text(name.isEmpty ? "Conta" : name)
          .font(AppTypography.profileName).foregroundStyle(c.textPrimary)
        if !email.isEmpty {
          Text(email).font(AppTypography.taskPreview).foregroundStyle(c.textSecondary)
        }
      }
      Spacer()
    }
    .padding(14)
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius))
    .overlay(
      RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius)
        .stroke(c.textPrimary.opacity(0.06), lineWidth: 0.5)
    )
  }

  private func settingsRow(icon: StackedIconKey, label: String, subtitle: String) -> some View {
    let c = theme.colors
    return HStack(spacing: 12) {
      StackedIcons.image(icon).font(.system(size: 16)).foregroundStyle(c.textSecondary).frame(width: 24)
      VStack(alignment: .leading, spacing: 2) {
        Text(label).font(AppTypography.settingsTitle).foregroundStyle(c.textPrimary)
        Text(subtitle).font(AppTypography.metaSmall).foregroundStyle(c.textTertiary)
      }
      Spacer()
    }
  }
}

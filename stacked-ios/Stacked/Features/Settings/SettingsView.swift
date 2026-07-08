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
          .settingsNavigationLinkStyle()
          .settingsGroupedNavigationRow(position: .only)
        }

        Section {
          NavigationLink {
            NotificationsSettingsView().environment(theme)
          } label: {
            settingsRow(icon: .notifications, label: "Notificações", subtitle: "Lembretes e resumo")
          }
          .settingsNavigationLinkStyle()
          .settingsGroupedNavigationRow(position: .first, showDivider: true)

          NavigationLink {
            CalendarSettingsView().environment(theme)
          } label: {
            settingsRow(icon: .calendar, label: "Calendário", subtitle: "Compromissos e exportação")
          }
          .settingsNavigationLinkStyle()
          .settingsGroupedNavigationRow(position: .middle, showDivider: true)

          NavigationLink {
            AppearanceView().environment(theme)
          } label: {
            settingsRow(icon: .paintbrush, label: "Aparência", subtitle: theme.currentId.displayName)
          }
          .settingsNavigationLinkStyle()
          .settingsGroupedNavigationRow(position: .last)
        } header: {
          SettingsSectionHeader(text: "Preferências")
        }

        Section {
          NavigationLink {
            ProductivitySettingsView().environment(theme)
          } label: {
            settingsRow(icon: .productivity, label: "Captura rápida", subtitle: "Descrição no Quick Add")
          }
          .settingsNavigationLinkStyle()
          .settingsGroupedNavigationRow(position: .only)
        } header: {
          SettingsSectionHeader(text: "Produtividade")
        }

        Section {
          NavigationLink {
            LabelsManagementView().environment(theme)
          } label: {
            settingsRow(icon: .tag, label: "Gerenciar Etiquetas", subtitle: "Criar e editar")
          }
          .settingsNavigationLinkStyle()
          .settingsGroupedNavigationRow(position: .first, showDivider: true)

          NavigationLink {
            LogbookView().environment(theme)
          } label: {
            settingsRow(icon: .logbook, label: "Registro", subtitle: "Tarefas concluídas")
          }
          .settingsNavigationLinkStyle()
          .settingsGroupedNavigationRow(position: .last)
        } header: {
          SettingsSectionHeader(text: "Organização")
        }

        Section {
          Button {
            _Concurrency.Task {
              await auth.signOut()
              dismiss()
            }
          } label: {
            logoutButton
          }
          .buttonStyle(.plain)
          .settingsListCardRow(top: 28, bottom: 24)
        }
      }
      .settingsDrillDownList(background: c.background)
      .listSectionSpacing(20)
      .stackedTabletCentered()
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
        size: 44
      )
      VStack(alignment: .leading, spacing: 2) {
        Text(name.isEmpty ? "Conta" : name)
          .font(AppTypography.bodySemibold)
          .foregroundStyle(c.textPrimary)
        if !email.isEmpty {
          Text(email)
            .font(AppTypography.meta)
            .foregroundStyle(c.textSecondary)
            .lineLimit(1)
        }
      }
      Spacer(minLength: 0)
      StackedIcons.image(.chevronRight)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(c.textTertiary)
    }
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
  }

  private var logoutButton: some View {
    HStack(spacing: 8) {
      StackedIcons.image(.logout)
        .font(.system(size: 16))
      Text("Sair da conta")
        .font(AppTypography.settingsTitle)
      Spacer(minLength: 0)
    }
    .foregroundStyle(AppColors.priorityHigh)
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, 14)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .stroke(AppColors.priorityHigh, lineWidth: 1)
    )
  }

  private func settingsRow(icon: StackedIconKey, label: String, subtitle: String) -> some View {
    let c = theme.colors
    return HStack(spacing: 12) {
      StackedIcons.image(icon)
        .font(.system(size: 18))
        .foregroundStyle(c.textSecondary)
        .frame(width: 24)
      VStack(alignment: .leading, spacing: 2) {
        Text(label)
          .font(AppTypography.settingsTitle)
          .foregroundStyle(c.textPrimary)
        Text(subtitle)
          .font(AppTypography.metaSmall)
          .foregroundStyle(c.textTertiary)
      }
      Spacer(minLength: 0)
      StackedIcons.image(.chevronRight)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(c.textTertiary)
    }
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
    .contentShape(Rectangle())
  }
}

extension View {
  /// Esconde chevron duplicado do NavigationLink — usamos chevron manual na row.
  @ViewBuilder
  func settingsNavigationLinkStyle() -> some View {
    if #available(iOS 17.0, *) {
      self.navigationLinkIndicatorVisibility(.hidden)
    } else {
      self
    }
  }
}

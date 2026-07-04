import SwiftUI
import Hugeicons

// Paridade lib/screens/auth_screen.dart — paleta Slate fixa na entrada do app
struct AuthView: View {
  private let c = AppThemeId.slate.colors

  @State private var auth = AuthManager.shared

  @State private var email = ""
  @State private var password = ""
  @State private var isLogin = true
  @State private var obscurePassword = true
  @State private var loading = false
  @State private var error: String?

  @FocusState private var focusedField: AuthField?

  private enum AuthField: Hashable {
    case email, password
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        AuthBrandMark()
          .padding(.bottom, 20)

        Text("STACKED")
          .font(AppTypography.authTitle)
          .foregroundStyle(c.accent)
          .kerning(-1)

        Text(isLogin ? "Bem-vindo de volta" : "Crie sua conta")
          .font(AppTypography.authSubtitle)
          .foregroundStyle(c.textSecondary)
          .padding(.top, 8)
          .padding(.bottom, 32)

        VStack(spacing: 16) {
          authField(
            "E-mail",
            text: $email,
            field: .email,
            keyboard: .emailAddress
          )
          authField(
            "Senha",
            text: $password,
            field: .password,
            secure: !obscurePassword,
            trailing: {
              Button {
                obscurePassword.toggle()
              } label: {
                StackedIcons.image(obscurePassword ? Hugeicons.eye : Hugeicons.eyeOff)
                  .frame(width: 44, height: 44)
                  .foregroundStyle(c.textTertiary)
              }
              .buttonStyle(.plain)
              .accessibilityLabel(obscurePassword ? "Mostrar senha" : "Ocultar senha")
            }
          )

          if let error {
            Text(error)
              .font(AppTypography.meta)
              .foregroundStyle(AppColors.priorityHigh)
              .multilineTextAlignment(.center)
          }

          PrimaryButton(
            title: isLogin ? "Entrar" : "Criar conta",
            action: submit,
            colors: c,
            isLoading: loading,
            isEnabled: !loading
          )
          .padding(.top, 4)

          Button {
            isLogin.toggle()
            error = nil
          } label: {
            Text(isLogin ? "Não tem conta? Criar conta" : "Já tem conta? Entrar")
              .font(AppTypography.authLink)
              .foregroundStyle(c.textSecondary)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 8)
          }
          .buttonStyle(.plain)
        }
        .padding(20)
        .background(c.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
          RoundedRectangle(cornerRadius: 20)
            .strokeBorder(c.surfaceVariant.opacity(0.85), lineWidth: 1)
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 40)
      .padding(.bottom, 32)
    }
    .scrollDismissesKeyboard(.interactively)
    .frame(maxWidth: 420)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(c.background.ignoresSafeArea())
  }

  @ViewBuilder
  private func authField(
    _ label: String,
    text: Binding<String>,
    field: AuthField,
    keyboard: UIKeyboardType = .default,
    secure: Bool = false,
    @ViewBuilder trailing: () -> some View = { EmptyView() }
  ) -> some View {
    let isFocused = focusedField == field

    VStack(alignment: .leading, spacing: 6) {
      Text(label)
        .font(AppTypography.fieldLabel)
        .foregroundStyle(c.textSecondary)

      HStack {
        if secure {
          SecureField("", text: text)
            .focused($focusedField, equals: field)
        } else {
          TextField("", text: text)
            .focused($focusedField, equals: field)
            .keyboardType(keyboard)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
        trailing()
      }
      .font(AppTypography.fieldInput)
      .foregroundStyle(c.textPrimary)
      .padding(.horizontal, 14)
      .padding(.vertical, 14)
      .background(c.surfaceVariant.opacity(0.55))
      .overlay {
        RoundedRectangle(cornerRadius: 10)
          .strokeBorder(
            isFocused ? c.accent : c.surfaceVariant,
            lineWidth: isFocused ? 1.5 : 1
          )
      }
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .animation(AppMotion.snappy, value: isFocused)
    }
  }

  private func submit() {
    let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.contains("@") else {
      error = "E-mail inválido"
      return
    }
    guard !password.isEmpty else {
      error = "Informe a senha"
      return
    }
    if !isLogin && password.count < 6 {
      error = "Mínimo de 6 caracteres"
      return
    }

    loading = true
    error = nil
    _Concurrency.Task {
      do {
        if isLogin {
          try await auth.signIn(email: trimmed, password: password)
        } else {
          try await auth.signUp(email: trimmed, password: password)
        }
      } catch {
        self.error = AuthManager.friendlyError(error)
      }
      loading = false
    }
  }
}

// Losangos empilhados — marca sutil em tons Slate
private struct AuthBrandMark: View {
  private let c = AppThemeId.slate.colors

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 6)
        .fill(c.surfaceVariant.opacity(0.5))
        .frame(width: 36, height: 36)
        .rotationEffect(.degrees(45))
        .offset(y: 10)

      RoundedRectangle(cornerRadius: 6)
        .fill(c.surfaceVariant.opacity(0.75))
        .frame(width: 36, height: 36)
        .rotationEffect(.degrees(45))
        .offset(y: 2)

      RoundedRectangle(cornerRadius: 6)
        .fill(c.accent.opacity(0.9))
        .frame(width: 36, height: 36)
        .rotationEffect(.degrees(45))
        .offset(y: -6)
    }
    .frame(height: 52)
  }
}

#Preview {
  AuthView()
}

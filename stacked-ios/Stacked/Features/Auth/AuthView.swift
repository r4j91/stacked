import SwiftUI

// Paridade lib/screens/auth_screen.dart
struct AuthView: View {
  @Environment(ThemeManager.self) private var theme
  @State private var auth = AuthManager.shared

  @State private var email = ""
  @State private var password = ""
  @State private var isLogin = true
  @State private var obscurePassword = true
  @State private var loading = false
  @State private var error: String?

  var body: some View {
    let c = theme.colors

    ScrollView {
      VStack(spacing: 0) {
        Text("STACKED")
          .font(.system(size: 40, weight: .heavy))
          .foregroundStyle(c.accent)
          .kerning(-1)
          .padding(.top, 16)

        Text(isLogin ? "Bem-vindo de volta" : "Crie sua conta")
          .font(.system(size: 14))
          .foregroundStyle(c.textSecondary)
          .padding(.top, 6)
          .padding(.bottom, 40)

        VStack(spacing: 14) {
          authField("E-mail", text: $email, keyboard: .emailAddress)
          authField("Senha", text: $password, secure: !obscurePassword, trailing: {
            Button {
              obscurePassword.toggle()
            } label: {
              Image(systemName: obscurePassword ? "eye" : "eye.slash")
                .font(.system(size: 16))
                .foregroundStyle(c.textTertiary)
            }
          })

          if let error {
            Text(error)
              .font(.system(size: 13))
              .foregroundStyle(AppColors.priorityHigh)
              .multilineTextAlignment(.center)
              .padding(.top, 4)
          }

          Button(action: submit) {
            Group {
              if loading {
                ProgressView()
                  .tint(c.isDark ? c.background : .white)
              } else {
                Text(isLogin ? "Entrar" : "Criar conta")
                  .font(.system(size: 15, weight: .bold))
              }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
          }
          .buttonStyle(.plain)
          .background(c.accent)
          .foregroundStyle(c.isDark ? c.background : Color(hex: 0x1A1B1E))
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .disabled(loading)
          .padding(.top, 10)

          Button {
            isLogin.toggle()
            error = nil
          } label: {
            Text(isLogin ? "Não tem conta? Criar conta" : "Já tem conta? Entrar")
              .font(.system(size: 13))
              .foregroundStyle(c.textSecondary)
          }
          .buttonStyle(.plain)
          .padding(.top, 8)
        }
      }
      .padding(.horizontal, 32)
      .padding(.bottom, 24)
    }
    .frame(maxWidth: 420)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(c.background.ignoresSafeArea())
  }

  @ViewBuilder
  private func authField(
    _ label: String,
    text: Binding<String>,
    keyboard: UIKeyboardType = .default,
    secure: Bool = false,
    @ViewBuilder trailing: () -> some View = { EmptyView() }
  ) -> some View {
    let c = theme.colors
  VStack(alignment: .leading, spacing: 6) {
      Text(label)
        .font(.system(size: 13))
        .foregroundStyle(c.textSecondary)
      HStack {
        if secure {
          SecureField("", text: text)
        } else {
          TextField("", text: text)
            .keyboardType(keyboard)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
        trailing()
      }
      .font(.system(size: 14))
      .foregroundStyle(c.textPrimary)
      .padding(.horizontal, 14)
      .padding(.vertical, 14)
      .background(c.surface)
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(c.surfaceVariant, lineWidth: 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: 10))
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

#Preview {
  AuthView()
    .environment(ThemeManager.shared)
}

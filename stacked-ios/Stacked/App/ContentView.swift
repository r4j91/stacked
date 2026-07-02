import SwiftUI

/// Fase 0 — valida design tokens. Substituída por auth + tabs na Fase 1.
struct ContentView: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    let c = theme.colors

    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          header(colors: c)
          themePicker
          colorSwatches(colors: c)
          typographySection(colors: c)
          taskRowPreview(colors: c)
          phaseFooter(colors: c)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
      }
      .background(c.background.ignoresSafeArea())
      .navigationBarHidden(true)
    }
    .animation(AppMotion.smooth(reduceMotion: reduceMotion), value: theme.currentId)
  }

  private func header(colors: AppThemeColors) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Stacked")
        .font(AppTypography.screenTitle)
        .foregroundStyle(colors.textPrimary)
      Text("iOS nativo — Fase 0")
        .font(AppTypography.taskPreview)
        .foregroundStyle(colors.textSecondary)
      Text("Flutter em lib/ permanece intacto.")
        .font(AppTypography.meta)
        .foregroundStyle(colors.textTertiary)
    }
    .padding(.top, 16)
  }

  private var themePicker: some View {
    let c = theme.colors
    return VStack(alignment: .leading, spacing: 10) {
      Text("Temas")
        .font(AppTypography.badge)
        .foregroundStyle(c.textSecondary)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(AppThemeId.allCases) { id in
            Button {
              theme.currentId = id
            } label: {
              Text(id.displayName)
                .font(AppTypography.meta)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(theme.currentId == id ? c.accent.opacity(0.2) : c.surfaceVariant)
                .foregroundStyle(theme.currentId == id ? c.accent : c.textSecondary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }

  private func colorSwatches(colors: AppThemeColors) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Superfícies")
        .font(AppTypography.badge)
        .foregroundStyle(colors.textSecondary)
      HStack(spacing: 8) {
        swatch("BG", colors.background, colors.textPrimary)
        swatch("Surface", colors.surface, colors.textPrimary)
        swatch("Variant", colors.surfaceVariant, colors.textPrimary)
        swatch("Accent", colors.accent, colors.isDark ? .black : .white)
      }
    }
  }

  private func swatch(_ label: String, _ color: Color, _ text: Color) -> some View {
    VStack(spacing: 4) {
      RoundedRectangle(cornerRadius: 8)
        .fill(color)
        .frame(height: 44)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08)))
      Text(label)
        .font(AppTypography.metaSmall)
        .foregroundStyle(theme.colors.textTertiary)
    }
  }

  private func typographySection(colors: AppThemeColors) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Tipografia")
        .font(AppTypography.badge)
        .foregroundStyle(colors.textSecondary)
      Text("Título de tarefa 15.5 semibold")
        .font(AppTypography.taskTitle)
        .foregroundStyle(colors.textPrimary)
      Text("Preview de descrição truncada com ellipsis…")
        .font(AppTypography.taskPreview)
        .foregroundStyle(colors.textSecondary)
        .lineLimit(1)
    }
  }

  private func taskRowPreview(colors: AppThemeColors) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Linha de tarefa (~\(Int(AppLayout.taskRowHeight))px)")
        .font(AppTypography.badge)
        .foregroundStyle(colors.textSecondary)

      HStack(spacing: 12) {
        Circle()
          .strokeBorder(colors.textTertiary.opacity(0.5), lineWidth: 1.5)
          .frame(width: 22, height: 22)
        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 6) {
            Text("Revisar design do ícone v3")
              .font(AppTypography.taskTitle)
              .foregroundStyle(colors.textPrimary)
            Text("P1")
              .font(.system(size: 10, weight: .bold))
              .foregroundStyle(AppColors.priorityHigh)
          }
          Text("Validar export 1024×1024 e variantes de cor")
            .font(AppTypography.taskPreview)
            .foregroundStyle(colors.textTertiary)
            .lineLimit(1)
        }
        Spacer(minLength: 0)
      }
      .frame(height: AppLayout.taskRowHeight)
      .padding(.horizontal, 14)
      .background(colors.surface)
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }

  private func phaseFooter(colors: AppThemeColors) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Próximo: Fase 1")
        .font(AppTypography.badge)
        .foregroundStyle(colors.accent)
      Text("Auth Supabase + 5 abas + pill flutuante")
        .font(AppTypography.meta)
        .foregroundStyle(colors.textTertiary)
      if !SupabaseConfig.isConfigured {
        Text("⚠ Configure Config/Secrets.xcconfig antes da Fase 1")
          .font(AppTypography.meta)
          .foregroundStyle(AppColors.priorityMedium)
      }
    }
    .padding(.top, 8)
  }
}

#Preview {
  ContentView()
    .environment(ThemeManager.shared)
}

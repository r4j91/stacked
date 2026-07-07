import SwiftUI

/// Ilustrações calmas para Inbox zero / Hoje livre — tema do app, composição centrada.
enum EmptyStateIllustrationKind {
  case inboxZero
  case todayClear
}

struct EmptyStateIllustration: View {
  @Environment(ThemeManager.self) private var theme
  let kind: EmptyStateIllustrationKind

  var body: some View {
    Group {
      switch kind {
      case .inboxZero: InboxZeroIllustration()
      case .todayClear: TodayClearIllustration()
      }
    }
    .frame(width: 168, height: 128)
    .accessibilityHidden(true)
  }
}

// MARK: - Inbox zero

private struct InboxZeroIllustration: View {
  @Environment(ThemeManager.self) private var theme

  var body: some View {
    let c = theme.colors
    let line = c.textTertiary.opacity(c.isDark ? 0.38 : 0.32)
    let fill = c.surface.opacity(c.isDark ? 0.78 : 0.96)

    ZStack {
      // Halo centrado — profundidade sem deslocar o peso visual
      Circle()
        .fill(
          RadialGradient(
            colors: [
              c.accent.opacity(c.isDark ? 0.20 : 0.14),
              c.accent.opacity(c.isDark ? 0.06 : 0.04),
              .clear,
            ],
            center: .center,
            startRadius: 8,
            endRadius: 58
          )
        )
        .frame(width: 116, height: 116)

      Circle()
        .fill(c.surfaceVariant.opacity(c.isDark ? 0.42 : 0.72))
        .overlay {
          Circle()
            .strokeBorder(c.textPrimary.opacity(c.isDark ? 0.06 : 0.08), lineWidth: 1)
        }
        .frame(width: 88, height: 88)

      // Bandeja
      RoundedRectangle(cornerRadius: 13, style: .continuous)
        .fill(fill)
        .overlay {
          RoundedRectangle(cornerRadius: 13, style: .continuous)
            .strokeBorder(line, lineWidth: 1.35)
        }
        .frame(width: 68, height: 44)
        .offset(y: 6)
        .overlay(alignment: .top) {
          InboxTrayLid()
            .stroke(line.opacity(0.85), style: StrokeStyle(lineWidth: 1.35, lineCap: .round))
            .frame(width: 68, height: 12)
            .offset(y: -6)
        }
        .overlay {
          VStack(spacing: 6) {
            Capsule()
              .fill(c.textTertiary.opacity(c.isDark ? 0.22 : 0.16))
              .frame(width: 34, height: 3)
            Capsule()
              .fill(c.textTertiary.opacity(c.isDark ? 0.14 : 0.10))
              .frame(width: 22, height: 3)
          }
          .offset(y: 8)
        }

      // Selo de “tudo certo” — centrado na borda superior da bandeja
      Circle()
        .fill(
          LinearGradient(
            colors: [
              c.accent.opacity(c.isDark ? 0.28 : 0.20),
              c.accent.opacity(c.isDark ? 0.16 : 0.12),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay {
          Circle()
            .strokeBorder(c.accent.opacity(c.isDark ? 0.35 : 0.28), lineWidth: 1)
        }
        .frame(width: 30, height: 30)
        .overlay {
          Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(c.accent.opacity(c.isDark ? 0.92 : 0.78))
        }
        .offset(y: -14)
    }
  }
}

private struct InboxTrayLid: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX + 6, y: rect.maxY))
    path.addQuadCurve(
      to: CGPoint(x: rect.maxX - 6, y: rect.maxY),
      control: CGPoint(x: rect.midX, y: rect.minY - 3)
    )
    return path
  }
}

// MARK: - Today clear

private struct TodayClearIllustration: View {
  @Environment(ThemeManager.self) private var theme

  var body: some View {
    let c = theme.colors
    let line = c.textTertiary.opacity(c.isDark ? 0.34 : 0.28)

    ZStack {
      Circle()
        .fill(
          RadialGradient(
            colors: [
              c.accent.opacity(c.isDark ? 0.16 : 0.11),
              c.accent.opacity(c.isDark ? 0.04 : 0.03),
              .clear,
            ],
            center: .center,
            startRadius: 6,
            endRadius: 56
          )
        )
        .frame(width: 112, height: 112)
        .offset(y: -4)

      Circle()
        .fill(c.surfaceVariant.opacity(c.isDark ? 0.38 : 0.68))
        .overlay {
          Circle()
            .strokeBorder(c.textPrimary.opacity(c.isDark ? 0.05 : 0.07), lineWidth: 1)
        }
        .frame(width: 84, height: 84)
        .offset(y: 2)

      // Sol — arco simétrico
      Circle()
        .trim(from: 0.14, to: 0.86)
        .stroke(
          c.accent.opacity(c.isDark ? 0.48 : 0.36),
          style: StrokeStyle(lineWidth: 2.6, lineCap: .round)
        )
        .frame(width: 46, height: 46)
        .rotationEffect(.degrees(180))
        .offset(y: -22)

      Circle()
        .fill(c.accent.opacity(c.isDark ? 0.62 : 0.48))
        .frame(width: 7, height: 7)
        .offset(y: -44)

      // Horizonte + colinas suaves
      Capsule()
        .fill(line.opacity(0.55))
        .frame(width: 88, height: 2)
        .offset(y: 18)

      HStack(spacing: 0) {
        Hill()
          .fill(c.textTertiary.opacity(c.isDark ? 0.14 : 0.10))
          .frame(width: 42, height: 14)
        Spacer(minLength: 10)
        Hill()
          .fill(c.textTertiary.opacity(c.isDark ? 0.09 : 0.07))
          .frame(width: 30, height: 10)
      }
      .frame(width: 88)
      .offset(y: 12)

      // Detalhe “calma” — folha mínima, bem discreta
      Circle()
        .fill(AppColors.tagGreen.opacity(c.isDark ? 0.18 : 0.14))
        .frame(width: 24, height: 24)
        .overlay {
          Image(systemName: "leaf.fill")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(AppColors.tagGreen.opacity(c.isDark ? 0.78 : 0.65))
        }
        .offset(x: 38, y: 26)
    }
  }
}

private struct Hill: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addQuadCurve(
      to: CGPoint(x: rect.maxX, y: rect.maxY),
      control: CGPoint(x: rect.midX, y: rect.minY)
    )
    path.closeSubpath()
    return path
  }
}

// MARK: - Home all clear (inline)

/// Selo mínimo para "Tudo em dia" na Home — mesma linguagem das empty states, ~28pt.
struct HomeAllClearBadge: View {
  @Environment(ThemeManager.self) private var theme

  var body: some View {
    let c = theme.colors
    let green = AppColors.tagGreen

    ZStack {
      Circle()
        .fill(
          RadialGradient(
            colors: [
              green.opacity(c.isDark ? 0.20 : 0.14),
              green.opacity(c.isDark ? 0.05 : 0.03),
              .clear,
            ],
            center: .center,
            startRadius: 1,
            endRadius: 15
          )
        )
        .frame(width: 30, height: 30)

      Circle()
        .trim(from: 0.06, to: 0.44)
        .stroke(
          green.opacity(c.isDark ? 0.28 : 0.22),
          style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
        )
        .frame(width: 26, height: 26)
        .rotationEffect(.degrees(-108))

      Circle()
        .strokeBorder(green.opacity(c.isDark ? 0.34 : 0.28), lineWidth: 1)
        .frame(width: 22, height: 22)

      Circle()
        .fill(c.surfaceVariant.opacity(c.isDark ? 0.42 : 0.58))
        .overlay {
          Circle()
            .strokeBorder(c.textPrimary.opacity(c.isDark ? 0.05 : 0.07), lineWidth: 0.75)
        }
        .frame(width: 18, height: 18)

      Image(systemName: "checkmark")
        .font(.system(size: 8.5, weight: .bold))
        .foregroundStyle(green.opacity(c.isDark ? 0.90 : 0.78))
    }
    .frame(width: 28, height: 28)
    .accessibilityHidden(true)
  }
}

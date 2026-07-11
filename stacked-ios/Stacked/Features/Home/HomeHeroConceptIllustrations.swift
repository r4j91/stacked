import SwiftUI

// Ilustrações geométricas compactas para os cards conceito (hero Home).

struct HomeMotivationMountainArt: View {
  var accent: Color = AppColors.priorityLow

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      // Halo atmosférico
      Circle()
        .fill(
          RadialGradient(
            colors: [accent.opacity(0.14), accent.opacity(0.04), .clear],
            center: .center,
            startRadius: 2,
            endRadius: 34
          )
        )
        .frame(width: 68, height: 68)
        .offset(x: -6, y: -10)

      // Horizonte
      Path { path in
        path.move(to: CGPoint(x: 4, y: 44))
        path.addQuadCurve(to: CGPoint(x: 70, y: 44), control: CGPoint(x: 38, y: 41))
      }
      .stroke(accent.opacity(0.2), lineWidth: 1)

      // Pico distante
      Path { path in
        path.move(to: CGPoint(x: 6, y: 44))
        path.addLine(to: CGPoint(x: 28, y: 22))
        path.addLine(to: CGPoint(x: 50, y: 44))
        path.closeSubpath()
      }
      .fill(accent.opacity(0.07))
      .overlay {
        Path { path in
          path.move(to: CGPoint(x: 6, y: 44))
          path.addLine(to: CGPoint(x: 28, y: 22))
          path.addLine(to: CGPoint(x: 50, y: 44))
          path.closeSubpath()
        }
        .stroke(accent.opacity(0.14), lineWidth: 0.75)
      }

      // Pico médio
      Path { path in
        path.move(to: CGPoint(x: 24, y: 44))
        path.addLine(to: CGPoint(x: 42, y: 18))
        path.addLine(to: CGPoint(x: 62, y: 44))
        path.closeSubpath()
      }
      .fill(
        LinearGradient(
          colors: [accent.opacity(0.2), accent.opacity(0.1)],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .overlay {
        Path { path in
          path.move(to: CGPoint(x: 24, y: 44))
          path.addLine(to: CGPoint(x: 42, y: 18))
          path.addLine(to: CGPoint(x: 62, y: 44))
          path.closeSubpath()
        }
        .stroke(accent.opacity(0.22), lineWidth: 0.75)
      }

      // Capa de neve
      Path { path in
        path.move(to: CGPoint(x: 36, y: 28))
        path.addLine(to: CGPoint(x: 42, y: 18))
        path.addLine(to: CGPoint(x: 48, y: 28))
        path.closeSubpath()
      }
      .fill(accent.opacity(0.38))

      Path { path in
        path.move(to: CGPoint(x: 22, y: 34))
        path.addLine(to: CGPoint(x: 28, y: 22))
        path.addLine(to: CGPoint(x: 34, y: 34))
        path.closeSubpath()
      }
      .fill(accent.opacity(0.22))

      // Astro discreto
      Circle()
        .fill(accent.opacity(0.42))
        .frame(width: 5, height: 5)
        .offset(x: -8, y: -30)
    }
    .frame(width: 74, height: 48)
    .accessibilityHidden(true)
  }
}

struct HomeFocusTargetArt: View {
  var accent: Color = AppColors.tagPurple

  var body: some View {
    ZStack {
      Circle()
        .stroke(accent.opacity(0.18), lineWidth: 2)
        .frame(width: 46, height: 46)
      Circle()
        .stroke(accent.opacity(0.28), lineWidth: 2)
        .frame(width: 30, height: 30)
      Circle()
        .fill(accent.opacity(0.42))
        .frame(width: 8, height: 8)

      Image(systemName: "arrow.up.right")
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(accent.opacity(0.45))
        .offset(x: 20, y: -18)
      Image(systemName: "arrow.down.left")
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(accent.opacity(0.32))
        .offset(x: -18, y: 16)
    }
    .frame(width: 56, height: 52)
    .accessibilityHidden(true)
  }
}

struct HomeStreakFlameArt: View {
  var accent: Color = AppColors.priorityLow

  var body: some View {
    Image(systemName: "flame.fill")
      .font(.system(size: 30, weight: .medium))
      .foregroundStyle(accent.opacity(0.48))
      .frame(width: 40, height: 44)
      .accessibilityHidden(true)
  }
}

struct HomeStreakWeekTracker: View {
  let completed: [Bool]
  var accent: Color = AppColors.priorityLow
  var labelColor: Color = AppColors.textTertiary
  var emptyDotColor: Color = Color.white.opacity(0.07)
  private let labels = ["S", "T", "Q", "Q", "S", "S", "D"]

  var body: some View {
    HStack(spacing: 6) {
      ForEach(0..<7, id: \.self) { index in
        VStack(spacing: 4) {
          Text(labels[index])
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(labelColor.opacity(0.85))
          ZStack {
            Circle()
              .fill(completed[index] ? accent.opacity(0.28) : emptyDotColor)
              .frame(width: 16, height: 16)
            if completed[index] {
              Image(systemName: "checkmark")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(accent.opacity(0.85))
            }
          }
        }
      }
    }
    .accessibilityHidden(true)
  }
}

// MARK: - Card chrome compartilhado

/// Rodapé de status dentro do card (opção integrada).
struct HomeConceptIntegratedStatusFooter: View {
  @Environment(ThemeManager.self) private var theme

  let isOverdue: Bool
  let statusLabel: String
  var onTap: (() -> Void)?

  var body: some View {
    let c = theme.colors
    let row = HStack(spacing: 8) {
      Circle()
        .fill(isOverdue ? AppColors.overdue.opacity(0.88) : AppColors.tagGreen.opacity(0.72))
        .frame(width: 5, height: 5)
      Text(statusLabel)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(isOverdue ? c.textPrimary : c.textSecondary)
        .lineLimit(1)
      Spacer(minLength: 0)
      if isOverdue {
        DisclosureChevron(color: c.textTertiary)
      }
    }
    .padding(.top, 9)
    .overlay(alignment: .top) {
      Rectangle()
        .fill(c.textPrimary.opacity(c.isDark ? 0.06 : 0.05))
        .frame(height: 1)
    }

    if isOverdue, let onTap {
      Button(action: onTap) { row }
        .buttonStyle(.plain)
        .accessibilityHint("Abre tarefas atrasadas")
    } else {
      row
    }
  }
}

struct HomeConceptStatusChip: View {
  let isOverdue: Bool
  let overdueCount: Int

  var body: some View {
    let accent = isOverdue ? AppColors.overdue : AppColors.tagGreen
    let label = isOverdue
      ? (overdueCount == 1 ? "1 atrasada" : "\(overdueCount) atrasadas")
      : "Tudo em dia"
    Text(label)
      .font(.system(size: 10, weight: .semibold))
      .foregroundStyle(accent.opacity(isOverdue ? 0.92 : 0.82))
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(accent.opacity(0.14))
      .clipShape(Capsule())
  }
}

struct HomeConceptCard<Content: View>: View {
  @Environment(ThemeManager.self) private var theme

  let accent: Color
  var minHeight: CGFloat = 100
  var maxHeight: CGFloat? = 100
  @ViewBuilder var content: () -> Content

  var body: some View {
    let c = theme.colors
    content()
      .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight, alignment: .leading)
      .background {
        ZStack {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(c.surface)

          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
              LinearGradient(
                colors: [
                  accent.opacity(c.isDark ? 0.1 : 0.08),
                  accent.opacity(c.isDark ? 0.04 : 0.03),
                  .clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )

          GeometryReader { geo in
            RadialGradient(
              colors: [accent.opacity(c.isDark ? 0.08 : 0.06), .clear],
              center: .topTrailing,
              startRadius: 2,
              endRadius: geo.size.width * 0.52
            )
          }
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(accent.opacity(c.isDark ? 0.14 : 0.12), lineWidth: 1)
      }
  }
}

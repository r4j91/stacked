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

struct HomeGreetingSunriseMountainArt: View {
  var accent: Color = AppColors.tagPurple
  var sunColor: Color = AppColors.priorityMedium

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      Circle()
        .fill(
          RadialGradient(
            colors: [sunColor.opacity(0.42), sunColor.opacity(0.12), .clear],
            center: .center,
            startRadius: 2,
            endRadius: 22
          )
        )
        .frame(width: 44, height: 44)
        .offset(x: -8, y: -28)

      Circle()
        .fill(sunColor.opacity(0.72))
        .frame(width: 18, height: 18)
        .offset(x: -8, y: -28)

      Path { path in
        path.move(to: CGPoint(x: 8, y: 44))
        path.addLine(to: CGPoint(x: 24, y: 24))
        path.addLine(to: CGPoint(x: 42, y: 44))
        path.closeSubpath()
      }
      .fill(accent.opacity(0.1))

      Path { path in
        path.move(to: CGPoint(x: 20, y: 44))
        path.addLine(to: CGPoint(x: 38, y: 18))
        path.addLine(to: CGPoint(x: 58, y: 44))
        path.closeSubpath()
      }
      .fill(accent.opacity(0.18))
      .overlay {
        Path { path in
          path.move(to: CGPoint(x: 20, y: 44))
          path.addLine(to: CGPoint(x: 38, y: 18))
          path.addLine(to: CGPoint(x: 58, y: 44))
          path.closeSubpath()
        }
        .stroke(accent.opacity(0.2), lineWidth: 0.75)
      }

      Path { path in
        path.move(to: CGPoint(x: 4, y: 44))
        path.addQuadCurve(to: CGPoint(x: 66, y: 44), control: CGPoint(x: 34, y: 41))
      }
      .stroke(accent.opacity(0.16), lineWidth: 1)
    }
    .frame(width: 72, height: 48)
    .accessibilityHidden(true)
  }
}

struct HomeGreetingFlagPeakArt: View {
  var accent: Color = AppColors.tagPurple

  var body: some View {
    ZStack(alignment: .bottom) {
      Path { path in
        path.move(to: CGPoint(x: 10, y: 50))
        path.addLine(to: CGPoint(x: 34, y: 16))
        path.addLine(to: CGPoint(x: 58, y: 50))
        path.closeSubpath()
      }
      .fill(accent.opacity(0.14))
      .overlay {
        Path { path in
          path.move(to: CGPoint(x: 10, y: 50))
          path.addLine(to: CGPoint(x: 34, y: 16))
          path.addLine(to: CGPoint(x: 58, y: 50))
          path.closeSubpath()
        }
        .stroke(accent.opacity(0.22), lineWidth: 0.75)
      }

      Path { path in
        path.move(to: CGPoint(x: 34, y: 16))
        path.addLine(to: CGPoint(x: 34, y: 8))
        path.addLine(to: CGPoint(x: 48, y: 12))
        path.addLine(to: CGPoint(x: 34, y: 16))
        path.closeSubpath()
      }
      .fill(accent.opacity(0.55))

      Rectangle()
        .fill(accent.opacity(0.35))
        .frame(width: 1.5, height: 14)
        .offset(x: 0, y: -21)

      Circle()
        .fill(accent.opacity(0.2))
        .frame(width: 3, height: 3)
        .offset(x: -14, y: -30)
      Circle()
        .fill(accent.opacity(0.14))
        .frame(width: 2, height: 2)
        .offset(x: 10, y: -34)
    }
    .frame(width: 68, height: 52)
    .accessibilityHidden(true)
  }
}

struct HomeGreetingWeatherArt: View {
  var accent: Color = AppColors.priorityMedium
  var style: HomeHeroInsights.WeatherSnapshot.Style = .sunny

  var body: some View {
    ZStack {
      switch style {
      case .sunny:
        sunCore
      case .clear:
        nightSky
      case .partlyCloudy, .cloudy, .foggy:
        sunCore.opacity(style == .foggy ? 0.35 : 0.7)
        cloudLayer(opacity: style == .cloudy ? 0.24 : 0.16)
      case .rainy:
        cloudLayer(opacity: 0.22)
        rainStreaks
      case .stormy:
        cloudLayer(opacity: 0.28)
        rainStreaks
        bolt
      case .snowy:
        cloudLayer(opacity: 0.2)
        snowFlakes
      }
    }
    .frame(width: 64, height: 44)
    .accessibilityHidden(true)
  }

  private var sunCore: some View {
    ZStack {
      Circle()
        .fill(
          RadialGradient(
            colors: [accent.opacity(0.5), accent.opacity(0.16), .clear],
            center: .center,
            startRadius: 2,
            endRadius: 18
          )
        )
        .frame(width: 36, height: 36)
        .offset(x: -6, y: -4)
      Circle()
        .fill(accent.opacity(0.78))
        .frame(width: 16, height: 16)
        .offset(x: -6, y: -4)
    }
  }

  private var nightSky: some View {
    ZStack {
      Circle()
        .fill(AppColors.priorityLow.opacity(0.35))
        .frame(width: 10, height: 10)
        .offset(x: -10, y: -8)
      Circle()
        .fill(AppColors.priorityLow.opacity(0.28))
        .frame(width: 7, height: 7)
        .offset(x: 4, y: -12)
      Circle()
        .fill(AppColors.tagPurple.opacity(0.22))
        .frame(width: 5, height: 5)
        .offset(x: 12, y: -2)
    }
  }

  private func cloudLayer(opacity: Double) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.white.opacity(opacity))
        .frame(width: 34, height: 16)
        .offset(x: 8, y: 6)
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.white.opacity(opacity * 0.75))
        .frame(width: 26, height: 12)
        .offset(x: 14, y: 12)
    }
  }

  private var rainStreaks: some View {
    ZStack {
      ForEach(0..<5, id: \.self) { index in
        Capsule()
          .fill(AppColors.priorityLow.opacity(0.55))
          .frame(width: 1.2, height: 7)
          .offset(x: CGFloat(-4 + index * 5), y: 14)
      }
    }
  }

  private var bolt: some View {
    Image(systemName: "bolt.fill")
      .font(.system(size: 9, weight: .bold))
      .foregroundStyle(AppColors.priorityMedium.opacity(0.85))
      .offset(x: 16, y: 2)
  }

  private var snowFlakes: some View {
    ZStack {
      ForEach(0..<4, id: \.self) { index in
        Circle()
          .fill(Color.white.opacity(0.55))
          .frame(width: 3, height: 3)
          .offset(x: CGFloat(-6 + index * 5), y: CGFloat(10 + (index % 2) * 4))
      }
    }
  }
}

struct HomeGreetingWeatherPremiumArt: View {
  @Environment(ThemeManager.self) private var theme

  var accent: Color = AppColors.priorityMedium
  var style: HomeHeroInsights.WeatherSnapshot.Style = .sunny

  var body: some View {
    let c = theme.colors
    ZStack {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(
          LinearGradient(
            colors: skyColors(isDark: c.isDark),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(
          RadialGradient(
            colors: [accent.opacity(c.isDark ? 0.14 : 0.1), .clear],
            center: style == .clear ? .topTrailing : .topLeading,
            startRadius: 4,
            endRadius: 52
          )
        )

      sceneContent

      // Horizonte sutil
      VStack {
        Spacer()
        Rectangle()
          .fill(c.textPrimary.opacity(c.isDark ? 0.05 : 0.04))
          .frame(height: 1)
          .padding(.horizontal, 10)
          .padding(.bottom, 11)
      }
    }
    .frame(width: 88, height: 64)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .strokeBorder(accent.opacity(c.isDark ? 0.16 : 0.12), lineWidth: 1)
    }
    .accessibilityHidden(true)
  }

  @ViewBuilder
  private var sceneContent: some View {
    switch style {
    case .sunny:
      premiumSun(intensity: 1)
    case .clear:
      premiumMoon
    case .partlyCloudy:
      premiumSun(intensity: 0.82)
      premiumClouds(density: 0.55, offsetY: 4)
    case .cloudy:
      premiumSun(intensity: 0.42)
      premiumClouds(density: 0.85, offsetY: 2)
    case .foggy:
      premiumClouds(density: 0.7, offsetY: -2)
        .opacity(0.75)
      fogVeil
    case .rainy:
      premiumClouds(density: 0.9, offsetY: -4)
      premiumRain(intensity: 0.75)
    case .stormy:
      premiumClouds(density: 1, offsetY: -6)
      premiumRain(intensity: 1)
      premiumBolt
    case .snowy:
      premiumClouds(density: 0.75, offsetY: -4)
      premiumSnow
    }
  }

  private func skyColors(isDark: Bool) -> [Color] {
    switch style {
    case .sunny, .partlyCloudy:
      return [
        accent.opacity(isDark ? 0.28 : 0.2),
        accent.opacity(isDark ? 0.1 : 0.08),
        Color.white.opacity(isDark ? 0.03 : 0.06),
      ]
    case .rainy, .stormy:
      return [
        AppColors.priorityLow.opacity(isDark ? 0.24 : 0.16),
        AppColors.priorityLow.opacity(isDark ? 0.1 : 0.07),
        cSurface(isDark).opacity(0.5),
      ]
    case .snowy, .foggy:
      return [
        AppColors.priorityLow.opacity(isDark ? 0.16 : 0.12),
        Color.white.opacity(isDark ? 0.05 : 0.08),
        cSurface(isDark).opacity(0.45),
      ]
    case .cloudy:
      return [
        AppColors.textTertiary.opacity(isDark ? 0.18 : 0.12),
        accent.opacity(isDark ? 0.08 : 0.06),
        cSurface(isDark).opacity(0.4),
      ]
    case .clear:
      return [
        AppColors.tagPurple.opacity(isDark ? 0.22 : 0.14),
        AppColors.priorityLow.opacity(isDark ? 0.12 : 0.08),
        Color.black.opacity(isDark ? 0.15 : 0.04),
      ]
    }
  }

  private func cSurface(_ isDark: Bool) -> Color {
    theme.colors.surfaceVariant
  }

  private func premiumSun(intensity: Double) -> some View {
    ZStack {
      Circle()
        .fill(
          RadialGradient(
            colors: [
              accent.opacity(0.42 * intensity),
              accent.opacity(0.14 * intensity),
              .clear,
            ],
            center: .center,
            startRadius: 2,
            endRadius: 24
          )
        )
        .frame(width: 48, height: 48)
        .offset(x: -14, y: -10)

      Circle()
        .stroke(accent.opacity(0.2 * intensity), lineWidth: 1)
        .frame(width: 26, height: 26)
        .offset(x: -14, y: -10)

      Circle()
        .fill(
          LinearGradient(
            colors: [accent.opacity(0.92 * intensity), accent.opacity(0.65 * intensity)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 18, height: 18)
        .offset(x: -14, y: -10)
    }
  }

  private var premiumMoon: some View {
    ZStack {
      Circle()
        .fill(AppColors.priorityLow.opacity(0.2))
        .frame(width: 20, height: 20)
        .offset(x: -10, y: -12)
      Circle()
        .fill(
          LinearGradient(
            colors: [AppColors.priorityLow.opacity(0.55), AppColors.tagPurple.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 14, height: 14)
        .offset(x: -10, y: -12)
      Circle()
        .fill(Color.white.opacity(0.7))
        .frame(width: 2.5, height: 2.5)
        .offset(x: 8, y: -16)
      Circle()
        .fill(Color.white.opacity(0.45))
        .frame(width: 1.8, height: 1.8)
        .offset(x: 14, y: -8)
      Circle()
        .fill(Color.white.opacity(0.35))
        .frame(width: 1.5, height: 1.5)
        .offset(x: 4, y: -4)
    }
  }

  private func premiumClouds(density: Double, offsetY: CGFloat) -> some View {
    ZStack {
      cloudBlob(width: 36, height: 15, opacity: 0.22 * density)
        .offset(x: 10, y: offsetY + 8)
      cloudBlob(width: 28, height: 12, opacity: 0.18 * density)
        .offset(x: 18, y: offsetY + 14)
      cloudBlob(width: 22, height: 10, opacity: 0.14 * density)
        .offset(x: 4, y: offsetY + 12)
    }
  }

  private func cloudBlob(width: CGFloat, height: CGFloat, opacity: Double) -> some View {
    ZStack {
      Capsule()
        .fill(Color.white.opacity(opacity))
        .frame(width: width, height: height)
      Capsule()
        .fill(Color.white.opacity(opacity * 0.75))
        .frame(width: width * 0.62, height: height * 0.72)
        .offset(x: width * 0.14, y: height * 0.08)
      Circle()
        .fill(Color.white.opacity(opacity * 0.85))
        .frame(width: height * 0.95, height: height * 0.95)
        .offset(x: -width * 0.18, y: 0)
    }
  }

  private var fogVeil: some View {
    RoundedRectangle(cornerRadius: 10, style: .continuous)
      .fill(Color.white.opacity(0.08))
      .frame(width: 70, height: 22)
      .offset(y: 8)
      .blur(radius: 2)
  }

  private func premiumRain(intensity: Double) -> some View {
    ZStack {
      ForEach(0..<7, id: \.self) { index in
        Capsule()
          .fill(AppColors.priorityLow.opacity(0.35 + 0.35 * intensity))
          .frame(width: 1.4, height: CGFloat(5 + (index % 3) * 3))
          .offset(
            x: CGFloat(-18 + index * 6),
            y: CGFloat(14 + (index % 2) * 2)
          )
          .rotationEffect(.degrees(12))
      }
    }
  }

  private var premiumBolt: some View {
    Image(systemName: "bolt.fill")
      .font(.system(size: 11, weight: .bold))
      .foregroundStyle(
        LinearGradient(
          colors: [AppColors.priorityMedium, AppColors.priorityMedium.opacity(0.7)],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .shadow(color: AppColors.priorityMedium.opacity(0.35), radius: 4, y: 1)
      .offset(x: 20, y: 0)
  }

  private var premiumSnow: some View {
    ZStack {
      ForEach(0..<6, id: \.self) { index in
        Circle()
          .fill(Color.white.opacity(0.45 + Double(index % 2) * 0.15))
          .frame(width: CGFloat(2 + (index % 3)), height: CGFloat(2 + (index % 3)))
          .offset(
            x: CGFloat(-16 + index * 6),
            y: CGFloat(12 + (index % 3) * 4)
          )
      }
    }
  }
}

struct HomeGreetingTintedCard<Content: View>: View {
  @Environment(ThemeManager.self) private var theme

  let accent: Color
  var minHeight: CGFloat = 100
  var maxHeight: CGFloat? = nil
  @ViewBuilder var content: () -> Content

  var body: some View {
    let c = theme.colors
    content()
      .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight, alignment: .leading)
      .background {
        ZStack {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
              LinearGradient(
                colors: [
                  accent.opacity(c.isDark ? 0.22 : 0.16),
                  c.surface.opacity(0.98),
                  c.surfaceVariant.opacity(c.isDark ? 0.92 : 0.88),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )

          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(c.surface.opacity(c.isDark ? 0.35 : 0.25))

          GeometryReader { geo in
            RadialGradient(
              colors: [accent.opacity(c.isDark ? 0.16 : 0.12), .clear],
              center: .topTrailing,
              startRadius: 4,
              endRadius: geo.size.width * 0.65
            )
          }
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(accent.opacity(c.isDark ? 0.22 : 0.18), lineWidth: 1)
      }
  }
}

// MARK: - Card chrome compartilhado

/// Rodapé de status integrado (dentro do card ou em layout aberto).
struct HomeConceptIntegratedStatusFooter: View {
  enum Presentation {
    case card
    case open
  }

  @Environment(ThemeManager.self) private var theme

  let isOverdue: Bool
  let statusLabel: String
  var presentation: Presentation = .card
  var onTap: (() -> Void)?

  var body: some View {
    let c = theme.colors
    let dividerColor = presentation == .open
      ? (isOverdue ? AppColors.overdue.opacity(0.12) : c.textPrimary.opacity(c.isDark ? 0.06 : 0.05))
      : c.textPrimary.opacity(c.isDark ? 0.06 : 0.05)
    let divider = Rectangle()
      .fill(dividerColor)
      .frame(height: 1)

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

    let footer = VStack(spacing: 0) {
      divider
      row
    }
    .padding(.top, presentation == .open ? 14 : 12)

    if isOverdue, let onTap {
      Button(action: onTap) { footer }
        .buttonStyle(.plain)
        .accessibilityHint("Abre tarefas atrasadas")
    } else {
      footer
    }
  }
}

struct HomeConceptStatusChip: View {
  let isOverdue: Bool
  let overdueCount: Int

  var body: some View {
    let accent = isOverdue ? AppColors.overdue : AppColors.tagGreen
    let label = isOverdue
      ? (overdueCount == 1 ? "1 pendência atrasada" : "\(overdueCount) pendências atrasadas")
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

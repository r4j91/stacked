import SwiftUI

// Saudação + módulo contextual (progresso, foco ou clima) com status integrado no rodapé.

private struct HomeGreetingNameBlock: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let subtitle: String
  var accent: Color = AppColors.tagPurple

  var body: some View {
    let c = theme.colors
    VStack(alignment: .leading, spacing: 4) {
      Text(store.greetingPhrase)
        .font(.system(size: metrics.phraseSize, weight: .semibold))
        .foregroundStyle(accent.opacity(0.72))
      if !store.firstName.isEmpty {
        Text(store.firstName)
          .font(.system(size: metrics.nameSize, weight: .heavy))
          .foregroundStyle(c.textPrimary)
          .tracking(-0.4)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
      }
      Text(subtitle)
        .font(.system(size: metrics.focusSubtitleSize, weight: .medium))
        .foregroundStyle(c.textSecondary)
        .lineLimit(2)
        .minimumScaleFactor(0.9)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct HomeHeroGreetingProgressCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void
  var chrome: GreetingIntegratedChrome = .standard(AppColors.tagPurple)
  var progressAccent: Color = AppColors.tagPurple

  private var progress: Double {
    guard store.todayTotal > 0 else { return store.todayPending == 0 && !isOverdue ? 1 : 0 }
    return Double(store.todayDone) / Double(store.todayTotal)
  }

  var body: some View {
    let c = theme.colors
    let percent = store.todayProgressPercent
    let accent = progressAccent
    let cardAccent: Color = {
      if case .tinted(let color) = chrome { return color }
      return AppColors.tagPurple
    }()

    greetingIntegratedCard(chrome: chrome, minHeight: 132) {
      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .top, spacing: 8) {
          HomeGreetingNameBlock(
            store: store,
            metrics: metrics,
            subtitle: store.greetingProgressSubtitle,
            accent: cardAccent
          )

          HomeGreetingSunriseMountainArt(accent: accent)
            .scaleEffect(0.95)
        }

        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 8) {
            ZStack {
              Circle()
                .stroke(accent.opacity(0.28), lineWidth: 1.5)
                .frame(width: 22, height: 22)
              if progress >= 1 {
                Image(systemName: "checkmark")
                  .font(.system(size: 10, weight: .bold))
                  .foregroundStyle(accent.opacity(0.85))
              }
            }

            Text(progressLabel)
              .font(.system(size: metrics.focusSubtitleSize, weight: .medium))
              .foregroundStyle(c.textSecondary)
              .lineLimit(1)

            Spacer(minLength: 0)

            Text("\(percent)%")
              .font(.system(size: metrics.focusSubtitleSize, weight: .bold))
              .foregroundStyle(accent.opacity(0.9))
          }

          GeometryReader { geo in
            ZStack(alignment: .leading) {
              Capsule()
                .fill(c.textPrimary.opacity(c.isDark ? 0.08 : 0.06))
              Capsule()
                .fill(
                  LinearGradient(
                    colors: [accent.opacity(0.85), accent.opacity(0.55)],
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
                .frame(width: max(0, geo.size.width * progress))
            }
          }
          .frame(height: 5)
        }
      }
    } footer: {
      HomeConceptIntegratedStatusFooter(
        isOverdue: isOverdue,
        statusLabel: store.statusLabel(overdueCount: store.overdueCount),
        onTap: isOverdue ? { HapticService.selection(); onOpenFilter(.overdue) } : nil
      )
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      "\(store.greetingPhrase) \(store.firstName). \(store.greetingProgressSubtitle). \(progressLabel), \(percent) por cento. \(store.statusLabel(overdueCount: store.overdueCount))"
    )
  }

  private var progressLabel: String {
    if store.todayTotal == 0 {
      return "Sem tarefas de hoje"
    }
    if store.todayDone == 1, store.todayTotal == 1 {
      return "1 de 1 tarefa concluída"
    }
    return "\(store.todayDone) de \(store.todayTotal) tarefas concluídas"
  }
}

struct HomeHeroGreetingFocusCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void
  var chrome: GreetingIntegratedChrome = .standard(AppColors.tagPurple)

  private var accent: Color { AppColors.tagPurple }

  var body: some View {
    let c = theme.colors

    greetingIntegratedCard(chrome: chrome, minHeight: 128) {
      HStack(alignment: .top, spacing: 10) {
        HomeGreetingNameBlock(
          store: store,
          metrics: metrics,
          subtitle: store.greetingFocusSubtitle,
          accent: accent
        )

        VStack(alignment: .trailing, spacing: 6) {
          HomeGreetingFlagPeakArt(accent: accent)
            .scaleEffect(0.92)

          VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
              Image(systemName: "scope")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(accent.opacity(0.75))
              Text("Foco de hoje")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(accent.opacity(0.72))
            }
            Text(store.greetingFocusCardTitle)
              .font(.system(size: 11.5, weight: .semibold))
              .foregroundStyle(c.textPrimary)
              .lineLimit(2)
              .minimumScaleFactor(0.85)
              .frame(maxWidth: 118, alignment: .leading)
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 8)
          .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .fill(c.textPrimary.opacity(c.isDark ? 0.06 : 0.05))
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .fill(accent.opacity(c.isDark ? 0.08 : 0.06))
          }
          .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .strokeBorder(accent.opacity(0.14), lineWidth: 1)
          }
        }
      }
    } footer: {
      HomeConceptIntegratedStatusFooter(
        isOverdue: isOverdue,
        statusLabel: store.statusLabel(overdueCount: store.overdueCount),
        onTap: isOverdue ? { HapticService.selection(); onOpenFilter(.overdue) } : nil
      )
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      "\(store.greetingPhrase) \(store.firstName). \(store.greetingFocusSubtitle). Foco de hoje: \(store.greetingFocusCardTitle). \(store.statusLabel(overdueCount: store.overdueCount))"
    )
  }
}

struct HomeHeroGreetingWeatherCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void
  var chrome: GreetingIntegratedChrome = .standard(AppColors.priorityMedium)
  var usesLiveWeather: Bool = false

  private var weather: HomeHeroInsights.WeatherSnapshot { store.weatherSnapshot }
  private var accent: Color {
    usesLiveWeather || weather.isLive ? weather.tintAccent : AppColors.priorityMedium
  }

  var body: some View {
    let c = theme.colors
    let cardAccent: Color = {
      if case .tinted(let color) = chrome { return color }
      return AppColors.tagPurple
    }()

    greetingIntegratedCard(chrome: chrome, minHeight: 128) {
      HStack(alignment: .top, spacing: 10) {
        HomeGreetingNameBlock(
          store: store,
          metrics: metrics,
          subtitle: store.formattedLongDate,
          accent: cardAccent
        )

        VStack(alignment: .trailing, spacing: 6) {
          HomeGreetingWeatherArt(accent: accent, style: weather.style)

          VStack(alignment: .trailing, spacing: 2) {
            Text("\(weather.temperatureC)°C")
              .font(.system(size: 22, weight: .heavy))
              .foregroundStyle(c.textPrimary)
            Text(weather.condition)
              .font(.system(size: metrics.focusSubtitleSize, weight: .medium))
              .foregroundStyle(c.textSecondary)
          }

          HStack(spacing: 8) {
            Label("\(weather.windKmh) km/h", systemImage: "wind")
            Rectangle()
              .fill(c.textPrimary.opacity(c.isDark ? 0.1 : 0.08))
              .frame(width: 1, height: 10)
            Label("\(weather.humidityPercent)%", systemImage: "drop.fill")
          }
          .font(.system(size: 9.5, weight: .semibold))
          .foregroundStyle(c.textTertiary)
          .padding(.horizontal, 8)
          .padding(.vertical, 5)
          .background(c.textPrimary.opacity(c.isDark ? 0.06 : 0.05))
          .clipShape(Capsule())
        }
      }
    } footer: {
      HomeConceptIntegratedStatusFooter(
        isOverdue: isOverdue,
        statusLabel: store.statusLabel(overdueCount: store.overdueCount),
        onTap: isOverdue ? { HapticService.selection(); onOpenFilter(.overdue) } : nil
      )
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      "\(store.greetingPhrase) \(store.firstName). \(store.formattedLongDate). \(weather.temperatureC) graus, \(weather.condition). \(store.statusLabel(overdueCount: store.overdueCount))"
    )
  }
}

// MARK: - Layout helper

enum GreetingIntegratedChrome {
  case standard(Color)
  case tinted(Color)
}

@ViewBuilder
private func greetingIntegratedCard<Main: View, Footer: View>(
  chrome: GreetingIntegratedChrome,
  minHeight: CGFloat,
  @ViewBuilder main: @escaping () -> Main,
  @ViewBuilder footer: @escaping () -> Footer
) -> some View {
  let layout = VStack(alignment: .leading, spacing: 0) {
    main()
    footer()
  }
  .padding(.horizontal, 14)
  .padding(.top, 12)
  .padding(.bottom, 10)

  switch chrome {
  case .standard(let accent):
    HomeConceptCard(accent: accent, minHeight: minHeight, maxHeight: nil) { layout }
  case .tinted(let accent):
    HomeGreetingTintedCard(accent: accent, minHeight: minHeight, maxHeight: nil) { layout }
  }
}

struct HomeHeroGreetingWeatherPremiumCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  private var weather: HomeHeroInsights.WeatherSnapshot { store.weatherSnapshot }
  private var accent: Color { weather.tintAccent }

  var body: some View {
    let c = theme.colors

    greetingIntegratedCard(chrome: .tinted(accent), minHeight: 132) {
      HStack(alignment: .center, spacing: 14) {
        premiumGreetingBlock(colors: c)

        VStack(alignment: .trailing, spacing: 7) {
          HomeGreetingWeatherPremiumArt(accent: accent, style: weather.style)

          VStack(alignment: .trailing, spacing: 2) {
            Text("\(weather.temperatureC)°")
              .font(.system(size: 24, weight: .heavy))
              .foregroundStyle(c.textPrimary)
              .tracking(-0.5)
            Text(weather.condition)
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(c.textSecondary)
              .lineLimit(1)
              .minimumScaleFactor(0.85)
          }

          HStack(spacing: 6) {
            weatherStat(icon: "wind", value: "\(weather.windKmh)")
            weatherStatDivider
            weatherStat(icon: "drop.fill", value: "\(weather.humidityPercent)%")
          }
        }
        .layoutPriority(1)
      }
    } footer: {
      HomeConceptIntegratedStatusFooter(
        isOverdue: isOverdue,
        statusLabel: store.statusLabel(overdueCount: store.overdueCount),
        onTap: isOverdue ? { HapticService.selection(); onOpenFilter(.overdue) } : nil
      )
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      "\(store.greetingPhrase) \(store.firstName). \(store.formattedLongDate). \(weather.temperatureC) graus, \(weather.condition). Vento \(weather.windKmh) quilômetros por hora. Umidade \(weather.humidityPercent) por cento. \(store.statusLabel(overdueCount: store.overdueCount))"
    )
  }

  private func premiumGreetingBlock(colors c: AppThemeColors) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(store.greetingPhrase)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(c.accent.opacity(0.82))
      if !store.firstName.isEmpty {
        Text(store.firstName)
          .font(.system(size: 25, weight: .heavy))
          .foregroundStyle(c.textPrimary)
          .tracking(-0.35)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
      }
      Text(store.formattedLongDate)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(c.textSecondary)
        .lineLimit(2)
        .minimumScaleFactor(0.9)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func weatherStat(icon: String, value: String) -> some View {
    let c = theme.colors
    return HStack(spacing: 3) {
      Image(systemName: icon)
        .font(.system(size: 8, weight: .semibold))
      Text(value)
        .font(.system(size: 9.5, weight: .semibold))
    }
    .foregroundStyle(c.textSecondary)
  }

  private var weatherStatDivider: some View {
    let c = theme.colors
    return Rectangle()
      .fill(c.textPrimary.opacity(c.isDark ? 0.1 : 0.08))
      .frame(width: 1, height: 10)
  }
}

// MARK: - Tinted variants (fundo com cor do app)

struct HomeHeroGreetingProgressTintedCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  private var accent: Color { theme.colors.accent }

  var body: some View {
    HomeHeroGreetingProgressCard(
      store: store,
      metrics: metrics,
      isOverdue: isOverdue,
      onOpenFilter: onOpenFilter,
      chrome: .tinted(accent),
      progressAccent: AppColors.tagGreen
    )
  }
}

struct HomeHeroGreetingFocusTintedCard: View {
  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    HomeHeroGreetingFocusCard(
      store: store,
      metrics: metrics,
      isOverdue: isOverdue,
      onOpenFilter: onOpenFilter,
      chrome: .tinted(AppColors.tagPurple)
    )
  }
}

struct HomeHeroGreetingWeatherTintedCard: View {
  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    HomeHeroGreetingWeatherCard(
      store: store,
      metrics: metrics,
      isOverdue: isOverdue,
      onOpenFilter: onOpenFilter,
      chrome: .tinted(store.weatherSnapshot.tintAccent),
      usesLiveWeather: true
    )
  }
}

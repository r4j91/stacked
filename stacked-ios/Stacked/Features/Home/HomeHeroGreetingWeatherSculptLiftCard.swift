import SwiftUI

/// Clima escultura destaque — ícone em relevo maior como âncora visual; saudação e status à esquerda.
struct HomeHeroGreetingWeatherSculptLiftCard: View {
  enum Presentation {
    case card
    case open
  }

  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  let presentation: Presentation
  var onOpenFilter: (TaskFilterKind) -> Void

  private var weather: HomeHeroInsights.WeatherSnapshot { store.weatherSnapshot }
  private var isNight: Bool { store.timeOfDay == .night }
  private var accent: Color { weather.displayTintAccent(isNight: isNight) }

  private let cornerRadius: CGFloat = HomeHeroLayout.cornerRadius
  private let cardHeight: CGFloat = 204
  private let artSize: CGFloat = 108

  var body: some View {
    let c = theme.colors
    let verticalPadding: CGFloat = presentation == .open ? metrics.openVerticalPadding + 10 : 16

    HStack(alignment: .center, spacing: 14) {
      textColumn(colors: c)
        .frame(maxWidth: .infinity, alignment: .leading)

      artColumn(colors: c)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, verticalPadding)
    .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight, alignment: .center)
    .background {
      if presentation == .card {
        cardBackground(colors: c)
          .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
      }
    }
    .overlay {
      if presentation == .card {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .strokeBorder(c.textPrimary.opacity(0.09), lineWidth: 1)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHint(isOverdue ? "Abre tarefas atrasadas" : "")
  }

  @ViewBuilder
  private func cardBackground(colors c: AppThemeColors) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(c.surface)

      // Sheen suave no topo — full-bleed, sem caixa.
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              c.textPrimary.opacity(c.isDark ? 0.045 : 0.035),
              .clear,
            ],
            startPoint: .top,
            endPoint: .center
          )
        )

      // Bloom da cor do clima espalhado no card (sem frame truncado = sem costura vertical).
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(
          RadialGradient(
            colors: [
              accent.opacity(c.isDark ? 0.14 : 0.09),
              accent.opacity(c.isDark ? 0.05 : 0.03),
              .clear,
            ],
            center: UnitPoint(x: 0.86, y: 0.38),
            startRadius: 6,
            endRadius: 220
          )
        )
        .allowsHitTesting(false)
    }
  }

  private func textColumn(colors c: AppThemeColors) -> some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(store.greetingPhrase)
        .font(.system(size: metrics.phraseSize + 1, weight: .semibold))
        .foregroundStyle(HomeHeroWeatherChrome.greetingPhraseColor(colors: c))

      if !store.firstName.isEmpty {
        Text(store.firstName)
          .font(.system(size: 26, weight: .heavy))
          .foregroundStyle(c.textPrimary)
          .tracking(-0.4)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
      }

      Text(store.formattedLongDate)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(c.textSecondary)
        .lineLimit(2)
        .minimumScaleFactor(0.9)
        .fixedSize(horizontal: false, vertical: true)

      HStack(spacing: 8) {
        metaChip(icon: "wind", value: "\(weather.windKmh) km/h", colors: c)
        metaChip(icon: "drop.fill", value: "\(weather.humidityPercent)%", colors: c)
      }
      .padding(.top, 2)

      Spacer(minLength: 6)

      HomeHeroWeatherStatusIndicator(
        isOverdue: isOverdue,
        statusLabel: store.statusLabel(overdueCount: store.overdueCount),
        clearTone: accent,
        onOpenFilter: isOverdue ? { HapticService.selection(); onOpenFilter(.overdue) } : nil
      )
    }
  }

  private func artColumn(colors c: AppThemeColors) -> some View {
    VStack(alignment: .trailing, spacing: 8) {
      HomeWeatherSculptArt(
        style: weather.style,
        isNight: isNight,
        size: artSize
      )

      VStack(alignment: .trailing, spacing: 1) {
        Text("\(weather.temperatureC)°")
          .font(.system(size: 30, weight: .heavy))
          .foregroundStyle(c.textPrimary)
          .tracking(-0.8)

        Text(weather.displayCondition(isNight: isNight))
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(c.textSecondary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .frame(maxWidth: artSize, alignment: .trailing)
      }
    }
    .frame(width: artSize, alignment: .trailing)
  }

  private func metaChip(icon: String, value: String, colors c: AppThemeColors) -> some View {
    HStack(spacing: 3) {
      Image(systemName: icon)
        .font(.system(size: 9, weight: .semibold))
      Text(value)
        .font(.system(size: 10.5, weight: .semibold))
    }
    .foregroundStyle(c.textTertiary)
  }

  private var accessibilityLabel: String {
    let condition = weather.displayCondition(isNight: isNight)
    return "\(store.greetingPhrase) \(store.firstName). \(store.formattedLongDate). \(weather.temperatureC) graus, \(condition). Vento \(weather.windKmh) quilômetros por hora. Umidade \(weather.humidityPercent) por cento. \(store.statusLabel(overdueCount: store.overdueCount))"
  }
}

struct HomeHeroGreetingWeatherSculptLiftOpenCard: View {
  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    HomeHeroGreetingWeatherSculptLiftCard(
      store: store,
      metrics: metrics,
      isOverdue: isOverdue,
      presentation: .open,
      onOpenFilter: onOpenFilter
    )
  }
}

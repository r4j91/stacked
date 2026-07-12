import SwiftUI

/// Clima premium minimalista — ícone estilo !Weather, card escuro, pill integrado.
struct HomeHeroGreetingWeatherMinimalCard: View {
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

  private let cornerRadius: CGFloat = 16
  private let cardHeight: CGFloat = 184

  var body: some View {
    let c = theme.colors
    let verticalPadding: CGFloat = presentation == .open ? metrics.openVerticalPadding + 8 : 14

    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 14) {
        greetingBlock(colors: c)
          .frame(maxWidth: .infinity, alignment: .leading)

        weatherColumn(colors: c)
          .layoutPriority(1)
      }

      Spacer(minLength: 8)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, verticalPadding)
    .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight, alignment: .topLeading)
    .background { cardBackground(colors: c) }
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .strokeBorder(
          c.textPrimary.opacity(presentation == .card ? 0.08 : 0.05),
          lineWidth: 1
        )
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

      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              c.textPrimary.opacity(c.isDark ? 0.04 : 0.03),
              .clear,
            ],
            startPoint: .top,
            endPoint: .center
          )
        )

      if presentation == .card {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .fill(
            RadialGradient(
              colors: [weather.tintAccent.opacity(c.isDark ? 0.06 : 0.04), .clear],
              center: .topTrailing,
              startRadius: 4,
              endRadius: 140
            )
          )
      }
    }
  }

  private func greetingBlock(colors c: AppThemeColors) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(store.greetingPhrase)
        .font(.system(size: metrics.phraseSize, weight: .semibold))
        .foregroundStyle(HomeHeroWeatherChrome.greetingPhraseColor(colors: c))

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

      HomeHeroWeatherStatusIndicator(
        isOverdue: isOverdue,
        statusLabel: store.statusLabel(overdueCount: store.overdueCount),
        clearTone: weather.tintAccent,
        onOpenFilter: isOverdue ? { HapticService.selection(); onOpenFilter(.overdue) } : nil
      )
      .padding(.top, 2)
    }
  }

  private func weatherColumn(colors c: AppThemeColors) -> some View {
    VStack(alignment: .trailing, spacing: 8) {
      HomeWeatherMinimalArt(
        style: weather.style,
        isNight: store.timeOfDay == .night
      )

      VStack(alignment: .trailing, spacing: 2) {
        Text("\(weather.temperatureC)°")
          .font(.system(size: 26, weight: .heavy))
          .foregroundStyle(c.textPrimary)
          .tracking(-0.6)

        Text(weather.condition)
          .font(.system(size: 11.5, weight: .semibold))
          .foregroundStyle(c.textSecondary)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
      }

      HStack(spacing: 6) {
        weatherStat(icon: "wind", value: "\(weather.windKmh)", colors: c)
        weatherStatDivider(colors: c)
        weatherStat(icon: "drop.fill", value: "\(weather.humidityPercent)%", colors: c)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(c.surfaceVariant.opacity(0.85))
      .clipShape(Capsule())
      .overlay {
        Capsule().strokeBorder(c.textPrimary.opacity(c.isDark ? 0.06 : 0.05), lineWidth: 1)
      }
    }
    .frame(minWidth: 88, alignment: .trailing)
  }

  private func weatherStat(icon: String, value: String, colors c: AppThemeColors) -> some View {
    HStack(spacing: 3) {
      Image(systemName: icon)
        .font(.system(size: 8, weight: .semibold))
      Text(value)
        .font(.system(size: 9.5, weight: .semibold))
    }
    .foregroundStyle(c.textTertiary)
  }

  private func weatherStatDivider(colors c: AppThemeColors) -> some View {
    Rectangle()
      .fill(c.textPrimary.opacity(c.isDark ? 0.08 : 0.06))
      .frame(width: 1, height: 10)
  }

  private var accessibilityLabel: String {
    "\(store.greetingPhrase) \(store.firstName). \(store.formattedLongDate). \(weather.temperatureC) graus, \(weather.condition). Vento \(weather.windKmh) quilômetros por hora. Umidade \(weather.humidityPercent) por cento. \(store.statusLabel(overdueCount: store.overdueCount))"
  }
}

struct HomeHeroGreetingWeatherMinimalOpenCard: View {
  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    HomeHeroGreetingWeatherMinimalCard(
      store: store,
      metrics: metrics,
      isOverdue: isOverdue,
      presentation: .open,
      onOpenFilter: onOpenFilter
    )
  }
}

import SwiftUI

/// Clima premium com cena ilustrada (estilo !Weather / Jornada diária).
struct HomeHeroGreetingWeatherSceneCard: View {
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
  private var accent: Color { weather.tintAccent }
  private var sceneImageName: String {
    if weather.style == .sunny, store.timeOfDay == .night {
      return HomeHeroWeatherSceneImages.assetName(for: .clear)
    }
    return HomeHeroWeatherSceneImages.assetName(for: weather.style)
  }

  private let cornerRadius: CGFloat = HomeHeroLayout.cornerRadius
  private let cardHeight: CGFloat = HomeHeroLayout.weatherCardHeight

  var body: some View {
    let c = theme.colors
    let borderOpacity: CGFloat = presentation == .card ? 0.16 : 0.12
    let verticalPadding: CGFloat = presentation == .open ? metrics.openVerticalPadding + 8 : 14

    ZStack(alignment: .leading) {
      Image(sceneImageName)
        .resizable()
        .scaledToFill()
        .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight)
        .clipped()
        .accessibilityHidden(true)

      LinearGradient(
        colors: [
          c.background.opacity(0.97),
          c.background.opacity(0.82),
          c.background.opacity(0.38),
          .clear,
        ],
        startPoint: .leading,
        endPoint: .trailing
      )

      LinearGradient(
        colors: [.clear, c.background.opacity(0.18), c.background.opacity(0.52)],
        startPoint: .center,
        endPoint: .bottom
      )

      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .top, spacing: 12) {
          greetingBlock(colors: c)
            .frame(maxWidth: .infinity, alignment: .leading)

          weatherPanel(colors: c)
            .layoutPriority(1)
        }

        Spacer(minLength: 8)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, verticalPadding)
    }
    .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight)
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .strokeBorder(accent.opacity(borderOpacity), lineWidth: 1)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHint(isOverdue ? "Abre tarefas atrasadas" : "")
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
        clearTone: accent,
        onOpenFilter: isOverdue ? { HapticService.selection(); onOpenFilter(.overdue) } : nil
      )
      .padding(.top, 2)
    }
  }

  private func weatherPanel(colors c: AppThemeColors) -> some View {
    VStack(alignment: .trailing, spacing: 6) {
      Text("\(weather.temperatureC)°")
        .font(.system(size: 28, weight: .heavy))
        .foregroundStyle(c.textPrimary)
        .tracking(-0.8)

      Text(weather.condition)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(c.textSecondary)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .multilineTextAlignment(.trailing)

      HStack(spacing: 6) {
        weatherStat(icon: "wind", value: "\(weather.windKmh)", colors: c)
        weatherStatDivider(colors: c)
        weatherStat(icon: "drop.fill", value: "\(weather.humidityPercent)%", colors: c)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 5)
      .background(c.surface.opacity(0.55))
      .clipShape(Capsule())
      .overlay {
        Capsule().strokeBorder(c.textPrimary.opacity(c.isDark ? 0.08 : 0.06), lineWidth: 1)
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
    .foregroundStyle(c.textSecondary)
  }

  private func weatherStatDivider(colors c: AppThemeColors) -> some View {
    Rectangle()
      .fill(c.textPrimary.opacity(c.isDark ? 0.1 : 0.08))
      .frame(width: 1, height: 10)
  }

  private var accessibilityLabel: String {
    "\(store.greetingPhrase) \(store.firstName). \(store.formattedLongDate). \(weather.temperatureC) graus, \(weather.condition). Vento \(weather.windKmh) quilômetros por hora. Umidade \(weather.humidityPercent) por cento. \(store.statusLabel(overdueCount: store.overdueCount))"
  }
}

struct HomeHeroGreetingWeatherSceneOpenCard: View {
  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    HomeHeroGreetingWeatherSceneCard(
      store: store,
      metrics: metrics,
      isOverdue: isOverdue,
      presentation: .open,
      onOpenFilter: onOpenFilter
    )
  }
}

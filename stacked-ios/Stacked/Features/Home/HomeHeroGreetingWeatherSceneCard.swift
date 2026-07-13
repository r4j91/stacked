import SwiftUI

/// Clima premium com cena ilustrada (estilo !Weather / Jornada diária).
struct HomeHeroGreetingWeatherSceneCard: View {
  enum Presentation {
    case card
    case open
  }

  enum ScenePalette {
    case color
    case monochrome
  }

  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  let presentation: Presentation
  var palette: ScenePalette = .color
  var onOpenFilter: (TaskFilterKind) -> Void

  private var weather: HomeHeroInsights.WeatherSnapshot { store.weatherSnapshot }
  private var isNight: Bool { store.timeOfDay == .night }
  private var accent: Color {
    palette == .monochrome
      ? theme.colors.textSecondary
      : weather.displayTintAccent(isNight: isNight)
  }
  private var sceneImageName: String {
    HomeHeroWeatherSceneImages.assetName(for: weather.resolvedStyle(isNight: isNight))
  }

  private let cornerRadius: CGFloat = HomeHeroLayout.cornerRadius
  private let cardHeight: CGFloat = HomeHeroLayout.weatherCardHeight

  var body: some View {
    let c = theme.colors
    let borderOpacity: CGFloat = presentation == .card ? 0.16 : 0.12
    let verticalPadding: CGFloat = presentation == .open ? metrics.openVerticalPadding + 8 : 14

    ZStack(alignment: .leading) {
      sceneBackground(colors: c)

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
        colors: [
          c.background.opacity(palette == .monochrome ? 0.62 : 0.48),
          c.background.opacity(palette == .monochrome ? 0.28 : 0.18),
          .clear,
        ],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
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

  @ViewBuilder
  private func sceneBackground(colors c: AppThemeColors) -> some View {
    let image = Image(sceneImageName)
      .resizable()
      .scaledToFill()
      .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight)
      .clipped()
      .accessibilityHidden(true)

    if palette == .monochrome {
      image
        .saturation(0)
        .contrast(c.isDark ? 1.08 : 1.04)
    } else {
      image
    }
  }

  private func greetingBlock(colors c: AppThemeColors) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(store.greetingPhrase)
        .font(.system(size: metrics.phraseSize, weight: .semibold))
        .foregroundStyle(greetingPhraseColor(colors: c))

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

  private func greetingPhraseColor(colors c: AppThemeColors) -> Color {
    palette == .monochrome
      ? c.textSecondary.opacity(c.isDark ? 0.9 : 0.82)
      : HomeHeroWeatherChrome.greetingPhraseColor(colors: c)
  }

  private func weatherPanel(colors c: AppThemeColors) -> some View {
    VStack(alignment: .trailing, spacing: 6) {
      Text("\(weather.temperatureC)°")
        .font(.system(size: 26, weight: .heavy))
        .foregroundStyle(c.textPrimary)
        .tracking(-0.7)

      Text(weather.displayCondition(isNight: isNight))
        .font(.system(size: 11.5, weight: .semibold))
        .foregroundStyle(c.textSecondary)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .multilineTextAlignment(.trailing)

      HStack(spacing: 6) {
        weatherStat(icon: "wind", value: "\(weather.windKmh)", colors: c)
        weatherStatDivider(colors: c)
        weatherStat(icon: "drop.fill", value: "\(weather.humidityPercent)%", colors: c)
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(c.surface.opacity(c.isDark ? 0.9 : 0.94))
    }
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(c.textPrimary.opacity(c.isDark ? 0.1 : 0.08), lineWidth: 1)
    }
    .shadow(color: c.background.opacity(c.isDark ? 0.45 : 0.18), radius: 8, y: 3)
    .frame(minWidth: 92, alignment: .trailing)
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
    let condition = weather.displayCondition(isNight: isNight)
    return "\(store.greetingPhrase) \(store.firstName). \(store.formattedLongDate). \(weather.temperatureC) graus, \(condition). Vento \(weather.windKmh) quilômetros por hora. Umidade \(weather.humidityPercent) por cento. \(store.statusLabel(overdueCount: store.overdueCount))"
  }
}

struct HomeHeroGreetingWeatherSceneOpenCard: View {
  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var palette: HomeHeroGreetingWeatherSceneCard.ScenePalette = .color
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    HomeHeroGreetingWeatherSceneCard(
      store: store,
      metrics: metrics,
      isOverdue: isOverdue,
      presentation: .open,
      palette: palette,
      onOpenFilter: onOpenFilter
    )
  }
}

import SwiftUI

/// Hero Jornada — ilustração editorial com estados claro/atrasado.
struct HomeHeroJourneyCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let art: HomeHeroJourneyArt
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  private var weather: HomeHeroInsights.WeatherSnapshot { store.weatherSnapshot }

  private var factualSubtitle: String {
    if art.showsWeather {
      return weather.condition
    }
    return store.formattedLongDate
  }

  private var imageName: String {
    isOverdue ? art.overdueAssetName() : art.clearAssetName()
  }

  var body: some View {
    let c = theme.colors

    ZStack(alignment: .leading) {
      Image(imageName)
        .resizable()
        .interpolation(.high)
        .antialiased(true)
        .scaledToFill()
        .frame(maxWidth: .infinity, minHeight: HomeHeroLayout.sceneCardHeight, maxHeight: HomeHeroLayout.sceneCardHeight)
        .clipped()
        .accessibilityHidden(true)

      LinearGradient(
        colors: [
          c.background.opacity(isOverdue ? 0.98 : 0.97),
          c.background.opacity(isOverdue ? 0.9 : 0.82),
          c.background.opacity(0.4),
          .clear,
        ],
        startPoint: .leading,
        endPoint: .trailing
      )

      LinearGradient(
        colors: [.clear, c.background.opacity(0.25)],
        startPoint: .top,
        endPoint: .bottom
      )

      VStack(alignment: .leading, spacing: 0) {
        greetingBlock(colors: c)
        Spacer(minLength: AppSpacing.sm + 2)
        HomeHeroSceneStatusFooter.pill(
          colors: c,
          isOverdue: isOverdue,
          statusLabel: store.statusLabel(overdueCount: store.overdueCount),
          onOpenFilter: isOverdue ? { HapticService.selection(); onOpenFilter(.overdue) } : nil
        )
      }
      .padding(.horizontal, HomeHeroLayout.scenePaddingH)
      .padding(.vertical, HomeHeroLayout.scenePaddingV)
    }
    .frame(maxWidth: .infinity, minHeight: HomeHeroLayout.sceneCardHeight, maxHeight: HomeHeroLayout.sceneCardHeight)
    .clipShape(RoundedRectangle(cornerRadius: HomeHeroLayout.cornerRadius, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: HomeHeroLayout.cornerRadius, style: .continuous)
        .strokeBorder(
          (isOverdue ? AppColors.overdue : AppColors.tagGreen).opacity(isOverdue ? 0.14 : 0.14),
          lineWidth: 1
        )
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHint(isOverdue ? "Abre tarefas atrasadas" : "")
  }

  @ViewBuilder
  private func greetingBlock(colors c: AppThemeColors) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(store.greetingPhrase)
        .font(.system(size: metrics.phraseSize, weight: .semibold))
        .foregroundStyle(HomeHeroWeatherChrome.greetingPhraseColor(colors: c))

      if !store.firstName.isEmpty {
        Text(store.firstName)
          .font(.system(size: metrics.nameSize + 3, weight: .heavy))
          .foregroundStyle(c.textPrimary)
          .tracking(-0.35)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
      }

      if art.showsWeather {
        weatherLine(colors: c)
      } else {
        Text(factualSubtitle)
          .font(.system(size: metrics.focusSubtitleSize, weight: .medium))
          .foregroundStyle(c.textSecondary)
          .lineLimit(2)
          .minimumScaleFactor(0.9)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: isOverdue ? 210 : nil, alignment: .leading)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func weatherLine(colors c: AppThemeColors) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("\(weather.temperatureC)°")
        .font(.system(size: 22, weight: .heavy))
        .foregroundStyle(c.textPrimary)
        .tracking(-0.4)

      Text(factualSubtitle)
        .font(.system(size: metrics.focusSubtitleSize, weight: .medium))
        .foregroundStyle(c.textSecondary)
        .lineLimit(2)
        .minimumScaleFactor(0.9)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: isOverdue ? 200 : 220, alignment: .leading)
  }

  private var accessibilityLabel: String {
    let name = store.firstName.isEmpty ? "" : " \(store.firstName)."
    if art.showsWeather {
      return "\(store.greetingPhrase)\(name) \(weather.temperatureC) graus, \(weather.condition). \(store.statusLabel(overdueCount: store.overdueCount))"
    }
    return "\(store.greetingPhrase)\(name) \(factualSubtitle). \(store.statusLabel(overdueCount: store.overdueCount))"
  }
}

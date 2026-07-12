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

  private let cardHeight: CGFloat = 172
  private let cornerRadius: CGFloat = 16
  private let overdueAccent = Color(hex: 0x7A5BA8)
  private let overdueAccentDeep = Color(hex: 0x4A3568)

  private var narrativeSubtitle: String {
    if isOverdue {
      return "Pendências no caminho — hora de retomar."
    }
    return "Siga em frente, você está no caminho certo."
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
        .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight)
        .clipped()
        .accessibilityHidden(true)

      LinearGradient(
        colors: [
          c.background.opacity(isOverdue ? 0.98 : 0.97),
          c.background.opacity(isOverdue ? 0.88 : 0.82),
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

      if isOverdue {
        LinearGradient(
          colors: [
            overdueAccentDeep.opacity(0.04),
            overdueAccent.opacity(0.06),
            .clear,
          ],
          startPoint: .bottomTrailing,
          endPoint: .topLeading
        )
        .blendMode(.plusLighter)
      }

      VStack(alignment: .leading, spacing: 0) {
        greetingBlock(colors: c)
        Spacer(minLength: 10)
        HomeHeroSceneStatusFooter.pill(
          colors: c,
          isOverdue: isOverdue,
          overdueCount: store.overdueCount,
          onOpenFilter: isOverdue ? { HapticService.selection(); onOpenFilter(.overdue) } : nil
        )
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
    }
    .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight)
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .strokeBorder(
          (isOverdue ? overdueAccent : AppColors.tagGreen).opacity(isOverdue ? 0.1 : 0.14),
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
        .foregroundStyle(AppColors.tagPurple.opacity(0.82))

      if !store.firstName.isEmpty {
        Text(store.firstName)
          .font(.system(size: 25, weight: .heavy))
          .foregroundStyle(c.textPrimary)
          .tracking(-0.35)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
      }

      if art.showsWeather {
        weatherLine(colors: c)
      } else {
        Text(narrativeSubtitle)
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

      Text(weather.condition)
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
    return "\(store.greetingPhrase)\(name) \(narrativeSubtitle). \(store.statusLabel(overdueCount: store.overdueCount))"
  }
}

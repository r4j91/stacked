import SwiftUI

/// Hero Aurora — arte abstrata premium estilo conceito, clima ao vivo.
struct HomeHeroAuroraCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let art: HomeHeroAuroraArt
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  private var weather: HomeHeroInsights.WeatherSnapshot { store.weatherSnapshot }

  private let cardHeight: CGFloat = 172
  private let cornerRadius: CGFloat = 16

  private var overdueAccent: Color { Color(hex: art.overdueAccent) }
  private var overdueAccentDeep: Color { Color(hex: art.overdueAccentDeep) }

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
          c.background.opacity(isOverdue ? 0.98 : 0.96),
          c.background.opacity(isOverdue ? 0.9 : 0.78),
          c.background.opacity(0.35),
          .clear,
        ],
        startPoint: .leading,
        endPoint: .trailing
      )

      LinearGradient(
        colors: [.clear, c.background.opacity(0.2)],
        startPoint: .top,
        endPoint: .bottom
      )

      if isOverdue {
        LinearGradient(
          colors: [
            overdueAccentDeep.opacity(0.04),
            overdueAccent.opacity(0.055),
            .clear,
          ],
          startPoint: .topTrailing,
          endPoint: .bottomLeading
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

      if isOverdue {
        VStack {
          HStack {
            Spacer()
            overdueBadge
          }
          Spacer()
        }
        .padding(12)
        .allowsHitTesting(false)
      }
    }
    .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight)
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .strokeBorder(
          (isOverdue ? overdueAccent : AppColors.tagGreen).opacity(isOverdue ? 0.12 : 0.14),
          lineWidth: 1
        )
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHint(isOverdue ? "Abre tarefas atrasadas" : "")
  }

  private var overdueBadge: some View {
    ZStack {
      Circle()
        .fill(Color(hex: 0xEF5A5F).opacity(0.12))
        .frame(width: 30, height: 30)
        .blur(radius: 6)

      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color(hex: 0xEF5A5F).opacity(0.75))
        .shadow(color: Color(hex: 0xEF5A5F).opacity(0.2), radius: 3)
    }
  }

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

      weatherLine(colors: c)
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
    return "\(store.greetingPhrase)\(name) \(weather.temperatureC) graus, \(weather.condition). \(store.statusLabel(overdueCount: store.overdueCount))"
  }
}

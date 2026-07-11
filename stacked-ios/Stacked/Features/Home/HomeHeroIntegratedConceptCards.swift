import SwiftUI

// Versões integradas de Mensagem, Foco do dia e Sequência (status no rodapé do card).

struct HomeHeroMotivationIntegratedCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    let c = theme.colors
    let accent = c.accent
    let content = store.motivationContent

    integratedCard(accent: accent, minHeight: 118) {
      HStack(alignment: .top, spacing: 8) {
        VStack(alignment: .leading, spacing: 5) {
          Text("\u{201C}")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(accent.opacity(0.38))
            .offset(y: -3)
          Text(content.quote)
            .font(.system(size: metrics.focusTitleSize, weight: .semibold))
            .foregroundStyle(c.textPrimary)
            .lineLimit(2)
            .minimumScaleFactor(0.9)
          Text(content.footnote)
            .font(.system(size: metrics.focusSubtitleSize, weight: .medium))
            .foregroundStyle(c.textSecondary)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        HomeMotivationMountainArt(accent: accent)
          .scaleEffect(0.92)
          .offset(x: 2, y: 0)
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
      isOverdue
        ? "\(content.quote). \(store.statusLabel(overdueCount: store.overdueCount))"
        : "\(content.quote). Tudo em dia"
    )
  }
}

struct HomeHeroFocusDayIntegratedCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    let c = theme.colors
    let accent = AppColors.tagPurple
    let title = store.focusTaskTitle ?? "Nada pendente para hoje"
    let time = store.focusTaskTime

    integratedCard(accent: accent, minHeight: 118) {
      HStack(alignment: .center, spacing: 8) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Foco do dia")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(accent.opacity(0.62))
          Text(title)
            .font(.system(size: metrics.focusTitleSize, weight: .bold))
            .foregroundStyle(c.textPrimary)
            .lineLimit(2)
            .minimumScaleFactor(0.9)
          if let time, !time.isEmpty {
            HStack(spacing: 4) {
              Image(systemName: "clock")
                .font(.system(size: 11, weight: .semibold))
              Text(time)
                .font(.system(size: metrics.focusSubtitleSize, weight: .medium))
            }
            .foregroundStyle(c.textSecondary)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        HomeFocusTargetArt(accent: accent)
          .scaleEffect(0.9)
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
      time.map { "Foco do dia: \(title), \($0). \(store.statusLabel(overdueCount: store.overdueCount))" }
        ?? "Foco do dia: \(title). \(store.statusLabel(overdueCount: store.overdueCount))"
    )
  }
}

struct HomeHeroStreakIntegratedCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    let c = theme.colors
    let accent = c.accent
    let days = store.completionStreak

    integratedCard(accent: accent, minHeight: 128) {
      VStack(alignment: .leading, spacing: 7) {
        HStack(alignment: .top, spacing: 10) {
          HomeStreakFlameArt(accent: accent)
          VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
              Text("\(days)")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(c.textPrimary)
              Text(days == 1 ? "dia seguido" : "dias seguidos")
                .font(.system(size: metrics.focusSubtitleSize, weight: .semibold))
                .foregroundStyle(c.textSecondary)
            }
            Text(days > 0 ? "Constância conta." : "Conclua uma tarefa para começar.")
              .font(.system(size: metrics.focusSubtitleSize))
              .foregroundStyle(c.textTertiary)
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        HomeStreakWeekTracker(
          completed: store.streakWeekCompleted,
          accent: accent,
          labelColor: c.textTertiary,
          emptyDotColor: c.textPrimary.opacity(c.isDark ? 0.07 : 0.06)
        )
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
      days == 1
        ? "1 dia seguido. \(store.statusLabel(overdueCount: store.overdueCount))"
        : "\(days) dias seguidos. \(store.statusLabel(overdueCount: store.overdueCount))"
    )
  }
}

struct HomeHeroStreakOpenCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    let c = theme.colors
    let accent = c.accent
    let days = store.completionStreak

    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .top, spacing: 12) {
          HomeStreakFlameArt(accent: accent)
            .scaleEffect(1.04)

          VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
              Text("\(days)")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(c.textPrimary)
              Text(days == 1 ? "dia seguido" : "dias seguidos")
                .font(.system(size: metrics.focusSubtitleSize, weight: .semibold))
                .foregroundStyle(c.textSecondary)
            }
            Text(days > 0 ? "Constância conta." : "Conclua uma tarefa para começar.")
              .font(.system(size: metrics.focusSubtitleSize))
              .foregroundStyle(c.textTertiary)
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        HomeStreakWeekTracker(
          completed: store.streakWeekCompleted,
          accent: accent,
          labelColor: c.textTertiary,
          emptyDotColor: c.textPrimary.opacity(c.isDark ? 0.08 : 0.06)
        )
      }
      .padding(.vertical, metrics.openVerticalPadding)

      HomeConceptIntegratedStatusFooter(
        isOverdue: isOverdue,
        statusLabel: store.statusLabel(overdueCount: store.overdueCount),
        presentation: .open,
        onTap: isOverdue ? { HapticService.selection(); onOpenFilter(.overdue) } : nil
      )
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      days == 1
        ? "1 dia seguido. \(store.statusLabel(overdueCount: store.overdueCount))"
        : "\(days) dias seguidos. \(store.statusLabel(overdueCount: store.overdueCount))"
    )
  }
}

// MARK: - Layout helper

@ViewBuilder
private func integratedCard<Main: View, Footer: View>(
  accent: Color,
  minHeight: CGFloat,
  @ViewBuilder main: @escaping () -> Main,
  @ViewBuilder footer: @escaping () -> Footer
) -> some View {
  HomeConceptCard(accent: accent, minHeight: minHeight, maxHeight: nil) {
    VStack(alignment: .leading, spacing: 0) {
      main()
      footer()
    }
    .padding(.horizontal, 14)
    .padding(.top, 12)
    .padding(.bottom, 10)
  }
}

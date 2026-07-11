import SwiftUI

// Cards unificados (status + conteúdo no mesmo bloco).

struct HomeHeroPanelCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    let c = theme.colors
    let accent = isOverdue ? AppColors.overdue : AppColors.tagGreen
    let card = HomeConceptCard(accent: accent, minHeight: 108, maxHeight: nil) {
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .top) {
          Text("Foco do dia")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(AppColors.tagPurple.opacity(0.62))
          Spacer(minLength: 8)
          HomeConceptStatusChip(isOverdue: isOverdue, overdueCount: store.overdueCount)
        }

        Text(store.panelPrimaryTitle)
          .font(.system(size: metrics.focusTitleSize, weight: .bold))
          .foregroundStyle(c.textPrimary)
          .lineLimit(2)
          .minimumScaleFactor(0.9)
          .padding(.top, 6)

        if let time = store.panelPrimaryTime, !time.isEmpty {
          HStack(spacing: 4) {
            Image(systemName: "clock")
              .font(.system(size: 11, weight: .semibold))
            Text(time)
              .font(.system(size: metrics.focusSubtitleSize, weight: .medium))
          }
          .foregroundStyle(c.textSecondary)
          .padding(.top, 3)
        }

        HStack(spacing: 8) {
          Text("Hoje: \(store.todayPending)")
            .foregroundStyle(isOverdue ? AppColors.overdue.opacity(0.8) : c.textTertiary)
          Text("·")
            .foregroundStyle(c.textTertiary.opacity(0.5))
          Text("Em breve: \(store.upcomingCount)")
            .foregroundStyle(c.textSecondary)
          Spacer(minLength: 0)
          if isOverdue {
            DisclosureChevron(color: c.textTertiary)
          }
        }
        .font(.system(size: 11, weight: .medium))
        .padding(.top, 10)
        .overlay(alignment: .top) {
          Rectangle()
            .fill(c.textPrimary.opacity(c.isDark ? 0.06 : 0.05))
            .frame(height: 1)
        }
      }
      .padding(.horizontal, metrics.cardPaddingH)
      .padding(.vertical, metrics.cardPaddingV)
    }

    if isOverdue {
      Button {
        HapticService.selection()
        onOpenFilter(.overdue)
      } label: { card }
        .buttonStyle(.plain)
        .accessibilityLabel(store.statusLabel(overdueCount: store.overdueCount))
        .accessibilityHint("Abre tarefas atrasadas")
    } else {
      card
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Foco do dia. Tudo em dia. Hoje: \(store.todayPending). Em breve: \(store.upcomingCount)")
    }
  }
}

struct HomeHeroCompassCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    let c = theme.colors
    let accent = isOverdue ? AppColors.overdue : AppColors.tagGreen
    let statusColor = isOverdue ? AppColors.overdue.opacity(0.9) : AppColors.tagGreen.opacity(0.88)
    let detail = compassDetail

    let card = HomeConceptCard(accent: accent, minHeight: 100, maxHeight: 100) {
      HStack(alignment: .center, spacing: 10) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Norte de hoje")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(c.textTertiary)
          Text(isOverdue ? store.statusLabel(overdueCount: store.overdueCount) : "Tudo em dia")
            .font(.system(size: metrics.focusTitleSize, weight: .bold))
            .foregroundStyle(statusColor)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
          Text(detail)
            .font(.system(size: metrics.focusSubtitleSize, weight: .medium))
            .foregroundStyle(c.textSecondary)
            .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        HomeFocusTargetArt(accent: accent)
          .scaleEffect(0.92)
      }
      .padding(.horizontal, metrics.cardPaddingH)
      .padding(.vertical, metrics.cardPaddingV)
    }

    if isOverdue {
      Button {
        HapticService.selection()
        onOpenFilter(.overdue)
      } label: { card }
        .buttonStyle(.plain)
        .accessibilityLabel("\(store.statusLabel(overdueCount: store.overdueCount)). \(detail)")
        .accessibilityHint("Abre tarefas atrasadas")
    } else {
      card
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tudo em dia. \(detail)")
    }
  }

  private var compassDetail: String {
    if isOverdue {
      return store.primaryOverdueTitle ?? "Toque para ver"
    }
    if store.upcomingCount > 0 {
      return "\(store.upcomingCount) tarefas em breve · nada para hoje"
    }
    return "Nada pendente para hoje"
  }
}

struct HomeHeroQueueCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    let c = theme.colors
    let accent = isOverdue ? AppColors.overdue : theme.colors.accent
    let lines = store.queueLines

    let card = HomeConceptCard(accent: accent, minHeight: 108, maxHeight: nil) {
      VStack(alignment: .leading, spacing: 0) {
        Text("Sua fila")
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(c.textTertiary)
          .padding(.bottom, 8)

        if lines.isEmpty {
          queueRow(
            title: "Nada pendente para hoje",
            scope: nil,
            colors: c
          )
        } else {
          ForEach(lines) { line in
            if line.id != lines.first?.id {
              Divider().opacity(0.06)
            }
            queueRow(title: line.title, scope: line.scope, colors: c)
          }
        }

        if store.upcomingCount > 0 {
          Text("+\(store.upcomingCount) em breve")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(c.textTertiary)
            .padding(.top, 8)
            .overlay(alignment: .top) {
              if !lines.isEmpty {
                Rectangle()
                  .fill(c.textPrimary.opacity(c.isDark ? 0.06 : 0.05))
                  .frame(height: 1)
              }
            }
        }
      }
      .padding(.horizontal, metrics.cardPaddingH)
      .padding(.vertical, metrics.cardPaddingV)
    }

    if isOverdue {
      Button {
        HapticService.selection()
        onOpenFilter(.overdue)
      } label: { card }
        .buttonStyle(.plain)
        .accessibilityLabel("Sua fila. \(store.statusLabel(overdueCount: store.overdueCount))")
        .accessibilityHint("Abre tarefas atrasadas")
    } else {
      card.accessibilityLabel("Sua fila. Nada pendente para hoje")
    }
  }

  @ViewBuilder
  private func queueRow(
    title: String,
    scope: HomeHeroInsights.QueueLine.Scope?,
    colors: AppThemeColors
  ) -> some View {
    HStack(spacing: 8) {
      Circle()
        .fill(dotColor(for: scope))
        .frame(width: 6, height: 6)
      Text(title)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(colors.textPrimary)
        .lineLimit(1)
      Spacer(minLength: 4)
      if let scope {
        Text(scope == .overdue ? "atrasada" : "hoje")
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(scope == .overdue ? AppColors.overdue.opacity(0.75) : colors.accent.opacity(0.75))
      }
    }
    .padding(.vertical, 4)
  }

  private func dotColor(for scope: HomeHeroInsights.QueueLine.Scope?) -> Color {
    switch scope {
    case .overdue: AppColors.overdue.opacity(0.85)
    case .today: theme.colors.accent.opacity(0.7)
    case nil: AppColors.textTertiary.opacity(0.55)
    }
  }
}

struct HomeHeroThermometerCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    let c = theme.colors
    let accent = isOverdue ? AppColors.overdue : AppColors.tagGreen
    let overdueNum = store.overdueCount
    let todayNum = store.todayPending
    let upcomingNum = store.upcomingCount

    let card = HomeConceptCard(accent: accent, minHeight: 108, maxHeight: nil) {
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          metricColumn(
            value: overdueNum,
            label: "atrasadas",
            emphasized: isOverdue,
            hot: true,
            colors: c
          )
          metricColumn(
            value: todayNum,
            label: "hoje",
            emphasized: !isOverdue,
            hot: false,
            colors: c
          )
          metricColumn(
            value: upcomingNum,
            label: "em breve",
            emphasized: false,
            hot: false,
            colors: c
          )
        }
        .frame(maxWidth: .infinity)

        Text(
          isOverdue
            ? (store.overdueCount == 1 ? "1 precisa de atenção" : "\(store.overdueCount) precisam de atenção")
            : "Tudo sob controle"
        )
          .font(.system(size: metrics.focusSubtitleSize, weight: .semibold))
          .foregroundStyle(isOverdue ? AppColors.overdue.opacity(0.85) : AppColors.tagGreen.opacity(0.8))
          .padding(.top, 10)
          .overlay(alignment: .top) {
            Rectangle()
              .fill(c.textPrimary.opacity(c.isDark ? 0.06 : 0.05))
              .frame(height: 1)
          }
      }
      .padding(.horizontal, metrics.cardPaddingH)
      .padding(.vertical, metrics.cardPaddingV)
    }

    if isOverdue {
      Button {
        HapticService.selection()
        onOpenFilter(.overdue)
      } label: { card }
        .buttonStyle(.plain)
        .accessibilityLabel("\(overdueNum) atrasadas, \(todayNum) hoje, \(upcomingNum) em breve")
        .accessibilityHint("Abre tarefas atrasadas")
    } else {
      card.accessibilityLabel("Tudo sob controle. \(todayNum) hoje, \(upcomingNum) em breve")
    }
  }

  @ViewBuilder
  private func metricColumn(
    value: Int,
    label: String,
    emphasized: Bool,
    hot: Bool,
    colors: AppThemeColors
  ) -> some View {
    VStack(spacing: 4) {
      Text("\(value)")
        .font(.system(size: emphasized ? 22 : 18, weight: emphasized ? .heavy : .bold))
        .foregroundStyle(numberColor(emphasized: emphasized, hot: hot, colors: colors))
      Text(label)
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(colors.textTertiary)
    }
    .frame(maxWidth: .infinity)
  }

  private func numberColor(emphasized: Bool, hot: Bool, colors: AppThemeColors) -> Color {
    if emphasized && hot { return AppColors.overdue.opacity(0.95) }
    if emphasized { return AppColors.tagGreen.opacity(0.9) }
    return colors.textTertiary
  }
}

struct HomeHeroRhythmCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool

  var body: some View {
    let c = theme.colors
    let accent = theme.colors.accent
    let days = store.completedDaysThisWeek

    HomeConceptCard(accent: accent, minHeight: 100, maxHeight: 100) {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("Esta semana")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(c.textTertiary)
          Spacer(minLength: 8)
          if isOverdue {
            HomeConceptStatusChip(isOverdue: true, overdueCount: store.overdueCount)
          }
        }

        HomeStreakWeekTracker(
          completed: store.streakWeekCompleted,
          accent: accent,
          labelColor: c.textTertiary,
          emptyDotColor: c.textPrimary.opacity(c.isDark ? 0.07 : 0.06)
        )

        Text(days == 1 ? "1 dia com conclusão" : "\(days) dias com conclusão")
          .font(.system(size: metrics.focusSubtitleSize, weight: .semibold))
          .foregroundStyle(c.textSecondary)
          .lineLimit(1)
      }
      .padding(.horizontal, metrics.cardPaddingH)
      .padding(.vertical, metrics.cardPaddingV)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      days == 1 ? "Esta semana, 1 dia com conclusão" : "Esta semana, \(days) dias com conclusão"
    )
  }
}

struct HomeHeroNextStepCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    let c = theme.colors
    let accent = isOverdue ? AppColors.overdue : theme.colors.accent

    let card = HomeConceptCard(accent: accent, minHeight: 100, maxHeight: 100) {
      HStack(alignment: .center, spacing: 10) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Próximo")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(accent.opacity(0.7))
          Text(store.nextStepTitle)
            .font(.system(size: metrics.focusTitleSize, weight: .bold))
            .foregroundStyle(c.textPrimary)
            .lineLimit(2)
            .minimumScaleFactor(0.9)
          if !isOverdue, store.upcomingCount > 0 {
            Text("\(store.upcomingCount) tarefas em breve")
              .font(.system(size: 11, weight: .medium))
              .foregroundStyle(c.textSecondary)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        DisclosureChevron(color: isOverdue ? AppColors.overdue.opacity(0.7) : c.textTertiary)
      }
      .padding(.horizontal, metrics.cardPaddingH)
      .padding(.vertical, metrics.cardPaddingV)
    }

    Button {
      HapticService.selection()
      onOpenFilter(isOverdue ? .overdue : .today)
    } label: { card }
      .buttonStyle(.plain)
      .accessibilityLabel("Próximo: \(store.nextStepTitle)")
      .accessibilityHint(isOverdue ? "Abre tarefas atrasadas" : "Abre tarefas de hoje")
  }
}

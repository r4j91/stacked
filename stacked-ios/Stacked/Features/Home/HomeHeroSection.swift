import SwiftUI

struct HomeHeroSection: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let style: HomeHeroStyle
  let store: HomeStore
  var onOpenFilter: (TaskFilterKind) -> Void
  var onRetry: () -> Void

  private var isOverdue: Bool { store.overdueCount > 0 }

  private var metrics: HomeHeroMetrics { HomeHeroMetrics.forStyle(style) }

  var body: some View {
    Section {
      Group {
        if store.isLoading {
          ProgressView()
            .tint(theme.colors.accent)
            .frame(maxWidth: .infinity, minHeight: 44)
        } else if let err = store.error {
          LoadErrorView(message: err, onRetry: onRetry)
        } else {
          heroContent
        }
      }
      .listRowInsets(heroInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
    }
  }

  private var heroInsets: EdgeInsets {
    switch style {
    case .classic:
      return EdgeInsets(top: 8, leading: AppSpacing.xl, bottom: AppSpacing.sm, trailing: AppSpacing.xl)
    case .openType, .orbitalOpen, .streakOpen, .streakOpenCentered, .greetingWeatherPremiumOpen, .greetingWeatherPremiumSceneOpen, .greetingWeatherPremiumSceneMonoOpen, .greetingWeatherMinimalOpen, .greetingWeatherRefinedOpen, .greetingWeatherTintOpen, .greetingWeatherSculptOpen, .greetingWeatherSculptLiftOpen:
      return EdgeInsets(top: 8, leading: AppSpacing.xl, bottom: AppSpacing.sm, trailing: AppSpacing.xl)
    default:
      return EdgeInsets(top: 4, leading: AppSpacing.xl, bottom: AppSpacing.sm, trailing: AppSpacing.xl)
    }
  }

  @ViewBuilder
  private var heroContent: some View {
    switch style {
    case .classic:
      classicHero
    case .orbital:
      overdueButton { orbitalHero }
    case .orbitalOpen:
      overdueButton { orbitalOpenHero }
    case .horizon:
      overdueButton { horizonHero }
    case .capsule:
      overdueButton { capsuleHero }
    case .openType:
      overdueButton { openTypeHero }
    case .focus:
      overdueButton(clearAccessibility: focusClearAccessibility) { focusHero }
    case .motivation:
      conceptHeroLayout { motivationHero }
    case .focusDay:
      conceptHeroLayout { focusDayHero }
    case .streak:
      conceptHeroLayout { streakHero }
    case .motivationIntegrated:
      HomeHeroMotivationIntegratedCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .focusDayIntegrated:
      HomeHeroFocusDayIntegratedCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .streakIntegrated:
      HomeHeroStreakIntegratedCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .streakOpen:
      HomeHeroStreakOpenCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .streakOpenCentered:
      HomeHeroStreakOpenCenteredCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .greetingProgress:
      HomeHeroGreetingProgressCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .greetingFocus:
      HomeHeroGreetingFocusCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .greetingWeather:
      HomeHeroGreetingWeatherCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .greetingProgressTinted:
      HomeHeroGreetingProgressTintedCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .greetingFocusTinted:
      HomeHeroGreetingFocusTintedCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .greetingWeatherTinted:
      HomeHeroGreetingWeatherTintedCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .greetingWeatherPremium:
      HomeHeroGreetingWeatherPremiumCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .greetingWeatherPremiumOpen:
      HomeHeroGreetingWeatherPremiumOpenCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .greetingWeatherPremiumScene:
      HomeHeroGreetingWeatherSceneCard(
        store: store,
        metrics: metrics,
        isOverdue: isOverdue,
        presentation: .card,
        onOpenFilter: onOpenFilter
      )
    case .greetingWeatherPremiumSceneOpen:
      HomeHeroGreetingWeatherSceneOpenCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .greetingWeatherPremiumSceneMono:
      HomeHeroGreetingWeatherSceneCard(
        store: store,
        metrics: metrics,
        isOverdue: isOverdue,
        presentation: .card,
        palette: .monochrome,
        onOpenFilter: onOpenFilter
      )
    case .greetingWeatherPremiumSceneMonoOpen:
      HomeHeroGreetingWeatherSceneOpenCard(
        store: store,
        metrics: metrics,
        isOverdue: isOverdue,
        palette: .monochrome,
        onOpenFilter: onOpenFilter
      )
    case .greetingWeatherMinimal:
      HomeHeroGreetingWeatherMinimalCard(
        store: store,
        metrics: metrics,
        isOverdue: isOverdue,
        presentation: .card,
        onOpenFilter: onOpenFilter
      )
    case .greetingWeatherMinimalOpen:
      HomeHeroGreetingWeatherMinimalOpenCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .greetingWeatherRefined:
      HomeHeroGreetingWeatherRefinedCard(
        store: store,
        metrics: metrics,
        isOverdue: isOverdue,
        presentation: .card,
        onOpenFilter: onOpenFilter
      )
    case .greetingWeatherRefinedOpen:
      HomeHeroGreetingWeatherRefinedOpenCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .greetingWeatherTint:
      HomeHeroGreetingWeatherTintCard(
        store: store,
        metrics: metrics,
        isOverdue: isOverdue,
        presentation: .card,
        onOpenFilter: onOpenFilter
      )
    case .greetingWeatherTintOpen:
      HomeHeroGreetingWeatherTintOpenCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .greetingWeatherSculpt:
      HomeHeroGreetingWeatherSculptCard(
        store: store,
        metrics: metrics,
        isOverdue: isOverdue,
        presentation: .card,
        onOpenFilter: onOpenFilter
      )
    case .greetingWeatherSculptOpen:
      HomeHeroGreetingWeatherSculptOpenCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .greetingWeatherSculptLift:
      HomeHeroGreetingWeatherSculptLiftCard(
        store: store,
        metrics: metrics,
        isOverdue: isOverdue,
        presentation: .card,
        onOpenFilter: onOpenFilter
      )
    case .greetingWeatherSculptLiftOpen:
      HomeHeroGreetingWeatherSculptLiftOpenCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .journeyDaily:
      HomeHeroJourneyDailyCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .journeyMist:
      HomeHeroJourneyCard(
        store: store, metrics: metrics, art: .mist, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .journeyForest:
      HomeHeroJourneyCard(
        store: store, metrics: metrics, art: .forest, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .journeySummit:
      HomeHeroJourneyCard(
        store: store, metrics: metrics, art: .summit, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .auroraCalm:
      HomeHeroAuroraCard(
        store: store, metrics: metrics, art: .calm, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .auroraDusk:
      HomeHeroAuroraCard(
        store: store, metrics: metrics, art: .dusk, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .auroraEmber:
      HomeHeroAuroraCard(
        store: store, metrics: metrics, art: .ember, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    case .panel:
      HomeHeroPanelCard(store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter)
    case .compass:
      HomeHeroCompassCard(store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter)
    case .queue:
      HomeHeroQueueCard(store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter)
    case .thermometer:
      HomeHeroThermometerCard(store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter)
    case .rhythm:
      HomeHeroRhythmCard(store: store, metrics: metrics, isOverdue: isOverdue)
    case .nextStep:
      HomeHeroNextStepCard(store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter)
    }
  }

  @ViewBuilder
  private func conceptHeroLayout<Content: View>(@ViewBuilder card: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      card()
      conceptStatusRow
    }
  }

  private var conceptStatusRow: some View {
    Group {
      if isOverdue {
        conceptOverdueBanner
      } else {
        conceptAllClearBanner
      }
    }
  }

  private func conceptStatusCardChrome(accent: Color) -> some View {
    let c = theme.colors
    return Group {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(c.surfaceVariant.opacity(c.isDark ? 0.65 : 0.85))
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(accent.opacity(c.isDark ? 0.07 : 0.06))
    }
  }

  private func conceptStatusCardBorder(accent: Color) -> some View {
    RoundedRectangle(cornerRadius: 12, style: .continuous)
      .strokeBorder(accent.opacity(0.12), lineWidth: 1)
  }

  private var conceptAllClearBanner: some View {
    let c = theme.colors
    let accent = AppColors.tagGreen
    return HStack(spacing: 10) {
      ZStack {
        Circle()
          .fill(accent.opacity(c.isDark ? 0.14 : 0.12))
          .frame(width: 28, height: 28)
        Image(systemName: "checkmark")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(accent.opacity(0.82))
      }

      Text("Tudo em dia")
        .font(AppTypography.bodySemibold)
        .foregroundStyle(c.textPrimary)

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background { conceptStatusCardChrome(accent: accent) }
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay { conceptStatusCardBorder(accent: accent) }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Tudo em dia")
  }

  private var conceptOverdueBanner: some View {
    let c = theme.colors
    return Button {
      HapticService.selection()
      onOpenFilter(.overdue)
    } label: {
      HStack(spacing: 10) {
        StackedIcons.image(.exclamation)
          .foregroundStyle(AppColors.overdue.opacity(0.8))
        Text(store.statusLabel(overdueCount: store.overdueCount))
          .font(AppTypography.bodySemibold)
          .foregroundStyle(c.textPrimary)
        Spacer()
        DisclosureChevron(color: c.textTertiary)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .background { conceptStatusCardChrome(accent: AppColors.overdue) }
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      .overlay { conceptStatusCardBorder(accent: AppColors.overdue) }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(store.statusLabel(overdueCount: store.overdueCount))
    .accessibilityHint("Abre tarefas atrasadas")
  }

  private var focusClearAccessibility: String {
    "\(store.focusHeroTitle(overdueCount: 0)). \(store.focusHeroSubtitle(overdueCount: 0))"
  }

  @ViewBuilder
  private func overdueButton<Content: View>(
    clearAccessibility: String? = nil,
    @ViewBuilder content: () -> Content
  ) -> some View {
    if isOverdue {
      Button {
        HapticService.selection()
        onOpenFilter(.overdue)
      } label: {
        content()
      }
      .buttonStyle(.plain)
      .accessibilityLabel(
        style == .focus
          ? "\(store.focusHeroTitle(overdueCount: store.overdueCount)). \(store.focusHeroSubtitle(overdueCount: store.overdueCount))"
          : store.statusLabel(overdueCount: store.overdueCount)
      )
      .accessibilityHint("Abre tarefas atrasadas")
    } else {
      content()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(clearAccessibility ?? "\(store.greetingPhrase) \(store.firstName). Tudo em dia")
    }
  }

  // MARK: - Classic

  private var classicHero: some View {
    let c = theme.colors
    return VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 6) {
        Text(store.greeting)
          .font(AppTypography.screenGreeting)
          .foregroundStyle(c.textPrimary)
        Text(store.formattedLongDate)
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textSecondary)
      }

      if isOverdue {
        classicOverdueBanner
          .padding(.top, AppSpacing.sm)
      } else {
        HStack(spacing: AppSpacing.sm) {
          HomeAllClearBadge()
          Text("Tudo em dia")
            .font(AppTypography.body.weight(.medium))
            .foregroundStyle(AppColors.tagGreen.opacity(0.72))
        }
        .padding(.top, AppSpacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tudo em dia")
      }
    }
  }

  private var classicOverdueBanner: some View {
    Button {
      HapticService.selection()
      onOpenFilter(.overdue)
    } label: {
      HStack(spacing: 10) {
        StackedIcons.image(.exclamation).foregroundStyle(AppColors.overdue)
        Text(store.statusLabel(overdueCount: store.overdueCount))
          .font(AppTypography.bodySemibold)
          .foregroundStyle(AppColors.overdue)
        Spacer()
        DisclosureChevron(color: AppColors.overdue.opacity(0.85))
      }
      .padding(14)
      .background(AppColors.overdue.opacity(0.15))
      .clipShape(RoundedRectangle(cornerRadius: 14))
      .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.overdue.opacity(0.28)))
    }
    .buttonStyle(.plain)
  }

  // MARK: - Orbital (P1)

  private var orbitalHero: some View {
    let c = theme.colors
    let m = metrics
    return HStack(alignment: .center, spacing: m.rowSpacing) {
      HomeOrbitalStackIllustration(
        isOverdue: isOverdue,
        overdueCount: store.overdueCount,
        artSize: m.orbitalArtSize
      )

      greetingTextBlock(metrics: m)
        .frame(maxWidth: .infinity, alignment: .leading)

      if isOverdue {
        DisclosureChevron(color: AppColors.overdue.opacity(0.7))
      }
    }
    .padding(.horizontal, m.cardPaddingH)
    .padding(.vertical, m.cardPaddingV)
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(
          isOverdue ? AppColors.overdue.opacity(0.16) : c.textPrimary.opacity(c.isDark ? 0.07 : 0.06),
          lineWidth: 1
        )
    }
    .overlay(alignment: .top) {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(c.textPrimary.opacity(c.isDark ? 0.04 : 0.03), lineWidth: 0.5)
        .padding(0.5)
        .allowsHitTesting(false)
    }
  }

  // MARK: - Orbital aberto (sem card)

  private var orbitalOpenHero: some View {
    let c = theme.colors
    let m = metrics
    return VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center, spacing: m.rowSpacing) {
        HomeOrbitalStackIllustration(
          isOverdue: isOverdue,
          overdueCount: store.overdueCount,
          artSize: m.orbitalArtSize
        )

        greetingTextBlock(metrics: m)
          .frame(maxWidth: .infinity, alignment: .leading)

        if isOverdue {
          DisclosureChevron(color: AppColors.overdue.opacity(0.7))
        }
      }

      Rectangle()
        .fill(isOverdue ? AppColors.overdue.opacity(0.12) : c.textPrimary.opacity(c.isDark ? 0.06 : 0.05))
        .frame(height: 1)
        .padding(.top, m.dividerTopPadding)
    }
    .padding(.vertical, m.openVerticalPadding)
  }

  // MARK: - Horizon (E4)

  private var horizonHero: some View {
    let c = theme.colors
    let m = metrics
    return HStack(alignment: .center, spacing: m.rowSpacing) {
      greetingTextBlock(metrics: m)
        .frame(maxWidth: .infinity, alignment: .leading)

      HomeHorizonGlyphIllustration(
        timeOfDay: store.timeOfDay,
        isOverdue: isOverdue,
        overdueCount: store.overdueCount
      )

      if isOverdue {
        DisclosureChevron(color: AppColors.overdue.opacity(0.7))
      }
    }
    .padding(.horizontal, m.cardPaddingH)
    .padding(.vertical, m.cardPaddingV)
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(
          isOverdue ? AppColors.overdue.opacity(0.14) : c.textPrimary.opacity(c.isDark ? 0.07 : 0.06),
          lineWidth: 1
        )
    }
  }

  // MARK: - Capsule (E2)

  private var capsuleHero: some View {
    let c = theme.colors
    let m = metrics
    return VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .top) {
        Text(store.greetingPhrase)
          .font(.system(size: m.phraseSize, weight: .medium))
          .foregroundStyle(c.textSecondary)
        Spacer(minLength: 8)
        HomeHeroStatusCapsule(
          isOverdue: isOverdue,
          label: store.statusLabel(overdueCount: store.overdueCount),
          fontSize: m.capsuleStatusSize
        )
      }

      HStack(alignment: .center) {
        if !store.firstName.isEmpty {
          Text(store.firstName)
            .font(.system(size: m.nameSize, weight: .heavy))
            .foregroundStyle(c.textPrimary)
            .tracking(-0.6)
        }
        Spacer()
        if isOverdue {
          DisclosureChevron(color: AppColors.overdue.opacity(0.7))
        }
      }
    }
    .padding(.horizontal, m.cardPaddingH)
    .padding(.vertical, m.cardPaddingV)
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(
          isOverdue ? AppColors.overdue.opacity(0.14) : c.textPrimary.opacity(c.isDark ? 0.07 : 0.06),
          lineWidth: 1
        )
    }
  }

  // MARK: - Focus (A-H sem saudação)

  private var focusHero: some View {
    let c = theme.colors
    let m = metrics
    return HStack(alignment: .center, spacing: m.rowSpacing) {
      HomeFocusInboxIllustration(isOverdue: isOverdue, overdueCount: store.overdueCount)

      VStack(alignment: .leading, spacing: 2) {
        Text(store.focusHeroTitle(overdueCount: store.overdueCount))
          .font(.system(size: m.focusTitleSize, weight: .bold))
          .foregroundStyle(isOverdue ? AppColors.overdue : c.textPrimary)
          .lineLimit(1)

        Text(store.focusHeroSubtitle(overdueCount: store.overdueCount))
          .font(.system(size: m.focusSubtitleSize))
          .foregroundStyle(c.textTertiary)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      if isOverdue {
        DisclosureChevron(color: AppColors.overdue.opacity(0.75))
      }
    }
    .padding(.horizontal, m.cardPaddingH)
    .padding(.vertical, m.cardPaddingV)
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .strokeBorder(
          isOverdue ? AppColors.overdue.opacity(0.18) : c.textPrimary.opacity(c.isDark ? 0.07 : 0.06),
          lineWidth: 1
        )
    }
  }

  // MARK: - Concept cards (mensagem / foco do dia / sequência)

  private var motivationHero: some View {
    let content = store.motivationContent
    let m = metrics
    let c = theme.colors
    let accent = c.accent
    return conceptCard(accent: accent) {
      HStack(alignment: .top, spacing: 8) {
        VStack(alignment: .leading, spacing: 6) {
          Text("\u{201C}")
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(accent.opacity(0.38))
            .offset(y: -4)
          Text(content.quote)
            .font(.system(size: m.focusTitleSize, weight: .semibold))
            .foregroundStyle(c.textPrimary)
            .lineLimit(3)
            .minimumScaleFactor(0.9)
            .fixedSize(horizontal: false, vertical: true)
          Text(content.footnote)
            .font(.system(size: m.focusSubtitleSize, weight: .medium))
            .foregroundStyle(c.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        HomeMotivationMountainArt(accent: accent)
          .offset(x: 4, y: 2)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(content.quote) \(content.footnote)")
  }

  private var focusDayHero: some View {
    let m = metrics
    let c = theme.colors
    let accent = AppColors.tagPurple
    let title = store.focusTaskTitle ?? "Nada pendente para hoje"
    let time = store.focusTaskTime
    return conceptCard(accent: accent) {
      HStack(alignment: .center, spacing: 8) {
        VStack(alignment: .leading, spacing: 5) {
          Text("Foco do dia")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(accent.opacity(0.62))
          Text(title)
            .font(.system(size: m.focusTitleSize, weight: .bold))
            .foregroundStyle(c.textPrimary)
            .lineLimit(2)
            .minimumScaleFactor(0.9)
          if let time, !time.isEmpty {
            HStack(spacing: 4) {
              Image(systemName: "clock")
                .font(.system(size: 11, weight: .semibold))
              Text(time)
                .font(.system(size: m.focusSubtitleSize, weight: .medium))
            }
            .foregroundStyle(c.textSecondary)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        HomeFocusTargetArt(accent: accent)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(time.map { "Foco do dia: \(title), \($0)" } ?? "Foco do dia: \(title)")
  }

  private var streakHero: some View {
    let m = metrics
    let c = theme.colors
    let accent = c.accent
    let days = store.completionStreak
    return conceptCard(accent: accent) {
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .top, spacing: 10) {
          HomeStreakFlameArt(accent: accent)
          VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
              Text("\(days)")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(c.textPrimary)
              Text(days == 1 ? "dia seguido" : "dias seguidos")
                .font(.system(size: m.focusSubtitleSize, weight: .semibold))
                .foregroundStyle(c.textSecondary)
            }
            Text(days > 0 ? "Constância conta." : "Conclua uma tarefa para começar.")
              .font(.system(size: m.focusSubtitleSize))
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
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      days == 1 ? "1 dia seguido com conclusões" : "\(days) dias seguidos com conclusões"
    )
  }

  private func conceptCard<Content: View>(
    accent: Color,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    HomeConceptCard(accent: accent, minHeight: 100, maxHeight: 100) {
      content()
        .padding(.horizontal, metrics.cardPaddingH)
        .padding(.vertical, metrics.cardPaddingV)
    }
  }

  // MARK: - Open type (E3)

  private var openTypeHero: some View {
    let c = theme.colors
    let m = metrics
    return VStack(alignment: .leading, spacing: 0) {
      Text(store.greetingPhrase)
        .font(.system(size: m.phraseSize, weight: .medium))
        .foregroundStyle(c.textSecondary)

      HStack(alignment: .firstTextBaseline) {
        if !store.firstName.isEmpty {
          Text(store.firstName)
            .font(.system(size: m.nameSize, weight: .heavy))
            .foregroundStyle(c.textPrimary)
            .tracking(-0.7)
        }
        Spacer()
        if isOverdue {
          DisclosureChevron(color: AppColors.overdue.opacity(0.7))
        }
      }
      .padding(.top, 1)

      HomeHeroAccentLine(isOverdue: isOverdue, reduceMotion: reduceMotion)
        .padding(.top, 8)

      HomeHeroStatusLine(
        isOverdue: isOverdue,
        label: store.statusLabel(overdueCount: store.overdueCount),
        fontSize: m.statusSize
      )
      .padding(.top, 8)
    }
    .padding(.vertical, m.openVerticalPadding)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(isOverdue ? AppColors.overdue.opacity(0.15) : c.textPrimary.opacity(c.isDark ? 0.06 : 0.05))
        .frame(height: 1)
        .offset(y: 8)
    }
  }

  @ViewBuilder
  private func greetingTextBlock(metrics: HomeHeroMetrics) -> some View {
    let c = theme.colors
    VStack(alignment: .leading, spacing: 3) {
      Text(store.greetingPhrase)
        .font(.system(size: metrics.phraseSize, weight: .medium))
        .foregroundStyle(c.textSecondary)
      if !store.firstName.isEmpty {
        Text(store.firstName)
          .font(.system(size: metrics.nameSize, weight: .heavy))
          .foregroundStyle(c.textPrimary)
          .tracking(-0.5)
      }
      HomeHeroStatusLine(
        isOverdue: isOverdue,
        label: store.statusLabel(overdueCount: store.overdueCount),
        fontSize: metrics.statusSize
      )
      .padding(.top, 2)
    }
  }
}

// MARK: - Shared pieces

private struct HomeHeroStatusLine: View {
  let isOverdue: Bool
  let label: String
  var fontSize: CGFloat = 12.5

  var body: some View {
    HStack(spacing: 5) {
      Circle()
        .fill(isOverdue ? AppColors.overdue : AppColors.tagGreen)
        .frame(width: 5, height: 5)
      Text(label)
        .font(.system(size: fontSize, weight: .semibold))
        .foregroundStyle(isOverdue ? AppColors.overdue : AppColors.tagGreen)
    }
  }
}

private struct HomeHeroStatusCapsule: View {
  let isOverdue: Bool
  let label: String
  var fontSize: CGFloat = 10

  var body: some View {
    Text(label)
      .font(.system(size: fontSize, weight: .bold))
      .foregroundStyle(isOverdue ? AppColors.overdue : AppColors.tagGreen)
      .padding(.horizontal, 9)
      .padding(.vertical, 4)
      .background((isOverdue ? AppColors.overdue : AppColors.tagGreen).opacity(0.12))
      .clipShape(Capsule())
      .overlay(Capsule().strokeBorder((isOverdue ? AppColors.overdue : AppColors.tagGreen).opacity(0.22)))
  }
}

private struct HomeHeroAccentLine: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.isTabActive) private var isTabActive
  let isOverdue: Bool
  let reduceMotion: Bool

  @State private var pulse = false

  var body: some View {
    let accent = theme.colors.accent
    return Rectangle()
      .fill(
        LinearGradient(
          colors: [
            (isOverdue ? AppColors.overdue : accent).opacity(pulse ? 0.5 : 0.38),
            (isOverdue ? AppColors.overdue : accent).opacity(0.08),
            .clear,
          ],
          startPoint: .leading,
          endPoint: .trailing
        )
      )
      .frame(height: 2)
      .clipShape(Capsule())
      .onAppear { restartPulse() }
      .onChange(of: isOverdue) { _, _ in restartPulse() }
      .onChange(of: isTabActive) { _, active in
        if active { restartPulse() } else { pulse = false }
      }
  }

  private func restartPulse() {
    pulse = false
    guard isTabActive, !reduceMotion else { return }
    withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
      pulse = true
    }
  }
}

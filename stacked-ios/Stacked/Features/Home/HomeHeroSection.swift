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
          ProgressView().frame(maxWidth: .infinity, minHeight: 44)
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
    case .openType, .orbitalOpen:
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
    }
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
        Text("Vamos focar no que realmente importa hoje.")
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
        StackedIcons.image(.chevronRight).font(.system(size: 12, weight: .semibold))
          .foregroundStyle(AppColors.overdue.opacity(0.85))
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
        StackedIcons.image(.chevronRight)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(AppColors.overdue.opacity(0.7))
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
          StackedIcons.image(.chevronRight)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppColors.overdue.opacity(0.7))
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
        StackedIcons.image(.chevronRight)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(AppColors.overdue.opacity(0.7))
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
          StackedIcons.image(.chevronRight)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppColors.overdue.opacity(0.7))
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
        StackedIcons.image(.chevronRight)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(AppColors.overdue.opacity(0.75))
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
          StackedIcons.image(.chevronRight)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppColors.overdue.opacity(0.7))
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
      .onAppear {
        pulse = false
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
          pulse = true
        }
      }
      .onChange(of: isOverdue) { _, _ in
        pulse = false
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
          pulse = true
        }
      }
  }
}

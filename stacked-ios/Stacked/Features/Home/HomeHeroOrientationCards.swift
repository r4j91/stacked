import SwiftUI

// Âncoras de orientação (A1–A3): uma âncora, sem card genérico / ilustração.

// MARK: - A1 Masthead

struct HomeHeroMastheadCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    let c = theme.colors
    let content = VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        Text(store.formattedDateline)
          .font(.system(size: 11, weight: .semibold))
          .tracking(0.6)
          .foregroundStyle(c.textTertiary)
        Spacer(minLength: 8)
        Text(store.weatherCompactLabel)
          .font(.system(size: 11.5, weight: .medium))
          .foregroundStyle(c.textTertiary)
          .monospacedDigit()
      }

      orientationGreeting(
        phrase: store.greetingPhrase,
        name: store.firstName,
        phraseSize: metrics.phraseSize,
        nameSize: metrics.nameSize,
        colors: c
      )
      .padding(.top, 7)

      HomeHeroOrientationStatusLine(
        isOverdue: isOverdue,
        label: store.orientationStatusLabel(overdueCount: store.overdueCount),
        fontSize: metrics.statusSize,
        emphasizeCount: !isOverdue
      )
      .padding(.top, 8)

      Rectangle()
        .fill(c.textPrimary.opacity(c.isDark ? 0.07 : 0.06))
        .frame(height: 1)
        .padding(.top, metrics.dividerTopPadding)
    }
    .padding(.vertical, metrics.openVerticalPadding)

    orientationTapWrapper(content: content)
  }

  @ViewBuilder
  private func orientationTapWrapper<Content: View>(content: Content) -> some View {
    if isOverdue {
      Button {
        HapticService.selection()
        onOpenFilter(.overdue)
      } label: { content }
        .buttonStyle(.plain)
        .accessibilityLabel(store.orientationStatusLabel(overdueCount: store.overdueCount))
        .accessibilityHint("Abre tarefas atrasadas")
    } else {
      content
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
          "\(store.greetingPhrase) \(store.firstName). \(store.orientationStatusLabel(overdueCount: store.overdueCount))"
        )
    }
  }
}

// MARK: - A2 Horizonte tonal

struct HomeHeroHorizonToneCard: View {
  @Environment(ThemeManager.self) private var theme

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    let c = theme.colors
    let wash = horizonWashColor(colors: c)

    let content = VStack(alignment: .leading, spacing: 0) {
      orientationGreetingInline(
        phrase: store.greetingPhrase,
        name: store.firstName,
        nameSize: metrics.nameSize - 1,
        colors: c
      )

      HStack(spacing: 6) {
        Text(store.formattedClock)
          .font(.system(size: 12.5, weight: .semibold))
          .foregroundStyle(c.textSecondary)
          .monospacedDigit()
        metaSep(colors: c)
        Text(store.formattedMediumDate)
          .font(.system(size: 12.5, weight: .medium))
          .foregroundStyle(c.textTertiary)
          .lineLimit(1)
        metaSep(colors: c)
        Text(store.weatherDegreeLabel)
          .font(.system(size: 12.5, weight: .medium))
          .foregroundStyle(c.textTertiary)
          .monospacedDigit()
      }
      .padding(.top, 6)

      HomeHeroOrientationStatusLine(
        isOverdue: isOverdue,
        label: store.orientationStatusLabel(overdueCount: store.overdueCount),
        fontSize: metrics.statusSize,
        emphasizeCount: !isOverdue
      )
      .padding(.top, 9)
    }
    .padding(.vertical, metrics.openVerticalPadding + 2)
    .padding(.horizontal, 2)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      LinearGradient(
        colors: [
          wash.opacity(c.isDark ? 0.09 : 0.07),
          wash.opacity(c.isDark ? 0.03 : 0.025),
          .clear,
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .padding(.horizontal, -AppSpacing.xl)
      .padding(.top, -10)
      .allowsHitTesting(false)
    }

    if isOverdue {
      Button {
        HapticService.selection()
        onOpenFilter(.overdue)
      } label: { content }
        .buttonStyle(.plain)
        .accessibilityLabel(store.orientationStatusLabel(overdueCount: store.overdueCount))
        .accessibilityHint("Abre tarefas atrasadas")
    } else {
      content
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
          "\(store.greetingPhrase) \(store.firstName). \(store.formattedClock). \(store.orientationStatusLabel(overdueCount: store.overdueCount))"
        )
    }
  }

  private func metaSep(colors c: AppThemeColors) -> some View {
    Text("·")
      .font(.system(size: 12.5, weight: .medium))
      .foregroundStyle(c.textTertiary.opacity(0.55))
  }

  private func horizonWashColor(colors c: AppThemeColors) -> Color {
    if isOverdue { return AppColors.overdue }
    switch store.timeOfDay {
    case .morning:
      return Color(red: 0.92, green: 0.72, blue: 0.38)
    case .afternoon:
      return c.accent
    case .night:
      return Color(red: 0.48, green: 0.42, blue: 0.82)
    }
  }
}

// MARK: - A3 Régua do dia

struct HomeHeroDayRulerCard: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  private var currentHour: Int {
    Calendar.current.component(.hour, from: Date())
  }

  var body: some View {
    let c = theme.colors
    let now = currentHour

    let content = VStack(alignment: .leading, spacing: 0) {
      orientationGreetingInline(
        phrase: store.greetingPhrase,
        name: store.firstName,
        nameSize: metrics.nameSize - 2,
        colors: c
      )

      DayRulerView(
        currentHour: now,
        accent: isOverdue ? AppColors.overdue : c.accent,
        tickColor: c.textPrimary,
        reduceMotion: reduceMotion
      )
      .padding(.top, 12)
      .accessibilityHidden(true)

      HStack(alignment: .firstTextBaseline) {
        Text(store.formattedClock)
          .font(.system(size: 13, weight: .bold))
          .foregroundStyle(c.textPrimary)
          .monospacedDigit()
        Spacer(minLength: 8)
        Text("\(store.formattedMediumDate) · \(store.weatherDegreeLabel)")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(c.textTertiary)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
      }
      .padding(.top, 8)

      HomeHeroOrientationStatusLine(
        isOverdue: isOverdue,
        label: store.orientationStatusLabel(overdueCount: store.overdueCount),
        fontSize: metrics.statusSize,
        emphasizeCount: !isOverdue
      )
      .padding(.top, 6)
    }
    .padding(.vertical, metrics.openVerticalPadding)

    if isOverdue {
      Button {
        HapticService.selection()
        onOpenFilter(.overdue)
      } label: { content }
        .buttonStyle(.plain)
        .accessibilityLabel(store.orientationStatusLabel(overdueCount: store.overdueCount))
        .accessibilityHint("Abre tarefas atrasadas")
    } else {
      content
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
          "\(store.greetingPhrase) \(store.firstName). \(store.formattedClock). \(store.orientationStatusLabel(overdueCount: store.overdueCount))"
        )
    }
  }
}

// MARK: - A3b Trilho do dia (variante compacta)

struct HomeHeroDayRailCard: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  private var dayProgress: CGFloat {
    let cal = Calendar.current
    let now = Date()
    let h = CGFloat(cal.component(.hour, from: now))
    let m = CGFloat(cal.component(.minute, from: now))
    return min(1, max(0, (h + m / 60) / 24))
  }

  var body: some View {
    let c = theme.colors
    let accent = isOverdue ? AppColors.overdue : c.accent

    let content = VStack(alignment: .leading, spacing: 0) {
      orientationGreetingInline(
        phrase: store.greetingPhrase,
        name: store.firstName,
        nameSize: metrics.nameSize - 3,
        colors: c
      )

      HStack(alignment: .center, spacing: 10) {
        DayRailView(
          progress: dayProgress,
          accent: accent,
          trackColor: c.textPrimary,
          reduceMotion: reduceMotion
        )
        .accessibilityHidden(true)

        Text(store.formattedClock)
          .font(.system(size: 12.5, weight: .bold))
          .foregroundStyle(c.textPrimary)
          .monospacedDigit()
          .fixedSize()
      }
      .padding(.top, 10)

      HStack(alignment: .firstTextBaseline, spacing: 8) {
        HomeHeroOrientationStatusLine(
          isOverdue: isOverdue,
          label: store.orientationStatusLabel(overdueCount: store.overdueCount),
          fontSize: metrics.statusSize - 0.5,
          emphasizeCount: !isOverdue
        )
        Spacer(minLength: 6)
        Text("\(store.formattedDateline) · \(store.weatherDegreeLabel)")
          .font(.system(size: 11, weight: .medium))
          .tracking(0.2)
          .foregroundStyle(c.textTertiary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
      .padding(.top, 8)
    }
    .padding(.vertical, metrics.openVerticalPadding)

    if isOverdue {
      Button {
        HapticService.selection()
        onOpenFilter(.overdue)
      } label: { content }
        .buttonStyle(.plain)
        .accessibilityLabel(store.orientationStatusLabel(overdueCount: store.overdueCount))
        .accessibilityHint("Abre tarefas atrasadas")
    } else {
      content
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
          "\(store.greetingPhrase) \(store.firstName). \(store.formattedClock). \(store.orientationStatusLabel(overdueCount: store.overdueCount))"
        )
    }
  }
}

// MARK: - Shared pieces

private struct HomeHeroOrientationStatusLine: View {
  @Environment(ThemeManager.self) private var theme

  let isOverdue: Bool
  let label: String
  var fontSize: CGFloat = 13
  var emphasizeCount: Bool = false

  var body: some View {
    let c = theme.colors
    if isOverdue {
      HStack(spacing: 6) {
        Text(label)
          .font(.system(size: fontSize, weight: .semibold))
          .foregroundStyle(AppColors.overdue)
        Spacer(minLength: 4)
        DisclosureChevron(color: AppColors.overdue.opacity(0.75))
      }
    } else {
      clearStatus(colors: c)
    }
  }

  @ViewBuilder
  private func clearStatus(colors c: AppThemeColors) -> some View {
    if emphasizeCount, let split = splitLeadingNumber(label) {
      HStack(spacing: 0) {
        Text(split.number)
          .font(.system(size: fontSize, weight: .bold))
          .foregroundStyle(c.textPrimary)
        Text(split.rest)
          .font(.system(size: fontSize, weight: .medium))
          .foregroundStyle(c.textSecondary)
      }
    } else {
      Text(label)
        .font(.system(size: fontSize, weight: .medium))
        .foregroundStyle(c.textSecondary)
    }
  }

  private func splitLeadingNumber(_ text: String) -> (number: String, rest: String)? {
    guard let match = text.range(of: #"^\d+"#, options: .regularExpression) else { return nil }
    return (String(text[match]), String(text[match.upperBound...]))
  }
}

private struct DayRulerView: View {
  let currentHour: Int
  let accent: Color
  let tickColor: Color
  let reduceMotion: Bool

  @State private var appeared = false

  var body: some View {
    HStack(alignment: .bottom, spacing: 0) {
      ForEach(0..<24, id: \.self) { hour in
        let isNow = hour == currentHour
        let isPast = hour < currentHour
        Capsule(style: .continuous)
          .fill(tickFill(isNow: isNow, isPast: isPast))
          .frame(width: isNow ? 2.5 : 1.5, height: isNow ? 15 : 7)
          .frame(maxWidth: .infinity)
          .opacity(appeared || reduceMotion ? 1 : 0.35)
          .scaleEffect(y: appeared || reduceMotion || !isNow ? 1 : 0.7, anchor: .bottom)
      }
    }
    .frame(height: 16)
    .onAppear {
      guard !reduceMotion else {
        appeared = true
        return
      }
      withAnimation(.easeOut(duration: 0.45).delay(0.05)) {
        appeared = true
      }
    }
  }

  private func tickFill(isNow: Bool, isPast: Bool) -> Color {
    if isNow { return accent }
    if isPast { return tickColor.opacity(0.34) }
    return tickColor.opacity(0.10)
  }
}

/// Trilho contínuo: o dia como uma faixa, posição atual como leitura (minuto incluso).
private struct DayRailView: View {
  let progress: CGFloat
  let accent: Color
  let trackColor: Color
  let reduceMotion: Bool

  @State private var revealedProgress: CGFloat = 0

  private let majorHours: [CGFloat] = [0, 0.25, 0.5, 0.75]

  var body: some View {
    GeometryReader { geo in
      let w = geo.size.width
      let p = reduceMotion ? progress : revealedProgress
      let beadX = max(3, min(w - 3, w * p))

      ZStack(alignment: .leading) {
        // Base track
        Capsule(style: .continuous)
          .fill(trackColor.opacity(0.10))
          .frame(height: 2)

        // Elapsed fill
        Capsule(style: .continuous)
          .fill(
            LinearGradient(
              colors: [accent.opacity(0.55), accent.opacity(0.28)],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .frame(width: max(2, beadX), height: 2)

        // Quarter-day notches (0 / 6 / 12 / 18)
        ForEach(Array(majorHours.enumerated()), id: \.offset) { _, fraction in
          Capsule(style: .continuous)
            .fill(trackColor.opacity(fraction <= p + 0.001 ? 0.42 : 0.16))
            .frame(width: 1.5, height: 5)
            .offset(x: w * fraction - 0.75)
        }

        // Reading head (now)
        Circle()
          .fill(accent)
          .frame(width: 7, height: 7)
          .overlay {
            Circle()
              .strokeBorder(Color.black.opacity(0.18), lineWidth: 0.5)
          }
          .offset(x: beadX - 3.5)
      }
      .frame(maxHeight: .infinity, alignment: .center)
    }
    .frame(height: 12)
    .onAppear { animateIn() }
    .onChange(of: progress) { _, _ in
      guard !reduceMotion else {
        revealedProgress = progress
        return
      }
      withAnimation(.easeOut(duration: 0.35)) {
        revealedProgress = progress
      }
    }
  }

  private func animateIn() {
    if reduceMotion {
      revealedProgress = progress
      return
    }
    revealedProgress = 0
    withAnimation(.easeOut(duration: 0.55)) {
      revealedProgress = progress
    }
  }
}

private func orientationGreeting(
  phrase: String,
  name: String,
  phraseSize: CGFloat,
  nameSize: CGFloat,
  colors c: AppThemeColors
) -> some View {
  VStack(alignment: .leading, spacing: 2) {
    Text(phrase)
      .font(.system(size: phraseSize, weight: .medium))
      .foregroundStyle(c.textSecondary)
    if !name.isEmpty {
      Text(name.hasSuffix(".") ? name : "\(name).")
        .font(.system(size: nameSize, weight: .heavy))
        .foregroundStyle(c.textPrimary)
        .tracking(-0.7)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
  }
}

private func orientationGreetingInline(
  phrase: String,
  name: String,
  nameSize: CGFloat,
  colors c: AppThemeColors
) -> some View {
  let displayName = name.isEmpty ? "" : (name.hasSuffix(".") ? name : "\(name).")
  return HStack(alignment: .firstTextBaseline, spacing: 5) {
    Text(phrase)
      .font(.system(size: max(13, nameSize * 0.48), weight: .medium))
      .foregroundStyle(c.textSecondary)
    if !displayName.isEmpty {
      Text(displayName)
        .font(.system(size: nameSize, weight: .heavy))
        .foregroundStyle(c.textPrimary)
        .tracking(-0.55)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
  }
}

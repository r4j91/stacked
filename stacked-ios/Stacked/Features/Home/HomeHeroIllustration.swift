import SwiftUI

// MARK: - Orbital stack (P1)

struct HomeOrbitalStackIllustration: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.isTabActive) private var isTabActive

  let isOverdue: Bool
  let overdueCount: Int
  var artSize: CGFloat = 48

  @State private var breathe = false
  @State private var floatUp = false

  var body: some View {
    let c = theme.colors

    ZStack {
      Circle()
        .fill(
          RadialGradient(
            colors: haloColors(c: c),
            center: .center,
            startRadius: 2,
            endRadius: 28
          )
        )
        .frame(width: 52, height: 52)
        .scaleEffect(breathe ? 1.06 : 1)
        .opacity(breathe ? 0.85 : 1)

      ZStack(alignment: .topTrailing) {
        ZStack {
          stackLayer(c: c, index: 0)
          stackLayer(c: c, index: 1)
          stackLayer(c: c, index: 2)
            .offset(y: floatUp ? -2 : 0)
        }
        .frame(width: 36, height: 32)

        if isOverdue {
          overdueBadge
        } else {
          clearBadge
        }
      }
    }
    .frame(width: 48, height: 48)
    .scaleEffect(artSize / 48, anchor: .center)
    .frame(width: artSize, height: artSize)
    .onAppear { startAnimations() }
    .onChange(of: isOverdue) { _, _ in startAnimations() }
    .onChange(of: isTabActive) { _, active in
      if active { startAnimations() } else { stopAnimations() }
    }
    .accessibilityHidden(true)
  }

  private var clearBadge: some View {
    Circle()
      .fill(AppColors.tagGreen.opacity(0.22))
      .overlay(Circle().strokeBorder(AppColors.tagGreen.opacity(0.35), lineWidth: 1))
      .frame(width: 16, height: 16)
      .overlay {
        Image(systemName: "checkmark")
          .font(.system(size: 7, weight: .bold))
          .foregroundStyle(AppColors.tagGreen)
      }
      .offset(x: 6, y: -4)
  }

  private var overdueBadge: some View {
    Circle()
      .fill(AppColors.overdue.opacity(0.22))
      .overlay(Circle().strokeBorder(AppColors.overdue.opacity(0.4), lineWidth: 1))
      .frame(width: 16, height: 16)
      .overlay {
        Text(overdueCount > 9 ? "9+" : "\(overdueCount)")
          .font(.system(size: 8, weight: .bold))
          .foregroundStyle(AppColors.overdue)
      }
      .offset(x: 6, y: -4)
  }

  private func stackLayer(c: AppThemeColors, index: Int) -> some View {
    let offsets: [(CGFloat, Double, Double)] = [
      (0, -3, 0.5),
      (7, 2, 0.7),
      (14, isOverdue ? 7 : -1, 1),
    ]
    let item = offsets[index]
    let isTop = index == 2

    return RoundedRectangle(cornerRadius: 5, style: .continuous)
      .fill(isTop && isOverdue
        ? AppColors.overdue.opacity(0.1)
        : (isTop ? c.accent.opacity(0.09) : c.surfaceVariant))
      .overlay {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
          .strokeBorder(
            isTop
              ? (isOverdue ? AppColors.overdue.opacity(0.35) : c.accent.opacity(0.28))
              : c.textPrimary.opacity(c.isDark ? 0.1 : 0.08),
            lineWidth: 1
          )
      }
      .frame(width: 30, height: 18)
      .rotationEffect(.degrees(item.1))
      .offset(x: isTop && isOverdue ? 2 : 0, y: -item.0)
      .opacity(item.2)
  }

  private func haloColors(c: AppThemeColors) -> [Color] {
    if isOverdue {
      return [
        AppColors.overdue.opacity(c.isDark ? 0.16 : 0.12),
        AppColors.overdue.opacity(c.isDark ? 0.04 : 0.03),
        .clear,
      ]
    }
    return [
      c.accent.opacity(c.isDark ? 0.2 : 0.14),
      c.accent.opacity(c.isDark ? 0.05 : 0.03),
      .clear,
    ]
  }

  private func startAnimations() {
    breathe = false
    floatUp = false
    guard isTabActive, !reduceMotion else { return }
    withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
      breathe = true
    }
    withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
      floatUp = true
    }
  }

  private func stopAnimations() {
    breathe = false
    floatUp = false
  }
}

// MARK: - Horizon glyph (E4)

struct HomeHorizonGlyphIllustration: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.isTabActive) private var isTabActive

  let timeOfDay: HomeTimeOfDay
  let isOverdue: Bool
  let overdueCount: Int

  @State private var breathe = false

  var body: some View {
    let c = theme.colors

    ZStack {
      Circle()
        .fill(
          RadialGradient(
            colors: glowColors(c: c),
            center: .center,
            startRadius: 2,
            endRadius: 24
          )
        )
        .scaleEffect(breathe ? 1.05 : 1)
        .opacity(breathe ? 0.82 : 1)

      Hill()
        .fill(c.surfaceVariant.opacity(0.7))
        .frame(width: 28, height: 10)
        .offset(x: -4, y: 14)

      Capsule()
        .fill(c.textPrimary.opacity(c.isDark ? 0.12 : 0.1))
        .frame(width: 32, height: 1)
        .offset(y: 10)

      Circle()
        .fill(orbColor)
        .frame(width: orbSize, height: orbSize)
        .shadow(color: orbShadow, radius: 4)
        .offset(x: orbOffset.x, y: orbOffset.y)

      if isOverdue {
        overdueFlag
      } else {
        clearFlag
      }
    }
    .frame(width: 44, height: 44)
    .onAppear { restartBreathe() }
    .onChange(of: isTabActive) { _, active in
      if active { restartBreathe() } else { breathe = false }
    }
    .accessibilityHidden(true)
  }

  private func restartBreathe() {
    breathe = false
    guard isTabActive, !reduceMotion else { return }
    withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
      breathe = true
    }
  }

  private var clearFlag: some View {
    Circle()
      .fill(AppColors.tagGreen.opacity(0.2))
      .overlay(Circle().strokeBorder(AppColors.tagGreen.opacity(0.35), lineWidth: 1))
      .frame(width: 14, height: 14)
      .overlay {
        Image(systemName: "checkmark")
          .font(.system(size: 7, weight: .bold))
          .foregroundStyle(AppColors.tagGreen)
      }
      .offset(x: 14, y: -12)
  }

  private var overdueFlag: some View {
    Circle()
      .fill(AppColors.overdue.opacity(0.2))
      .overlay(Circle().strokeBorder(AppColors.overdue.opacity(0.4), lineWidth: 1))
      .frame(width: 14, height: 14)
      .overlay {
        Text(overdueCount > 9 ? "9+" : "\(overdueCount)")
          .font(.system(size: 7, weight: .bold))
          .foregroundStyle(AppColors.overdue)
      }
      .offset(x: 14, y: -12)
  }

  private var orbColor: Color {
    if isOverdue { return AppColors.overdue.opacity(0.75) }
    switch timeOfDay {
    case .morning: return theme.colors.accent.opacity(0.65)
    case .afternoon: return Color(hex: 0xF5A623, opacity: 0.75)
    case .night: return Color(hex: 0xB18CF5, opacity: 0.7)
    }
  }

  private var orbShadow: Color {
    if isOverdue { return AppColors.overdue.opacity(0.35) }
    switch timeOfDay {
    case .morning: return theme.colors.accent.opacity(0.4)
    case .afternoon: return Color(hex: 0xF5A623, opacity: 0.35)
    case .night: return Color(hex: 0xB18CF5, opacity: 0.3)
    }
  }

  private var orbSize: CGFloat {
    timeOfDay == .night && !isOverdue ? 6 : 8
  }

  private var orbOffset: CGPoint {
    if isOverdue { return CGPoint(x: 0, y: 2) }
    switch timeOfDay {
    case .morning: return CGPoint(x: -10, y: 4)
    case .afternoon: return CGPoint(x: 0, y: -6)
    case .night: return CGPoint(x: 10, y: 4)
    }
  }

  private func glowColors(c: AppThemeColors) -> [Color] {
    if isOverdue {
      return [AppColors.overdue.opacity(0.12), .clear]
    }
    return [c.accent.opacity(c.isDark ? 0.14 : 0.1), .clear]
  }
}

// MARK: - Focus inbox (A-H)

struct HomeFocusInboxIllustration: View {
  @Environment(ThemeManager.self) private var theme

  let isOverdue: Bool
  let overdueCount: Int

  var body: some View {
    let c = theme.colors
    let line = c.textTertiary.opacity(c.isDark ? 0.38 : 0.32)
    let fill = c.surfaceVariant.opacity(c.isDark ? 0.55 : 0.72)

    ZStack {
      Circle()
        .fill(
          RadialGradient(
            colors: isOverdue
              ? [AppColors.overdue.opacity(c.isDark ? 0.14 : 0.1), .clear]
              : [c.accent.opacity(c.isDark ? 0.16 : 0.11), .clear],
            center: .center,
            startRadius: 2,
            endRadius: 24
          )
        )
        .frame(width: 44, height: 44)

      RoundedRectangle(cornerRadius: 6, style: .continuous)
        .fill(fill)
        .overlay {
          RoundedRectangle(cornerRadius: 6, style: .continuous)
            .strokeBorder(line.opacity(0.85), lineWidth: 1)
        }
        .frame(width: 30, height: 20)
        .offset(y: 2)
        .overlay(alignment: .top) {
          FocusInboxTrayLid()
            .stroke(line.opacity(0.8), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            .frame(width: 30, height: 8)
            .offset(y: -5)
        }
        .overlay {
          VStack(spacing: 3) {
            Capsule().fill(line.opacity(0.35)).frame(width: 14, height: 2)
            Capsule().fill(line.opacity(0.22)).frame(width: 9, height: 2)
          }
          .offset(y: 3)
        }

      if isOverdue {
        overdueBadge
      } else {
        clearBadge
      }
    }
    .frame(width: 44, height: 44)
    .accessibilityHidden(true)
  }

  private var clearBadge: some View {
    Circle()
      .fill(AppColors.tagGreen.opacity(0.22))
      .overlay(Circle().strokeBorder(AppColors.tagGreen.opacity(0.38), lineWidth: 1))
      .frame(width: 16, height: 16)
      .overlay {
        Image(systemName: "checkmark")
          .font(.system(size: 7, weight: .bold))
          .foregroundStyle(AppColors.tagGreen)
      }
      .offset(x: 14, y: -12)
  }

  private var overdueBadge: some View {
    Circle()
      .fill(AppColors.overdue)
      .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
      .frame(width: 18, height: 18)
      .overlay {
        Text(overdueCount > 9 ? "9+" : "\(overdueCount)")
          .font(.system(size: 9, weight: .bold))
          .foregroundStyle(.white)
      }
      .shadow(color: AppColors.overdue.opacity(0.25), radius: 0, x: 0, y: 0)
      .offset(x: 14, y: -12)
  }
}

private struct FocusInboxTrayLid: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX + 4, y: rect.maxY))
    path.addQuadCurve(
      to: CGPoint(x: rect.maxX - 4, y: rect.maxY),
      control: CGPoint(x: rect.midX, y: rect.minY - 2)
    )
    return path
  }
}

private struct Hill: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addQuadCurve(
      to: CGPoint(x: rect.maxX, y: rect.maxY),
      control: CGPoint(x: rect.midX, y: rect.minY)
    )
    path.closeSubpath()
    return path
  }
}
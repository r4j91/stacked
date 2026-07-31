import SwiftUI

struct HomeHeroStylePreview: View {
  let style: HomeHeroStyle
  let colors: AppThemeColors
  var selected: Bool = false

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(colors.surfaceVariant)
      previewContent
        .padding(.horizontal, 5)
        .padding(.vertical, 6)
    }
    .frame(width: 56, height: 36)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .strokeBorder(
          selected ? colors.accent : (colors.isDark ? Color.white : Color.black).opacity(0.08),
          lineWidth: selected ? 1.5 : 1
        )
    }
  }

  @ViewBuilder
  private var previewContent: some View {
    switch style {
    case .masthead:
      mastheadPreview
    case .dayRail:
      dayRailPreview
    }
  }

  private var mastheadPreview: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        RoundedRectangle(cornerRadius: 0.5)
          .fill(colors.textTertiary.opacity(0.45))
          .frame(width: 18, height: 1.5)
        Spacer(minLength: 0)
        RoundedRectangle(cornerRadius: 0.5)
          .fill(colors.textTertiary.opacity(0.35))
          .frame(width: 10, height: 1.5)
      }
      RoundedRectangle(cornerRadius: 1)
        .fill(colors.textSecondary.opacity(0.45))
        .frame(width: 14, height: 2)
      RoundedRectangle(cornerRadius: 1)
        .fill(colors.textPrimary.opacity(0.85))
        .frame(width: 24, height: 4)
      RoundedRectangle(cornerRadius: 0.5)
        .fill(colors.textPrimary.opacity(0.08))
        .frame(height: 1)
        .padding(.top, 1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var dayRailPreview: some View {
    VStack(alignment: .leading, spacing: 3) {
      RoundedRectangle(cornerRadius: 1)
        .fill(colors.textPrimary.opacity(0.8))
        .frame(width: 20, height: 3)
      HStack(spacing: 3) {
        ZStack(alignment: .leading) {
          Capsule().fill(colors.textPrimary.opacity(0.12)).frame(height: 2)
          Capsule().fill(colors.accent.opacity(0.45)).frame(width: 18, height: 2)
          Circle().fill(colors.accent).frame(width: 4, height: 4)
            .offset(x: 16)
        }
        .frame(height: 6)
        RoundedRectangle(cornerRadius: 0.5)
          .fill(colors.textPrimary.opacity(0.55))
          .frame(width: 8, height: 2)
      }
      RoundedRectangle(cornerRadius: 0.5)
        .fill(colors.textTertiary.opacity(0.4))
        .frame(width: 24, height: 1.5)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// Miniatura da moldura do topo — aberto, card com borda ou card sem borda.
struct HomeHeroFramePreview: View {
  let frame: HomeHeroFrame
  let colors: AppThemeColors
  var selected: Bool = false

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(colors.background)
      content
        .padding(.horizontal, 5)
        .padding(.vertical, 6)
    }
    .frame(width: 56, height: 36)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .strokeBorder(
          selected ? colors.accent : (colors.isDark ? Color.white : Color.black).opacity(0.08),
          lineWidth: selected ? 1.5 : 1
        )
    }
  }

  @ViewBuilder
  private var content: some View {
    switch frame {
    case .open:
      heroLines
        .frame(maxWidth: .infinity, alignment: .leading)
    case .matchHome, .bordered, .plain:
      heroLines
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(colors.surface)
        }
        .overlay {
          if frame != .plain {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
              .strokeBorder(colors.textTertiary.opacity(frame == .matchHome ? 0.35 : 0.55), lineWidth: 0.5)
          }
        }
    }
  }

  private var heroLines: some View {
    VStack(alignment: .leading, spacing: 3) {
      RoundedRectangle(cornerRadius: 1)
        .fill(colors.textPrimary.opacity(0.8))
        .frame(width: 20, height: 3)
      RoundedRectangle(cornerRadius: 0.5)
        .fill(colors.accent.opacity(0.5))
        .frame(width: 28, height: 2)
      RoundedRectangle(cornerRadius: 0.5)
        .fill(colors.textTertiary.opacity(0.4))
        .frame(width: 16, height: 1.5)
    }
  }
}

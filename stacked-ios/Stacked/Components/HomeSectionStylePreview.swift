import SwiftUI

/// Miniatura do agrupamento das seções da Home — mesmo formato do `HomeHeroStylePreview`.
struct HomeSectionStylePreview: View {
  let style: HomeSectionStyle
  let colors: AppThemeColors
  var selected: Bool = false

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(colors.background)
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
    VStack(alignment: .leading, spacing: 3) {
      headerBar
      switch style {
      case .classic:
        VStack(alignment: .leading, spacing: 3) {
          ForEach(0..<3, id: \.self) { _ in looseRow }
        }
      case .capsule:
        VStack(alignment: .leading, spacing: 2) {
          ForEach(0..<3, id: \.self) { _ in
            RoundedRectangle(cornerRadius: 2.5)
              .fill(colors.surface)
              .frame(height: 5)
          }
        }
      case .container, .quiet:
        VStack(spacing: 0) {
          ForEach(0..<3, id: \.self) { index in
            ZStack(alignment: .bottom) {
              Rectangle().fill(colors.surface).frame(height: 5)
              if index < 2 {
                Rectangle()
                  .fill(colors.background.opacity(0.9))
                  .frame(height: 0.5)
                  .padding(.leading, 4)
              }
            }
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .overlay {
          if style.drawsBorder {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
              .strokeBorder(colors.textTertiary.opacity(0.5), lineWidth: 0.5)
          }
        }
      }
      Spacer(minLength: 0)
    }
  }

  private var headerBar: some View {
    RoundedRectangle(cornerRadius: 1)
      .fill(colors.textTertiary.opacity(0.75))
      .frame(width: 16, height: 2.5)
  }

  private var looseRow: some View {
    RoundedRectangle(cornerRadius: 1)
      .fill(colors.textSecondary.opacity(0.35))
      .frame(height: 3)
  }
}

/// Miniatura da escala tipográfica — header vs. linha, em proporção.
struct AppTypeScalePreview: View {
  let scale: AppTypeScale
  let colors: AppThemeColors
  var selected: Bool = false

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(colors.background)
      VStack(alignment: .leading, spacing: 4) {
        RoundedRectangle(cornerRadius: 1)
          .fill(headerColor)
          .frame(width: headerWidth, height: headerHeight)
        RoundedRectangle(cornerRadius: 1)
          .fill(colors.textSecondary.opacity(0.4))
          .frame(width: 34, height: rowHeight)
        RoundedRectangle(cornerRadius: 1)
          .fill(colors.textSecondary.opacity(0.4))
          .frame(width: 26, height: rowHeight)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 6)
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

  private var headerColor: Color {
    scale == .large ? colors.textPrimary : colors.textTertiary.opacity(0.8)
  }

  private var headerWidth: CGFloat {
    switch scale {
    case .classic: 14
    case .large: 26
    case .eyebrow: 20
    }
  }

  private var headerHeight: CGFloat {
    switch scale {
    case .classic: 2
    case .large: 5
    case .eyebrow: 3
    }
  }

  private var rowHeight: CGFloat {
    scale == .large ? 4 : 3.5
  }
}

import SwiftUI

/// Miniatura da barra do topo da Home — pill do avatar à esquerda e sino/config
/// à direita, com o que cada estilo coloca (ou não) no vão do meio.
struct HomeHeaderStylePreview: View {
  let style: HomeHeaderStyle
  let colors: AppThemeColors
  var selected: Bool = false

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(colors.background)
      content
        .padding(.horizontal, 5)
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
    switch style {
    case .classic:
      HStack(spacing: 0) {
        leadingPill(width: 26) { avatarDot }
        Spacer(minLength: 0)
        trailingPill
      }
    case .progressRing:
      HStack(spacing: 0) {
        leadingPill(width: 30) {
          HStack(spacing: 3) {
            ringedAvatarDot
            bar(width: 5, opacity: 0.35)
          }
        }
        Spacer(minLength: 0)
        trailingPill
      }
    case .greeting:
      HStack(spacing: 0) {
        leadingPill(width: 32) {
          HStack(spacing: 3) {
            ringedAvatarDot
            VStack(alignment: .leading, spacing: 1.5) {
              bar(width: 12, opacity: 0.75)
              bar(width: 8, opacity: 0.3)
            }
          }
        }
        Spacer(minLength: 0)
        trailingPill
      }
    case .search:
      HStack(spacing: 3) {
        leadingPill(width: 12) { avatarDot }
        Capsule()
          .fill(colors.surfaceVariant)
          .frame(height: 12)
          .overlay(alignment: .leading) {
            Circle()
              .strokeBorder(colors.textSecondary.opacity(0.55), lineWidth: 1)
              .frame(width: 5, height: 5)
              .padding(.leading, 3)
          }
        trailingPill
      }
    }
  }

  private var avatarDot: some View {
    Circle()
      .fill(colors.accent.opacity(0.55))
      .frame(width: 8, height: 8)
  }

  private var ringedAvatarDot: some View {
    avatarDot.overlay {
      Circle()
        .trim(from: 0, to: 0.62)
        .stroke(colors.accent, style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .padding(-1.4)
    }
  }

  private func bar(width: CGFloat, opacity: Double) -> some View {
    RoundedRectangle(cornerRadius: 0.5)
      .fill(colors.textPrimary.opacity(opacity))
      .frame(width: width, height: 1.5)
  }

  private func leadingPill<Content: View>(
    width: CGFloat,
    @ViewBuilder content: () -> Content
  ) -> some View {
    Capsule()
      .fill(colors.surfaceVariant)
      .frame(width: width, height: 12)
      .overlay {
        content()
          .padding(.horizontal, 2)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
  }

  private var trailingPill: some View {
    Capsule()
      .fill(colors.surfaceVariant)
      .frame(width: 17, height: 12)
      .overlay {
        HStack(spacing: 3) {
          Circle().fill(colors.textSecondary.opacity(0.5)).frame(width: 4, height: 4)
          Circle().fill(colors.textSecondary.opacity(0.5)).frame(width: 4, height: 4)
        }
      }
  }
}

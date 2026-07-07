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
          selected ? colors.accent : Color.white.opacity(0.08),
          lineWidth: selected ? 1.5 : 1
        )
    }
  }

  @ViewBuilder
  private var previewContent: some View {
    switch style {
    case .classic:
      classicPreview
    case .orbital:
      orbitalPreview
    case .orbitalOpen:
      orbitalOpenPreview
    case .horizon:
      horizonPreview
    case .capsule:
      capsulePreview
    case .openType:
      openPreview
    case .focus:
      focusPreview
    }
  }

  private var classicPreview: some View {
    VStack(alignment: .leading, spacing: 3) {
      RoundedRectangle(cornerRadius: 1)
        .fill(colors.textPrimary.opacity(0.85))
        .frame(width: 28, height: 4)
      RoundedRectangle(cornerRadius: 1)
        .fill(colors.textSecondary.opacity(0.5))
        .frame(width: 36, height: 2)
      HStack(spacing: 3) {
        Circle().fill(AppColors.tagGreen.opacity(0.7)).frame(width: 4, height: 4)
        RoundedRectangle(cornerRadius: 1)
          .fill(AppColors.tagGreen.opacity(0.6))
          .frame(width: 18, height: 2)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var orbitalPreview: some View {
    HStack(spacing: 4) {
      ZStack {
        RoundedRectangle(cornerRadius: 2)
          .fill(colors.accent.opacity(0.2))
          .frame(width: 12, height: 10)
        RoundedRectangle(cornerRadius: 1)
          .fill(colors.accent.opacity(0.35))
          .frame(width: 9, height: 5)
          .offset(y: -2)
      }
      VStack(alignment: .leading, spacing: 2) {
        RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.5)).frame(width: 16, height: 2)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.8)).frame(width: 22, height: 3)
        RoundedRectangle(cornerRadius: 1).fill(AppColors.tagGreen.opacity(0.6)).frame(width: 14, height: 2)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var orbitalOpenPreview: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 4) {
        ZStack {
          RoundedRectangle(cornerRadius: 2)
            .fill(colors.accent.opacity(0.2))
            .frame(width: 12, height: 10)
          RoundedRectangle(cornerRadius: 1)
            .fill(colors.accent.opacity(0.35))
            .frame(width: 9, height: 5)
            .offset(y: -2)
        }
        VStack(alignment: .leading, spacing: 2) {
          RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.5)).frame(width: 16, height: 2)
          RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.8)).frame(width: 22, height: 3)
          RoundedRectangle(cornerRadius: 1).fill(AppColors.tagGreen.opacity(0.6)).frame(width: 14, height: 2)
        }
      }
      Rectangle()
        .fill(colors.textPrimary.opacity(0.08))
        .frame(height: 1)
        .padding(.top, 4)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var horizonPreview: some View {
    HStack(spacing: 4) {
      VStack(alignment: .leading, spacing: 2) {
        RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.5)).frame(width: 14, height: 2)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.8)).frame(width: 20, height: 3)
      }
      ZStack {
        Circle().fill(colors.accent.opacity(0.25)).frame(width: 12, height: 12)
        Circle().fill(colors.accent.opacity(0.6)).frame(width: 3, height: 3).offset(y: 1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var capsulePreview: some View {
    VStack(alignment: .leading, spacing: 3) {
      HStack {
        RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.5)).frame(width: 12, height: 2)
        Spacer(minLength: 0)
        Capsule().fill(AppColors.tagGreen.opacity(0.25)).frame(width: 14, height: 5)
      }
      RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.85)).frame(width: 24, height: 4)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var focusPreview: some View {
    HStack(spacing: 4) {
      ZStack(alignment: .topTrailing) {
        RoundedRectangle(cornerRadius: 2)
          .fill(colors.surface.opacity(0.9))
          .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(colors.textTertiary.opacity(0.3), lineWidth: 0.5))
          .frame(width: 10, height: 7)
        Circle().fill(AppColors.tagGreen.opacity(0.7)).frame(width: 4, height: 4).offset(x: 2, y: -2)
      }
      VStack(alignment: .leading, spacing: 2) {
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.85)).frame(width: 22, height: 3)
        RoundedRectangle(cornerRadius: 1).fill(colors.textTertiary.opacity(0.45)).frame(width: 28, height: 2)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var openPreview: some View {
    VStack(alignment: .leading, spacing: 3) {
      RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.5)).frame(width: 14, height: 2)
      RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.85)).frame(width: 26, height: 4)
      RoundedRectangle(cornerRadius: 1)
        .fill(
          LinearGradient(
            colors: [colors.accent.opacity(0.5), .clear],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .frame(width: 34, height: 2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

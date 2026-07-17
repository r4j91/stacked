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
    case .masthead:
      mastheadPreview
    case .horizonTone:
      horizonTonePreview
    case .dayRuler:
      dayRulerPreview
    case .dayRail:
      dayRailPreview
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
    case .motivation:
      motivationPreview
    case .focusDay:
      focusDayPreview
    case .streak:
      streakPreview
    case .motivationIntegrated:
      motivationIntegratedPreview
    case .focusDayIntegrated:
      focusDayIntegratedPreview
    case .streakIntegrated:
      streakIntegratedPreview
    case .streakOpen:
      streakOpenPreview
    case .streakOpenCentered:
      streakOpenCenteredPreview
    case .greetingProgress:
      greetingProgressPreview
    case .greetingFocus:
      greetingFocusPreview
    case .greetingWeather:
      greetingWeatherPreview
    case .greetingProgressTinted:
      greetingProgressTintedPreview
    case .greetingFocusTinted:
      greetingFocusTintedPreview
    case .greetingWeatherTinted:
      greetingWeatherTintedPreview
    case .greetingWeatherPremium:
      greetingWeatherPremiumPreview
    case .greetingWeatherPremiumOpen:
      greetingWeatherPremiumOpenPreview
    case .greetingWeatherPremiumScene:
      greetingWeatherScenePreview
    case .greetingWeatherPremiumSceneOpen:
      greetingWeatherSceneOpenPreview
    case .greetingWeatherPremiumSceneMono:
      greetingWeatherSceneMonoPreview
    case .greetingWeatherPremiumSceneMonoOpen:
      greetingWeatherSceneMonoOpenPreview
    case .greetingWeatherMinimal:
      greetingWeatherMinimalPreview
    case .greetingWeatherMinimalOpen:
      greetingWeatherMinimalOpenPreview
    case .greetingWeatherRefined:
      greetingWeatherRefinedPreview
    case .greetingWeatherRefinedOpen:
      greetingWeatherRefinedOpenPreview
    case .greetingWeatherTint:
      greetingWeatherTintPreview
    case .greetingWeatherTintOpen:
      greetingWeatherTintOpenPreview
    case .greetingWeatherSculpt:
      greetingWeatherSculptPreview
    case .greetingWeatherSculptOpen:
      greetingWeatherSculptOpenPreview
    case .greetingWeatherSculptLift:
      greetingWeatherSculptLiftPreview
    case .greetingWeatherSculptLiftOpen:
      greetingWeatherSculptLiftOpenPreview
    case .journeyDaily:
      journeyDailyPreview
    case .journeyMist:
      journeyVariantPreview(asset: "HeroJourneyMistClear")
    case .journeyForest:
      journeyVariantPreview(asset: "HeroJourneyForestClear")
    case .journeySummit:
      journeyVariantPreview(asset: "HeroJourneySummitClear")
    case .auroraCalm:
      auroraPreview(asset: "HeroAuroraCalmClear")
    case .auroraDusk:
      auroraPreview(asset: "HeroAuroraDuskClear")
    case .auroraEmber:
      auroraPreview(asset: "HeroAuroraEmberClear")
    case .panel:
      panelPreview
    case .compass:
      compassPreview
    case .queue:
      queuePreview
    case .thermometer:
      thermometerPreview
    case .rhythm:
      rhythmPreview
    case .nextStep:
      nextStepPreview
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

  private var horizonTonePreview: some View {
    ZStack(alignment: .topLeading) {
      LinearGradient(
        colors: [colors.accent.opacity(0.18), colors.accent.opacity(0.04), .clear],
        startPoint: .top,
        endPoint: .bottom
      )
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
          RoundedRectangle(cornerRadius: 0.5)
            .fill(colors.textSecondary.opacity(0.45))
            .frame(width: 10, height: 2)
          RoundedRectangle(cornerRadius: 1)
            .fill(colors.textPrimary.opacity(0.85))
            .frame(width: 16, height: 4)
        }
        RoundedRectangle(cornerRadius: 0.5)
          .fill(colors.textTertiary.opacity(0.4))
          .frame(width: 28, height: 1.5)
        RoundedRectangle(cornerRadius: 0.5)
          .fill(colors.textSecondary.opacity(0.5))
          .frame(width: 20, height: 1.5)
      }
      .padding(4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var dayRulerPreview: some View {
    VStack(alignment: .leading, spacing: 3) {
      RoundedRectangle(cornerRadius: 1)
        .fill(colors.textPrimary.opacity(0.8))
        .frame(width: 22, height: 3)
      HStack(alignment: .bottom, spacing: 1.2) {
        ForEach(0..<12, id: \.self) { i in
          Capsule()
            .fill(i == 7 ? colors.accent.opacity(0.9) : colors.textPrimary.opacity(i < 7 ? 0.35 : 0.12))
            .frame(width: 1.2, height: i == 7 ? 8 : 4)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      RoundedRectangle(cornerRadius: 0.5)
        .fill(colors.textTertiary.opacity(0.45))
        .frame(width: 26, height: 1.5)
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

  private func conceptPreviewSurface(accent: Color) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 3)
        .fill(colors.surface)
      RoundedRectangle(cornerRadius: 3)
        .fill(
          LinearGradient(
            colors: [accent.opacity(0.14), accent.opacity(0.04), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
    }
    .overlay {
      RoundedRectangle(cornerRadius: 3)
        .strokeBorder(accent.opacity(0.16), lineWidth: 0.5)
    }
  }

  private var motivationPreview: some View {
    ZStack(alignment: .leading) {
      conceptPreviewSurface(accent: colors.accent)
      VStack(alignment: .leading, spacing: 2) {
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.7)).frame(width: 24, height: 2)
        RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.55)).frame(width: 16, height: 2)
      }
      .padding(.leading, 4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var focusDayPreview: some View {
    ZStack(alignment: .leading) {
      conceptPreviewSurface(accent: AppColors.tagPurple)
      VStack(alignment: .leading, spacing: 2) {
        RoundedRectangle(cornerRadius: 1).fill(AppColors.tagPurple.opacity(0.45)).frame(width: 14, height: 2)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.75)).frame(width: 28, height: 3)
      }
      .padding(.leading, 4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var streakPreview: some View {
    ZStack(alignment: .leading) {
      conceptPreviewSurface(accent: colors.accent)
      HStack(spacing: 3) {
        Circle().fill(colors.accent.opacity(0.4)).frame(width: 6, height: 6)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.7)).frame(width: 14, height: 3)
      }
      .padding(.leading, 4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func integratedConceptPreview(accent: Color) -> some View {
    ZStack(alignment: .bottomLeading) {
      conceptPreviewSurface(accent: accent)
      VStack(alignment: .leading, spacing: 0) {
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.7)).frame(width: 22, height: 3)
          .padding(.leading, 4)
          .padding(.top, 4)
        Spacer(minLength: 0)
        Rectangle().fill(colors.textPrimary.opacity(0.08)).frame(height: 1).padding(.horizontal, 3)
        HStack(spacing: 2) {
          Circle().fill(AppColors.tagGreen.opacity(0.6)).frame(width: 3, height: 3)
          RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.5)).frame(width: 14, height: 2)
        }
        .padding(.leading, 4)
        .padding(.bottom, 3)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var motivationIntegratedPreview: some View {
    integratedConceptPreview(accent: colors.accent)
  }

  private var focusDayIntegratedPreview: some View {
    integratedConceptPreview(accent: AppColors.tagPurple)
  }

  private var streakIntegratedPreview: some View {
    integratedConceptPreview(accent: colors.accent)
  }

  private var streakOpenPreview: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 3) {
        Image(systemName: "flame.fill")
          .font(.system(size: 7, weight: .medium))
          .foregroundStyle(colors.accent.opacity(0.5))
        VStack(alignment: .leading, spacing: 2) {
          RoundedRectangle(cornerRadius: 1)
            .fill(colors.textPrimary.opacity(0.75))
            .frame(width: 18, height: 3)
          RoundedRectangle(cornerRadius: 1)
            .fill(colors.textTertiary.opacity(0.45))
            .frame(width: 22, height: 2)
        }
      }
      HStack(spacing: 2) {
        ForEach(0..<7, id: \.self) { _ in
          Circle()
            .fill(colors.textPrimary.opacity(0.1))
            .frame(width: 3, height: 3)
        }
      }
      .padding(.top, 3)
      Rectangle()
        .fill(colors.textPrimary.opacity(0.08))
        .frame(height: 1)
        .padding(.top, 3)
      HStack(spacing: 2) {
        Circle().fill(AppColors.overdue.opacity(0.55)).frame(width: 3, height: 3)
        RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.5)).frame(width: 16, height: 2)
      }
      .padding(.top, 2)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var streakOpenCenteredPreview: some View {
    VStack(alignment: .center, spacing: 0) {
      HStack(spacing: 3) {
        Image(systemName: "flame.fill")
          .font(.system(size: 7, weight: .medium))
          .foregroundStyle(colors.accent.opacity(0.5))
        VStack(alignment: .leading, spacing: 2) {
          RoundedRectangle(cornerRadius: 1)
            .fill(colors.textPrimary.opacity(0.75))
            .frame(width: 18, height: 3)
          RoundedRectangle(cornerRadius: 1)
            .fill(colors.textTertiary.opacity(0.45))
            .frame(width: 22, height: 2)
        }
      }
      HStack(spacing: 2) {
        ForEach(0..<7, id: \.self) { _ in
          Circle()
            .fill(colors.textPrimary.opacity(0.1))
            .frame(width: 3, height: 3)
        }
      }
      .padding(.top, 3)
      Rectangle()
        .fill(colors.textPrimary.opacity(0.08))
        .frame(height: 1)
        .padding(.top, 3)
      HStack(spacing: 2) {
        Circle().fill(AppColors.overdue.opacity(0.55)).frame(width: 3, height: 3)
        RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.5)).frame(width: 16, height: 2)
      }
      .padding(.top, 2)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  private var greetingProgressPreview: some View {
    ZStack(alignment: .bottomLeading) {
      conceptPreviewSurface(accent: AppColors.tagPurple)
      VStack(alignment: .leading, spacing: 2) {
        RoundedRectangle(cornerRadius: 1).fill(AppColors.tagPurple.opacity(0.45)).frame(width: 14, height: 2)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.75)).frame(width: 20, height: 3)
        Capsule().fill(AppColors.tagPurple.opacity(0.55)).frame(width: 24, height: 2).padding(.top, 2)
        Rectangle().fill(colors.textPrimary.opacity(0.08)).frame(height: 1).padding(.top, 2)
        HStack(spacing: 2) {
          Circle().fill(AppColors.tagGreen.opacity(0.6)).frame(width: 3, height: 3)
          RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.5)).frame(width: 14, height: 2)
        }
      }
      .padding(4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var greetingFocusPreview: some View {
    ZStack(alignment: .topLeading) {
      conceptPreviewSurface(accent: AppColors.tagPurple)
      HStack(alignment: .top, spacing: 3) {
        VStack(alignment: .leading, spacing: 2) {
          RoundedRectangle(cornerRadius: 1).fill(AppColors.tagPurple.opacity(0.45)).frame(width: 12, height: 2)
          RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.75)).frame(width: 18, height: 3)
        }
        RoundedRectangle(cornerRadius: 2)
          .strokeBorder(AppColors.tagPurple.opacity(0.3), lineWidth: 0.5)
          .frame(width: 14, height: 10)
      }
      .padding(4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var greetingWeatherPreview: some View {
    ZStack(alignment: .topTrailing) {
      conceptPreviewSurface(accent: AppColors.priorityMedium)
      VStack(alignment: .trailing, spacing: 2) {
        Circle().fill(AppColors.priorityMedium.opacity(0.45)).frame(width: 6, height: 6)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.7)).frame(width: 12, height: 3)
        Capsule().fill(colors.textTertiary.opacity(0.35)).frame(width: 18, height: 4)
      }
      .padding(4)
      VStack(alignment: .leading, spacing: 2) {
        RoundedRectangle(cornerRadius: 1).fill(AppColors.tagPurple.opacity(0.45)).frame(width: 12, height: 2)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.75)).frame(width: 16, height: 3)
      }
      .padding(4)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var greetingProgressTintedPreview: some View {
    ZStack(alignment: .bottomLeading) {
      RoundedRectangle(cornerRadius: 4)
        .fill(
          LinearGradient(
            colors: [colors.accent.opacity(0.35), colors.surfaceVariant.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
      greetingProgressPreview
        .padding(1)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var greetingFocusTintedPreview: some View {
    ZStack(alignment: .topLeading) {
      RoundedRectangle(cornerRadius: 4)
        .fill(
          LinearGradient(
            colors: [AppColors.tagPurple.opacity(0.32), colors.surfaceVariant.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
      greetingFocusPreview
        .padding(1)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var greetingWeatherTintedPreview: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 4)
        .fill(
          LinearGradient(
            colors: [AppColors.priorityLow.opacity(0.3), colors.surfaceVariant.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
      greetingWeatherPreview
        .padding(1)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var greetingWeatherPremiumPreview: some View {
    ZStack(alignment: .topTrailing) {
      RoundedRectangle(cornerRadius: 4)
        .fill(
          LinearGradient(
            colors: [AppColors.priorityLow.opacity(0.35), colors.surfaceVariant.opacity(0.92)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
      VStack(alignment: .trailing, spacing: 2) {
        RoundedRectangle(cornerRadius: 3)
          .fill(
            LinearGradient(
              colors: [AppColors.priorityMedium.opacity(0.4), AppColors.priorityLow.opacity(0.15)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 22, height: 14)
          .overlay(alignment: .topLeading) {
            Circle().fill(AppColors.priorityMedium.opacity(0.7)).frame(width: 4, height: 4).padding(3)
          }
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.75)).frame(width: 12, height: 3)
      }
      .padding(4)
      VStack(alignment: .leading, spacing: 2) {
        RoundedRectangle(cornerRadius: 1).fill(colors.accent.opacity(0.45)).frame(width: 12, height: 2)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.75)).frame(width: 16, height: 3)
      }
      .padding(4)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var greetingWeatherPremiumOpenPreview: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 4) {
        VStack(alignment: .leading, spacing: 2) {
          RoundedRectangle(cornerRadius: 1).fill(colors.accent.opacity(0.45)).frame(width: 12, height: 2)
          RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.75)).frame(width: 16, height: 3)
          RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.45)).frame(width: 20, height: 2)
        }
        Spacer(minLength: 0)
        VStack(alignment: .trailing, spacing: 2) {
          RoundedRectangle(cornerRadius: 3)
            .fill(
              LinearGradient(
                colors: [AppColors.priorityMedium.opacity(0.4), AppColors.priorityLow.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 22, height: 14)
            .overlay(alignment: .topLeading) {
              Circle().fill(AppColors.priorityMedium.opacity(0.7)).frame(width: 4, height: 4).padding(3)
            }
          RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.75)).frame(width: 12, height: 3)
        }
      }
      Rectangle()
        .fill(colors.textPrimary.opacity(0.08))
        .frame(height: 1)
        .padding(.top, 3)
      HStack(spacing: 2) {
        Circle().fill(AppColors.overdue.opacity(0.55)).frame(width: 3, height: 3)
        RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.5)).frame(width: 16, height: 2)
      }
      .padding(.top, 2)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var greetingWeatherScenePreview: some View {
    ZStack(alignment: .leading) {
      Image("HeroWeatherClear")
        .resizable()
        .scaledToFill()
      LinearGradient(
        colors: [colors.background.opacity(0.95), colors.background.opacity(0.35), .clear],
        startPoint: .leading,
        endPoint: .trailing
      )
      VStack(alignment: .leading, spacing: 2) {
        RoundedRectangle(cornerRadius: 1).fill(AppColors.tagPurple.opacity(0.5)).frame(width: 14, height: 2)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.8)).frame(width: 16, height: 3)
        Spacer(minLength: 0)
      }
      .padding(4)
      VStack(alignment: .trailing, spacing: 1) {
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.85)).frame(width: 10, height: 4)
        RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.5)).frame(width: 14, height: 2)
      }
      .padding(4)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var greetingWeatherSceneOpenPreview: some View {
    greetingWeatherScenePreview
  }

  private var greetingWeatherSceneMonoPreview: some View {
    ZStack(alignment: .leading) {
      Image("HeroWeatherClear")
        .resizable()
        .scaledToFill()
        .saturation(0)
        .contrast(1.06)
      LinearGradient(
        colors: [colors.background.opacity(0.95), colors.background.opacity(0.35), .clear],
        startPoint: .leading,
        endPoint: .trailing
      )
      LinearGradient(
        colors: [colors.background.opacity(0.55), colors.background.opacity(0.2), .clear],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
      )
      VStack(alignment: .leading, spacing: 2) {
        RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.55)).frame(width: 14, height: 2)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.8)).frame(width: 16, height: 3)
        Spacer(minLength: 0)
      }
      .padding(4)
      VStack(alignment: .trailing, spacing: 1) {
        RoundedRectangle(cornerRadius: 2).fill(colors.surface.opacity(0.9)).frame(width: 16, height: 10)
      }
      .padding(4)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var greetingWeatherSceneMonoOpenPreview: some View {
    greetingWeatherSceneMonoPreview
  }

  private var greetingWeatherMinimalPreview: some View {
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: 4).fill(colors.surface.opacity(0.9))
      HStack(alignment: .top, spacing: 4) {
        VStack(alignment: .leading, spacing: 2) {
          RoundedRectangle(cornerRadius: 1).fill(AppColors.tagPurple.opacity(0.5)).frame(width: 14, height: 2)
          RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.8)).frame(width: 16, height: 3)
        }
        Spacer(minLength: 0)
        RoundedRectangle(cornerRadius: 3)
          .fill(colors.surfaceVariant)
          .frame(width: 18, height: 18)
          .overlay {
            Image("HeroMinimalWeatherPartlyCloudy")
              .resizable()
              .scaledToFill()
              .clipShape(RoundedRectangle(cornerRadius: 3))
          }
      }
      .padding(4)
      VStack {
        Spacer()
        RoundedRectangle(cornerRadius: 2).fill(colors.surfaceVariant.opacity(0.9)).frame(height: 5)
      }
      .padding(4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var greetingWeatherMinimalOpenPreview: some View {
    greetingWeatherMinimalPreview
  }

  private var greetingWeatherRefinedPreview: some View {
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: 4).fill(colors.surface.opacity(0.9))
      HStack(alignment: .top, spacing: 4) {
        VStack(alignment: .leading, spacing: 2) {
          RoundedRectangle(cornerRadius: 1).fill(AppColors.tagPurple.opacity(0.5)).frame(width: 14, height: 2)
          RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.8)).frame(width: 16, height: 3)
        }
        Spacer(minLength: 0)
        RoundedRectangle(cornerRadius: 3)
          .fill(colors.surfaceVariant)
          .frame(width: 19, height: 19)
          .overlay {
            Image("HeroRefinedWeatherPartlyCloudy")
              .resizable()
              .scaledToFill()
              .clipShape(RoundedRectangle(cornerRadius: 3))
          }
          .shadow(color: colors.background.opacity(0.3), radius: 1, y: 1)
      }
      .padding(4)
      VStack {
        Spacer()
        RoundedRectangle(cornerRadius: 2).fill(colors.surfaceVariant.opacity(0.9)).frame(height: 5)
      }
      .padding(4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var greetingWeatherRefinedOpenPreview: some View {
    greetingWeatherRefinedPreview
  }

  private var greetingWeatherTintPreview: some View {
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: 4).fill(colors.surface.opacity(0.9))
      HStack(alignment: .top, spacing: 4) {
        VStack(alignment: .leading, spacing: 2) {
          RoundedRectangle(cornerRadius: 1).fill(AppColors.tagPurple.opacity(0.5)).frame(width: 14, height: 2)
          RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.8)).frame(width: 16, height: 3)
        }
        Spacer(minLength: 0)
        RoundedRectangle(cornerRadius: 3)
          .fill(colors.surfaceVariant)
          .frame(width: 19, height: 19)
          .overlay {
            Image("HeroTintWeatherPartlyCloudy")
              .resizable()
              .scaledToFill()
              .clipShape(RoundedRectangle(cornerRadius: 3))
          }
          .shadow(color: AppColors.priorityLow.opacity(0.25), radius: 1, y: 1)
      }
      .padding(4)
      VStack {
        Spacer()
        RoundedRectangle(cornerRadius: 2).fill(colors.surfaceVariant.opacity(0.9)).frame(height: 5)
      }
      .padding(4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var greetingWeatherTintOpenPreview: some View {
    greetingWeatherTintPreview
  }

  private var greetingWeatherSculptPreview: some View {
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: 4).fill(colors.surface.opacity(0.9))
      HStack(alignment: .top, spacing: 4) {
        VStack(alignment: .leading, spacing: 2) {
          RoundedRectangle(cornerRadius: 1).fill(AppColors.tagPurple.opacity(0.5)).frame(width: 14, height: 2)
          RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.8)).frame(width: 16, height: 3)
        }
        Spacer(minLength: 0)
        RoundedRectangle(cornerRadius: 3)
          .fill(colors.surfaceVariant)
          .frame(width: 19, height: 19)
          .overlay {
            Image("HeroSculptWeatherSunny")
              .resizable()
              .scaledToFill()
              .clipShape(RoundedRectangle(cornerRadius: 3))
          }
          .shadow(color: AppColors.priorityMedium.opacity(0.25), radius: 1, y: 1)
      }
      .padding(4)
      VStack {
        Spacer()
        RoundedRectangle(cornerRadius: 2).fill(colors.surfaceVariant.opacity(0.9)).frame(height: 5)
      }
      .padding(4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var greetingWeatherSculptOpenPreview: some View {
    greetingWeatherSculptPreview
  }

  private var greetingWeatherSculptLiftPreview: some View {
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: 4).fill(colors.surface.opacity(0.9))
      HStack(alignment: .center, spacing: 3) {
        VStack(alignment: .leading, spacing: 2) {
          RoundedRectangle(cornerRadius: 1).fill(AppColors.tagPurple.opacity(0.5)).frame(width: 12, height: 2)
          RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.8)).frame(width: 14, height: 3)
          RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.45)).frame(width: 18, height: 2)
          Spacer(minLength: 0)
          RoundedRectangle(cornerRadius: 2).fill(AppColors.tagGreen.opacity(0.55)).frame(width: 16, height: 4)
        }
        Spacer(minLength: 0)
        RoundedRectangle(cornerRadius: 4)
          .fill(colors.surfaceVariant)
          .frame(width: 24, height: 24)
          .overlay {
            Image("HeroSculptWeatherSunny")
              .resizable()
              .scaledToFill()
              .clipShape(RoundedRectangle(cornerRadius: 4))
          }
          .shadow(color: AppColors.priorityMedium.opacity(0.28), radius: 1.5, y: 1)
      }
      .padding(4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var greetingWeatherSculptLiftOpenPreview: some View {
    greetingWeatherSculptLiftPreview
  }

  private var journeyDailyPreview: some View {
    ZStack(alignment: .leading) {
      Image("HeroJourneyClear")
        .resizable()
        .scaledToFill()
      LinearGradient(
        colors: [colors.background.opacity(0.95), colors.background.opacity(0.4), .clear],
        startPoint: .leading,
        endPoint: .trailing
      )
      VStack(alignment: .leading, spacing: 2) {
        RoundedRectangle(cornerRadius: 1).fill(AppColors.tagPurple.opacity(0.5)).frame(width: 14, height: 2)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.8)).frame(width: 18, height: 3)
        Spacer(minLength: 0)
        RoundedRectangle(cornerRadius: 2).fill(colors.surface.opacity(0.8)).frame(height: 6)
      }
      .padding(4)
    }
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func journeyVariantPreview(asset: String) -> some View {
    ZStack(alignment: .leading) {
      Image(asset)
        .resizable()
        .scaledToFill()
      LinearGradient(
        colors: [colors.background.opacity(0.95), colors.background.opacity(0.45), .clear],
        startPoint: .leading,
        endPoint: .trailing
      )
      VStack(alignment: .leading, spacing: 2) {
        RoundedRectangle(cornerRadius: 1).fill(AppColors.tagPurple.opacity(0.5)).frame(width: 14, height: 2)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.8)).frame(width: 16, height: 3)
        RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.55)).frame(width: 10, height: 2)
        Spacer(minLength: 0)
        RoundedRectangle(cornerRadius: 2).fill(colors.surface.opacity(0.8)).frame(height: 6)
      }
      .padding(4)
    }
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func auroraPreview(asset: String) -> some View {
    ZStack(alignment: .leading) {
      Image(asset)
        .resizable()
        .scaledToFill()
      LinearGradient(
        colors: [colors.background.opacity(0.92), colors.background.opacity(0.35), .clear],
        startPoint: .leading,
        endPoint: .trailing
      )
      VStack(alignment: .leading, spacing: 2) {
        RoundedRectangle(cornerRadius: 1).fill(AppColors.tagPurple.opacity(0.5)).frame(width: 14, height: 2)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.8)).frame(width: 16, height: 3)
        RoundedRectangle(cornerRadius: 1).fill(colors.textSecondary.opacity(0.5)).frame(width: 8, height: 2)
        Spacer(minLength: 0)
        RoundedRectangle(cornerRadius: 2).fill(colors.surface.opacity(0.8)).frame(height: 6)
      }
      .padding(4)
    }
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var panelPreview: some View {
    ZStack(alignment: .topLeading) {
      conceptPreviewSurface(accent: AppColors.tagGreen)
      VStack(alignment: .leading, spacing: 2) {
        Capsule().fill(AppColors.tagGreen.opacity(0.3)).frame(width: 16, height: 4)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.75)).frame(width: 26, height: 3)
        RoundedRectangle(cornerRadius: 1).fill(colors.textTertiary.opacity(0.45)).frame(width: 20, height: 2)
      }
      .padding(4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var compassPreview: some View {
    ZStack {
      conceptPreviewSurface(accent: AppColors.tagGreen)
      HStack(spacing: 3) {
        VStack(alignment: .leading, spacing: 2) {
          RoundedRectangle(cornerRadius: 1).fill(colors.textTertiary.opacity(0.5)).frame(width: 16, height: 2)
          RoundedRectangle(cornerRadius: 1).fill(AppColors.tagGreen.opacity(0.65)).frame(width: 18, height: 3)
        }
        Circle().strokeBorder(AppColors.tagGreen.opacity(0.35), lineWidth: 0.5).frame(width: 10, height: 10)
      }
      .padding(4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var queuePreview: some View {
    ZStack(alignment: .leading) {
      conceptPreviewSurface(accent: colors.accent)
      VStack(alignment: .leading, spacing: 2) {
        RoundedRectangle(cornerRadius: 1).fill(colors.textTertiary.opacity(0.5)).frame(width: 14, height: 2)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.7)).frame(width: 24, height: 2)
        RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.55)).frame(width: 20, height: 2)
      }
      .padding(4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var thermometerPreview: some View {
    ZStack(alignment: .bottom) {
      conceptPreviewSurface(accent: AppColors.tagGreen)
      HStack(spacing: 6) {
        RoundedRectangle(cornerRadius: 1).fill(colors.textTertiary.opacity(0.45)).frame(width: 4, height: 6)
        RoundedRectangle(cornerRadius: 1).fill(AppColors.tagGreen.opacity(0.65)).frame(width: 4, height: 8)
        RoundedRectangle(cornerRadius: 1).fill(colors.textTertiary.opacity(0.45)).frame(width: 4, height: 5)
      }
      .padding(.bottom, 5)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var rhythmPreview: some View {
    ZStack(alignment: .leading) {
      conceptPreviewSurface(accent: colors.accent)
      HStack(spacing: 2) {
        ForEach(0..<5, id: \.self) { i in
          Circle()
            .fill(i < 3 ? colors.accent.opacity(0.35) : colors.textTertiary.opacity(0.2))
            .frame(width: 4, height: 4)
        }
      }
      .padding(.leading, 4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var nextStepPreview: some View {
    ZStack(alignment: .leading) {
      conceptPreviewSurface(accent: colors.accent)
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          RoundedRectangle(cornerRadius: 1).fill(colors.accent.opacity(0.5)).frame(width: 12, height: 2)
          RoundedRectangle(cornerRadius: 1).fill(colors.textPrimary.opacity(0.75)).frame(width: 24, height: 3)
        }
        Spacer(minLength: 0)
        RoundedRectangle(cornerRadius: 1).fill(colors.textTertiary.opacity(0.45)).frame(width: 3, height: 6)
      }
      .padding(.horizontal, 4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

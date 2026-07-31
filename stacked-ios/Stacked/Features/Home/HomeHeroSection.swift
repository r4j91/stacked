import SwiftUI

struct HomeHeroSection: View {
  @Environment(ThemeManager.self) private var theme

  let style: HomeHeroStyle
  let store: HomeStore
  var onOpenFilter: (TaskFilterKind) -> Void
  var onRetry: () -> Void

  @AppStorage(HomeHeroFrameStorage.key) private var frameRaw = HomeHeroFrameStorage.defaultRawValue
  @AppStorage(HomeSectionStyleStorage.key) private var sectionStyleRaw = HomeSectionStyleStorage.defaultRawValue
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue

  private var isOverdue: Bool { store.overdueCount > 0 }

  private var metrics: HomeHeroMetrics {
    HomeHeroMetrics.forScale(AppTypeScaleStorage.scale(from: typeScaleRaw))
  }

  private var frame: HomeHeroFrameResolution {
    HomeHeroFrameStorage.frame(from: frameRaw)
      .resolved(sectionStyle: HomeSectionStyleStorage.style(from: sectionStyleRaw))
  }

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
          framedHeroContent
        }
      }
      .listRowInsets(heroInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
    }
  }

  /// Aberto mantém os insets de sempre; em card, a margem lateral passa a ser a do
  /// container das seções para o topo alinhar com Visão geral e Projetos.
  private var heroInsets: EdgeInsets {
    switch frame {
    case .open:
      return EdgeInsets(top: 8, leading: AppSpacing.xl, bottom: AppSpacing.sm, trailing: AppSpacing.xl)
    case .card:
      let inset = HomeSectionStyle.container.metrics.containerInsetH
      return EdgeInsets(top: 8, leading: inset, bottom: AppSpacing.sm, trailing: inset)
    }
  }

  @ViewBuilder
  private var framedHeroContent: some View {
    let c = theme.colors
    let radius = HomeSectionStyle.container.metrics.cornerRadius

    switch frame {
    case .open:
      heroContent
    case .card(let bordered):
      heroContent
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
          RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(c.surface)
        }
        .overlay {
          if bordered {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
              .strokeBorder(
                (c.isDark ? Color.white : Color.black).opacity(c.isDark ? 0.08 : 0.06),
                lineWidth: 1
              )
          }
        }
    }
  }

  @ViewBuilder
  private var heroContent: some View {
    switch style {
    case .masthead:
      HomeHeroMastheadCard(
        store: store,
        metrics: metrics,
        isOverdue: isOverdue,
        showsBaseDivider: !frame.isCard,
        onOpenFilter: onOpenFilter
      )
    case .dayRail:
      HomeHeroDayRailCard(
        store: store, metrics: metrics, isOverdue: isOverdue, onOpenFilter: onOpenFilter
      )
    }
  }
}

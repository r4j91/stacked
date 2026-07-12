import SwiftUI

/// Atalho para a variante original da Jornada diária.
struct HomeHeroJourneyDailyCard: View {
  let store: HomeStore
  let metrics: HomeHeroMetrics
  let isOverdue: Bool
  var onOpenFilter: (TaskFilterKind) -> Void

  var body: some View {
    HomeHeroJourneyCard(
      store: store,
      metrics: metrics,
      art: .daily,
      isOverdue: isOverdue,
      onOpenFilter: onOpenFilter
    )
  }
}

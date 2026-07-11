import SwiftUI
import Supabase

// Paridade lib/screens/productivity_screen.dart
struct ProductivityView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var tab = 0
  @State private var loading = true
  @State private var completionDates: [Date] = []
  @State private var todayCompletedCount = 0
  @State private var totalCompleted = 0
  @State private var displayName = ""
  @State private var taskStore = TaskStore.shared

  private let repo = TaskRepository.shared
  private var client: SupabaseClient { SupabaseService.client }

  var body: some View {
    let c = theme.colors

    VStack(spacing: 0) {
      SheetDragHandle()

      HStack(alignment: .firstTextBaseline) {
        Text("Relatório")
          .font(AppTypography.sheetTitle)
          .foregroundStyle(c.textPrimary)
        Spacer()
        ModalChrome.closeTextButton(dismiss: dismiss, accent: c.accent)
      }
      .padding(.horizontal, 16)
      .padding(.top, 4)
      .padding(.bottom, 2)

      if loading && completionDates.isEmpty && todayCompletedCount == 0 {
        Spacer()
        ProgressView().tint(c.accent)
        Spacer()
      } else {
        ScrollView {
          VStack(spacing: 0) {
            profileCard
            segmentedControl
            tabContent
          }
          .padding(.bottom, 24)
        }
      }
    }
    .background(c.background)
    .presentationDetents([.large])
    .presentationDragIndicator(.hidden)
    .task { await load(initial: true) }
    .onAppear { _Concurrency.Task { await load(initial: false) } }
    .onChange(of: taskStore.todayCompleted.count) { _, _ in
      _Concurrency.Task { await load(initial: false) }
    }
    .onChange(of: taskStore.inboxCompleted.count) { _, _ in
      _Concurrency.Task { await load(initial: false) }
    }
  }

  // MARK: - Profile

  private var profileCard: some View {
    let c = theme.colors
    let store = HomeStore.shared
    let email = client.auth.currentUser?.email ?? ""
    let name = displayName.isEmpty ? (email.split(separator: "@").first.map(String.init) ?? "") : displayName

    return HStack(spacing: 14) {
      UserAvatarView(
        url: store.avatarURL,
        initials: store.avatarInitials,
        size: 48
      )

      VStack(alignment: .leading, spacing: 2) {
        Text(name.isEmpty ? "Conta" : name)
          .font(AppTypography.bodySemibold)
          .foregroundStyle(c.textPrimary)
        Text("\(totalCompleted) tarefas concluídas")
          .font(AppTypography.screenSubtitle)
          .foregroundStyle(c.textTertiary)
      }
      Spacer()
    }
    .padding(16)
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .padding(.horizontal, 16)
    .padding(.top, 16)
  }

  // MARK: - Tabs

  private var segmentedControl: some View {
    let c = theme.colors
    let tabs = ["Diário", "Semanal"]

    return HStack(spacing: 0) {
      ForEach(tabs.indices, id: \.self) { i in
        let active = tab == i
        Button {
          HapticService.prepareTabChange()
          HapticService.tabChanged()
          // SUBSTITUIDO_FASE2: withAnimation(.easeOut(duration: 0.2)) { tab = i }
          AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) { tab = i }
        } label: {
          Text(tabs[i])
            .font(AppTypography.meta)
            .fontWeight(active ? .semibold : .regular)
            .foregroundStyle(active ? c.textPrimary : c.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(active ? c.surfaceVariant : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(3)
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, 16)
    .padding(.top, 16)
    .padding(.bottom, 4)
  }

  @ViewBuilder
  private var tabContent: some View {
    if tab == 0 {
      dailyTab
    } else {
      weeklyTab
    }
  }

  private var dailyTab: some View {
    VStack(spacing: 10) {
      productivityCard(alignment: .center) {
        HStack(spacing: 8) {
          Image(systemName: "checkmark.circle")
            .font(.system(size: 18))
            .foregroundStyle(theme.colors.accent)
          Text("Concluídas hoje")
            .font(AppTypography.cardHeading)
            .foregroundStyle(theme.colors.textPrimary)
        }
        .frame(maxWidth: .infinity)

        Text("\(todayCount)")
          .font(AppTypography.metricHero)
          .foregroundStyle(theme.colors.textPrimary)
          .padding(.top, 12)
        Text(todayCount == 1 ? "tarefa" : "tarefas")
          .font(AppTypography.screenSubtitle)
          .foregroundStyle(theme.colors.textTertiary)
      }

      productivityCard {
        Text("Últimos 7 dias")
          .font(AppTypography.cardHeading)
          .foregroundStyle(theme.colors.textPrimary)
        HorizontalBarChart(
          values: last7Days,
          maxValue: max(1, last7Days.max() ?? 0),
          accent: theme.colors.accent,
          track: theme.colors.surfaceVariant,
          textSecondary: theme.colors.textSecondary,
          textTertiary: theme.colors.textTertiary
        )
        .padding(.top, 16)
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
  }

  private var weeklyTab: some View {
    let diff: Int? = {
      guard lastWeekTotal > 0 else { return nil }
      return Int((Double(thisWeekTotal - lastWeekTotal) / Double(lastWeekTotal) * 100).rounded())
    }()

    return VStack(spacing: 10) {
      HStack(spacing: 10) {
        productivityCard {
          Text("Esta semana")
            .font(AppTypography.meta)
            .foregroundStyle(theme.colors.textTertiary)
          Text("\(thisWeekTotal)")
            .font(AppTypography.metricHeroCompact)
            .foregroundStyle(theme.colors.textPrimary)
            .padding(.top, 6)
          Text("tarefas")
            .font(AppTypography.metaSmall)
            .foregroundStyle(theme.colors.textTertiary)
        }

        productivityCard {
          Text("Semana anterior")
            .font(AppTypography.meta)
            .foregroundStyle(theme.colors.textTertiary)
          Text("\(lastWeekTotal)")
            .font(AppTypography.metricHeroCompact)
            .foregroundStyle(theme.colors.textPrimary)
            .padding(.top, 6)
          if let diff {
            HStack(spacing: 2) {
              Image(systemName: diff >= 0 ? "arrow.up" : "arrow.down")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(diff >= 0 ? theme.colors.textSecondary : theme.colors.textTertiary)
              Text("\(abs(diff))%")
                .font(AppTypography.metaSmall)
                .fontWeight(.semibold)
                .foregroundStyle(diff >= 0 ? theme.colors.textSecondary : theme.colors.textTertiary)
            }
          } else {
            Text("—")
              .font(AppTypography.metaSmall)
              .foregroundStyle(theme.colors.textTertiary)
          }
        }
      }

      productivityCard {
        Text("Por dia da semana")
          .font(AppTypography.cardHeading)
          .foregroundStyle(theme.colors.textPrimary)
        HorizontalBarChart(
          values: weekByDay,
          maxValue: max(1, weekByDay.max() ?? 0),
          labels: ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"],
          accent: theme.colors.accent,
          track: theme.colors.surfaceVariant,
          textSecondary: theme.colors.textSecondary,
          textTertiary: theme.colors.textTertiary
        )
        .padding(.top, 16)
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
  }

  private func productivityCard<Content: View>(
    alignment: HorizontalAlignment = .leading,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: alignment, spacing: 4) {
      content()
    }
    .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
    .padding(16)
    .background(theme.colors.surface)
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }

  // MARK: - Metrics

  private var today: Date {
    Calendar.current.startOfDay(for: Date())
  }

  private var todayCount: Int {
    todayCompletedCount
  }

  private var last7Days: [Int] {
    (0..<7).map { offset in
      let day = Calendar.current.date(byAdding: .day, value: offset - 6, to: today)!
      return completionDates.filter { Calendar.current.isDate($0, inSameDayAs: day) }.count
    }
  }

  private var thisWeekTotal: Int {
    let weekday = Calendar.current.component(.weekday, from: today)
    let daysFromMonday = (weekday + 5) % 7
    let monday = Calendar.current.date(byAdding: .day, value: -daysFromMonday, to: today)!
    return completionDates.filter { $0 >= monday }.count
  }

  private var lastWeekTotal: Int {
    let weekday = Calendar.current.component(.weekday, from: today)
    let daysFromMonday = (weekday + 5) % 7
    let thisMonday = Calendar.current.date(byAdding: .day, value: -daysFromMonday, to: today)!
    let lastMonday = Calendar.current.date(byAdding: .day, value: -7, to: thisMonday)!
    return completionDates.filter { $0 >= lastMonday && $0 < thisMonday }.count
  }

  private var weekByDay: [Int] {
    let weekday = Calendar.current.component(.weekday, from: today)
    let daysFromMonday = (weekday + 5) % 7
    let monday = Calendar.current.date(byAdding: .day, value: -daysFromMonday, to: today)!
    return (0..<7).map { offset in
      let day = Calendar.current.date(byAdding: .day, value: offset, to: monday)!
      return completionDates.filter { Calendar.current.isDate($0, inSameDayAs: day) }.count
    }
  }

  // MARK: - Data

  private func load(initial: Bool) async {
    if initial { loading = true }
    defer { if initial { loading = false } }

    let meta = client.auth.currentUser?.userMetadata ?? [:]
    let apelido = metadataString(meta["apelido"])
    let nome = metadataString(meta["nome"])
    if !apelido.isEmpty {
      displayName = apelido
    } else if !nome.isEmpty {
      displayName = nome.split(separator: " ").first.map(String.init) ?? nome
    } else {
      displayName = client.auth.currentUser?.email?.split(separator: "@").first.map(String.init) ?? ""
    }

    do {
      let weekday = Calendar.current.component(.weekday, from: today)
      let daysFromMonday = (weekday + 5) % 7
      let thisMonday = Calendar.current.date(byAdding: .day, value: -daysFromMonday, to: today)!
      let lastMonday = Calendar.current.date(byAdding: .day, value: -7, to: thisMonday)!

      async let completionTimestamps = repo.fetchProductivityCompletionDates(since: lastMonday)
      async let completedToday = repo.fetchCompletedTodayTasks()
      async let totalCount = repo.countAllCompletedTasks()

      let (timestamps, todayTasks, total) = try await (completionTimestamps, completedToday, totalCount)
      completionDates = timestamps
      todayCompletedCount = todayTasks.count
      totalCompleted = total
    } catch {
      if !initial {
        return
      }
      completionDates = []
      todayCompletedCount = 0
      totalCompleted = 0
    }
  }

  private func metadataString(_ value: AnyJSON?) -> String {
    guard let value else { return "" }
    if let s = value.stringValue { return s.trimmingCharacters(in: .whitespacesAndNewlines) }
    return String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

// MARK: - Bar chart

private struct HorizontalBarChart: View {
  let values: [Int]
  let maxValue: Int
  var labels: [String]?
  let accent: Color
  let track: Color
  let textSecondary: Color
  let textTertiary: Color

  var body: some View {
    let dayNames = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]
    let now = Calendar.current.startOfDay(for: Date())
    let defaultLabels = (0..<7).map { i in
      let day = Calendar.current.date(byAdding: .day, value: i - 6, to: now)!
      let weekday = Calendar.current.component(.weekday, from: day)
      return dayNames[(weekday + 5) % 7]
    }
    let usedLabels = labels ?? defaultLabels

    VStack(spacing: 8) {
      ForEach(values.indices, id: \.self) { i in
        let val = values[i]
        let ratio = maxValue > 0 ? CGFloat(val) / CGFloat(maxValue) : 0
        HStack(spacing: 8) {
          Text(usedLabels[i])
            .font(AppTypography.metaSmall)
            .foregroundStyle(textTertiary)
            .frame(width: 32, alignment: .leading)

          GeometryReader { geo in
            ZStack(alignment: .leading) {
              RoundedRectangle(cornerRadius: 6)
                .fill(track)
                .frame(height: 20)
              RoundedRectangle(cornerRadius: 6)
                .fill(
                  LinearGradient(
                    colors: [accent.opacity(0.45), accent],
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
                .frame(width: geo.size.width * ratio, height: 20)
            }
          }
          .frame(height: 20)

          Text("\(val)")
            .font(AppTypography.metaSmall)
            .fontWeight(.semibold)
            .foregroundStyle(val > 0 ? textSecondary : textTertiary)
            .frame(width: 24, alignment: .trailing)
        }
      }
    }
  }
}

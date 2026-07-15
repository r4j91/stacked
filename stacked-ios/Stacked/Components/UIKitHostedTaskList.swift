import SwiftUI
import UIKit

/// Tipo de cabeçalho de seção — paridade com `List` / `CollapsibleSectionHeader`.
enum UIKitTaskSectionHeader: Equatable {
  case plain(String)
  case collapsible(title: String, count: Int, expanded: Bool)
  case completedToggle(count: Int, expanded: Bool)
}

/// Seção de tarefas para a lista UIKit.
struct UIKitTaskSection: Equatable {
  var id: String
  var header: UIKitTaskSectionHeader?
  var tasks: [Task]
  var dimmed: Bool = false
  var projectSection: ProjectSection? = nil

  init(
    id: String,
    title: String? = nil,
    tasks: [Task],
    dimmed: Bool = false,
    projectSection: ProjectSection? = nil
  ) {
    self.id = id
    if let title, !title.isEmpty {
      self.header = .plain(title)
    } else {
      self.header = nil
    }
    self.tasks = tasks
    self.dimmed = dimmed
    self.projectSection = projectSection
  }

  init(
    id: String,
    header: UIKitTaskSectionHeader?,
    tasks: [Task],
    dimmed: Bool = false,
    projectSection: ProjectSection? = nil
  ) {
    self.id = id
    self.header = header
    self.tasks = tasks
    self.dimmed = dimmed
    self.projectSection = projectSection
  }
}

/// UICollectionView + `UIHostingConfiguration` — baseline fluido (919c1ec) + seções/modos.
struct UIKitHostedTaskList: UIViewControllerRepresentable {
  var sections: [UIKitTaskSection]
  var showProject: Bool = true
  var style: TaskRowStyle = .card
  var flatSubtaskQueue: Bool = false
  var rowInsets: EdgeInsets = EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
  var background: Color
  var leadingChrome: (() -> AnyView)? = nil
  var onToggleSection: ((String) -> Void)? = nil
  var onRenameSection: ((ProjectSection) -> Void)? = nil
  var onDeleteSection: ((ProjectSection) -> Void)? = nil
  var onToggle: (Task) -> Void
  var onTap: (Task) -> Void
  var onSubtaskTap: (Task, Subtask) -> Void
  var onSubtaskChanged: (SubtaskSaveSnapshot) -> Void
  var onSubtaskDeleted: (Task, Subtask) -> Void
  var onEdit: (Task) -> Void
  var onComplete: (Task) -> Void
  var onDuplicate: (Task) -> Void
  var onDelete: (Task) -> Void
  var onRefresh: () -> Void
  var onWhatsAppCopy: ((Task) -> Void)? = nil

  init(
    tasks: [Task],
    showProject: Bool = true,
    style: TaskRowStyle = .card,
    flatSubtaskQueue: Bool = false,
    rowInsets: EdgeInsets = EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16),
    background: Color,
    leadingChrome: (() -> AnyView)? = nil,
    onToggleSection: ((String) -> Void)? = nil,
    onRenameSection: ((ProjectSection) -> Void)? = nil,
    onDeleteSection: ((ProjectSection) -> Void)? = nil,
    onToggle: @escaping (Task) -> Void,
    onTap: @escaping (Task) -> Void,
    onSubtaskTap: @escaping (Task, Subtask) -> Void,
    onSubtaskChanged: @escaping (SubtaskSaveSnapshot) -> Void,
    onSubtaskDeleted: @escaping (Task, Subtask) -> Void,
    onEdit: @escaping (Task) -> Void,
    onComplete: @escaping (Task) -> Void,
    onDuplicate: @escaping (Task) -> Void,
    onDelete: @escaping (Task) -> Void,
    onRefresh: @escaping () -> Void,
    onWhatsAppCopy: ((Task) -> Void)? = nil
  ) {
    self.init(
      sections: [UIKitTaskSection(id: "main", title: nil, tasks: tasks)],
      showProject: showProject,
      style: style,
      flatSubtaskQueue: flatSubtaskQueue,
      rowInsets: rowInsets,
      background: background,
      leadingChrome: leadingChrome,
      onToggleSection: onToggleSection,
      onRenameSection: onRenameSection,
      onDeleteSection: onDeleteSection,
      onToggle: onToggle,
      onTap: onTap,
      onSubtaskTap: onSubtaskTap,
      onSubtaskChanged: onSubtaskChanged,
      onSubtaskDeleted: onSubtaskDeleted,
      onEdit: onEdit,
      onComplete: onComplete,
      onDuplicate: onDuplicate,
      onDelete: onDelete,
      onRefresh: onRefresh,
      onWhatsAppCopy: onWhatsAppCopy
    )
  }

  init(
    sections: [UIKitTaskSection],
    showProject: Bool = true,
    style: TaskRowStyle = .card,
    flatSubtaskQueue: Bool = false,
    rowInsets: EdgeInsets = EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16),
    background: Color,
    leadingChrome: (() -> AnyView)? = nil,
    onToggleSection: ((String) -> Void)? = nil,
    onRenameSection: ((ProjectSection) -> Void)? = nil,
    onDeleteSection: ((ProjectSection) -> Void)? = nil,
    onToggle: @escaping (Task) -> Void,
    onTap: @escaping (Task) -> Void,
    onSubtaskTap: @escaping (Task, Subtask) -> Void,
    onSubtaskChanged: @escaping (SubtaskSaveSnapshot) -> Void,
    onSubtaskDeleted: @escaping (Task, Subtask) -> Void,
    onEdit: @escaping (Task) -> Void,
    onComplete: @escaping (Task) -> Void,
    onDuplicate: @escaping (Task) -> Void,
    onDelete: @escaping (Task) -> Void,
    onRefresh: @escaping () -> Void,
    onWhatsAppCopy: ((Task) -> Void)? = nil
  ) {
    self.sections = sections
    self.showProject = showProject
    self.style = style
    self.flatSubtaskQueue = flatSubtaskQueue
    self.rowInsets = rowInsets
    self.background = background
    self.leadingChrome = leadingChrome
    self.onToggleSection = onToggleSection
    self.onRenameSection = onRenameSection
    self.onDeleteSection = onDeleteSection
    self.onToggle = onToggle
    self.onTap = onTap
    self.onSubtaskTap = onSubtaskTap
    self.onSubtaskChanged = onSubtaskChanged
    self.onSubtaskDeleted = onSubtaskDeleted
    self.onEdit = onEdit
    self.onComplete = onComplete
    self.onDuplicate = onDuplicate
    self.onDelete = onDelete
    self.onRefresh = onRefresh
    self.onWhatsAppCopy = onWhatsAppCopy
  }

  func makeUIViewController(context: Context) -> UIKitHostedTaskListController {
    let vc = UIKitHostedTaskListController()
    vc.apply(configuration: makeConfig())
    return vc
  }

  func updateUIViewController(_ uiViewController: UIKitHostedTaskListController, context: Context) {
    uiViewController.apply(configuration: makeConfig())
  }

  private func makeConfig() -> UIKitHostedTaskListController.Configuration {
    .init(
      sections: sections,
      showProject: showProject,
      style: style,
      flatSubtaskQueue: flatSubtaskQueue,
      rowInsets: UIEdgeInsets(
        top: rowInsets.top,
        left: rowInsets.leading,
        bottom: rowInsets.bottom,
        right: rowInsets.trailing
      ),
      background: UIColor(background),
      leadingChrome: leadingChrome,
      onToggleSection: onToggleSection,
      onRenameSection: onRenameSection,
      onDeleteSection: onDeleteSection,
      onToggle: onToggle,
      onTap: onTap,
      onSubtaskTap: onSubtaskTap,
      onSubtaskChanged: onSubtaskChanged,
      onSubtaskDeleted: onSubtaskDeleted,
      onEdit: onEdit,
      onComplete: onComplete,
      onDuplicate: onDuplicate,
      onDelete: onDelete,
      onRefresh: onRefresh,
      onWhatsAppCopy: onWhatsAppCopy
    )
  }
}

@MainActor
final class UIKitHostedTaskListController: UIViewController, UICollectionViewDelegate {
  struct Configuration {
    var sections: [UIKitTaskSection]
    var showProject: Bool
    var style: TaskRowStyle
    var flatSubtaskQueue: Bool
    var rowInsets: UIEdgeInsets
    var background: UIColor
    var leadingChrome: (() -> AnyView)?
    var onToggleSection: ((String) -> Void)?
    var onRenameSection: ((ProjectSection) -> Void)?
    var onDeleteSection: ((ProjectSection) -> Void)?
    var onToggle: (Task) -> Void
    var onTap: (Task) -> Void
    var onSubtaskTap: (Task, Subtask) -> Void
    var onSubtaskChanged: (SubtaskSaveSnapshot) -> Void
    var onSubtaskDeleted: (Task, Subtask) -> Void
    var onEdit: (Task) -> Void
    var onComplete: (Task) -> Void
    var onDuplicate: (Task) -> Void
    var onDelete: (Task) -> Void
    var onRefresh: () -> Void
    var onWhatsAppCopy: ((Task) -> Void)?
  }

  private enum SectionID: Hashable {
    case chrome
    case block(String)
  }

  private enum ItemID: Hashable {
    case leadingChrome
    case header(String)
    /// Inclui estilo no id → troca de modo remonta sem reconfigure storm.
    case task(id: String, style: Int)
  }

  private var collectionView: UICollectionView!
  private var dataSource: UICollectionViewDiffableDataSource<SectionID, ItemID>!
  private var config: Configuration?
  private var lastFingerprint: Int = 0
  private var taskById: [String: Task] = [:]
  private var sectionById: [String: UIKitTaskSection] = [:]
  private var dimmedTaskIds: Set<String> = []
  /// Headers observam isto — chevron anima sem remount da cell (reconfigure matava a rotação).
  private let headerFlags = UIKitSectionHeaderFlags()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    var listConfig = UICollectionLayoutListConfiguration(appearance: .plain)
    listConfig.backgroundColor = .clear
    listConfig.showsSeparators = false
    listConfig.headerMode = .none
    let layout = UICollectionViewCompositionalLayout.list(using: listConfig)

    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
    collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    collectionView.backgroundColor = .clear
    collectionView.alwaysBounceVertical = true
    collectionView.delegate = self
    // Automático: safe area (navbar/home). Inset extra = dock+FAB (+home se safe=0).
    collectionView.contentInsetAdjustmentBehavior = .automatic
    // Soft top (blur) hitchava o scroll; hard bottom virava tarja opaca no projeto.
    disableScrollEdgeEffects(on: collectionView)
    view.addSubview(collectionView)
    refreshBottomInset()

    let refresh = UIRefreshControl()
    refresh.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    collectionView.refreshControl = refresh

    let chromeRegistration = UICollectionView.CellRegistration<UICollectionViewCell, String> {
      [weak self] cell, _, _ in
      guard let chrome = self?.config?.leadingChrome else {
        cell.contentConfiguration = nil
        return
      }
      cell.contentConfiguration = UIHostingConfiguration {
        chrome()
          .environment(ThemeManager.shared)
          .environment(MobileChromeController.shared)
      }
      .margins(.all, 0)
      .minSize(height: 1)
    }

    let headerRegistration = UICollectionView.CellRegistration<UICollectionViewCell, String> {
      [weak self] cell, _, sectionId in
      guard let self, let config = self.config, let section = self.sectionById[sectionId] else {
        cell.contentConfiguration = nil
        return
      }
      cell.contentConfiguration = UIHostingConfiguration {
        Self.makeHeaderView(
          section: section,
          flags: self.headerFlags,
          onToggle: { config.onToggleSection?(sectionId) },
          onRename: config.onRenameSection,
          onDelete: config.onDeleteSection
        )
        .padding(.top, 8)
        .padding(.leading, 4)
        .padding(.trailing, 16)
        .environment(ThemeManager.shared)
        .environment(MobileChromeController.shared)
      }
      .margins(.all, 0)
      .minSize(height: 1)
    }

    let taskRegistration = UICollectionView.CellRegistration<UICollectionViewCell, String> {
      [weak self] cell, _, taskId in
      guard let self, let config = self.config, let task = self.taskById[taskId] else {
        cell.contentConfiguration = nil
        return
      }
      let dimmed = self.dimmedTaskIds.contains(taskId)
      let insets = config.rowInsets

      cell.contentConfiguration = UIHostingConfiguration {
        TaskRow(
          task: task,
          style: config.style,
          flatSubtaskPanel: config.flatSubtaskQueue,
          showProject: config.showProject,
          deferHeavyWork: false,
          restoreExpansionOnAppear: false,
          stabilizeExpandInSelfSizingCell: true,
          onToggle: { config.onToggle(task) },
          onTap: { config.onTap(task) },
          onSubtaskTap: { config.onSubtaskTap(task, $0) },
          onSubtaskChanged: config.onSubtaskChanged,
          onSubtaskDeleted: { config.onSubtaskDeleted(task, $0) },
          onWhatsAppCopy: config.onWhatsAppCopy.map { handler in { handler(task) } }
        )
        // Top-leading: no centro vertical durante o grow da cell (título “chutava”).
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.top, insets.top)
        .padding(.leading, insets.left)
        .padding(.bottom, insets.bottom)
        .padding(.trailing, insets.right)
        .opacity(dimmed ? 0.7 : 1)
        .taskContextMenu(
          task: task,
          onEdit: { config.onEdit(task) },
          onComplete: { config.onComplete(task) },
          onDuplicate: { config.onDuplicate(task) },
          onDelete: { config.onDelete(task) },
          onRefresh: config.onRefresh
        )
        .environment(ThemeManager.shared)
        .environment(MobileChromeController.shared)
      }
      .margins(.all, 0)
      .minSize(height: 1)
    }

    dataSource = UICollectionViewDiffableDataSource<SectionID, ItemID>(
      collectionView: collectionView
    ) { collectionView, indexPath, item in
      switch item {
      case .leadingChrome:
        return collectionView.dequeueConfiguredReusableCell(
          using: chromeRegistration,
          for: indexPath,
          item: "chrome"
        )
      case .header(let sectionId):
        return collectionView.dequeueConfiguredReusableCell(
          using: headerRegistration,
          for: indexPath,
          item: sectionId
        )
      case .task(let id, _):
        return collectionView.dequeueConfiguredReusableCell(
          using: taskRegistration,
          for: indexPath,
          item: id
        )
      }
    }
  }

  /// Soft top = blur variável (stutter). Hard bottom = tarja opaca (print do projeto).
  private func disableScrollEdgeEffects(on scrollView: UIScrollView) {
    if #available(iOS 26.0, *) {
      scrollView.topEdgeEffect.isHidden = true
      scrollView.bottomEdgeEffect.isHidden = true
    }
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    refreshBottomInset()
  }

  /// Dock+FAB+folga. Se o shell zerou o safe bottom (full-bleed), soma o home indicator.
  private func refreshBottomInset() {
    guard collectionView != nil else { return }
    let chrome = AppLayout.fabSize
      + AppLayout.fabGap
      + AppLayout.bottomNavPillHeight
      + AppLayout.bottomNavPillMargin
      + 8
    let home = collectionView.safeAreaInsets.bottom < 1
      ? AppLayout.windowSafeBottomInsetCached
      : 0
    let inset = chrome + home
    guard abs(collectionView.contentInset.bottom - inset) > 0.5 else { return }
    collectionView.contentInset.bottom = inset
    collectionView.verticalScrollIndicatorInsets.bottom = inset
  }

  func apply(configuration: Configuration) {
    if collectionView == nil {
      loadViewIfNeeded()
    }

    let fingerprint = Self.fingerprint(configuration)
    // Callbacks sempre frescos; snapshot só se a estrutura/modo mudou.
    config = configuration

    var map: [String: Task] = [:]
    var sectionsMap: [String: UIKitTaskSection] = [:]
    var dimmed: Set<String> = []
    for section in configuration.sections {
      sectionsMap[section.id] = section
      for task in section.tasks {
        map[task.id] = task
        if section.dimmed { dimmed.insert(task.id) }
      }
    }
    taskById = map
    sectionById = sectionsMap
    dimmedTaskIds = dimmed
    headerFlags.publish(from: configuration.sections)

    view.backgroundColor = configuration.background
    collectionView.backgroundColor = configuration.background

    if fingerprint == lastFingerprint {
      return
    }
    lastFingerprint = fingerprint

    let styleCode = Self.styleCode(configuration.style)
    var snapshot = NSDiffableDataSourceSnapshot<SectionID, ItemID>()
    if configuration.leadingChrome != nil {
      snapshot.appendSections([.chrome])
      snapshot.appendItems([.leadingChrome], toSection: .chrome)
    }
    for section in configuration.sections {
      let sid = SectionID.block(section.id)
      snapshot.appendSections([sid])
      var items: [ItemID] = []
      if section.header != nil {
        items.append(.header(section.id))
      }
      let showTasks: Bool
      switch section.header {
      case .collapsible(_, _, let expanded):
        showTasks = expanded
      case .completedToggle(_, let expanded):
        showTasks = expanded
      case .plain, .none:
        showTasks = true
      }
      if showTasks {
        items.append(contentsOf: section.tasks.map { .task(id: $0.id, style: styleCode) })
      }
      snapshot.appendItems(items, toSection: sid)
    }
    dataSource.apply(snapshot, animatingDifferences: false)
  }

  private static func styleCode(_ style: TaskRowStyle) -> Int {
    switch style {
    case .card: 0
    case .cardLight: 1
    case .list: 2
    case .listPremium: 3
    }
  }

  private static func fingerprint(_ configuration: Configuration) -> Int {
    var hasher = Hasher()
    hasher.combine(configuration.leadingChrome != nil)
    hasher.combine(configuration.showProject)
    hasher.combine(configuration.flatSubtaskQueue)
    hasher.combine(configuration.rowInsets.left)
    hasher.combine(configuration.rowInsets.top)
    hasher.combine(styleCode(configuration.style))
    for section in configuration.sections {
      hasher.combine(section.id)
      hasher.combine(section.dimmed)
      switch section.header {
      case .plain(let t):
        hasher.combine(0)
        hasher.combine(t)
      case .collapsible(let t, let c, let e):
        hasher.combine(1)
        hasher.combine(t)
        hasher.combine(c)
        hasher.combine(e)
      case .completedToggle(let c, let e):
        hasher.combine(2)
        hasher.combine(c)
        hasher.combine(e)
      case .none:
        hasher.combine(3)
      }
      for task in section.tasks {
        hasher.combine(task.id)
      }
    }
    return hasher.finalize()
  }

  private static func makeHeaderView(
    section: UIKitTaskSection,
    flags: UIKitSectionHeaderFlags,
    onToggle: @escaping () -> Void,
    onRename: ((ProjectSection) -> Void)?,
    onDelete: ((ProjectSection) -> Void)?
  ) -> AnyView {
    switch section.header {
    case .plain(let text):
      return AnyView(
        ListSectionHeader(text: text)
          .frame(maxWidth: .infinity, alignment: .leading)
      )
    case .collapsible:
      return AnyView(
        UIKitObservedCollapsibleHeader(
          flags: flags,
          sectionId: section.id,
          onToggle: onToggle,
          section: section.projectSection,
          onRename: onRename,
          onDelete: onDelete
        )
      )
    case .completedToggle:
      return AnyView(
        UIKitObservedCompletedToggle(
          flags: flags,
          sectionId: section.id,
          onToggle: onToggle
        )
      )
    case .none:
      return AnyView(EmptyView())
    }
  }

  @objc private func handleRefresh() {
    config?.onRefresh()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
      self?.collectionView.refreshControl?.endRefreshing()
    }
  }

  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    reportScrolling(true)
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate { reportScrolling(false) }
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    reportScrolling(false)
  }

  private func reportScrolling(_ scrolling: Bool) {
    guard !AlwaysStaticGlassStorage.isEnabled,
          !AlwaysFrozenDockGlassStorage.isEnabled,
          !DisableAllGlassStorage.isEnabled,
          FreezeDockGlassWhileScrollingStorage.isEnabled
    else { return }
    MobileChromeController.shared.setContentScrolling(scrolling)
  }
}

/// Estado vivo dos headers — atualiza chevron/count sem trocar a `UIHostingConfiguration`.
private final class UIKitSectionHeaderFlags: ObservableObject {
  struct Info: Equatable {
    var title: String
    var count: Int
    var expanded: Bool
  }

  @Published var byId: [String: Info] = [:]

  func publish(from sections: [UIKitTaskSection]) {
    var next: [String: Info] = [:]
    next.reserveCapacity(sections.count)
    for section in sections {
      switch section.header {
      case .collapsible(let title, let count, let expanded):
        next[section.id] = Info(title: title, count: count, expanded: expanded)
      case .completedToggle(let count, let expanded):
        next[section.id] = Info(title: "Concluídas", count: count, expanded: expanded)
      case .plain, .none:
        break
      }
    }
    if next != byId {
      byId = next
    }
  }
}

private struct UIKitObservedCollapsibleHeader: View {
  @ObservedObject var flags: UIKitSectionHeaderFlags
  let sectionId: String
  let onToggle: () -> Void
  var section: ProjectSection?
  var onRename: ((ProjectSection) -> Void)?
  var onDelete: ((ProjectSection) -> Void)?

  var body: some View {
    let info = flags.byId[sectionId]
    CollapsibleSectionHeader(
      title: info?.title ?? "",
      count: info?.count ?? 0,
      expanded: info?.expanded ?? true,
      onToggle: onToggle,
      section: section,
      onRename: onRename,
      onDelete: onDelete
    )
  }
}

private struct UIKitObservedCompletedToggle: View {
  @Environment(ThemeManager.self) private var theme
  @ObservedObject var flags: UIKitSectionHeaderFlags
  let sectionId: String
  let onToggle: () -> Void

  var body: some View {
    let c = theme.colors
    let info = flags.byId[sectionId]
    let count = info?.count ?? 0
    let expanded = info?.expanded ?? false
    Button(action: onToggle) {
      HStack {
        Text("Concluídas (\(count))")
          .font(AppTypography.completedSectionHeader)
          .foregroundStyle(c.textSecondary)
        Spacer()
        Image(systemName: expanded ? "chevron.up" : "chevron.down")
          .font(AppTypography.metaSmall.weight(.semibold))
          .foregroundStyle(c.textTertiary)
          .animation(AppMotion.subtaskChevronTurnSpring, value: expanded)
      }
    }
    .buttonStyle(.plain)
  }
}

enum UIKitScheduleSupport {
  static func onlyTasks(_ items: [ScheduleItem]) -> [Task]? {
    var out: [Task] = []
    out.reserveCapacity(items.count)
    for item in items {
      guard case .task(let task) = item else { return nil }
      out.append(task)
    }
    return out
  }

  static func allTaskOnly(_ lists: [[ScheduleItem]]) -> Bool {
    lists.allSatisfy { onlyTasks($0) != nil }
  }
}

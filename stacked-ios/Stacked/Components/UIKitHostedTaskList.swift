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
    // UIKIT_SCROLL_POLISH: insets crus → pixel-snapped (altura total da cell no grid).
    let snappedInsets = UIEdgeInsets(
      top: AppLayout.pixelSnap(rowInsets.top),
      left: AppLayout.pixelSnap(rowInsets.leading),
      bottom: AppLayout.pixelSnap(rowInsets.bottom),
      right: AppLayout.pixelSnap(rowInsets.trailing)
    )
    return .init(
      sections: sections,
      showProject: showProject,
      style: style,
      flatSubtaskQueue: flatSubtaskQueue,
      rowInsets: snappedInsets,
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

/// Cell com altura travada no layout — evita jump 0→full quando o recycle remonta o SwiftUI.
final class UIKitSizedTaskCell: UICollectionViewListCell {
  /// Preferida pelo layout da collection (antes do sizeThatFits do hosting).
  var lockedHeight: CGFloat?

  override func prepareForReuse() {
    super.prepareForReuse()
    lockedHeight = nil
  }

  /// ListCell default = fundo preto do sistema — vaza nos gaps de altura.
  func applyClearChrome() {
    var bg = UIBackgroundConfiguration.clear()
    bg.backgroundColor = .clear
    backgroundConfiguration = bg
    backgroundColor = .clear
    contentView.backgroundColor = .clear
  }

  override func preferredLayoutAttributesFitting(
    _ layoutAttributes: UICollectionViewLayoutAttributes
  ) -> UICollectionViewLayoutAttributes {
    let attrs = super.preferredLayoutAttributesFitting(layoutAttributes)
    guard let lockedHeight, lockedHeight > 1 else { return attrs }
    attrs.frame.size.height = lockedHeight
    return attrs
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
  /// Conteúdo da task (subtasks done/título) — fingerprint estrutural ignora isto.
  private var taskContentHashById: [String: Int] = [:]
  /// Altura medida da row com painel expandido — remount no fling não cresce 0→full.
  private var expandedRowHeightCache: [String: CGFloat] = [:]
  /// Cancela lock agendado se o usuário fechar antes.
  private var expansionGeneration: [String: UInt] = [:]
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
    warmRowIconCache()

    let chromeRegistration = UICollectionView.CellRegistration<UICollectionViewCell, String> {
      [weak self] cell, _, _ in
      guard let chrome = self?.config?.leadingChrome else {
        // UIKIT_SCROLL_POLISH: cell.contentConfiguration = nil
        UIView.performWithoutAnimation { cell.contentConfiguration = nil }
        return
      }
      // UIKIT_SCROLL_POLISH: atribuição direta de contentConfiguration
      UIView.performWithoutAnimation {
        var clearBg = UIBackgroundConfiguration.clear()
        clearBg.backgroundColor = .clear
        cell.backgroundConfiguration = clearBg
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.contentConfiguration = UIHostingConfiguration {
          chrome()
            .environment(ThemeManager.shared)
            .environment(MobileChromeController.shared)
        }
        .margins(.all, 0)
        .minSize(height: 1)
      }
    }

    let headerRegistration = UICollectionView.CellRegistration<UICollectionViewCell, String> {
      [weak self] cell, _, sectionId in
      guard let self, let config = self.config, let section = self.sectionById[sectionId] else {
        UIView.performWithoutAnimation { cell.contentConfiguration = nil }
        return
      }
      UIView.performWithoutAnimation {
        var clearBg = UIBackgroundConfiguration.clear()
        clearBg.backgroundColor = .clear
        cell.backgroundConfiguration = clearBg
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
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
    }

    let taskRegistration = UICollectionView.CellRegistration<UIKitSizedTaskCell, String> {
      [weak self] cell, _, taskId in
      guard let self, let config = self.config, let task = self.taskById[taskId] else {
        UIView.performWithoutAnimation { cell.contentConfiguration = nil }
        return
      }
      let dimmed = self.dimmedTaskIds.contains(taskId)
      let insets = config.rowInsets

      UIView.performWithoutAnimation {
        cell.applyClearChrome()
        // minSize = sempre só header.
        // lockedHeight = só cache MEDIDO (estimativa alta = buraco preto sob o card).
        let isExpanded =
          task.hasSubtasks
          && ProjectDetailPreferences.isSubtaskListExpanded(taskId: taskId)
        let headerMin = AppLayout.estimatedUIKitTaskRowHeight(
          task: task,
          showProject: config.showProject,
          expanded: false,
          rowInsets: insets,
          cachedHeight: nil
        )
        if isExpanded, let cached = self.expandedRowHeightCache[taskId], cached > headerMin {
          cell.lockedHeight = cached
        } else {
          cell.lockedHeight = nil
        }

        cell.contentConfiguration = UIHostingConfiguration {
          TaskRow(
            task: task,
            style: config.style,
            flatSubtaskPanel: config.flatSubtaskQueue,
            showProject: config.showProject,
            deferHeavyWork: false,
            // Recycle: init já seeda expansão — sem false→true no onAppear.
            restoreExpansionOnAppear: true,
            stabilizeExpandInSelfSizingCell: true,
            onToggle: { config.onToggle(task) },
            onTap: { config.onTap(task) },
            onSubtaskTap: { config.onSubtaskTap(task, $0) },
            onSubtaskChanged: config.onSubtaskChanged,
            onSubtaskDeleted: { config.onSubtaskDeleted(task, $0) },
            onWhatsAppCopy: config.onWhatsAppCopy.map { handler in { handler(task) } },
            onSubtaskExpansionChanged: { [weak self] expanded in
              self?.handleSubtaskExpansionChanged(taskId: taskId, expanded: expanded)
            }
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
        .minSize(height: headerMin)
      }
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

  /// UIKIT_SCROLL_POLISH: decode/raster fora do cell configure.
  private func warmRowIconCache() {
    let colors = ThemeManager.shared.colors
    UIKitRowIconRaster.warmCommon(
      textTertiary: UIColor(colors.textTertiary),
      accent: UIColor(colors.accent)
    )
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
    // Garante que o UIColor sólido fica (fallback se Color→UIColor vier transparente).
    if configuration.background.cgColor.alpha < 0.99 {
      let solid = UIColor(ThemeManager.shared.colors.background)
      view.backgroundColor = solid
      collectionView.backgroundColor = solid
    }

    if fingerprint == lastFingerprint {
      // Mesma estrutura — ainda assim refresca bodies (done de subtarefa etc.).
      reconfigureChangedTasks(in: configuration)
      return
    }
    lastFingerprint = fingerprint
    taskContentHashById = [:]
    for section in configuration.sections {
      for task in section.tasks {
        taskContentHashById[task.id] = Self.taskContentFingerprint(task)
      }
    }

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

  /// Após patch otimista de subtarefa: `taskById` já está novo; cell precisa do Task fresco.
  private func reconfigureChangedTasks(in configuration: Configuration) {
    guard dataSource != nil else { return }
    let styleCode = Self.styleCode(configuration.style)
    var dirty: [ItemID] = []
    dirty.reserveCapacity(8)
    for section in configuration.sections {
      for task in section.tasks {
        let hash = Self.taskContentFingerprint(task)
        if taskContentHashById[task.id] != hash {
          taskContentHashById[task.id] = hash
          dirty.append(.task(id: task.id, style: styleCode))
        }
      }
    }
    guard !dirty.isEmpty else { return }
    var snap = dataSource.snapshot()
    let present = Set(snap.itemIdentifiers)
    let toReconfigure = dirty.filter { present.contains($0) }
    guard !toReconfigure.isEmpty else { return }
    snap.reconfigureItems(toReconfigure)
    dataSource.apply(snap, animatingDifferences: false)
  }

  private static func taskContentFingerprint(_ task: Task) -> Int {
    var hasher = Hasher()
    hasher.combine(task.done)
    hasher.combine(task.title)
    hasher.combine(task.priority)
    hasher.combine(task.subtasksDoneCount)
    hasher.combine(task.subtasksTotalCount)
    // Chips de data são relativos a “hoje” — sem isto a cell UIKit fica com “Hoje”
    // stale até trocar o modo de visualização (rebuild estrutural).
    hasher.combine(task.dueDate?.timeIntervalSince1970)
    hasher.combine(task.dueDateChipLabel)
    for sub in task.subtasks {
      hasher.combine(sub.idOrFallback)
      hasher.combine(sub.done)
      hasher.combine(sub.title)
      hasher.combine(sub.order)
      hasher.combine(sub.dueDate?.timeIntervalSince1970)
      hasher.combine(sub.dueDateChipLabel)
    }
    return hasher.finalize()
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

  private func handleSubtaskExpansionChanged(taskId: String, expanded: Bool) {
    let gen = (expansionGeneration[taskId] ?? 0) &+ 1
    expansionGeneration[taskId] = gen

    // Solta lock durante a animação — senão a cell fica alta com card pequeno = buraco preto.
    if let cell = cellForTask(taskId) as? UIKitSizedTaskCell {
      cell.lockedHeight = nil
    }

    if expanded {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
        guard let self, self.expansionGeneration[taskId] == gen else { return }
        self.cacheVisibleExpandedHeights()
        if let h = self.expandedRowHeightCache[taskId],
           let cell = self.cellForTask(taskId) as? UIKitSizedTaskCell {
          cell.lockedHeight = h
        }
      }
      return
    }

    expandedRowHeightCache.removeValue(forKey: taskId)
  }

  private func cellForTask(_ taskId: String) -> UICollectionViewCell? {
    guard let config, dataSource != nil else { return nil }
    let item = ItemID.task(id: taskId, style: Self.styleCode(config.style))
    guard let indexPath = dataSource.indexPath(for: item) else { return nil }
    return collectionView.cellForItem(at: indexPath)
  }

  private func reconfigureTaskCell(taskId: String) {
    guard dataSource != nil, let config else { return }
    let item = ItemID.task(id: taskId, style: Self.styleCode(config.style))
    var snap = dataSource.snapshot()
    guard snap.itemIdentifiers.contains(item) else { return }
    snap.reconfigureItems([item])
    dataSource.apply(snap, animatingDifferences: false)
  }

  private func cacheExpandedRowHeightIfNeeded(taskId: String, cell: UICollectionViewCell) {
    guard ProjectDetailPreferences.isSubtaskListExpanded(taskId: taskId) else { return }
    let h = cell.bounds.height
    guard h > 40 else { return }
    let prev = expandedRowHeightCache[taskId] ?? 0
    if abs(h - prev) > 0.5 {
      expandedRowHeightCache[taskId] = h
    }
  }

  func collectionView(
    _ collectionView: UICollectionView,
    willDisplay cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    guard let item = dataSource.itemIdentifier(for: indexPath),
          case .task(let id, _) = item else { return }
    DispatchQueue.main.async { [weak self, weak cell] in
      guard let self, let cell else { return }
      self.cacheExpandedRowHeightIfNeeded(taskId: id, cell: cell)
    }
  }

    private func pixelSnapContentOffsetIfSettled(_ scrollView: UIScrollView) {
    // Não trava Y no meio do fling — brigava com física do scroll (salto/ghost).
    // Só no settle: Text + DoneCircle nearest alinhados.
    guard !scrollView.isDragging, !scrollView.isDecelerating else { return }
    let scale = scrollView.traitCollection.displayScale
    guard scale > 1 else { return }
    let y = scrollView.contentOffset.y
    let snapped = (y * scale).rounded() / scale
    if abs(snapped - y) > .ulpOfOne {
      scrollView.contentOffset.y = snapped
    }
  }

  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    reportScrolling(true)
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      pixelSnapContentOffsetIfSettled(scrollView)
      reportScrolling(false)
      cacheVisibleExpandedHeights()
    }
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    pixelSnapContentOffsetIfSettled(scrollView)
    reportScrolling(false)
    cacheVisibleExpandedHeights()
  }

  private func cacheVisibleExpandedHeights() {
    for indexPath in collectionView.indexPathsForVisibleItems {
      guard let item = dataSource.itemIdentifier(for: indexPath),
            case .task(let id, _) = item,
            let cell = collectionView.cellForItem(at: indexPath) else { continue }
      cacheExpandedRowHeightIfNeeded(taskId: id, cell: cell)
    }
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

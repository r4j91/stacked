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
  /// Timeline Hoje/Em breve — subtarefas avulsas e eventos de calendário.
  var scheduleItems: [ScheduleItem] = []
  /// Resultados de filtro — tarefas e subtarefas avulsas.
  var filterItems: [FilterResultItem] = []
  var dimmed: Bool = false
  /// Opacidade reduzida (ex.: Registro concluído).
  var muted: Bool = false
  var projectSection: ProjectSection? = nil

  init(
    id: String,
    title: String? = nil,
    tasks: [Task],
    dimmed: Bool = false,
    muted: Bool = false,
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
    self.muted = muted
    self.projectSection = projectSection
  }

  init(
    id: String,
    header: UIKitTaskSectionHeader?,
    tasks: [Task],
    dimmed: Bool = false,
    muted: Bool = false,
    scheduleItems: [ScheduleItem] = [],
    filterItems: [FilterResultItem] = [],
    projectSection: ProjectSection? = nil
  ) {
    self.id = id
    self.header = header
    self.tasks = tasks
    self.scheduleItems = scheduleItems
    self.filterItems = filterItems
    self.dimmed = dimmed
    self.muted = muted
    self.projectSection = projectSection
  }
}

/// UICollectionView + `UIHostingConfiguration` — baseline fluido (919c1ec) + seções/modos.
struct UIKitHostedTaskList: UIViewControllerRepresentable {
  @AppStorage(TaskRowLayoutStorage.key) private var taskRowLayoutRaw = TaskRowLayoutStorage.defaultRawValue
  @AppStorage(TimelineRailStorage.key) private var timelineRailPreference = TimelineRailStorage.defaultEnabled
  @AppStorage(SubtaskProgressRingStorage.key) private var subtaskProgressRing = SubtaskProgressRingStorage.defaultEnabled
  @AppStorage(SubtaskBranchStorage.key) private var subtaskBranch = SubtaskBranchStorage.defaultEnabled

  var sections: [UIKitTaskSection]
  var showProject: Bool = true
  var style: TaskRowStyle = .card
  var flatSubtaskQueue: Bool = false
  var rowInsets: EdgeInsets = EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
  var background: Color
  var leadingChrome: (() -> AnyView)? = nil
  /// Preferência Aparência + esta flag (só Hoje / Em breve).
  var supportsTimelineRail: Bool = false
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
  var onScheduledSubtaskToggle: ((SubtaskScheduleEntry) -> Void)? = nil
  var onScheduledSubtaskTap: ((SubtaskScheduleEntry) -> Void)? = nil
  var onCalendarEventTap: ((CalendarEvent) -> Void)? = nil
  var onFilterSubtaskToggle: ((Subtask, Task, Int) -> Void)? = nil
  var onFilterSubtaskTap: ((Subtask, Task) -> Void)? = nil
  /// Catálogo de etiquetas para `FilterSubtaskRow` (filtros); vazio = usa `parent.labels`.
  var labelCatalog: [TaskLabel] = []
  /// Headers `.plain` como supplementary sticky (Em breve / dias).
  var pinPlainSectionHeaders: Bool = false

  private var taskRowLayout: TaskRowLayout {
    TaskRowLayoutStorage.layout(from: taskRowLayoutRaw)
  }

  private var timelineRailEnabled: Bool {
    supportsTimelineRail && timelineRailPreference
  }

  init(
    tasks: [Task],
    showProject: Bool = true,
    style: TaskRowStyle = .card,
    flatSubtaskQueue: Bool = false,
    rowInsets: EdgeInsets = EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16),
    background: Color,
    leadingChrome: (() -> AnyView)? = nil,
    supportsTimelineRail: Bool = false,
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
    onWhatsAppCopy: ((Task) -> Void)? = nil,
    onScheduledSubtaskToggle: ((SubtaskScheduleEntry) -> Void)? = nil,
    onScheduledSubtaskTap: ((SubtaskScheduleEntry) -> Void)? = nil,
    onCalendarEventTap: ((CalendarEvent) -> Void)? = nil,
    onFilterSubtaskToggle: ((Subtask, Task, Int) -> Void)? = nil,
    onFilterSubtaskTap: ((Subtask, Task) -> Void)? = nil,
    labelCatalog: [TaskLabel] = []
  ) {
    self.init(
      sections: [UIKitTaskSection(id: "main", title: nil, tasks: tasks)],
      showProject: showProject,
      style: style,
      flatSubtaskQueue: flatSubtaskQueue,
      rowInsets: rowInsets,
      background: background,
      leadingChrome: leadingChrome,
      supportsTimelineRail: supportsTimelineRail,
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
      onWhatsAppCopy: onWhatsAppCopy,
      onScheduledSubtaskToggle: onScheduledSubtaskToggle,
      onScheduledSubtaskTap: onScheduledSubtaskTap,
      onCalendarEventTap: onCalendarEventTap,
      onFilterSubtaskToggle: onFilterSubtaskToggle,
      onFilterSubtaskTap: onFilterSubtaskTap,
      labelCatalog: labelCatalog
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
    supportsTimelineRail: Bool = false,
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
    onWhatsAppCopy: ((Task) -> Void)? = nil,
    onScheduledSubtaskToggle: ((SubtaskScheduleEntry) -> Void)? = nil,
    onScheduledSubtaskTap: ((SubtaskScheduleEntry) -> Void)? = nil,
    onCalendarEventTap: ((CalendarEvent) -> Void)? = nil,
    onFilterSubtaskToggle: ((Subtask, Task, Int) -> Void)? = nil,
    onFilterSubtaskTap: ((Subtask, Task) -> Void)? = nil,
    labelCatalog: [TaskLabel] = [],
    pinPlainSectionHeaders: Bool = false
  ) {
    self.sections = sections
    self.showProject = showProject
    self.style = style
    self.flatSubtaskQueue = flatSubtaskQueue
    self.rowInsets = rowInsets
    self.background = background
    self.leadingChrome = leadingChrome
    self.supportsTimelineRail = supportsTimelineRail
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
    self.onScheduledSubtaskToggle = onScheduledSubtaskToggle
    self.onScheduledSubtaskTap = onScheduledSubtaskTap
    self.onCalendarEventTap = onCalendarEventTap
    self.onFilterSubtaskToggle = onFilterSubtaskToggle
    self.onFilterSubtaskTap = onFilterSubtaskTap
    self.labelCatalog = labelCatalog
    self.pinPlainSectionHeaders = pinPlainSectionHeaders
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
      taskRowLayout: taskRowLayout,
      timelineRailEnabled: timelineRailEnabled,
      subtaskProgressRing: subtaskProgressRing,
      subtaskBranch: subtaskBranch,
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
      onWhatsAppCopy: onWhatsAppCopy,
      onScheduledSubtaskToggle: onScheduledSubtaskToggle,
      onScheduledSubtaskTap: onScheduledSubtaskTap,
      onCalendarEventTap: onCalendarEventTap,
      onFilterSubtaskToggle: onFilterSubtaskToggle,
      onFilterSubtaskTap: onFilterSubtaskTap,
      labelCatalog: labelCatalog,
      pinPlainSectionHeaders: pinPlainSectionHeaders
    )
  }
}

/// Cell com altura travada no layout — evita jump 0→full quando o recycle remonta o SwiftUI.
final class UIKitSizedTaskCell: UICollectionViewListCell {
  /// Preferida pelo layout da collection (antes do sizeThatFits do hosting).
  var lockedHeight: CGFloat?
  /// UIKIT_SCROLL_POLISH: hosts separados header/painel.
  var splitRowView: UIKitSplitTaskRowView?

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
    var taskRowLayout: TaskRowLayout
    var timelineRailEnabled: Bool
    var subtaskProgressRing: Bool
    var subtaskBranch: Bool
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
    var onScheduledSubtaskToggle: ((SubtaskScheduleEntry) -> Void)?
    var onScheduledSubtaskTap: ((SubtaskScheduleEntry) -> Void)?
    var onCalendarEventTap: ((CalendarEvent) -> Void)?
    var onFilterSubtaskToggle: ((Subtask, Task, Int) -> Void)?
    var onFilterSubtaskTap: ((Subtask, Task) -> Void)?
    var labelCatalog: [TaskLabel]
    var pinPlainSectionHeaders: Bool = false
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
    case scheduleSubtask(id: String)
    case calendarEvent(id: String)
    case filterSubtask(id: String)
  }

  private var collectionView: UICollectionView!
  private var dataSource: UICollectionViewDiffableDataSource<SectionID, ItemID>!
  private var config: Configuration?
  private var lastFingerprint: Int = 0
  /// Estilo/layout da row — se só flat/insets mudam, ItemIDs iguais e o apply não reconfigura cells.
  private var lastPresentationKey: Int = 0
  private var taskById: [String: Task] = [:]
  private var scheduleSubtaskById: [String: SubtaskScheduleEntry] = [:]
  private var calendarEventById: [String: CalendarEvent] = [:]
  private var filterSubtaskById: [String: (Subtask, Task, Int)] = [:]
  private var sectionById: [String: UIKitTaskSection] = [:]
  private var dimmedTaskIds: Set<String> = []
  private var mutedTaskIds: Set<String> = []
  /// Conteúdo da task (subtasks done/título) — fingerprint estrutural ignora isto.
  private var taskContentHashById: [String: Int] = [:]
  /// Altura medida da row com painel expandido — remount no fling não cresce 0→full.
  private var expandedRowHeightCache: [String: CGFloat] = [:]
  /// Invalida cache quando meta das subtarefas muda (etiqueta etc.) — senão
  /// `lockedHeight` antigo deixa buraco embaixo ao encolher o painel.
  private var expandedLayoutSignatureByTask: [String: Int] = [:]
  /// Cancela lock agendado se o usuário fechar antes.
  private var expansionGeneration: [String: UInt] = [:]
  /// Headers observam isto — chevron anima sem remount da cell (reconfigure matava a rotação).
  private let headerFlags = UIKitSectionHeaderFlags()
  /// PERF_SCROLL_345 (item 4): rows configuradas no fling adiam labels/bump até o settle.
  private let scrollWorkGate = UIKitListScrollWorkGate()
  /// true entre begin drag e settle (fim do drag sem decelerate, ou fim do decelerate).
  private var isUserScrolling = false
  /// PERF_SCROLL_345 (item 3): reconfigure de conteúdo chegado no meio do fling —
  /// aplica uma vez só no settle em vez de custar frames durante o gesto.
  private var pendingContentRefresh = false
  /// Continuidade do trilho por ItemID (só com timelineRailEnabled).
  private var timelineRailEdges: [ItemID: (up: Bool, down: Bool)] = [:]

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: makeCollectionLayout())
    collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    collectionView.backgroundColor = .clear
    collectionView.alwaysBounceVertical = true
    collectionView.delegate = self
    // PERF_SCROLL_345 (item 5): células próximas pré-preparadas + rasters quentes.
    collectionView.isPrefetchingEnabled = true
    collectionView.prefetchDataSource = self
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

    let pinnedPlainHeaderRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(
      elementKind: UICollectionView.elementKindSectionHeader
    ) { [weak self] cell, _, indexPath in
      guard let self else {
        UIView.performWithoutAnimation { cell.contentConfiguration = nil }
        return
      }
      self.configurePinnedPlainHeader(cell, at: indexPath)
    }

    let taskRegistration = UICollectionView.CellRegistration<UIKitSizedTaskCell, String> {
      [weak self] cell, _, taskId in
      guard let self, let config = self.config, let task = self.taskById[taskId] else {
        UIView.performWithoutAnimation { cell.contentConfiguration = nil }
        return
      }
      let dimmed = self.dimmedTaskIds.contains(taskId)
      let muted = self.mutedTaskIds.contains(taskId)
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
        let layoutSig = Self.subtasksExpandLayoutSignature(task.subtasks)
        if self.expandedLayoutSignatureByTask[taskId] != layoutSig {
          self.expandedLayoutSignatureByTask[taskId] = layoutSig
          self.expandedRowHeightCache.removeValue(forKey: taskId)
        }
        if isExpanded, let cached = self.expandedRowHeightCache[taskId], cached > headerMin {
          cell.lockedHeight = cached
        } else {
          cell.lockedHeight = nil
        }

        // UIKIT_SCROLL_POLISH: era UIHostingConfiguration { TaskRow(...) } único —
        // self-sizing recalculava o chevron com a altura do painel.
        cell.contentConfiguration = nil
        let split: UIKitSplitTaskRowView
        if let existing = cell.splitRowView {
          split = existing
        } else {
          split = UIKitSplitTaskRowView()
          split.translatesAutoresizingMaskIntoConstraints = false
          cell.contentView.addSubview(split)
          NSLayoutConstraint.activate([
            split.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            split.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            split.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            split.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
          ])
          cell.splitRowView = split
        }
        let styleCode = Self.rowPresentationCode(style: config.style, layout: config.taskRowLayout)
        let rail = self.timelineRailEdges[.task(id: taskId, style: styleCode)] ?? (false, false)
        split.apply(.init(
          task: task,
          style: config.style,
          flatSubtaskQueue: config.flatSubtaskQueue,
          showProject: config.showProject,
          rowInsets: insets,
          dimmed: dimmed,
          muted: muted,
          scrollGate: self.scrollWorkGate,
          configuredWhileScrolling: self.isUserScrolling,
          onToggle: { config.onToggle(task) },
          onTap: { config.onTap(task) },
          onSubtaskTap: { config.onSubtaskTap(task, $0) },
          onSubtaskChanged: config.onSubtaskChanged,
          onSubtaskDeleted: { config.onSubtaskDeleted(task, $0) },
          onWhatsAppCopy: config.onWhatsAppCopy.map { handler in { handler(task) } },
          onSubtaskExpansionChanged: { [weak self] expanded in
            self?.handleSubtaskExpansionChanged(taskId: taskId, expanded: expanded)
          },
          onEdit: { config.onEdit(task) },
          onComplete: { config.onComplete(task) },
          onDuplicate: { config.onDuplicate(task) },
          onDelete: { config.onDelete(task) },
          onRefresh: config.onRefresh,
          timelineRailEnabled: config.timelineRailEnabled,
          timelineConnectsUp: rail.up,
          timelineConnectsDown: rail.down,
          timelineNodeColor: UIColor(TimelineRailNodeColor.forTask(task))
        ))
      }
    }

    let scheduleSubtaskRegistration = UICollectionView.CellRegistration<UICollectionViewCell, String> {
      [weak self] cell, _, entryId in
      guard let self, let config = self.config, let entry = self.scheduleSubtaskById[entryId] else {
        UIView.performWithoutAnimation { cell.contentConfiguration = nil }
        return
      }
      let insets = config.rowInsets
      let rail = self.timelineRailEdges[.scheduleSubtask(id: entryId)] ?? (false, false)
      let leading = Self.timelineAdjustedLeading(insets.left, enabled: config.timelineRailEnabled)
      UIView.performWithoutAnimation {
        var clearBg = UIBackgroundConfiguration.clear()
        clearBg.backgroundColor = .clear
        cell.backgroundConfiguration = clearBg
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.contentConfiguration = UIHostingConfiguration {
          FilterSubtaskRow(
            subtask: entry.subtask,
            parent: entry.parent,
            labelCatalog: config.labelCatalog,
            style: config.style,
            stabilizeInUIKitCell: true,
            onToggle: { config.onScheduledSubtaskToggle?(entry) },
            onTap: { config.onScheduledSubtaskTap?(entry) }
          )
          .padding(.top, insets.top)
          .padding(.bottom, insets.bottom)
          .timelineRail(
            enabled: config.timelineRailEnabled,
            nodeColor: TimelineRailNodeColor.forSubtask(entry.subtask),
            connectsUp: rail.up,
            connectsDown: rail.down
          )
          .padding(.leading, leading)
          .padding(.trailing, insets.right)
          .environment(ThemeManager.shared)
          .environment(MobileChromeController.shared)
        }
        .margins(.all, 0)
        .minSize(height: 1)
      }
    }

    let filterSubtaskRegistration = UICollectionView.CellRegistration<UICollectionViewCell, String> {
      [weak self] cell, _, itemId in
      guard let self, let config = self.config, let triple = self.filterSubtaskById[itemId] else {
        UIView.performWithoutAnimation { cell.contentConfiguration = nil }
        return
      }
      let (sub, parent, index) = triple
      let insets = config.rowInsets
      UIView.performWithoutAnimation {
        var clearBg = UIBackgroundConfiguration.clear()
        clearBg.backgroundColor = .clear
        cell.backgroundConfiguration = clearBg
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.contentConfiguration = UIHostingConfiguration {
          FilterSubtaskRow(
            subtask: sub,
            parent: parent,
            labelCatalog: config.labelCatalog,
            style: config.style,
            stabilizeInUIKitCell: true,
            onToggle: { config.onFilterSubtaskToggle?(sub, parent, index) },
            onTap: { config.onFilterSubtaskTap?(sub, parent) }
          )
          .padding(.top, insets.top)
          .padding(.leading, insets.left)
          .padding(.bottom, insets.bottom)
          .padding(.trailing, insets.right)
          .environment(ThemeManager.shared)
          .environment(MobileChromeController.shared)
        }
        .margins(.all, 0)
        .minSize(height: 1)
      }
    }

    let calendarEventRegistration = UICollectionView.CellRegistration<UICollectionViewCell, String> {
      [weak self] cell, _, eventId in
      guard let self, let config = self.config, let event = self.calendarEventById[eventId] else {
        UIView.performWithoutAnimation { cell.contentConfiguration = nil }
        return
      }
      let insets = config.rowInsets
      let rail = self.timelineRailEdges[.calendarEvent(id: eventId)] ?? (false, false)
      let leading = Self.timelineAdjustedLeading(insets.left, enabled: config.timelineRailEnabled)
      UIView.performWithoutAnimation {
        var clearBg = UIBackgroundConfiguration.clear()
        clearBg.backgroundColor = .clear
        cell.backgroundConfiguration = clearBg
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.contentConfiguration = UIHostingConfiguration {
          CalendarEventRow(event: event) {
            config.onCalendarEventTap?(event)
          }
          .padding(.top, insets.top)
          .padding(.bottom, insets.bottom)
          .timelineRail(
            enabled: config.timelineRailEnabled,
            nodeColor: AppColors.priorityLow,
            connectsUp: rail.up,
            connectsDown: rail.down
          )
          .padding(.leading, leading)
          .padding(.trailing, insets.right)
          .environment(ThemeManager.shared)
          .environment(MobileChromeController.shared)
        }
        .margins(.all, 0)
        .minSize(height: 1)
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
      case .scheduleSubtask(let id):
        return collectionView.dequeueConfiguredReusableCell(
          using: scheduleSubtaskRegistration,
          for: indexPath,
          item: id
        )
      case .filterSubtask(let id):
        return collectionView.dequeueConfiguredReusableCell(
          using: filterSubtaskRegistration,
          for: indexPath,
          item: id
        )
      case .calendarEvent(let id):
        return collectionView.dequeueConfiguredReusableCell(
          using: calendarEventRegistration,
          for: indexPath,
          item: id
        )
      }
    }

    dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
      guard elementKind == UICollectionView.elementKindSectionHeader else { return nil }
      return collectionView.dequeueConfiguredReusableSupplementary(
        using: pinnedPlainHeaderRegistration,
        for: indexPath
      )
    }
  }

  private func makeCollectionLayout() -> UICollectionViewCompositionalLayout {
    UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
      var listConfig = UICollectionLayoutListConfiguration(appearance: .plain)
      listConfig.backgroundColor = .clear
      listConfig.showsSeparators = false
      // Sempre `.none` — o sticky plain é boundary item nosso (evita header duplo do list).
      listConfig.headerMode = .none

      let section = NSCollectionLayoutSection.list(using: listConfig, layoutEnvironment: environment)
      if self?.shouldPinHeader(at: sectionIndex) == true {
        let headerSize = NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(1),
          heightDimension: .estimated(40)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
          layoutSize: headerSize,
          elementKind: UICollectionView.elementKindSectionHeader,
          alignment: .top
        )
        header.pinToVisibleBounds = true
        section.boundarySupplementaryItems = [header]
      }
      return section
    }
  }

  private func shouldPinHeader(at sectionIndex: Int) -> Bool {
    guard config?.pinPlainSectionHeaders == true, dataSource != nil else { return false }
    let ids = dataSource.snapshot().sectionIdentifiers
    guard sectionIndex >= 0, sectionIndex < ids.count else { return false }
    guard case .block(let id) = ids[sectionIndex],
          case .plain = sectionById[id]?.header
    else { return false }
    return true
  }

  private func configurePinnedPlainHeader(_ cell: UICollectionViewCell, at indexPath: IndexPath) {
    guard config?.pinPlainSectionHeaders == true,
          dataSource != nil,
          indexPath.section < dataSource.snapshot().sectionIdentifiers.count,
          case .block(let id) = dataSource.snapshot().sectionIdentifiers[indexPath.section],
          let section = sectionById[id],
          case .plain(let text) = section.header
    else {
      UIView.performWithoutAnimation { cell.contentConfiguration = nil }
      return
    }

    let fill = config?.background ?? .clear
    UIView.performWithoutAnimation {
      var clearBg = UIBackgroundConfiguration.clear()
      clearBg.backgroundColor = .clear
      cell.backgroundConfiguration = clearBg
      cell.backgroundColor = .clear
      cell.contentView.backgroundColor = .clear
      cell.contentConfiguration = UIHostingConfiguration {
        ZStack(alignment: .leading) {
          // Fill opaco — evita bleed das rows sob o sticky sem blur (soft edge hitcha no UIKit).
          Color(uiColor: fill)
          ListSectionHeader(text: text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .padding(.leading, 4)
            .padding(.trailing, 16)
        }
        .environment(ThemeManager.shared)
        .environment(MobileChromeController.shared)
      }
      .margins(.all, 0)
      .minSize(height: 1)
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
    var scheduleMap: [String: SubtaskScheduleEntry] = [:]
    var eventMap: [String: CalendarEvent] = [:]
    var filterMap: [String: (Subtask, Task, Int)] = [:]
    var sectionsMap: [String: UIKitTaskSection] = [:]
    var dimmed: Set<String> = []
    var muted: Set<String> = []
    for section in configuration.sections {
      sectionsMap[section.id] = section
      Self.indexSection(
        section,
        tasks: &map,
        scheduleSubtasks: &scheduleMap,
        calendarEvents: &eventMap,
        filterSubtasks: &filterMap,
        dimmed: &dimmed,
        muted: &muted
      )
    }
    taskById = map
    scheduleSubtaskById = scheduleMap
    calendarEventById = eventMap
    filterSubtaskById = filterMap
    sectionById = sectionsMap
    dimmedTaskIds = dimmed
    mutedTaskIds = muted
    headerFlags.publish(from: configuration.sections)
    rebuildTimelineRailEdges(from: configuration)

    view.backgroundColor = configuration.background
    collectionView.backgroundColor = configuration.background
    // Garante que o UIColor sólido fica (fallback se Color→UIColor vier transparente).
    if configuration.background.cgColor.alpha < 0.99 {
      let solid = UIColor(ThemeManager.shared.colors.background)
      view.backgroundColor = solid
      collectionView.backgroundColor = solid
    }

    let presentationKey = Self.presentationKey(configuration)
    let presentationChanged = presentationKey != lastPresentationKey

    if fingerprint == lastFingerprint {
      // PERF_SCROLL_345 (item 3): store “pingando” no meio do fling não custa
      // frames — o refresh de conteúdo é aplicado uma vez só no settle.
      // Estrutura (fingerprint) mudando ainda aplica na hora, mesmo rolando.
      if isUserScrolling {
        pendingContentRefresh = true
        return
      }
      // Mesma estrutura — ainda assim refresca bodies (done de subtarefa etc.).
      reconfigureChangedTasks(in: configuration)
      return
    }
    lastFingerprint = fingerprint
    lastPresentationKey = presentationKey
    // Rebuild estrutural cobre o conteúdo — refresh pendente do fling fica obsoleto.
    pendingContentRefresh = false
    taskContentHashById = [:]
    for section in configuration.sections {
      for task in Self.tasks(in: section) {
        taskContentHashById[task.id] = Self.taskContentFingerprint(task)
      }
    }

    if presentationChanged {
      // Altura/estilo antigos (ex.: Balões→Lista) não batem com o novo modo.
      expandedRowHeightCache.removeAll()
      expandedLayoutSignatureByTask.removeAll()
      expansionGeneration.removeAll()
    }

    let styleCode = Self.rowPresentationCode(
      style: configuration.style,
      layout: configuration.taskRowLayout
    )
    var snapshot = NSDiffableDataSourceSnapshot<SectionID, ItemID>()
    if configuration.leadingChrome != nil {
      snapshot.appendSections([.chrome])
      snapshot.appendItems([.leadingChrome], toSection: .chrome)
    }
    for section in configuration.sections {
      let sid = SectionID.block(section.id)
      snapshot.appendSections([sid])
      var items: [ItemID] = []
      let pinPlain =
        configuration.pinPlainSectionHeaders
        && {
          if case .plain = section.header { return true }
          return false
        }()
      if section.header != nil, !pinPlain {
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
        items.append(contentsOf: Self.rowItemIDs(for: section, styleCode: styleCode))
      }
      snapshot.appendItems(items, toSection: sid)
    }
    dataSource.apply(snapshot, animatingDifferences: false)
    if configuration.pinPlainSectionHeaders {
      // Reconsulta shouldPinHeader com o snapshot novo (1º layout ainda sem sections).
      collectionView.collectionViewLayout.invalidateLayout()
    }

    // Diffable: se os ItemIDs forem iguais (ex.: Balões↔Balões+), apply não
    // reconfigura — força refresh das task cells para o novo layout.
    if presentationChanged {
      clearVisibleLockedHeights()
      reconfigureAllTaskItems()
    }
  }

  private func clearVisibleLockedHeights() {
    for cell in collectionView.visibleCells {
      (cell as? UIKitSizedTaskCell)?.lockedHeight = nil
    }
  }

  private func reconfigureAllTaskItems() {
    guard dataSource != nil else { return }
    var snap = dataSource.snapshot()
    let rows = snap.itemIdentifiers.filter {
      switch $0 {
      case .task, .scheduleSubtask, .calendarEvent:
        return true
      default:
        return false
      }
    }
    guard !rows.isEmpty else { return }
    snap.reconfigureItems(rows)
    dataSource.apply(snap, animatingDifferences: false)
  }

  private func rebuildTimelineRailEdges(from configuration: Configuration) {
    timelineRailEdges = [:]
    guard configuration.timelineRailEnabled else { return }
    let styleCode = Self.rowPresentationCode(
      style: configuration.style,
      layout: configuration.taskRowLayout
    )
    for section in configuration.sections {
      let showTasks: Bool
      switch section.header {
      case .collapsible(_, _, let expanded):
        showTasks = expanded
      case .completedToggle(_, let expanded):
        showTasks = expanded
      case .plain, .none:
        showTasks = true
      }
      guard showTasks else { continue }
      let ids = Self.rowItemIDs(for: section, styleCode: styleCode)
      for (index, id) in ids.enumerated() {
        timelineRailEdges[id] = (index > 0, index < ids.count - 1)
      }
    }
  }

  private static func timelineAdjustedLeading(_ leading: CGFloat, enabled: Bool) -> CGFloat {
    guard enabled else { return leading }
    // Trilho (16) + spacing (8) = 24 — mantém o card alinhado ao layout sem trilho.
    return max(4, leading - 24)
  }

  /// Após patch otimista de subtarefa: `taskById` já está novo; cell precisa do Task fresco.
  private func reconfigureChangedTasks(in configuration: Configuration) {
    guard dataSource != nil else { return }
    let styleCode = Self.rowPresentationCode(
      style: configuration.style,
      layout: configuration.taskRowLayout
    )
    var dirty: [ItemID] = []
    dirty.reserveCapacity(8)
    for section in configuration.sections {
      for task in Self.tasks(in: section) {
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
    hasher.combine(task.description)
    hasher.combine(task.priority)
    hasher.combine(task.whatsappRoutine)
    hasher.combine(task.project)
    hasher.combine(task.projectId)
    hasher.combine(task.sectionId)
    hasher.combine(task.time)
    hasher.combine(task.timeDisplay)
    hasher.combine(task.recurrence)
    hasher.combine(task.commentCount)
    for label in task.labels {
      hasher.combine(label.id)
      hasher.combine(label.name)
      hasher.combine(label.sortOrder)
    }
    hasher.combine(task.subtasksDoneCount)
    hasher.combine(task.subtasksTotalCount)
    // Chips de data são relativos a “hoje” — sem isto a cell UIKit fica com “Hoje”
    // stale até trocar o modo de visualização (rebuild estrutural).
    hasher.combine(task.dueDate?.timeIntervalSince1970)
    hasher.combine(task.dueDateChipLabel)
    hasher.combine(TaskRowLayoutStorage.current.rawValue)
    for sub in task.subtasks {
      hasher.combine(sub.idOrFallback)
      hasher.combine(sub.done)
      hasher.combine(sub.title)
      hasher.combine(sub.order)
      hasher.combine(sub.description)
      hasher.combine(sub.priority)
      hasher.combine(sub.time)
      hasher.combine(sub.timeDisplay)
      hasher.combine(sub.labelIds)
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
    case .listComfort: 4
    }
  }

  private static func layoutCode(_ layout: TaskRowLayout) -> Int {
    switch layout {
    case .default: 0
    case .f2: 1
    case .x2: 2
    case .trailingTime: 3
    case .dense: 4
    }
  }

  /// Estilo visual + layout de meta (F2/X2) — muda o ItemID e remonta as cells.
  private static func rowPresentationCode(style: TaskRowStyle, layout: TaskRowLayout) -> Int {
    styleCode(style) * 10 + layoutCode(layout)
  }

  private static func subtasksExpandLayoutSignature(_ subs: [Subtask]) -> Int {
    var hasher = Hasher()
    hasher.combine(subs.count)
    for sub in subs {
      hasher.combine(sub.idOrFallback)
      hasher.combine(sub.description?.isEmpty == false)
      hasher.combine(sub.dueDate != nil)
      hasher.combine(sub.priority != nil)
      hasher.combine(sub.labelIds)
    }
    return hasher.finalize()
  }

  /// Só o “look” da row (não a lista de tasks) — troca de modo de visualização / layout.
  private static func presentationKey(_ configuration: Configuration) -> Int {
    var hasher = Hasher()
    hasher.combine(styleCode(configuration.style))
    hasher.combine(layoutCode(configuration.taskRowLayout))
    hasher.combine(configuration.timelineRailEnabled)
    hasher.combine(configuration.subtaskProgressRing)
    hasher.combine(configuration.subtaskBranch)
    hasher.combine(configuration.flatSubtaskQueue)
    hasher.combine(configuration.rowInsets.left)
    hasher.combine(configuration.rowInsets.top)
    hasher.combine(configuration.rowInsets.right)
    hasher.combine(configuration.rowInsets.bottom)
    return hasher.finalize()
  }

  private static func fingerprint(_ configuration: Configuration) -> Int {
    var hasher = Hasher()
    hasher.combine(configuration.leadingChrome != nil)
    hasher.combine(configuration.pinPlainSectionHeaders)
    hasher.combine(configuration.showProject)
    hasher.combine(configuration.flatSubtaskQueue)
    hasher.combine(configuration.timelineRailEnabled)
    hasher.combine(configuration.subtaskProgressRing)
    hasher.combine(configuration.subtaskBranch)
    hasher.combine(configuration.rowInsets.left)
    hasher.combine(configuration.rowInsets.top)
    hasher.combine(configuration.rowInsets.right)
    hasher.combine(configuration.rowInsets.bottom)
    hasher.combine(styleCode(configuration.style))
    hasher.combine(layoutCode(configuration.taskRowLayout))
    for section in configuration.sections {
      hasher.combine(section.id)
      hasher.combine(section.dimmed)
      hasher.combine(section.muted)
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
      for item in section.scheduleItems {
        hasher.combine(item.id)
      }
      for item in section.filterItems {
        hasher.combine(item.id)
      }
    }
    return hasher.finalize()
  }

  private static func rowItemIDs(for section: UIKitTaskSection, styleCode: Int) -> [ItemID] {
    if !section.filterItems.isEmpty {
      return section.filterItems.map { item in
        switch item {
        case .task(let task):
          return .task(id: task.id, style: styleCode)
        case .subtask:
          return .filterSubtask(id: item.id)
        }
      }
    }
    if !section.scheduleItems.isEmpty {
      return section.scheduleItems.map { item in
        switch item {
        case .task(let task):
          return .task(id: task.id, style: styleCode)
        case .subtask(let entry):
          return .scheduleSubtask(id: entry.id)
        case .calendarEvent(let event):
          return .calendarEvent(id: event.id)
        }
      }
    }
    return section.tasks.map { .task(id: $0.id, style: styleCode) }
  }

  private static func tasks(in section: UIKitTaskSection) -> [Task] {
    if !section.filterItems.isEmpty {
      return section.filterItems.compactMap { item in
        if case .task(let task) = item { return task }
        return nil
      }
    }
    if !section.scheduleItems.isEmpty {
      return section.scheduleItems.compactMap { item in
        if case .task(let task) = item { return task }
        return nil
      }
    }
    return section.tasks
  }

  private static func indexSection(
    _ section: UIKitTaskSection,
    tasks map: inout [String: Task],
    scheduleSubtasks scheduleMap: inout [String: SubtaskScheduleEntry],
    calendarEvents eventMap: inout [String: CalendarEvent],
    filterSubtasks filterMap: inout [String: (Subtask, Task, Int)],
    dimmed: inout Set<String>,
    muted: inout Set<String>
  ) {
    func mark(_ taskId: String) {
      if section.dimmed { dimmed.insert(taskId) }
      if section.muted { muted.insert(taskId) }
    }

    if !section.filterItems.isEmpty {
      for item in section.filterItems {
        switch item {
        case .task(let task):
          map[task.id] = task
          mark(task.id)
        case .subtask(let sub, let parent, let index):
          filterMap[item.id] = (sub, parent, index)
          map[parent.id] = parent
        }
      }
      return
    }

    if !section.scheduleItems.isEmpty {
      for item in section.scheduleItems {
        switch item {
        case .task(let task):
          map[task.id] = task
          mark(task.id)
        case .subtask(let entry):
          scheduleMap[entry.id] = entry
          map[entry.parent.id] = entry.parent
        case .calendarEvent(let event):
          eventMap[event.id] = event
        }
      }
      return
    }

    for task in section.tasks {
      map[task.id] = task
      mark(task.id)
    }
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
      // UIKIT_SCROLL_POLISH: resistance dinâmica + invalidate no mesmo frame do toggle.
      cell.splitRowView?.notifyExpansionChanged(expanded: expanded)
    }

    if expanded {
      // Descarta cache velho — senão lockedHeight alto reaparece no 1º frame (buraco).
      expandedRowHeightCache.removeValue(forKey: taskId)
      // Listas grandes (parcelas): 0.3s ainda mede alto/vazio — trava buraco preto.
      // Remede em dois passes antes de lockar o cache.
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
        guard let self, self.expansionGeneration[taskId] == gen else { return }
        if let cell = self.cellForTask(taskId) as? UIKitSizedTaskCell {
          cell.lockedHeight = nil
          cell.splitRowView?.invalidatePanelHostIntrinsicSize()
        }
        self.collectionView.performBatchUpdates(nil)
        self.collectionView.layoutIfNeeded()
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
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
    expandedLayoutSignatureByTask.removeValue(forKey: taskId)
  }

  private func cellForTask(_ taskId: String) -> UICollectionViewCell? {
    guard let config, dataSource != nil else { return nil }
    let item = ItemID.task(
      id: taskId,
      style: Self.rowPresentationCode(style: config.style, layout: config.taskRowLayout)
    )
    guard let indexPath = dataSource.indexPath(for: item) else { return nil }
    return collectionView.cellForItem(at: indexPath)
  }

  private func reconfigureTaskCell(taskId: String) {
    guard dataSource != nil, let config else { return }
    let item = ItemID.task(
      id: taskId,
      style: Self.rowPresentationCode(style: config.style, layout: config.taskRowLayout)
    )
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

  func replaceExpandedRowHeightCache(taskId: String, height: CGFloat) {
    guard height > 40 else { return }
    expandedRowHeightCache[taskId] = height
  }

  func collectionView(
    _ collectionView: UICollectionView,
    willDisplay cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    // PERF_SCROLL_345 (item 4): no fling não agenda hop por cell —
    // `cacheVisibleExpandedHeights()` no settle cobre as visíveis.
    guard !isUserScrolling else { return }
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
    isUserScrolling = true
    if !scrollWorkGate.isScrolling {
      scrollWorkGate.isScrolling = true
    }
    reportScrolling(true)
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      pixelSnapContentOffsetIfSettled(scrollView)
      reportScrolling(false)
      handleScrollSettled()
      cacheVisibleExpandedHeights()
    }
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    pixelSnapContentOffsetIfSettled(scrollView)
    reportScrolling(false)
    handleScrollSettled()
    cacheVisibleExpandedHeights()
  }

  /// PERF_SCROLL_345: settle — libera rows adiadas (item 4) e aplica o
  /// reconfigure de conteúdo que chegou durante o gesto (item 3).
  private func handleScrollSettled() {
    isUserScrolling = false
    if scrollWorkGate.isScrolling {
      scrollWorkGate.isScrolling = false
    }
    if pendingContentRefresh {
      pendingContentRefresh = false
      if let config {
        reconfigureChangedTasks(in: config)
      }
    }
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
          !StaticFrostedGlassStorage.isEnabled,
          !AlwaysFrozenDockGlassStorage.isEnabled,
          !DisableAllGlassStorage.isEnabled,
          FreezeDockGlassWhileScrollingStorage.isEnabled
    else { return }
    MobileChromeController.shared.setContentScrolling(scrolling)
  }
}

// MARK: - PERF_SCROLL_345 (item 5): prefetch de rasters para células próximas

extension UIKitHostedTaskListController: UICollectionViewDataSourcePrefetching {
  func collectionView(
    _ collectionView: UICollectionView,
    prefetchItemsAt indexPaths: [IndexPath]
  ) {
    guard dataSource != nil, config != nil else { return }
    let fallbackRing = UIColor(ThemeManager.shared.colors.textTertiary)
    for indexPath in indexPaths {
      guard let item = dataSource.itemIdentifier(for: indexPath),
            case .task(let id, _) = item,
            let task = taskById[id] else { continue }
      warmRasterImages(for: task, fallbackRing: fallbackRing)
    }
  }

  /// Anel done/prioridade + relógio já em cache quando a cell entra na tela —
  /// só desenha combos novos (cache por chave); repetições são hit de dicionário.
  private func warmRasterImages(for task: Task, fallbackRing: UIColor) {
    func warmRing(done: Bool, priority: Priority?) {
      let ring = priority.map { UIColor($0.color) } ?? fallbackRing
      _ = DoneCircleRaster.image(
        done: done,
        size: DoneCircle.listRowCircleSize,
        borderWidth: DoneCircle.RingStyle.borderWidth,
        ringColor: ring,
        ringFillAlpha: done ? 0 : DoneCircle.RingStyle.inactiveFillAlpha,
        tickSize: 13
      )
    }
    warmRing(done: task.done, priority: task.priority)
    if task.hasSubtasks, ProjectDetailPreferences.isSubtaskListExpanded(taskId: task.id) {
      for sub in task.subtasks {
        warmRing(done: sub.done, priority: sub.priority)
      }
    }
    _ = UIKitRowIconRaster.image(key: .clock, size: 11, color: fallbackRing)
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

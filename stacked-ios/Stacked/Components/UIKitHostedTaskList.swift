import SwiftUI
import UIKit

/// Spike: UICollectionView (list layout) + `UIHostingConfiguration` com a mesma `TaskRow`.
struct UIKitHostedTaskList: UIViewControllerRepresentable {
  let tasks: [Task]
  var deferHeavyWork: Bool = false
  var showProject: Bool = true
  var style: TaskRowStyle = .card
  var background: Color
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
      tasks: tasks,
      deferHeavyWork: deferHeavyWork,
      showProject: showProject,
      style: style,
      background: UIColor(background),
      onToggle: onToggle,
      onTap: onTap,
      onSubtaskTap: onSubtaskTap,
      onSubtaskChanged: onSubtaskChanged,
      onSubtaskDeleted: onSubtaskDeleted,
      onEdit: onEdit,
      onComplete: onComplete,
      onDuplicate: onDuplicate,
      onDelete: onDelete,
      onRefresh: onRefresh
    )
  }
}

extension Notification.Name {
  /// TaskRow mudou altura (expand/collapse) — invalida self-size da cell UIKit.
  static let stackedUIKitTaskRowHeightMayChange = Notification.Name("stackedUIKitTaskRowHeightMayChange")
}

/// Cells em UIHostingConfiguration: evitar `SubtaskExpandReveal` (UIHosting aninhado).
private struct UIKitHostedTaskRowKey: EnvironmentKey {
  static let defaultValue = false
}

extension EnvironmentValues {
  var uikitHostedTaskRow: Bool {
    get { self[UIKitHostedTaskRowKey.self] }
    set { self[UIKitHostedTaskRowKey.self] = newValue }
  }
}

@MainActor
final class UIKitHostedTaskListController: UIViewController, UICollectionViewDelegate {
  struct Configuration {
    var tasks: [Task]
    var deferHeavyWork: Bool
    var showProject: Bool
    var style: TaskRowStyle
    var background: UIColor
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
  }

  private enum Section: Hashable { case main }

  private var collectionView: UICollectionView!
  private var dataSource: UICollectionViewDiffableDataSource<Section, String>!
  private var config: Configuration?
  private var lastTaskIds: [String] = []
  private var lastContentToken: Int = 0
  private var lastDeferHeavyWork: Bool?
  private var taskById: [String: Task] = [:]
  private var heightObserver: NSObjectProtocol?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    var listConfig = UICollectionLayoutListConfiguration(appearance: .plain)
    listConfig.backgroundColor = .clear
    listConfig.showsSeparators = false
    let layout = UICollectionViewCompositionalLayout.list(using: listConfig)

    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
    collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    collectionView.backgroundColor = .clear
    collectionView.alwaysBounceVertical = true
    collectionView.delegate = self
    collectionView.allowsSelection = false
    collectionView.isPrefetchingEnabled = false
    if #available(iOS 16.0, *) {
      collectionView.selfSizingInvalidation = .enabled
    }
    collectionView.contentInset.bottom = AppLayout.listTailInset(
      safeBottom: AppLayout.windowSafeBottomInsetCached
    )
    // Evita ajuste de inset no rubber-band (hitch comum no fling inverso).
    collectionView.contentInsetAdjustmentBehavior = .never
    view.addSubview(collectionView)

    let refresh = UIRefreshControl()
    refresh.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    collectionView.refreshControl = refresh

    let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, String> {
      [weak self] cell, _, taskId in
      guard let self, let config = self.config, let task = self.taskById[taskId] else {
        cell.contentConfiguration = nil
        return
      }

      cell.contentConfiguration = UIHostingConfiguration {
        TaskRow(
          task: task,
          style: config.style,
          showProject: config.showProject,
          deferHeavyWork: config.deferHeavyWork,
          onToggle: { config.onToggle(task) },
          onTap: { config.onTap(task) },
          onSubtaskTap: { config.onSubtaskTap(task, $0) },
          onSubtaskChanged: config.onSubtaskChanged,
          onSubtaskDeleted: { config.onSubtaskDeleted(task, $0) }
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
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
        .environment(\.uikitHostedTaskRow, true)
      }
      .margins(.all, 0)
      .minSize(height: 1)
    }

    dataSource = UICollectionViewDiffableDataSource<Section, String>(
      collectionView: collectionView
    ) { collectionView, indexPath, taskId in
      collectionView.dequeueConfiguredReusableCell(
        using: cellRegistration,
        for: indexPath,
        item: taskId
      )
    }

    heightObserver = NotificationCenter.default.addObserver(
      forName: .stackedUIKitTaskRowHeightMayChange,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.invalidateSelfSizing()
    }
  }

  deinit {
    if let heightObserver {
      NotificationCenter.default.removeObserver(heightObserver)
    }
  }

  func apply(configuration: Configuration) {
    if collectionView == nil {
      loadViewIfNeeded()
    }

    let ids = configuration.tasks.map(\.id)
    let token = contentToken(for: configuration.tasks)
    let deferChanged = lastDeferHeavyWork != configuration.deferHeavyWork

    config = configuration
    taskById = Dictionary(uniqueKeysWithValues: configuration.tasks.map { ($0.id, $0) })
    view.backgroundColor = configuration.background
    collectionView.backgroundColor = configuration.background
    lastDeferHeavyWork = configuration.deferHeavyWork

    if ids == lastTaskIds {
      // NÃO reloadData / reconfigure genérico — destroi @State do expand e hitcha no fling.
      // Só reconfigura quando o gate de heavy work abre (1× no appear).
      if deferChanged {
        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems(ids)
        dataSource.apply(snapshot, animatingDifferences: false)
      }
      lastContentToken = token
      return
    }

    lastTaskIds = ids
    lastContentToken = token
    var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
    snapshot.appendSections([.main])
    snapshot.appendItems(ids, toSection: .main)
    dataSource.apply(snapshot, animatingDifferences: false)
  }

  private func contentToken(for tasks: [Task]) -> Int {
    var hasher = Hasher()
    for task in tasks {
      hasher.combine(task.id)
      hasher.combine(task.title)
      hasher.combine(task.done)
      hasher.combine(task.description)
      hasher.combine(task.priority?.rawValue)
      hasher.combine(task.dueDateChipLabel)
      hasher.combine(task.subtasksTotalCount)
      hasher.combine(task.subtasksDoneCount)
      hasher.combine(task.labels.map(\.id))
      for sub in task.subtasks {
        hasher.combine(sub.idOrFallback)
        hasher.combine(sub.title)
        hasher.combine(sub.done)
      }
    }
    return hasher.finalize()
  }

  private func invalidateSelfSizing() {
    guard isViewLoaded, collectionView != nil else { return }
    // Sem animação de layout do collection — evita “pulo” no expand.
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    collectionView.collectionViewLayout.invalidateLayout()
    collectionView.layoutIfNeeded()
    CATransaction.commit()
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

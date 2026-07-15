import SwiftUI
import UIKit

/// Spike: UICollectionView (list layout) + `UIHostingConfiguration` com a mesma `TaskRow`.
/// Visual ≈ SwiftUI List; recycle UIKit. Ligado só com `UIKitTaskListStorage`.
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
  private var taskById: [String: Task] = [:]

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
    collectionView.isPrefetchingEnabled = false
    collectionView.contentInset.bottom = AppLayout.listTailInset(
      safeBottom: AppLayout.windowSafeBottomInsetCached
    )
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
  }

  func apply(configuration: Configuration) {
    if collectionView == nil {
      loadViewIfNeeded()
    }
    config = configuration
    taskById = Dictionary(uniqueKeysWithValues: configuration.tasks.map { ($0.id, $0) })
    view.backgroundColor = configuration.background
    collectionView.backgroundColor = configuration.background

    let ids = configuration.tasks.map(\.id)
    if ids == lastTaskIds {
      // Mantém cells vivas — reloadData no scroll/expand zerava @State e hitchava.
      // taskById/config já atualizados acima para o próximo dequeue.
      return
    }
    lastTaskIds = ids
    var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
    snapshot.appendSections([.main])
    snapshot.appendItems(ids, toSection: .main)
    dataSource.apply(snapshot, animatingDifferences: false)
  }

  @objc private func handleRefresh() {
    config?.onRefresh()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
      self?.collectionView.refreshControl?.endRefreshing()
    }
  }

  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    // Glass freeze no dock hitchava no fling (esp. pra cima) — lista UIKit não reporta.
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {}

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}
}

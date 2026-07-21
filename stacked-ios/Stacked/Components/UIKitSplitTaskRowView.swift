import SwiftUI
import UIKit

/// PERF_SCROLL_345 (item 4): estado de fling da lista UIKit. Rows configuradas
/// durante o scroll nascem com `deferHeavyWork` e liberam (labels/bump) no settle.
@MainActor
final class UIKitListScrollWorkGate: ObservableObject {
  @Published var isScrolling = false
}

/// Observa o gate SÓ quando a row foi configurada no meio do fling — rows
/// configuradas com a lista parada não re-renderizam a cada begin/end de scroll.
private struct UIKitScrollGatedRow<Content: View>: View {
  let gate: UIKitListScrollWorkGate?
  let observesGate: Bool
  @ViewBuilder let content: (_ deferHeavyWork: Bool) -> Content

  var body: some View {
    if observesGate, let gate {
      UIKitScrollGateObserver(gate: gate, content: content)
    } else {
      content(false)
    }
  }
}

private struct UIKitScrollGateObserver<Content: View>: View {
  @ObservedObject var gate: UIKitListScrollWorkGate
  @ViewBuilder let content: (_ deferHeavyWork: Bool) -> Content

  var body: some View {
    content(gate.isScrolling)
  }
}

/// Cell content com DOIS hosts: header fixo (chevron) + painel expansível.
/// UIKIT_SCROLL_POLISH: substitui o UIHostingConfiguration único do TaskRow —
/// self-sizing só mede o painel; o chevron não entra na árvore de altura animada.
final class UIKitSplitTaskRowView: UIView {
  private let store = TaskRowSplitSession()
  /// UIKIT_SCROLL_POLISH: card fill/radius recuado pelos rowInsets — gap entre cards.
  private let chromeBackdrop = UIView()
  private var chromeTopConstraint: NSLayoutConstraint?
  private var chromeLeadingConstraint: NSLayoutConstraint?
  private var chromeBottomConstraint: NSLayoutConstraint?
  private var chromeTrailingConstraint: NSLayoutConstraint?
  private var headerHost: UIHostingController<AnyView>?
  private var panelHost: UIHostingController<AnyView>?
  private var headerHeightConstraint: NSLayoutConstraint?
  private var lastTaskId: String?
  var currentTaskId: String? { lastTaskId }
  private var lastPanelHeight: CGFloat = -1
  private var rowInsets: UIEdgeInsets = .zero
  private var style: TaskRowStyle = .card
  /// UIKIT_SCROLL_POLISH: lift do card inteiro (antes era só SwiftUI no header).
  private var liftPhase: TaskContextLiftPhase = .normal

  override init(frame: CGRect) {
    super.init(frame: frame)
    clipsToBounds = false
    backgroundColor = .clear
    setContentHuggingPriority(.required, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .vertical)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError() }

  override var intrinsicContentSize: CGSize {
    let headerH = headerHeightConstraint?.constant ?? 0
    let width = bounds.width > 1 ? bounds.width : UIScreen.main.bounds.width
    let contentWidth = max(width - rowInsets.left - rowInsets.right, 1)
    let panelH: CGFloat
    if let panelHost {
      panelH = ceil(panelHost.sizeThatFits(in: CGSize(
        width: contentWidth,
        height: .greatestFiniteMagnitude
      )).height)
    } else {
      panelH = 0
    }
    return CGSize(
      width: UIView.noIntrinsicMetric,
      height: rowInsets.top + headerH + panelH + rowInsets.bottom
    )
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    // UIKIT_SCROLL_POLISH: guarda secundária — invalidação primária é
    // sizingOptions + notifyExpansionChanged (não depender só de bounds).
    let panelH = panelHost?.view.bounds.height ?? 0
    if abs(panelH - lastPanelHeight) > 0.5 {
      lastPanelHeight = panelH
      invalidateIntrinsicContentSize()
      enclosingCell()?.invalidateIntrinsicContentSize()
    }
  }

  /// UIKIT_SCROLL_POLISH: invalidar cell no toggle, antes de esperar layout do painel.
  /// Resistance dinâmica: `.required` aberto (anti-overlap); `999` ao fechar (permite colapso).
  func notifyExpansionChanged(expanded: Bool) {
    applyPanelCompressionResistance(expanded: expanded)
    invalidateIntrinsicContentSize()
    setNeedsLayout()
    if let cell = enclosingCell() {
      cell.invalidateIntrinsicContentSize()
      cell.contentView.invalidateIntrinsicContentSize()
      cell.setNeedsLayout()
    }
  }

  /// UIKIT_SCROLL_POLISH: síncrono no toggle — antes do 1º frame do clip/colapso.
  func applyPanelCompressionResistance(expanded: Bool) {
    let priority: UILayoutPriority = expanded ? .required : UILayoutPriority(999)
    panelHost?.view.setContentCompressionResistancePriority(priority, for: .vertical)
  }

  /// UIKIT_SCROLL_POLISH: snap do reveal zera constraints internas; ICS do panelHost
  /// (sizingOptions) só remede se invalidado explicitamente — fora do ciclo SwiftUI.
  func invalidatePanelHostIntrinsicSize() {
    panelHost?.view.invalidateIntrinsicContentSize()
    panelHost?.view.setNeedsLayout()
    invalidateIntrinsicContentSize()
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    attachHostsIfNeeded()
  }

  struct Config {
    var task: Task
    var style: TaskRowStyle
    var flatSubtaskQueue: Bool
    var showProject: Bool
    var rowInsets: UIEdgeInsets
    var dimmed: Bool
    var muted: Bool
    /// PERF_SCROLL_345 (item 4): gate compartilhado do controller da lista.
    var scrollGate: UIKitListScrollWorkGate?
    /// true quando a cell foi (re)configurada com a lista em fling.
    var configuredWhileScrolling: Bool = false
    var onToggle: () -> Void
    var onTap: () -> Void
    var onSubtaskTap: (Subtask) -> Void
    var onSubtaskChanged: (SubtaskSaveSnapshot) -> Void
    var onSubtaskDeleted: (Subtask) -> Void
    var onWhatsAppCopy: (() -> Void)?
    var onSubtaskExpansionChanged: (Bool) -> Void
    var onEdit: () -> Void
    var onComplete: () -> Void
    var onDuplicate: () -> Void
    var onDelete: () -> Void
    var onRefresh: () -> Void
  }

  func apply(_ config: Config) {
    let task = config.task
    let headerH = AppLayout.taskRowHeaderHeight(
      hasDescription: task.hasDescription,
      hasMeta: AppLayout.taskRowShowsMeta(task: task, showProject: config.showProject),
      hasEyebrow: TaskRowLayoutStorage.showsEyebrow(
        projectName: config.showProject ? task.project : nil,
        showProject: config.showProject,
        priority: task.priority
      )
    )

    if lastTaskId != task.id {
      lastTaskId = task.id
      store.seed(from: task, restoreExpansion: true)
      applyLiftPhase(.normal, animated: false)
    } else if store.subtaskRevealActive || store.expanded {
      let sorted = TaskMapper.sortSubtasksForDisplay(task.subtasks)
      if store.displaySubtasks != sorted {
        // Durante dwell de concluir: atualiza campos in-place — não reshuffle (mata animação).
        if store.subtaskSortHoldId != nil {
          store.displaySubtasks = store.displaySubtasks.map { local in
            sorted.first(where: { Self.subtaskHoldKey($0) == Self.subtaskHoldKey(local) }) ?? local
          }
          store.subtasksDone = store.displaySubtasks.map(\.done)
        } else {
          let needsRemeasure =
            Self.expandLayoutSignature(store.displaySubtasks)
            != Self.expandLayoutSignature(sorted)
          store.displaySubtasks = sorted
          store.subtasksDone = sorted.map(\.done)
          if needsRemeasure {
            store.subtaskRevealLayoutPass &+= 1
            if let cell = enclosingCell() as? UIKitSizedTaskCell {
              cell.lockedHeight = nil
            }
            invalidatePanelHostIntrinsicSize()
          }
        }
      }
    }

    style = config.style
    rowInsets = config.rowInsets
    // UIKIT_SCROLL_POLISH: estrutura (hosts/backdrop/constraints) ANTES dos
    // valores — senão o 1º apply deixa insets em 0 (gap inconsistente no reuse).
    ensureHosts()
    updateChromeBackdropInsets(config.rowInsets)
    applyChrome()
    // Sync resistance com estado atual (recycle / restore aberto).
    applyPanelCompressionResistance(expanded: store.expanded)
    headerHeightConstraint?.constant = headerH

    let opacity: Double = config.dimmed ? 0.7 : (config.muted ? 0.85 : 1)
    let isCard = config.style.isCardFamily

    // PERF_SCROLL_345 (item 4): row nascida no fling adia labels/bump até o settle.
    let gate = config.scrollGate
    let observesGate = config.configuredWhileScrolling && gate != nil
    // Local — o builder da row é lazy agora; capturar `self.store` reteria a view.
    let sessionStore = store

    let header = UIKitScrollGatedRow(gate: gate, observesGate: observesGate) { deferHeavy in
      TaskRow(
        task: task,
        style: config.style,
        flatSubtaskQueue: config.flatSubtaskQueue,
        showProject: config.showProject,
        allLabels: [],
        deferHeavyWork: deferHeavy,
        restoreExpansionOnAppear: false,
        stabilizeExpandInSelfSizingCell: true,
        rowInteractionsEnabled: true,
        onToggle: config.onToggle,
        onTap: config.onTap,
        onSubtaskTap: config.onSubtaskTap,
        onSubtaskChanged: config.onSubtaskChanged,
        onSubtaskDeleted: { config.onSubtaskDeleted($0) },
        onWhatsAppCopy: config.onWhatsAppCopy,
        onSubtaskExpansionChanged: config.onSubtaskExpansionChanged,
        splitStore: sessionStore,
        bodyMode: .headerOnly,
        suppressCardChrome: isCard
      )
      .opacity(opacity)
      .taskContextMenu(
        task: task,
        onEdit: config.onEdit,
        onComplete: config.onComplete,
        onDuplicate: config.onDuplicate,
        onDelete: config.onDelete,
        onRefresh: config.onRefresh,
        onLiftPhaseChanged: { [weak self] phase in
          self?.applyLiftPhase(phase, animated: true)
        }
      )
    }
    .environment(ThemeManager.shared)
    .environment(MobileChromeController.shared)

    let panel = UIKitScrollGatedRow(gate: gate, observesGate: observesGate) { deferHeavy in
      TaskRow(
        task: task,
        style: config.style,
        flatSubtaskQueue: config.flatSubtaskQueue,
        showProject: config.showProject,
        allLabels: [],
        deferHeavyWork: deferHeavy,
        restoreExpansionOnAppear: false,
        stabilizeExpandInSelfSizingCell: true,
        rowInteractionsEnabled: true,
        onToggle: config.onToggle,
        onTap: nil,
        onSubtaskTap: config.onSubtaskTap,
        onSubtaskChanged: config.onSubtaskChanged,
        onSubtaskDeleted: { config.onSubtaskDeleted($0) },
        onWhatsAppCopy: nil,
        onSubtaskExpansionChanged: config.onSubtaskExpansionChanged,
        splitStore: sessionStore,
        bodyMode: .panelOnly,
        suppressCardChrome: isCard
      )
      .opacity(opacity)
    }
    .environment(ThemeManager.shared)
    .environment(MobileChromeController.shared)

    headerHost?.rootView = AnyView(header)
    panelHost?.rootView = AnyView(panel)

    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  private func ensureHosts() {
    ensureChromeBackdrop()
    let contentRoot = chromeBackdrop

    if headerHost == nil {
      let host = UIHostingController(rootView: AnyView(EmptyView()))
      host.safeAreaRegions = []
      host.view.backgroundColor = .clear
      host.view.translatesAutoresizingMaskIntoConstraints = false
      contentRoot.addSubview(host.view)
      let height = host.view.heightAnchor.constraint(equalToConstant: 54)
      headerHeightConstraint = height
      NSLayoutConstraint.activate([
        host.view.topAnchor.constraint(equalTo: contentRoot.topAnchor),
        host.view.leadingAnchor.constraint(equalTo: contentRoot.leadingAnchor),
        host.view.trailingAnchor.constraint(equalTo: contentRoot.trailingAnchor),
        height,
      ])
      headerHost = host
    }
    if panelHost == nil {
      let host = UIHostingController(rootView: AnyView(EmptyView()))
      host.safeAreaRegions = []
      // UIKIT_SCROLL_POLISH: intrinsic sincronizado com SwiftUI — evita B comprimido a ~0.
      host.sizingOptions = [.intrinsicContentSize]
      host.view.backgroundColor = .clear
      host.view.translatesAutoresizingMaskIntoConstraints = false
      host.view.setContentCompressionResistancePriority(
        // Fechado por padrão; apply/notify sobe para .required na abertura.
        UILayoutPriority(999),
        for: .vertical
      )
      host.view.setContentHuggingPriority(.defaultLow, for: .vertical)
      contentRoot.addSubview(host.view)
      guard let headerView = headerHost?.view else { return }
      NSLayoutConstraint.activate([
        host.view.topAnchor.constraint(equalTo: headerView.bottomAnchor),
        host.view.leadingAnchor.constraint(equalTo: contentRoot.leadingAnchor),
        host.view.trailingAnchor.constraint(equalTo: contentRoot.trailingAnchor),
        host.view.bottomAnchor.constraint(equalTo: contentRoot.bottomAnchor),
      ])
      panelHost = host
    }
    attachHostsIfNeeded()
  }

  private func ensureChromeBackdrop() {
    guard chromeBackdrop.superview == nil else { return }
    chromeBackdrop.translatesAutoresizingMaskIntoConstraints = false
    chromeBackdrop.clipsToBounds = true
    addSubview(chromeBackdrop)
    let top = chromeBackdrop.topAnchor.constraint(equalTo: topAnchor)
    let leading = chromeBackdrop.leadingAnchor.constraint(equalTo: leadingAnchor)
    let bottom = chromeBackdrop.bottomAnchor.constraint(equalTo: bottomAnchor)
    let trailing = chromeBackdrop.trailingAnchor.constraint(equalTo: trailingAnchor)
    chromeTopConstraint = top
    chromeLeadingConstraint = leading
    chromeBottomConstraint = bottom
    chromeTrailingConstraint = trailing
    NSLayoutConstraint.activate([top, leading, bottom, trailing])
  }

  private func updateChromeBackdropInsets(_ insets: UIEdgeInsets) {
    chromeTopConstraint?.constant = insets.top
    chromeLeadingConstraint?.constant = insets.left
    chromeBottomConstraint?.constant = -insets.bottom
    chromeTrailingConstraint?.constant = -insets.right
  }

  /// UIKIT_SCROLL_POLISH: mesmos valores de TaskContextLift — no container (backdrop+hosts).
  private func applyLiftPhase(_ phase: TaskContextLiftPhase, animated: Bool) {
    guard liftPhase != phase else { return }
    liftPhase = phase
    let lifted = phase != .normal
    let reduceMotion = UIAccessibility.isReduceMotionEnabled

    let applyVisual = { [weak self] in
      guard let self else { return }
      if lifted, !reduceMotion {
        // scale no centro do UIView, depois translate (paridade scaleEffect → offset).
        self.transform = CGAffineTransform(scaleX: TaskContextLift.scale, y: TaskContextLift.scale)
          .concatenating(CGAffineTransform(translationX: 0, y: TaskContextLift.offsetY))
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = Float(TaskContextLift.shadowOpacity)
        self.layer.shadowRadius = TaskContextLift.shadowRadius
        self.layer.shadowOffset = CGSize(width: 0, height: TaskContextLift.shadowY)
        self.layer.shadowPath = UIBezierPath(
          roundedRect: self.chromeBackdrop.frame,
          cornerRadius: self.style.isCardFamily ? 12 : 0
        ).cgPath
      } else {
        self.transform = .identity
        self.layer.shadowOpacity = 0
        self.layer.shadowRadius = 0
        self.layer.shadowOffset = .zero
        self.layer.shadowPath = nil
      }
      self.enclosingCell()?.layer.zPosition = lifted ? 1 : 0
    }

    guard animated, !reduceMotion else {
      applyVisual()
      return
    }

    // Paridade AppMotion.smooth(duration: 0.28).
    UIView.animate(
      withDuration: 0.28,
      delay: 0,
      options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction],
      animations: applyVisual
    )
  }

  private func attachHostsIfNeeded() {
    guard let parent = enclosingViewController() else { return }
    for host in [headerHost, panelHost].compactMap({ $0 }) where host.parent == nil {
      parent.addChild(host)
      host.didMove(toParent: parent)
    }
  }

  private func applyChrome() {
    let colors = ThemeManager.shared.colors
    backgroundColor = .clear
    layer.cornerRadius = 0
    layer.borderWidth = 0
    layer.borderColor = nil

    if style.isCardFamily {
      let fill: UIColor
      if style == .cardLight {
        fill = Self.opaqueBlend(
          src: UIColor(colors.surface),
          dst: UIColor(colors.background),
          alpha: 0.72
        )
      } else {
        fill = UIColor(colors.surface)
      }
      chromeBackdrop.backgroundColor = fill
      chromeBackdrop.layer.cornerRadius = 12
      chromeBackdrop.layer.cornerCurve = .continuous
      if style == .cardLight {
        chromeBackdrop.layer.borderWidth = 1
        chromeBackdrop.layer.borderColor = UIColor(colors.textPrimary).withAlphaComponent(0.055).cgColor
      } else {
        chromeBackdrop.layer.borderWidth = 0
        chromeBackdrop.layer.borderColor = nil
      }
    } else {
      chromeBackdrop.backgroundColor = .clear
      chromeBackdrop.layer.cornerRadius = 0
      chromeBackdrop.layer.borderWidth = 0
      chromeBackdrop.layer.borderColor = nil
    }
  }

  private static func subtaskHoldKey(_ sub: Subtask) -> String {
    if let id = sub.id, !id.isEmpty { return id }
    return "\(sub.taskId ?? ""):\(sub.order)"
  }

  private static func expandLayoutSignature(_ subs: [Subtask]) -> Int {
    var hasher = Hasher()
    hasher.combine(subs.count)
    for sub in subs {
      hasher.combine(sub.idOrFallback)
      hasher.combine(sub.description?.isEmpty == false)
      hasher.combine(sub.dueDate != nil)
      hasher.combine(sub.labelIds)
    }
    return hasher.finalize()
  }

  private static func opaqueBlend(src: UIColor, dst: UIColor, alpha: CGFloat) -> UIColor {
    let a = min(max(alpha, 0), 1)
    var sr: CGFloat = 0, sg: CGFloat = 0, sb: CGFloat = 0, sa: CGFloat = 0
    var dr: CGFloat = 0, dg: CGFloat = 0, db: CGFloat = 0, da: CGFloat = 0
    src.getRed(&sr, green: &sg, blue: &sb, alpha: &sa)
    dst.getRed(&dr, green: &dg, blue: &db, alpha: &da)
    return UIColor(
      red: sr * a + dr * (1 - a),
      green: sg * a + dg * (1 - a),
      blue: sb * a + db * (1 - a),
      alpha: 1
    )
  }

  private func enclosingViewController() -> UIViewController? {
    var responder: UIResponder? = self
    while let current = responder {
      if let vc = current as? UIViewController { return vc }
      responder = current.next
    }
    return nil
  }

  private func enclosingCell() -> UICollectionViewCell? {
    var view: UIView? = superview
    while let current = view {
      if let cell = current as? UICollectionViewCell { return cell }
      view = current.superview
    }
    return nil
  }
}

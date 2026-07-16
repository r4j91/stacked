import SwiftUI
import UIKit

/// Revela subtarefas com altura animada via UIKit — paridade Flutter `SizeTransition`, estável dentro de `List`.
struct SubtaskExpandReveal<Content: View>: UIViewRepresentable {
  let expanded: Bool
  let reduceMotion: Bool
  let layoutPass: Int
  let contentRevision: Int
  /// Em `UIHostingConfiguration`: título fica parado — abre/fecha só o painel.
  let stabilizeSelfSizingParent: Bool
  /// Remount/recycle já aberto: aplica altura final sem animar 0→full.
  let snapOpen: Bool
  /// Preenche slack de altura no clip (evita tarja do card atrás do painel).
  let panelFill: Color?
  let content: Content

  init(
    expanded: Bool,
    reduceMotion: Bool,
    layoutPass: Int = 0,
    contentRevision: Int = 0,
    stabilizeSelfSizingParent: Bool = false,
    snapOpen: Bool = false,
    panelFill: Color? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.expanded = expanded
    self.reduceMotion = reduceMotion
    self.layoutPass = layoutPass
    self.contentRevision = contentRevision
    self.stabilizeSelfSizingParent = stabilizeSelfSizingParent
    self.snapOpen = snapOpen
    self.panelFill = panelFill
    self.content = content()
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeUIView(context: Context) -> SubtaskExpandContainerView {
    let view = SubtaskExpandContainerView()
    context.coordinator.container = view
    return view
  }

  func updateUIView(_ uiView: SubtaskExpandContainerView, context: Context) {
    let width = uiView.bounds.width > 1 ? uiView.bounds.width : context.coordinator.lastWidth
    context.coordinator.lastWidth = width
    let hosting = context.coordinator.hosting(in: uiView)

    let revisionChanged = contentRevision != context.coordinator.lastContentRevision
    let openingOrOpen = expanded || context.coordinator.wasExpanded
    if openingOrOpen, revisionChanged || expanded != context.coordinator.wasExpanded || !context.coordinator.hasPushedContent {
      context.coordinator.updateContent(AnyView(content), hosting: hosting)
      context.coordinator.lastContentRevision = contentRevision
      context.coordinator.hasPushedContent = true
    }
    context.coordinator.wasExpanded = expanded

    uiView.setPanelFill(panelFill.map { UIColor($0) })
    uiView.configure(
      hosting: hosting,
      width: width,
      expanded: expanded,
      animated: !reduceMotion,
      layoutPass: layoutPass,
      stabilizeSelfSizingParent: stabilizeSelfSizingParent,
      snapOpen: snapOpen
    )
  }

  final class Coordinator {
    weak var container: SubtaskExpandContainerView?
    private var host: UIHostingController<AnyView>?
    var lastWidth: CGFloat = 320
    var wasExpanded = false
    var lastContentRevision: Int = .min
    var hasPushedContent = false

    func hosting(in container: SubtaskExpandContainerView) -> UIHostingController<AnyView> {
      if let host { return host }
      let host = UIHostingController(rootView: AnyView(EmptyView()))
      // Sem safe area: sizeThatFits inchava o fundo e deixava faixa vazia (tarja).
      host.safeAreaRegions = []
      host.view.backgroundColor = .clear
      host.view.translatesAutoresizingMaskIntoConstraints = false
      host.view.setContentHuggingPriority(.required, for: .vertical)
      host.view.setContentCompressionResistancePriority(.required, for: .vertical)
      container.install(host: host)
      self.host = host
      return host
    }

    func updateContent(_ content: AnyView, hosting: UIHostingController<AnyView>) {
      hosting.rootView = content
    }
  }
}

// MARK: - UIKit container

final class SubtaskExpandContainerView: UIView {
  private weak var hostedController: UIHostingController<AnyView>?
  private weak var hostView: UIView?
  private weak var clipView: UIView?
  private var hostHeightConstraint: NSLayoutConstraint?
  private var clipHeightConstraint: NSLayoutConstraint?
  private var selfHeightConstraint: NSLayoutConstraint?
  private var fullHeight: CGFloat = 0
  private var lastExpanded: Bool?
  private var lastAppliedWidth: CGFloat = 0
  private var lastLayoutPass: Int = -1
  private var isAnimating = false
  /// Remasure async precisa saber se o open usa pin (stabilize).
  private var stabilizeSelfSizingParent = false
  /// Altura antes do remasure de meta — detecta encolhe stale.
  private var contentRemeasureBaseline: CGFloat = 0

  override init(frame: CGRect) {
    super.init(frame: frame)
    clipsToBounds = true
    backgroundColor = .clear
    isUserInteractionEnabled = true
    setContentHuggingPriority(.required, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .vertical)
    selfHeightConstraint = heightAnchor.constraint(equalToConstant: 0)
    selfHeightConstraint?.isActive = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError() }

  override var intrinsicContentSize: CGSize {
    CGSize(width: UIView.noIntrinsicMetric, height: selfHeightConstraint?.constant ?? 0)
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    attachHostedControllerIfNeeded()
  }

  /// Fundo do clip = mesma tinta do painel SwiftUI (slack de medida não vira tarja).
  /// Só no `clipView` — no self, o close UIKit mantém altura travada e pintaria um bloco.
  func setPanelFill(_ color: UIColor?) {
    let fill = color ?? .clear
    if clipView?.backgroundColor != fill {
      clipView?.backgroundColor = fill
    }
  }

  func install(host: UIHostingController<AnyView>) {
    guard hostView == nil else { return }
    hostedController = host
    hostView = host.view

    // clipView: anima a altura VISUAL. selfHeight = altura reportada à lista.
    // No fechar UIKit, a lista só encolhe no fim — o clip faz o “fecha pra cima”
    // sem mexer a tarefa pai.
    let clip = UIView()
    clip.clipsToBounds = true
    clip.backgroundColor = backgroundColor
    clip.isUserInteractionEnabled = true
    clip.translatesAutoresizingMaskIntoConstraints = false
    addSubview(clip)
    clipView = clip
    let clipHeight = clip.heightAnchor.constraint(equalToConstant: 0)
    clipHeightConstraint = clipHeight
    NSLayoutConstraint.activate([
      clip.topAnchor.constraint(equalTo: topAnchor),
      clip.leadingAnchor.constraint(equalTo: leadingAnchor),
      clip.trailingAnchor.constraint(equalTo: trailingAnchor),
      clipHeight,
    ])

    host.view.backgroundColor = .clear
    host.view.isUserInteractionEnabled = true
    clip.addSubview(host.view)
    let height = host.view.heightAnchor.constraint(equalToConstant: 0)
    hostHeightConstraint = height
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: clip.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: clip.trailingAnchor),
      height,
    ])
    attachHostedControllerIfNeeded()
  }

  /// Nested UIHostingController sem child VC quebra taps (Inbox/Projeto UIKit).
  private func attachHostedControllerIfNeeded() {
    guard let host = hostedController, host.parent == nil else { return }
    guard let parent = enclosingViewController() else { return }
    parent.addChild(host)
    host.didMove(toParent: parent)
  }

  func configure(
    hosting: UIHostingController<AnyView>,
    width: CGFloat,
    expanded: Bool,
    animated: Bool,
    layoutPass: Int = 0,
    stabilizeSelfSizingParent: Bool = false,
    snapOpen: Bool = false
  ) {
    attachHostedControllerIfNeeded()
    self.stabilizeSelfSizingParent = stabilizeSelfSizingParent

    // Evita reentrada no meio do close.
    if isAnimating, !expanded, stabilizeSelfSizingParent {
      return
    }

    let fitWidth = max(width, 1)
    let widthChanged = abs(fitWidth - lastAppliedWidth) > 1
    if widthChanged {
      lastAppliedWidth = fitWidth
    }

    let stateChanged = lastExpanded != expanded
    let layoutPassChanged = layoutPass != lastLayoutPass
    if layoutPassChanged {
      lastLayoutPass = layoutPass
    }

    // Snap de remount: não zerar fullHeight (já sabemos a altura).
    if stateChanged && expanded && !snapOpen {
      fullHeight = 0
      hostView?.transform = .identity
    }

    // Só content change com painel já aberto (etiqueta etc.).
    // Não roda no open/close — senão mexe na animação de expandir.
    if layoutPassChanged, expanded, !stateChanged, !isAnimating, fitWidth > 1 {
      if let cell = enclosingCell() as? UIKitSizedTaskCell {
        cell.lockedHeight = nil
      }
      contentRemeasureBaseline = max(selfHeightConstraint?.constant ?? 0, fullHeight)
      lastExpanded = expanded
      scheduleContentRemeasure(hosting: hosting, width: fitWidth)
      return
    }

    if !isAnimating {
      let needsMeasure = widthChanged || fullHeight <= 0 || (stateChanged && expanded) || layoutPassChanged
      if needsMeasure, expanded || fullHeight <= 0 {
        let measured = measureHeight(hosting: hosting, width: fitWidth)
        if measured > 0 { fullHeight = measured }
      }
    }

    // Só aplica altura do host quando aberto — fechado o clip/self controlam o buraco.
    if expanded {
      hostHeightConstraint?.constant = fullHeight
    }
    let interactive = expanded
    hosting.view.isUserInteractionEnabled = interactive
    clipView?.isUserInteractionEnabled = interactive
    isUserInteractionEnabled = true

    let target = expanded ? fullHeight : 0
    lastExpanded = expanded

    let current = selfHeightConstraint?.constant ?? 0
    if expanded && fullHeight <= 0 && fitWidth > 1 {
      scheduleRemeasure(hosting: hosting, width: fitWidth, animated: animated && !snapOpen)
      return
    }

    // Fechado mas altura residual — zera sem reancorar offset (reancorar = “deslize”).
    if !expanded, !isAnimating, current > 0.5, !stateChanged {
      selfHeightConstraint?.constant = 0
      clipHeightConstraint?.constant = 0
      hostHeightConstraint?.constant = 0
      fullHeight = 0
      hostView?.transform = .identity
      invalidateIntrinsicContentSize()
      return
    }

    guard stateChanged || layoutPassChanged || abs(current - target) > 0.5 else { return }

    // snapOpen: recycle já aberto — sem flash 0→full no scroll.
    let shouldAnimate = animated && stateChanged && !snapOpen && !UIAccessibility.isReduceMotionEnabled

    // Fechar em cell self-sizing UIKit: clip encolhe primeiro; lista só zera no fim.
    if !expanded, stabilizeSelfSizingParent {
      collapseWithVisualClip(animated: shouldAnimate, reanchorParent: false)
      return
    }

    // Abrir UIKit: cresce a altura e reâncora o offset — topo do card (chevron) fica parado.
    // pinParent:false fazia o chevron “descer e voltar” no grow da collection.
    if expanded, stabilizeSelfSizingParent {
      expandWithPinnedParent(height: target, animated: shouldAnimate)
      return
    }

    applyVisibleHeight(
      target,
      expanded: expanded,
      animated: shouldAnimate,
      pinParent: false
    )
  }

  private func scheduleRemeasure(
    hosting: UIHostingController<AnyView>,
    width: CGFloat,
    animated: Bool,
    attempt: Int = 0
  ) {
    DispatchQueue.main.async { [weak self] in
      guard let self, self.lastExpanded == true else { return }
      self.remeasureExpanded(hosting: hosting, width: width, animated: animated, attempt: attempt)
    }
  }

  /// Remedir após swap de meta (etiqueta). Dois turns: SwiftUI precisa assentar
  /// o rootView antes do sizeThatFits encolher — 1 async às vezes ainda mede alto.
  private func scheduleContentRemeasure(
    hosting: UIHostingController<AnyView>,
    width: CGFloat,
    attempt: Int = 0
  ) {
    DispatchQueue.main.async { [weak self] in
      DispatchQueue.main.async { [weak self] in
        guard let self, self.lastExpanded == true else { return }
        hosting.view.invalidateIntrinsicContentSize()
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
        self.remeasureExpanded(
          hosting: hosting,
          width: width,
          animated: false,
          attempt: attempt,
          updateHeightCache: true
        )
      }
    }
  }

  private func remeasureExpanded(
    hosting: UIHostingController<AnyView>,
    width: CGFloat,
    animated: Bool,
    attempt: Int,
    updateHeightCache: Bool = false
  ) {
    guard !isAnimating else {
      if attempt < 6 {
        scheduleRemeasure(hosting: hosting, width: width, animated: animated, attempt: attempt + 1)
      }
      return
    }

    if updateHeightCache {
      // Solta constraints altas antes do sizeThatFits — senão a medida herda o buraco.
      selfHeightConstraint?.constant = 0
      clipHeightConstraint?.constant = 0
      hostHeightConstraint?.constant = 0
      hosting.view.invalidateIntrinsicContentSize()
      hosting.view.setNeedsLayout()
      hosting.view.layoutIfNeeded()
    }

    let measured = measureHeight(hosting: hosting, width: width)
    if measured <= 0 {
      if attempt < 6 {
        if updateHeightCache {
          scheduleContentRemeasure(hosting: hosting, width: width, attempt: attempt + 1)
        } else {
          scheduleRemeasure(hosting: hosting, width: width, animated: animated, attempt: attempt + 1)
        }
      }
      return
    }

    if updateHeightCache {
      let sameAsBaseline = abs(measured - contentRemeasureBaseline) <= 0.5
      if sameAsBaseline, contentRemeasureBaseline > 0.5, attempt < 4 {
        selfHeightConstraint?.constant = contentRemeasureBaseline
        clipHeightConstraint?.constant = contentRemeasureBaseline
        hostHeightConstraint?.constant = contentRemeasureBaseline
        scheduleContentRemeasure(hosting: hosting, width: width, attempt: attempt + 1)
        return
      }
    } else if abs(measured - (selfHeightConstraint?.constant ?? 0)) <= 0.5, fullHeight > 0 {
      return
    }

    fullHeight = measured
    hostHeightConstraint?.constant = measured
    clipHeightConstraint?.constant = measured
    // Remeasure no open UIKit: mesmo pin do configure (topo/chevron parado).
    if stabilizeSelfSizingParent, (selfHeightConstraint?.constant ?? 0) <= 0.5, !updateHeightCache {
      expandWithPinnedParent(height: measured, animated: animated)
      return
    }
    if let cell = enclosingCell() as? UIKitSizedTaskCell {
      cell.lockedHeight = nil
    }
    applyVisibleHeight(measured, expanded: true, animated: animated, pinParent: false)
    enclosingSplitRowView()?.invalidatePanelHostIntrinsicSize()
    if let collectionView = enclosingCollectionView() {
      collectionView.performBatchUpdates(nil)
      collectionView.layoutIfNeeded()
    }
    if updateHeightCache {
      syncExpandedHeightCacheAfterRemeasure()
    }
  }

  private func syncExpandedHeightCacheAfterRemeasure() {
    guard let cell = enclosingCell() as? UIKitSizedTaskCell else { return }
    let height = cell.bounds.height
    guard height > 40 else { return }
    cell.lockedHeight = height
    if let taskId = enclosingSplitRowView()?.currentTaskId,
       let list = enclosingCollectionView()?.delegate as? UIKitHostedTaskListController {
      list.replaceExpandedRowHeightCache(taskId: taskId, height: height)
    }
  }

  private func measureHeight(hosting: UIHostingController<AnyView>, width: CGFloat) -> CGFloat {
    // Constraint de altura 0 (clip fechado) faz sizeThatFits devolver 0 — soltar na medida.
    let heightConstraint = hostHeightConstraint
    let previousConstant = heightConstraint?.constant ?? 0
    let wasActive = heightConstraint?.isActive ?? false
    heightConstraint?.isActive = false
    defer {
      heightConstraint?.constant = previousConstant
      heightConstraint?.isActive = wasActive
    }

    if #available(iOS 16.0, *) {
      let size = hosting.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
      return ceil(size.height)
    }
    hosting.view.setNeedsLayout()
    hosting.view.layoutIfNeeded()
    return ceil(hosting.view.systemLayoutSizeFitting(
      CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    ).height)
  }

  private func applyVisibleHeight(
    _ height: CGFloat,
    expanded: Bool,
    animated: Bool,
    pinParent: Bool
  ) {
    // Fechar UIKit: altura da LISTA fica travada (pai parado); só o clip encolhe
    // — visual idêntico ao fechar por altura, sem deslizar o conteúdo.
    if !expanded, pinParent {
      collapseWithVisualClip(animated: animated, reanchorParent: true)
      return
    }

    // Abrir UIKit: cresce a altura e reâncora o offset — título não sobe no scroll.
    if expanded, pinParent {
      expandWithPinnedParent(height: height, animated: animated)
      return
    }

    hostView?.transform = .identity

    let collectionView = enclosingCollectionView()
    let applyLayout = { [weak self] in
      guard let self else { return }
      self.selfHeightConstraint?.constant = height
      self.clipHeightConstraint?.constant = height
      self.hostHeightConstraint?.constant = height
      self.invalidateIntrinsicContentSize()
    }

    guard animated else {
      applyLayout()
      return
    }

    isAnimating = true
    let duration: TimeInterval = expanded ? 0.22 : 0.16
    let options: UIView.AnimationOptions = [
      expanded ? .curveEaseOut : .curveEaseIn,
      .allowUserInteraction,
      .beginFromCurrentState,
      .layoutSubviews,
    ]

    UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
      applyLayout()
      self.clipView?.layoutIfNeeded()
      self.superview?.layoutIfNeeded()
      if expanded {
        collectionView?.layoutIfNeeded()
      }
    }) { [weak self] _ in
      self?.isAnimating = false
    }
  }

  /// Cresce a cell reancorando o contentOffset — pai fica parado na abertura.
  private func expandWithPinnedParent(height: CGFloat, animated: Bool) {
    hostView?.transform = .identity

    let collectionView = enclosingCollectionView()
    let anchorVisibleY: CGFloat? = {
      guard let cell = enclosingCell(), let collectionView else { return nil }
      return cell.convert(CGPoint.zero, to: collectionView).y - collectionView.contentOffset.y
    }()

    let applyLayout = { [weak self] in
      guard let self else { return }
      self.selfHeightConstraint?.constant = height
      self.clipHeightConstraint?.constant = height
      self.hostHeightConstraint?.constant = height
      self.invalidateIntrinsicContentSize()
    }

    let pin = { [weak self] in
      guard let self else { return }
      Self.restoreCellVisibleY(
        cell: self.enclosingCell(),
        collectionView: collectionView,
        anchorVisibleY: anchorVisibleY
      )
    }

    guard animated else {
      UIView.performWithoutAnimation {
        applyLayout()
        self.superview?.layoutIfNeeded()
        collectionView?.layoutIfNeeded()
        pin()
      }
      return
    }

    isAnimating = true
    // Pina durante o grow (~0.22s) — layout da collection empurra o título sem isto.
    Self.reanchorNextFrames(
      cellProvider: { [weak self] in self?.enclosingCell() },
      collectionView: collectionView,
      anchorVisibleY: anchorVisibleY,
      frames: 16
    )

    UIView.animate(
      withDuration: 0.22,
      delay: 0,
      options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState, .layoutSubviews],
      animations: {
        applyLayout()
        self.clipView?.layoutIfNeeded()
        self.superview?.layoutIfNeeded()
        pin()
      },
      completion: { [weak self] _ in
        pin()
        self?.isAnimating = false
      }
    )
  }

  /// Visual = altura do clip full→0 (conteúdo parado, some por baixo).
  /// Lista = altura travada até o fim; aí zera (opcionalmente reancora o pai).
  private func collapseWithVisualClip(animated: Bool, reanchorParent: Bool = true) {
    hostView?.transform = .identity

    let from = max(selfHeightConstraint?.constant ?? 0, fullHeight)
    guard from > 0.5 else {
      if reanchorParent {
        snapReportedHeightToZeroAndPin()
      } else {
        snapReportedHeightToZero()
      }
      return
    }

    // Trava a altura reportada à collection — título não anda.
    selfHeightConstraint?.constant = from
    hostHeightConstraint?.constant = from
    clipHeightConstraint?.constant = from
    invalidateIntrinsicContentSize()

    let shrinkClip = { [weak self] in
      self?.clipHeightConstraint?.constant = 0
      self?.clipView?.layoutIfNeeded()
    }

    let finish = { [weak self] in
      guard let self else { return }
      if reanchorParent {
        self.snapReportedHeightToZeroAndPin()
      } else {
        self.snapReportedHeightToZero()
      }
    }

    guard animated else {
      shrinkClip()
      finish()
      return
    }

    isAnimating = true
    UIView.animate(
      withDuration: 0.16,
      delay: 0,
      options: [.curveEaseIn, .allowUserInteraction, .beginFromCurrentState, .layoutSubviews],
      animations: {
        shrinkClip()
      },
      completion: { [weak self] _ in
        finish()
        self?.isAnimating = false
      }
    )
  }

  /// Zera altura reportada sem reancorar contentOffset (evita deslize no fechar UIKit).
  private func snapReportedHeightToZero() {
    let collectionView = enclosingCollectionView()

    selfHeightConstraint?.constant = 0
    clipHeightConstraint?.constant = 0
    hostHeightConstraint?.constant = 0
    fullHeight = 0
    invalidateIntrinsicContentSize()

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    UIView.performWithoutAnimation {
      self.superview?.setNeedsLayout()
      self.superview?.layoutIfNeeded()
      if let cell = self.enclosingCell() {
        cell.invalidateIntrinsicContentSize()
        cell.contentView.invalidateIntrinsicContentSize()
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
      }
      // UIKIT_SCROLL_POLISH: após constraints internas em 0 — remedir panelHost (ICS).
      // Sem layoutIfNeeded no panelHost ainda; só se validação mostrar vão residual.
      self.enclosingSplitRowView()?.invalidatePanelHostIntrinsicSize()
      collectionView?.layoutIfNeeded()
    }
    CATransaction.commit()

    hostView?.transform = .identity
  }

  private func snapReportedHeightToZeroAndPin() {
    let collectionView = enclosingCollectionView()
    let anchorVisibleY: CGFloat? = {
      guard let cell = enclosingCell(), let collectionView else { return nil }
      return cell.convert(CGPoint.zero, to: collectionView).y - collectionView.contentOffset.y
    }()

    selfHeightConstraint?.constant = 0
    clipHeightConstraint?.constant = 0
    hostHeightConstraint?.constant = 0
    fullHeight = 0
    invalidateIntrinsicContentSize()

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    UIView.performWithoutAnimation {
      self.superview?.setNeedsLayout()
      self.superview?.layoutIfNeeded()
      if let cell = self.enclosingCell() {
        cell.invalidateIntrinsicContentSize()
        cell.contentView.invalidateIntrinsicContentSize()
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
      }
      // UIKIT_SCROLL_POLISH: após constraints internas em 0 — remedir panelHost (ICS).
      self.enclosingSplitRowView()?.invalidatePanelHostIntrinsicSize()
      collectionView?.layoutIfNeeded()
      Self.restoreCellVisibleY(
        cell: self.enclosingCell(),
        collectionView: collectionView,
        anchorVisibleY: anchorVisibleY
      )
    }
    CATransaction.commit()

    hostView?.transform = .identity

    Self.reanchorNextFrames(
      cellProvider: { [weak self] in self?.enclosingCell() },
      collectionView: collectionView,
      anchorVisibleY: anchorVisibleY,
      frames: 3
    )
  }

  private static func restoreCellVisibleY(
    cell: UICollectionViewCell?,
    collectionView: UICollectionView?,
    anchorVisibleY: CGFloat?
  ) {
    guard let cell, let collectionView, let anchorVisibleY else { return }
    // Nunca roubar o fling do usuário — era o “pula subtarefa” no scroll rápido.
    if collectionView.isDragging || collectionView.isDecelerating { return }
    let cellY = cell.convert(CGPoint.zero, to: collectionView).y
    var targetOffset = cellY - anchorVisibleY
    // Evita forçar overscroll no fim da lista (rubber-band + remount).
    let minY = -collectionView.adjustedContentInset.top
    let maxY = max(
      minY,
      collectionView.contentSize.height - collectionView.bounds.height + collectionView.adjustedContentInset.bottom
    )
    targetOffset = min(max(targetOffset, minY), maxY)
    if abs(collectionView.contentOffset.y - targetOffset) > 0.25 {
      collectionView.contentOffset.y = targetOffset
    }
  }

  private static func reanchorNextFrames(
    cellProvider: @escaping () -> UICollectionViewCell?,
    collectionView: UICollectionView?,
    anchorVisibleY: CGFloat?,
    frames: Int
  ) {
    guard frames > 0, collectionView != nil, anchorVisibleY != nil else { return }
    let holder = CollapsePinDisplayLink(
      cellProvider: cellProvider,
      collectionView: collectionView,
      anchorVisibleY: anchorVisibleY,
      maxTicks: frames
    )
    holder.start()
  }

  private final class CollapsePinDisplayLink: NSObject {
    private var link: CADisplayLink?
    private let cellProvider: () -> UICollectionViewCell?
    private weak var collectionView: UICollectionView?
    private let anchorVisibleY: CGFloat?
    private var remaining: Int

    init(
      cellProvider: @escaping () -> UICollectionViewCell?,
      collectionView: UICollectionView?,
      anchorVisibleY: CGFloat?,
      maxTicks: Int
    ) {
      self.cellProvider = cellProvider
      self.collectionView = collectionView
      self.anchorVisibleY = anchorVisibleY
      self.remaining = maxTicks
      super.init()
    }

    func start() {
      let link = CADisplayLink(target: self, selector: #selector(tick))
      link.add(to: .main, forMode: .common)
      self.link = link
    }

    @objc private func tick() {
      if let collectionView, collectionView.isDragging || collectionView.isDecelerating {
        link?.invalidate()
        link = nil
        return
      }
      UIView.performWithoutAnimation {
        SubtaskExpandContainerView.restoreCellVisibleY(
          cell: cellProvider(),
          collectionView: collectionView,
          anchorVisibleY: anchorVisibleY
        )
      }
      remaining -= 1
      if remaining <= 0 {
        link?.invalidate()
        link = nil
      }
    }
  }

  private func enclosingCollectionView() -> UICollectionView? {
    var view: UIView? = superview
    while let current = view {
      if let collection = current as? UICollectionView { return collection }
      view = current.superview
    }
    return nil
  }

  private func enclosingSplitRowView() -> UIKitSplitTaskRowView? {
    var view: UIView? = superview
    while let current = view {
      if let split = current as? UIKitSplitTaskRowView { return split }
      view = current.superview
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

  private func enclosingViewController() -> UIViewController? {
    var responder: UIResponder? = self
    while let current = responder {
      if let vc = current as? UIViewController { return vc }
      responder = current.next
    }
    return nil
  }
}

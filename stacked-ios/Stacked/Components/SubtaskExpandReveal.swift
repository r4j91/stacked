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
    // Sem pin do pai: reancorar contentOffset no open/close deslizava a lista
    // (e brigava com o recycle). Altura sobe/desce normal, como no SwiftUI.
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

  private func remeasureExpanded(
    hosting: UIHostingController<AnyView>,
    width: CGFloat,
    animated: Bool,
    attempt: Int
  ) {
    guard !isAnimating else {
      if attempt < 6 {
        scheduleRemeasure(hosting: hosting, width: width, animated: animated, attempt: attempt + 1)
      }
      return
    }
    let measured = measureHeight(hosting: hosting, width: width)
    if measured <= 0 {
      if attempt < 6 {
        scheduleRemeasure(hosting: hosting, width: width, animated: animated, attempt: attempt + 1)
      }
      return
    }
    if abs(measured - (selfHeightConstraint?.constant ?? 0)) <= 0.5, fullHeight > 0 {
      return
    }
    fullHeight = measured
    hostHeightConstraint?.constant = measured
    clipHeightConstraint?.constant = measured
    // Remeasure while já aberto — nunca pin/rouba scroll.
    applyVisibleHeight(measured, expanded: true, animated: animated, pinParent: false)
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
      collapseWithVisualClip(animated: animated)
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
    let duration: TimeInterval = 0.22
    let options: UIView.AnimationOptions = [
      .curveEaseOut,
      .allowUserInteraction,
      .beginFromCurrentState,
      .layoutSubviews,
    ]

    UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
      applyLayout()
      self.clipView?.layoutIfNeeded()
      self.superview?.layoutIfNeeded()
      // Lista acompanha a altura no mesmo tick — evita salto discreto open/close.
      collectionView?.layoutIfNeeded()
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
  /// Lista = altura travada até o fim; aí zera e reancora (pai não pula).
  private func collapseWithVisualClip(animated: Bool) {
    hostView?.transform = .identity

    let from = max(selfHeightConstraint?.constant ?? 0, fullHeight)
    guard from > 0.5 else {
      snapReportedHeightToZeroAndPin()
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

    guard animated else {
      shrinkClip()
      snapReportedHeightToZeroAndPin()
      return
    }

    isAnimating = true
    UIView.animate(
      withDuration: 0.22,
      delay: 0,
      options: [.curveEaseIn, .allowUserInteraction, .beginFromCurrentState, .layoutSubviews],
      animations: {
        shrinkClip()
      },
      completion: { [weak self] _ in
        self?.snapReportedHeightToZeroAndPin()
        self?.isAnimating = false
      }
    )
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

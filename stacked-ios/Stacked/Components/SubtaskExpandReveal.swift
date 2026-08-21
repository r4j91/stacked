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
  /// Conteúdo interno mudou de altura (submenu) — remede sem reabrir de 0.
  let sizeRevision: Int
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
    sizeRevision: Int = 0,
    panelFill: Color? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.expanded = expanded
    self.reduceMotion = reduceMotion
    self.layoutPass = layoutPass
    self.contentRevision = contentRevision
    self.stabilizeSelfSizingParent = stabilizeSelfSizingParent
    self.snapOpen = snapOpen
    self.sizeRevision = sizeRevision
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
    // Prefere bounds reais; senão lastWidth / estimativa de tela (permite animar no cold open).
    let width = uiView.resolvedMeasureWidth(fallback: context.coordinator.lastWidth)
    if uiView.bounds.width > 1 || (uiView.superview?.bounds.width ?? 0) > 1 {
      context.coordinator.lastWidth = width
    }
    let hosting = context.coordinator.hosting(in: uiView)

    let revisionChanged = contentRevision != context.coordinator.lastContentRevision
    let sizeChanged = sizeRevision != context.coordinator.lastSizeRevision
    let openingOrOpen = expanded || context.coordinator.wasExpanded
    if openingOrOpen, revisionChanged || sizeChanged || expanded != context.coordinator.wasExpanded || !context.coordinator.hasPushedContent {
      context.coordinator.updateContent(AnyView(content), hosting: hosting)
      context.coordinator.lastContentRevision = contentRevision
      context.coordinator.lastSizeRevision = sizeRevision
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
      contentRevision: contentRevision,
      stabilizeSelfSizingParent: stabilizeSelfSizingParent,
      snapOpen: snapOpen,
      sizeRevision: sizeRevision
    )
  }

  final class Coordinator {
    weak var container: SubtaskExpandContainerView?
    private var host: UIHostingController<AnyView>?
    var lastWidth: CGFloat = 0
    var wasExpanded = false
    var lastContentRevision: Int = .min
    var lastSizeRevision: Int = .min
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
      // topLeading: listas longas com título largo (ex.: "…Cartões / Parcela") —
      // sizeThatFits pode medir alto e o hosting centralizava = vão sob o pai.
      // Sem fixedSize (quebrava a animação de abertura).
      hosting.rootView = AnyView(
        content.frame(maxWidth: .infinity, alignment: .topLeading)
      )
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
  private var lastContentRevision: Int = .min
  private var lastSizeRevision: Int = .min
  private var isAnimating = false
  /// Remasure async precisa saber se o open usa pin (stabilize).
  private var stabilizeSelfSizingParent = false
  /// Altura antes do remasure de meta — detecta encolhe stale.
  private var contentRemeasureBaseline: CGFloat = 0
  /// Cold open com width 0: preservar animação no remasure do 1º layout.
  private var pendingAnimatedExpand = false
  /// UIKit list: `apply()` da cell pode reconfigurar por outro motivo (qualquer
  /// refresh de snapshot) enquanto o grow/collapse já está em voo. Sem isto, esse
  /// bump de layoutPass/contentRevision caía direto no `expandWithPinnedParent`
  /// não animado no meio do `UIView.animate` em curso — snap abrupto de altura +
  /// re-pin do scroll, visto só na lista UIKit (a SwiftUI List não tem esse
  /// segundo reconfigure independente). Guardado para reaplicar no fim da animação.
  private var pendingPostAnimationRemeasure = false
  /// Cold open: sizeThatFits às vezes devolve curto; verify pós-commit só cresce.
  private var openVerifyGeneration = 0

  override init(frame: CGRect) {
    super.init(frame: frame)
    clipsToBounds = true
    backgroundColor = .clear
    isUserInteractionEnabled = false
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

  override func layoutSubviews() {
    super.layoutSubviews()
    // Cold open: width chega no 1º layout — remede PRESERVANDO animação (não snap).
    guard lastExpanded == true, !isAnimating, let hosting = hostedController else { return }
    let width = resolvedMeasureWidth(fallback: 0)
    guard width > 1 else { return }
    let widthDrift = abs(width - lastAppliedWidth) > 1
    let needsInitialHeight = fullHeight <= 0 || (selfHeightConstraint?.constant ?? 0) <= 0.5
    guard widthDrift || needsInitialHeight else { return }
    let animateOpen = pendingAnimatedExpand && needsInitialHeight
    pendingAnimatedExpand = false
    lastAppliedWidth = width
    scheduleRemeasure(hosting: hosting, width: width, animated: animateOpen)
  }

  /// Largura para sizeThatFits — só medidas reais. 0 = ainda não dá pra medir.
  ///
  /// SUBSTITUIDO_LARGURA_ESTIMADA: havia um fallback `DisplayScreen.bounds.width - 40`.
  /// Na `List` do SwiftUI o painel nasce no toque com pai de largura zero, então o
  /// chute era sempre usado — e `sizeThatFits` não é medição passiva, ele diagrama o
  /// conteúdo naquela largura. O texto das subtarefas assentava na largura errada e
  /// pulava pra certa no layout seguinte. O chute também não tinha como acertar: a
  /// largura real muda com o `listRowInsets` de cada tela e com o trilho da timeline.
  /// Sem ele, `configure` cai no caminho de largura desconhecida e o `layoutSubviews`
  /// retoma a abertura com a largura real, preservando a animação.
  func resolvedMeasureWidth(fallback: CGFloat) -> CGFloat {
    if bounds.width > 1 { return bounds.width }
    if let sw = superview?.bounds.width, sw > 1 { return sw }
    return fallback > 1 ? fallback : 0
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
    contentRevision: Int = 0,
    stabilizeSelfSizingParent: Bool = false,
    snapOpen: Bool = false,
    sizeRevision: Int = 0
  ) {
    attachHostedControllerIfNeeded()
    self.stabilizeSelfSizingParent = stabilizeSelfSizingParent

    // Evita reentrada no meio do close (UIKit e SwiftUI List).
    if isAnimating, !expanded {
      return
    }

    let fitWidth = width
    let widthChanged = fitWidth > 1 && abs(fitWidth - lastAppliedWidth) > 1
    if widthChanged {
      lastAppliedWidth = fitWidth
    }

    let stateChanged = lastExpanded != expanded
    let layoutPassChanged = layoutPass != lastLayoutPass
    if layoutPassChanged {
      lastLayoutPass = layoutPass
    }
    let contentChanged = contentRevision != lastContentRevision
    if contentChanged {
      lastContentRevision = contentRevision
    }
    let sizeChanged = sizeRevision != lastSizeRevision
    if sizeChanged {
      lastSizeRevision = sizeRevision
    }

    // Reconfigure chegou no meio de uma animação em voo (mesma transição, não um
    // novo open/close) — adia em vez de aplicar via expandWithPinnedParent(animated:
    // false), que causaria o snap abrupto descrito acima do isAnimating.
    if isAnimating, !stateChanged {
      if layoutPassChanged || contentChanged || sizeChanged {
        pendingPostAnimationRemeasure = true
      }
      return
    }

    // Snap de remount: não zerar fullHeight (já sabemos a altura).
    // Conteúdo novo no reuse/snap (outra task ou lista) — altura velha = buraco preto.
    if stateChanged && expanded {
      if !snapOpen || contentChanged || fullHeight <= 0 {
        fullHeight = 0
        hostView?.transform = .identity
      }
    }

    // Width ainda 0 (cold mount sem estimativa) — espera layout; guarda flag de animação.
    if expanded, fitWidth <= 1 {
      lastExpanded = expanded
      pendingAnimatedExpand = animated && !snapOpen
      hosting.view.isUserInteractionEnabled = true
      clipView?.isUserInteractionEnabled = true
      isUserInteractionEnabled = true
      // Este é o caminho normal de abertura na List do SwiftUI — garante o passe de
      // layout que traz a largura real, senão o painel não abriria.
      setNeedsLayout()
      return
    }

    if stateChanged, expanded {
      pendingAnimatedExpand = animated && !snapOpen
    }
    if !expanded {
      pendingAnimatedExpand = false
    }

    // Só layoutPass com painel já aberto (etiqueta etc.).
    // contentRevision (done/título) NÃO remede aqui — zerar altura no toggle matava o painel.
    if layoutPassChanged, expanded, !stateChanged, !isAnimating, fitWidth > 1 {
      contentRemeasureBaseline = max(selfHeightConstraint?.constant ?? 0, fullHeight)
      lastExpanded = expanded
      scheduleContentRemeasure(hosting: hosting, width: fitWidth)
      return
    }

    if sizeChanged, expanded, !stateChanged, !isAnimating, fitWidth > 1 {
      let measured = measureHeight(hosting: hosting, width: fitWidth)
      lastExpanded = expanded
      if measured > 0 {
        fullHeight = measured
        applyVisibleHeight(
          measured,
          expanded: true,
          animated: animated && !snapOpen,
          pinParent: stabilizeSelfSizingParent
        )
        scheduleOpenHeightVerify(hosting: hosting, width: fitWidth)
      }
      return
    }

    if !isAnimating {
      let needsMeasure =
        widthChanged || fullHeight <= 0 || (stateChanged && expanded) || layoutPassChanged
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
    // Colapsado: altura 0 ainda com hit-test ligado atrapalhava pan da List (Dinheiro).
    isUserInteractionEnabled = interactive || (selfHeightConstraint?.constant ?? 0) > 0.5

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

    // Mesma animação em UIKit e SwiftUI List:
    // fechar = clip encolhe (conteúdo some pra cima); abrir = grow easeOut 0.22s.
    // O pin de contentOffset só age quando há UICollectionViewCell (UIKit);
    // em List o pin é no-op, mas a curva/visual do painel fica igual.
    if !expanded {
      collapseWithVisualClip(
        animated: shouldAnimate,
        reanchorParent: stabilizeSelfSizingParent
      )
      return
    }

    pendingAnimatedExpand = false
    expandWithPinnedParent(height: target, animated: shouldAnimate)
  }

  /// Reaplica, sem animar, um bump de layoutPass/contentRevision que chegou
  /// enquanto o grow estava em voo e foi adiado (ver guard em `configure`).
  private func consumePendingPostAnimationRemeasure() {
    guard pendingPostAnimationRemeasure else { return }
    pendingPostAnimationRemeasure = false
    guard lastExpanded == true, let hosting = hostedController, lastAppliedWidth > 1 else { return }
    contentRemeasureBaseline = max(selfHeightConstraint?.constant ?? 0, fullHeight)
    scheduleContentRemeasure(hosting: hosting, width: lastAppliedWidth)
    scheduleOpenHeightVerify(hosting: hosting, width: lastAppliedWidth)
  }

  /// Pós-open: remede após settle — só cresce se sizeThatFits cold ficou curto.
  private func scheduleOpenHeightVerifyAfterCommit() {
    guard let hosting = hostedController else { return }
    let width = resolvedMeasureWidth(fallback: lastAppliedWidth)
    guard width > 1 else { return }
    scheduleOpenHeightVerify(hosting: hosting, width: width)
  }

  /// Dois turns (igual content remasure): SwiftUI pode assentar mais alto depois.
  private func scheduleOpenHeightVerify(
    hosting: UIHostingController<AnyView>,
    width: CGFloat,
    attempt: Int = 0,
    generation: Int? = nil
  ) {
    let gen = generation ?? openVerifyGeneration
    DispatchQueue.main.async { [weak self] in
      DispatchQueue.main.async { [weak self] in
        self?.verifyOpenHeight(
          hosting: hosting,
          width: width,
          attempt: attempt,
          generation: gen
        )
      }
    }
  }

  private func verifyOpenHeight(
    hosting: UIHostingController<AnyView>,
    width: CGFloat,
    attempt: Int,
    generation: Int
  ) {
    guard generation == openVerifyGeneration, lastExpanded == true else { return }
    if isAnimating {
      if attempt < 6 {
        scheduleOpenHeightVerify(
          hosting: hosting,
          width: width,
          attempt: attempt + 1,
          generation: generation
        )
      }
      return
    }

    hosting.view.invalidateIntrinsicContentSize()
    hosting.view.setNeedsLayout()
    hosting.view.layoutIfNeeded()
    let measured = measureHeight(hosting: hosting, width: width)
    if measured <= 0 {
      if attempt < 4 {
        scheduleOpenHeightVerify(
          hosting: hosting,
          width: width,
          attempt: attempt + 1,
          generation: generation
        )
      }
      return
    }

    let current = max(selfHeightConstraint?.constant ?? 0, fullHeight)
    if measured > current + 0.5 {
      fullHeight = measured
      applyVisibleHeight(
        measured,
        expanded: true,
        animated: false,
        pinParent: stabilizeSelfSizingParent
      )
      if let collectionView = enclosingCollectionView() {
        collectionView.performBatchUpdates(nil)
        collectionView.layoutIfNeeded()
      }
      if attempt < 3 {
        scheduleOpenHeightVerify(
          hosting: hosting,
          width: width,
          attempt: attempt + 1,
          generation: generation
        )
      }
      return
    }

    // Mesma altura: SwiftUI ainda pode crescer — tenta de novo.
    if attempt < 3 {
      scheduleOpenHeightVerify(
        hosting: hosting,
        width: width,
        attempt: attempt + 1,
        generation: generation
      )
    }
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
    // Remeasure no open: mesma curva do configure (UIKit e SwiftUI List).
    if (selfHeightConstraint?.constant ?? 0) <= 0.5, !updateHeightCache {
      expandWithPinnedParent(height: measured, animated: animated)
      return
    }
    applyVisibleHeight(
      measured,
      expanded: true,
      animated: animated,
      pinParent: stabilizeSelfSizingParent
    )
    if let collectionView = enclosingCollectionView() {
      collectionView.performBatchUpdates(nil)
      collectionView.layoutIfNeeded()
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
      self?.consumePendingPostAnimationRemeasure()
    }
  }

  /// Cresce a cell reancorando o contentOffset — pai fica parado na abertura.
  private func expandWithPinnedParent(height: CGFloat, animated: Bool) {
    openVerifyGeneration &+= 1
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
        if let collectionView {
          collectionView.performBatchUpdates(nil)
          collectionView.layoutIfNeeded()
        }
        pin()
      }
      scheduleOpenHeightVerifyAfterCommit()
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
        // Só após a animação — batch no meio do grow quebrava o ease.
        pin()
        self?.isAnimating = false
        self?.consumePendingPostAnimationRemeasure()
        self?.scheduleOpenHeightVerifyAfterCommit()
      }
    )
  }

  /// Visual = altura do clip full→0 (conteúdo parado, some por baixo).
  /// Lista = altura travada até o fim; aí zera (opcionalmente reancora o pai).
  private func collapseWithVisualClip(animated: Bool, reanchorParent: Bool = true) {
    openVerifyGeneration &+= 1
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
        // Fechado — nada pra remedir; só limpa a flag pra não vazar pro próximo open.
        self?.pendingPostAnimationRemeasure = false
      }
    )
  }

  /// Zera altura reportada sem reancorar contentOffset (evita deslize no fechar UIKit).
  private func snapReportedHeightToZero() {
    openVerifyGeneration &+= 1
    let collectionView = enclosingCollectionView()

    selfHeightConstraint?.constant = 0
    clipHeightConstraint?.constant = 0
    hostHeightConstraint?.constant = 0
    fullHeight = 0
    isUserInteractionEnabled = false
    clipView?.isUserInteractionEnabled = false
    hostView?.isUserInteractionEnabled = false
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
    }
    CATransaction.commit()

    hostView?.transform = .identity
  }

  private func snapReportedHeightToZeroAndPin() {
    openVerifyGeneration &+= 1
    let collectionView = enclosingCollectionView()
    let anchorVisibleY: CGFloat? = {
      guard let cell = enclosingCell(), let collectionView else { return nil }
      return cell.convert(CGPoint.zero, to: collectionView).y - collectionView.contentOffset.y
    }()

    selfHeightConstraint?.constant = 0
    clipHeightConstraint?.constant = 0
    hostHeightConstraint?.constant = 0
    fullHeight = 0
    isUserInteractionEnabled = false
    clipView?.isUserInteractionEnabled = false
    hostView?.isUserInteractionEnabled = false
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

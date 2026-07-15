import SwiftUI
import UIKit

/// Revela subtarefas com altura animada via UIKit — paridade Flutter `SizeTransition`, estável dentro de `List`.
struct SubtaskExpandReveal<Content: View>: UIViewRepresentable {
  let expanded: Bool
  let reduceMotion: Bool
  /// Incrementar após conteúdo pesado ou restore — força remedição de altura.
  let layoutPass: Int
  /// Muda só com dados das subtarefas — scroll idle não reescreve o hosting tree.
  let contentRevision: Int
  let content: Content

  init(
    expanded: Bool,
    reduceMotion: Bool,
    layoutPass: Int = 0,
    contentRevision: Int = 0,
    @ViewBuilder content: () -> Content
  ) {
    self.expanded = expanded
    self.reduceMotion = reduceMotion
    self.layoutPass = layoutPass
    self.contentRevision = contentRevision
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
    // PERF: `rootView =` a cada updateUIView (List scroll) re-layouta o hosting e stutter.
    // Só empurra tree quando expandindo/colapsando ou quando o conteúdo das subtarefas mudou.
    if openingOrOpen, revisionChanged || expanded != context.coordinator.wasExpanded || !context.coordinator.hasPushedContent {
      context.coordinator.updateContent(AnyView(content), hosting: hosting)
      context.coordinator.lastContentRevision = contentRevision
      context.coordinator.hasPushedContent = true
    }
    context.coordinator.wasExpanded = expanded

    uiView.configure(
      hosting: hosting,
      width: width,
      expanded: expanded,
      animated: !reduceMotion,
      layoutPass: layoutPass
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
  private weak var hostView: UIView?
  private var hostHeightConstraint: NSLayoutConstraint?
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

  func install(host: UIHostingController<AnyView>) {
    guard hostView == nil else { return }
    hostView = host.view
    addSubview(host.view)
    let height = host.view.heightAnchor.constraint(equalToConstant: 0)
    hostHeightConstraint = height
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: topAnchor),
      host.view.leadingAnchor.constraint(equalTo: leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: trailingAnchor),
      height,
    ])
  }

  func configure(
    hosting: UIHostingController<AnyView>,
    width: CGFloat,
    expanded: Bool,
    animated: Bool,
    layoutPass: Int = 0
  ) {
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

    // Só zera altura ao abrir — remedir com layoutPass não deve colapsar a célula (evita jump no scroll).
    if stateChanged && expanded {
      fullHeight = 0
    }

    // Mede ao abrir, quando a largura muda, ou após conteúdo pesado/restauração.
    // Nunca remedir durante animação — invalida List no meio do gesto.
    if !isAnimating {
      let needsMeasure = widthChanged || fullHeight <= 0 || (stateChanged && expanded) || layoutPassChanged
      if needsMeasure {
        let measured = measureHeight(hosting: hosting, width: fitWidth)
        if measured > 0 { fullHeight = measured }
      }
    }

    hostHeightConstraint?.constant = fullHeight
    hosting.view.isUserInteractionEnabled = expanded

    let target = expanded ? fullHeight : 0
    lastExpanded = expanded

    let current = selfHeightConstraint?.constant ?? 0
    if expanded && fullHeight <= 0 && fitWidth > 1 {
      scheduleRemeasure(hosting: hosting, width: fitWidth, animated: animated)
      return
    }

    guard stateChanged || layoutPassChanged || abs(current - target) > 0.5 else { return }

    let shouldAnimate = animated && stateChanged && !UIAccessibility.isReduceMotionEnabled
    applyVisibleHeight(target, expanded: expanded, animated: shouldAnimate)
  }

  private func scheduleRemeasure(
    hosting: UIHostingController<AnyView>,
    width: CGFloat,
    animated: Bool
  ) {
    DispatchQueue.main.async { [weak self] in
      guard let self, self.lastExpanded == true else { return }
      self.remeasureExpanded(hosting: hosting, width: width, animated: animated)
    }
  }

  private func remeasureExpanded(
    hosting: UIHostingController<AnyView>,
    width: CGFloat,
    animated: Bool
  ) {
    guard !isAnimating else { return }
    let measured = measureHeight(hosting: hosting, width: width)
    guard measured > 0 else { return }
    guard abs(measured - fullHeight) > 0.5 else { return }
    fullHeight = measured
    hostHeightConstraint?.constant = measured
    applyVisibleHeight(measured, expanded: true, animated: animated)
  }

  private func measureHeight(hosting: UIHostingController<AnyView>, width: CGFloat) -> CGFloat {
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

  private func applyVisibleHeight(_ height: CGFloat, expanded: Bool, animated: Bool) {
    let applyLayout = { [weak self] in
      guard let self else { return }
      self.selfHeightConstraint?.constant = height
      self.invalidateIntrinsicContentSize()
    }

    guard animated else {
      applyLayout()
      return
    }

    isAnimating = true
    let duration: TimeInterval = 0.22
    let options: UIView.AnimationOptions = expanded
      ? [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState, .layoutSubviews]
      : [.curveEaseIn, .allowUserInteraction, .beginFromCurrentState, .layoutSubviews]

    UIView.animate(withDuration: duration, delay: 0, options: options, animations: applyLayout) { [weak self] _ in
      self?.isAnimating = false
    }
  }
}

// MARK: - Expand simples (UIHostingConfiguration / UIKit list)

private struct SubtaskRevealHeightKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

/// Altura clipada + mesmos curves do SubtaskExpandReveal (0.22s) — sem UIHosting aninhado.
struct SimpleSubtaskExpand<Content: View>: View {
  let expanded: Bool
  let reduceMotion: Bool
  let content: Content

  @State private var measuredHeight: CGFloat = 0

  init(
    expanded: Bool,
    reduceMotion: Bool,
    @ViewBuilder content: () -> Content
  ) {
    self.expanded = expanded
    self.reduceMotion = reduceMotion
    self.content = content()
  }

  var body: some View {
    ZStack(alignment: .top) {
      // Camada só para medir altura real (fora do clip).
      content
        .fixedSize(horizontal: false, vertical: true)
        .background {
          GeometryReader { geo in
            Color.clear.preference(key: SubtaskRevealHeightKey.self, value: geo.size.height)
          }
        }
        .hidden()
        .accessibilityHidden(true)

      content
        .frame(height: expanded ? max(measuredHeight, 0) : 0, alignment: .top)
        .clipped()
        .opacity(expanded ? 1 : 0)
        .allowsHitTesting(expanded)
    }
    .frame(height: expanded ? max(measuredHeight, 0) : 0, alignment: .top)
    .clipped()
    .onPreferenceChange(SubtaskRevealHeightKey.self) { measuredHeight = $0 }
    .animation(expandAnimation, value: expanded)
  }

  private var expandAnimation: Animation? {
    if reduceMotion { return nil }
    return expanded ? AppMotion.subtaskExpandSpring : AppMotion.subtaskCollapseSpring
  }
}

private struct UIKitHostedTaskRowKey: EnvironmentKey {
  static let defaultValue = false
}

extension EnvironmentValues {
  var uikitHostedTaskRow: Bool {
    get { self[UIKitHostedTaskRowKey.self] }
    set { self[UIKitHostedTaskRowKey.self] = newValue }
  }
}

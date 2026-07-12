import SwiftUI
import UIKit

/// Revela subtarefas com altura animada via UIKit — paridade Flutter `SizeTransition`, estável dentro de `List`.
struct SubtaskExpandReveal<Content: View>: UIViewRepresentable {
  let expanded: Bool
  let reduceMotion: Bool
  /// Incrementar após conteúdo pesado ou restore — força remedição de altura.
  let layoutPass: Int
  let content: Content

  init(
    expanded: Bool,
    reduceMotion: Bool,
    layoutPass: Int = 0,
    @ViewBuilder content: () -> Content
  ) {
    self.expanded = expanded
    self.reduceMotion = reduceMotion
    self.layoutPass = layoutPass
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
    context.coordinator.updateContent(AnyView(content), hosting: hosting)
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

    if stateChanged && expanded {
      fullHeight = 0
    } else if layoutPassChanged && expanded {
      fullHeight = 0
    }

    // Mede ao abrir, quando a largura muda, ou após conteúdo pesado/restauração.
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
      let measured = self.measureHeight(hosting: hosting, width: width)
      guard measured > 0 else { return }
      self.fullHeight = measured
      self.hostHeightConstraint?.constant = measured
      self.applyVisibleHeight(measured, expanded: true, animated: false)
    }
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

import SwiftUI
import UIKit

/// Ancora conteúdo ao topo do teclado via `keyboardLayoutGuide` — evita comprimir o layout SwiftUI.
struct QuickAddKeyboardAnchorHost: UIViewControllerRepresentable {
  let backdropColor: Color
  let gapAboveKeyboard: CGFloat
  let horizontalInset: CGFloat
  let content: AnyView

  func makeUIViewController(context: Context) -> Controller {
    let controller = Controller(
      backdropColor: UIColor(backdropColor),
      gap: gapAboveKeyboard,
      horizontalInset: horizontalInset
    )
    controller.setContent(content)
    return controller
  }

  func updateUIViewController(_ controller: Controller, context: Context) {
    controller.backdropColor = UIColor(backdropColor)
    controller.gap = gapAboveKeyboard
    controller.horizontalInset = horizontalInset
    controller.setContent(content)
    controller.view.setNeedsUpdateConstraints()
    controller.view.setNeedsLayout()
  }

  final class Controller: UIViewController {
    var backdropColor: UIColor
    var gap: CGFloat
    var horizontalInset: CGFloat
    private var hosting: UIHostingController<AnyView>?
    private var bottomConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var keyboardZoneFill: UIView?

    init(backdropColor: UIColor, gap: CGFloat, horizontalInset: CGFloat) {
      self.backdropColor = backdropColor
      self.gap = gap
      self.horizontalInset = horizontalInset
      super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func loadView() {
      view = PassThroughView()
    }

    override func viewDidLoad() {
      super.viewDidLoad()
      view.backgroundColor = .clear
      installKeyboardZoneFillIfNeeded()
    }

    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      keyboardZoneFill?.backgroundColor = backdropColor
    }

    func setContent(_ content: AnyView) {
      if let hosting {
        hosting.rootView = content
        return
      }

      let host = UIHostingController(rootView: content)
      host.safeAreaRegions = []
      host.view.backgroundColor = .clear
      host.view.translatesAutoresizingMaskIntoConstraints = false

      addChild(host)
      view.addSubview(host.view)

      leadingConstraint = host.view.leadingAnchor.constraint(
        equalTo: view.leadingAnchor,
        constant: horizontalInset
      )
      trailingConstraint = host.view.trailingAnchor.constraint(
        equalTo: view.trailingAnchor,
        constant: -horizontalInset
      )
      bottomConstraint = host.view.bottomAnchor.constraint(
        equalTo: view.keyboardLayoutGuide.topAnchor,
        constant: -gap
      )

      NSLayoutConstraint.activate([
        leadingConstraint!,
        trailingConstraint!,
        bottomConstraint!,
      ])

      host.didMove(toParent: self)
      hosting = host
    }

    override func updateViewConstraints() {
      bottomConstraint?.constant = -gap
      leadingConstraint?.constant = horizontalInset
      trailingConstraint?.constant = -horizontalInset
      keyboardZoneFill?.backgroundColor = backdropColor
      super.updateViewConstraints()
    }

    /// Preenche a faixa do teclado (incl. cantos arredondados) — evita wedges pretos nas laterais.
    private func installKeyboardZoneFillIfNeeded() {
      guard keyboardZoneFill == nil else { return }

      let fill = UIView()
      fill.isUserInteractionEnabled = false
      fill.backgroundColor = backdropColor
      fill.translatesAutoresizingMaskIntoConstraints = false
      view.insertSubview(fill, at: 0)

      NSLayoutConstraint.activate([
        fill.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        fill.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        fill.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        fill.topAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -18),
      ])

      keyboardZoneFill = fill
    }
  }
}

/// Deixa toques passarem exceto nos filhos (cápsula Quick Add).
private final class PassThroughView: UIView {
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let hit = super.hitTest(point, with: event)
    return hit === self ? nil : hit
  }
}

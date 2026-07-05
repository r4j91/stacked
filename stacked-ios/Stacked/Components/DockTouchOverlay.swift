import SwiftUI
import UIKit

/// Botões UIKit transparentes sobre o dock SwiftUI — garante toques com List/UITableView.
struct DockTouchOverlay: UIViewRepresentable {
  let safeBottom: CGFloat
  @AppStorage(NavBarStyleStorage.key) private var navBarStyleRaw = NavBarStyleStorage.defaultRawValue

  private var navBarStyle: NavBarStyle {
    NavBarStyleStorage.style(from: navBarStyleRaw)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeUIView(context: Context) -> DockTouchUIView {
    let view = DockTouchUIView()
    view.coordinator = context.coordinator
    return view
  }

  func updateUIView(_ uiView: DockTouchUIView, context: Context) {
    let chrome = MobileChromeController.shared
    uiView.coordinator = context.coordinator
    uiView.applyLayout(
      safeBottom: safeBottom,
      navStyle: navBarStyle,
      islandExpanded: chrome.islandNavExpanded
    )
    uiView.syncSelection(
      selectedTab: chrome.selectedTab,
      fabOpen: chrome.fabOpen,
      navStyle: navBarStyle,
      islandExpanded: chrome.islandNavExpanded
    )
    uiView.bindActions()
  }

  final class Coordinator: NSObject {
    @MainActor
    @objc func tabTouchDown(_ sender: UIButton) {
      guard let tab = NavTab(rawValue: sender.tag) else { return }
      MobileChromeController.shared.setTabPressed(tab)
    }

    @MainActor
    @objc func tabTouchEnded(_ sender: UIButton) {
      MobileChromeController.shared.setTabPressed(nil)
    }

    @MainActor
    @objc func tabTapped(_ sender: UIButton) {
      guard let tab = NavTab(rawValue: sender.tag) else { return }
      MobileChromeController.shared.selectTab(tab)
    }

    @MainActor
    @objc func fabTapped() {
      MobileChromeController.shared.toggleFabMenu()
    }

    // ISLAND_FASE3 — toque na ilha compacta expande (não troca aba).
    @MainActor
    @objc func islandCompactTapped() {
      MobileChromeController.shared.expandIslandNav()
    }
  }
}

final class DockTouchUIView: UIView {
  weak var coordinator: DockTouchOverlay.Coordinator?

  private let tabStack = UIStackView()
  private var tabButtons: [UIButton] = []
  private let fabButton = UIButton(type: .custom)
  // ISLAND_FASE3
  private let islandCompactButton = UIButton(type: .custom)
  private var layoutConstraints: [NSLayoutConstraint] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = true
    backgroundColor = .clear

    tabStack.axis = .horizontal
    tabStack.distribution = .fillEqually
    tabStack.spacing = 0
    tabStack.translatesAutoresizingMaskIntoConstraints = false
    tabStack.isUserInteractionEnabled = true
    addSubview(tabStack)

    for index in 0..<NavTab.allCases.count {
      let button = UIButton(type: .custom)
      button.tag = index
      button.backgroundColor = .clear
      button.isUserInteractionEnabled = true
      button.accessibilityLabel = NavTab(rawValue: index)?.label
      tabButtons.append(button)
      tabStack.addArrangedSubview(button)
    }

    islandCompactButton.backgroundColor = .clear
    islandCompactButton.translatesAutoresizingMaskIntoConstraints = false
    islandCompactButton.isUserInteractionEnabled = true
    islandCompactButton.accessibilityLabel = "Expandir navegação"
    islandCompactButton.isHidden = true
    addSubview(islandCompactButton)

    fabButton.backgroundColor = .clear
    fabButton.translatesAutoresizingMaskIntoConstraints = false
    fabButton.isUserInteractionEnabled = true
    fabButton.accessibilityLabel = "Criar novo"
    addSubview(fabButton)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let hit = super.hitTest(point, with: event)
    if hit === self { return nil }
    return hit
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    bringSubviewToFront(fabButton)
    bringSubviewToFront(islandCompactButton)
  }

  func bindActions() {
    guard let coordinator else { return }
    for button in tabButtons {
      button.removeTarget(nil, action: nil, for: .allEvents)
      button.addTarget(coordinator, action: #selector(DockTouchOverlay.Coordinator.tabTouchDown(_:)), for: .touchDown)
      button.addTarget(
        coordinator,
        action: #selector(DockTouchOverlay.Coordinator.tabTouchEnded(_:)),
        for: [.touchUpInside, .touchUpOutside, .touchCancel]
      )
      button.addTarget(coordinator, action: #selector(DockTouchOverlay.Coordinator.tabTapped(_:)), for: .touchUpInside)
    }
    fabButton.removeTarget(nil, action: nil, for: .allEvents)
    fabButton.addTarget(coordinator, action: #selector(DockTouchOverlay.Coordinator.fabTapped), for: .touchUpInside)

    islandCompactButton.removeTarget(nil, action: nil, for: .allEvents)
    islandCompactButton.addTarget(
      coordinator,
      action: #selector(DockTouchOverlay.Coordinator.islandCompactTapped),
      for: .touchUpInside
    )
  }

  func applyLayout(safeBottom: CGFloat, navStyle: NavBarStyle, islandExpanded: Bool) {
    let pillMarginBottom = ChromeLayout.pillMarginBottom(safeBottom: safeBottom)
    let fabMarginBottom = ChromeLayout.fabMarginBottom(safeBottom: safeBottom)
    let side = AppLayout.fabSideMargin
    let inner = ChromeLayout.pillInnerPadding
    let pillHeight = navStyle == .island ? IslandNavMetrics.pillHeight + inner * 2 : ChromeLayout.pillVisualHeight
    let fabSize = AppLayout.fabSize
    let trackWidth = bounds.width > 0 ? bounds.width - side * 2 - inner * 2 : 0
    let islandCompactWidth = trackWidth * IslandNavMetrics.compactWidthRatio
    let islandLeading = side + inner + max(0, (trackWidth - islandCompactWidth) / 2)

    NSLayoutConstraint.deactivate(layoutConstraints)
    layoutConstraints = [
      fabButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -side),
      fabButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -fabMarginBottom),
      fabButton.widthAnchor.constraint(equalToConstant: fabSize),
      fabButton.heightAnchor.constraint(equalToConstant: fabSize),
    ]

    let useIslandCompact = navStyle == .island && !islandExpanded
    let useTabStack = navStyle != .island || islandExpanded

    tabStack.isHidden = !useTabStack
    islandCompactButton.isHidden = !useIslandCompact

    if useTabStack {
      layoutConstraints += [
        tabStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: side + inner),
        tabStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(side + inner)),
        tabStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -pillMarginBottom),
        tabStack.heightAnchor.constraint(equalToConstant: pillHeight),
      ]
    }

    if useIslandCompact {
      layoutConstraints += [
        islandCompactButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: islandLeading),
        islandCompactButton.widthAnchor.constraint(equalToConstant: max(islandCompactWidth, 44)),
        islandCompactButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -pillMarginBottom),
        islandCompactButton.heightAnchor.constraint(equalToConstant: max(pillHeight, 44)),
      ]
    }

    NSLayoutConstraint.activate(layoutConstraints)
  }

  func syncSelection(
    selectedTab: NavTab,
    fabOpen: Bool,
    navStyle: NavBarStyle,
    islandExpanded: Bool
  ) {
    for (i, button) in tabButtons.enumerated() {
      button.accessibilityTraits = i == selectedTab.rawValue ? [.button, .selected] : .button
    }
    fabButton.accessibilityLabel = fabOpen ? "Fechar menu de ações" : "Criar novo"
    islandCompactButton.accessibilityLabel = islandExpanded
      ? "Navegação expandida"
      : "Expandir navegação — \(selectedTab.label)"
  }
}

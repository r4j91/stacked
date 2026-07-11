import SwiftUI
import UIKit

/// Botões UIKit transparentes sobre o dock SwiftUI — garante toques com List/UITableView.
struct DockTouchOverlay: UIViewRepresentable {
  let safeBottom: CGFloat
  @AppStorage(NavBarStyleStorage.key) private var navBarStyleRaw = NavBarStyleStorage.defaultRawValue
  @AppStorage(FabIntegratedInIslandStorage.key) private var fabIntegratedInIsland = false

  private var navBarStyle: NavBarStyle {
    NavBarStyleStorage.style(from: navBarStyleRaw)
  }

  private var usesIntegratedIslandFab: Bool {
    navBarStyle == .island && fabIntegratedInIsland
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
      islandExpanded: chrome.islandNavExpanded,
      selectedTab: chrome.selectedTab,
      fabIntegratedInIsland: usesIntegratedIslandFab
    )
    uiView.syncSelection(
      selectedTab: chrome.selectedTab,
      fabOpen: chrome.fabOpen,
      navStyle: navBarStyle,
      islandExpanded: chrome.islandNavExpanded,
      fabIntegratedInIsland: usesIntegratedIslandFab
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

    @MainActor
    @objc func islandFabTapped() {
      MobileChromeController.shared.toggleFabMenu()
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
  // FAB_INTEGRADO_ETAPA2
  private let islandFabButton = UIButton(type: .custom)
  private var layoutConstraints: [NSLayoutConstraint] = []
  private var tabWidthConstraints: [NSLayoutConstraint] = []
  private var layoutSignature: Int?

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

    islandFabButton.backgroundColor = .clear
    islandFabButton.translatesAutoresizingMaskIntoConstraints = false
    islandFabButton.isUserInteractionEnabled = true
    islandFabButton.accessibilityLabel = "Criar novo"
    islandFabButton.isHidden = true
    addSubview(islandFabButton)

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
    bringSubviewToFront(islandFabButton)
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

    islandFabButton.removeTarget(nil, action: nil, for: .allEvents)
    islandFabButton.addTarget(
      coordinator,
      action: #selector(DockTouchOverlay.Coordinator.islandFabTapped),
      for: .touchUpInside
    )
  }

  func applyLayout(
    safeBottom: CGFloat,
    navStyle: NavBarStyle,
    islandExpanded: Bool,
    selectedTab: NavTab,
    fabIntegratedInIsland: Bool
  ) {
    let pillMarginBottom = ChromeLayout.pillMarginBottom(safeBottom: safeBottom)
    let fabMarginBottom = ChromeLayout.fabMarginBottom(safeBottom: safeBottom)
    let side = AppLayout.fabSideMargin
    let inner = ChromeLayout.pillInnerPadding
    let pillHeight = navStyle == .island ? IslandNavMetrics.pillHeight + inner * 2 : ChromeLayout.pillVisualHeight
    let fabSize = AppLayout.fabSize
    let screenWidth = bounds.width
    let trackWidth = IslandNavLayout.trackWidth(
      screenWidth: screenWidth,
      sideMargin: side,
      innerPadding: inner
    )
    let pillWidth = IslandNavLayout.pillWidth(
      trackWidth: trackWidth,
      expanded: islandExpanded,
      fabIntegrated: fabIntegratedInIsland && navStyle == .island
    )
    let pillLeading = IslandNavLayout.pillLeading(
      screenWidth: screenWidth,
      sideMargin: side,
      innerPadding: inner,
      trackWidth: trackWidth,
      pillWidth: pillWidth
    )
    let fabIntegrated = fabIntegratedInIsland && navStyle == .island
    let fabSegmentLeading = pillLeading + pillWidth - IslandNavLayout.fabSegmentWidth

    var hasher = Hasher()
    hasher.combine(navStyle)
    hasher.combine(islandExpanded)
    hasher.combine(fabIntegrated)
    hasher.combine(bounds.width)
    hasher.combine(bounds.height)
    hasher.combine(safeBottom)
    let signature = hasher.finalize()
    if signature == layoutSignature {
      return
    }
    layoutSignature = signature

    NSLayoutConstraint.deactivate(layoutConstraints)
    layoutConstraints = []

    let hideFloatingFab = fabIntegrated
    fabButton.isHidden = hideFloatingFab
    islandFabButton.isHidden = !fabIntegrated

    if !hideFloatingFab {
      layoutConstraints += [
        fabButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -side),
        fabButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -fabMarginBottom),
        fabButton.widthAnchor.constraint(equalToConstant: fabSize),
        fabButton.heightAnchor.constraint(equalToConstant: fabSize),
      ]
    }

    let useIslandCompact = navStyle == .island && !islandExpanded
    let useTabStack = navStyle != .island || islandExpanded
    let fabReserve = fabIntegrated ? IslandNavLayout.fabSegmentTotalWidth(integrated: true) : 0

    tabStack.isHidden = !useTabStack
    islandCompactButton.isHidden = !useIslandCompact

    if useTabStack {
      layoutConstraints += [
        tabStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: side + inner),
        tabStack.trailingAnchor.constraint(
          equalTo: trailingAnchor,
          constant: -(side + inner + fabReserve)
        ),
        tabStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -pillMarginBottom),
        tabStack.heightAnchor.constraint(equalToConstant: pillHeight),
      ]
      applyTabTouchWidths(
        trackWidth: max(0, trackWidth - fabReserve),
        navStyle: navStyle,
        selectedTab: selectedTab
      )
    } else {
      NSLayoutConstraint.deactivate(tabWidthConstraints)
      tabWidthConstraints.removeAll()
    }

    if useIslandCompact {
      let compactTapWidth = max(pillWidth - fabReserve, 44)
      layoutConstraints += [
        islandCompactButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pillLeading),
        islandCompactButton.widthAnchor.constraint(equalToConstant: compactTapWidth),
        islandCompactButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -pillMarginBottom),
        islandCompactButton.heightAnchor.constraint(equalToConstant: max(pillHeight, 44)),
      ]
    }

    if fabIntegrated {
      layoutConstraints += [
        islandFabButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: fabSegmentLeading),
        islandFabButton.widthAnchor.constraint(equalToConstant: IslandNavLayout.fabSegmentWidth),
        islandFabButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -pillMarginBottom),
        islandFabButton.heightAnchor.constraint(equalToConstant: max(pillHeight, 44)),
      ]
    }

    NSLayoutConstraint.activate(layoutConstraints)
  }

  // FAB_INTEGRADO_ETAPA2 — assinatura antiga substituída por fabIntegratedInIsland.
  // func applyLayout(safeBottom: CGFloat, navStyle: NavBarStyle, islandExpanded: Bool, selectedTab: NavTab) {

  /// Navbar expandida usa slots assimétricos — fillEqually deslocava o toque uma aba à frente.
  private func applyTabTouchWidths(trackWidth: CGFloat, navStyle: NavBarStyle, selectedTab: NavTab) {
    NSLayoutConstraint.deactivate(tabWidthConstraints)
    tabWidthConstraints.removeAll()

    let widths: [CGFloat]
    if navStyle == .expanded, trackWidth > 0 {
      tabStack.distribution = .fill
      widths = ExpandedNavLayout.orderedSlotWidths(totalWidth: trackWidth, selected: selectedTab)
    } else {
      tabStack.distribution = .fillEqually
      let equal = trackWidth > 0 ? trackWidth / CGFloat(NavTab.allCases.count) : 0
      widths = Array(repeating: equal, count: NavTab.allCases.count)
    }

    for (button, width) in zip(tabButtons, widths) {
      guard width > 0 else { continue }
      let constraint = button.widthAnchor.constraint(equalToConstant: width)
      tabWidthConstraints.append(constraint)
    }
    NSLayoutConstraint.activate(tabWidthConstraints)
  }

  func syncSelection(
    selectedTab: NavTab,
    fabOpen: Bool,
    navStyle: NavBarStyle,
    islandExpanded: Bool,
    fabIntegratedInIsland: Bool
  ) {
    for (i, button) in tabButtons.enumerated() {
      button.accessibilityTraits = i == selectedTab.rawValue ? [.button, .selected] : .button
    }
    fabButton.accessibilityLabel = fabOpen ? "Fechar menu de ações" : "Criar novo"
    islandFabButton.accessibilityLabel = fabOpen ? "Fechar menu de ações" : "Criar novo"
    islandCompactButton.accessibilityLabel = islandExpanded
      ? "Navegação expandida"
      : "Expandir navegação — \(selectedTab.label)"
    _ = fabIntegratedInIsland
  }
}

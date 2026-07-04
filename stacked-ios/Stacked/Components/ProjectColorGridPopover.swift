import SwiftUI

/// Grid de cores de projeto ancorado ao botão — usado em Novo projeto e opções.
struct ProjectColorGridPopoverOverlay: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let anchorRect: CGRect
  let selectedHex: String
  var hostBounds: CGRect = .zero
  let onSelect: (String) -> Void
  let onDismiss: () -> Void

  @State private var isPresented = false

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
  private let cardWidth: CGFloat = PopoverStyle.menuWidth
  private let gridPadding: CGFloat = 14
  private let swatchSize: CGFloat = 28
  private let rowSpacing: CGFloat = 8

  private var cardHeight: CGFloat {
    let rows = ceil(Double(PaletteColors.projectHex.count) / 6.0)
    let gridH = rows * swatchSize + max(0, rows - 1) * rowSpacing
    return gridPadding * 2 + 28 + gridH
  }

  private var localAnchor: CGRect {
    guard hostBounds.width > 1, hostBounds.height > 1 else { return anchorRect }
    return anchorRect.offsetBy(dx: -hostBounds.minX, dy: -hostBounds.minY)
  }

  private var layoutSize: CGSize {
    hostBounds.width > 1 ? hostBounds.size : ScreenMetrics.bounds.size
  }

  private var cardPosition: CGPoint {
    let screen = layoutSize
    let w = cardWidth
    let h = cardHeight
    let anchor = localAnchor

    var left = anchor.midX - w / 2
    left = min(max(12, left), screen.width - w - 12)

    // Acima da linha "Cor" — teclado fica abaixo do painel.
    var top = anchor.minY - h - 10
    if top < 56 {
      top = anchor.maxY + 10
    }
    top = min(top, screen.height - h - 12)

    return CGPoint(x: left + w / 2, y: top + h / 2)
  }

  private var scaleAnchor: UnitPoint {
    cardPosition.y < localAnchor.midY ? .bottom : .top
  }

  var body: some View {
    ZStack {
      Color.black.opacity(PopoverStyle.scrimOpacity * (isPresented ? 1 : 0))
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .animation(AppMotion.snappy(reduceMotion: reduceMotion), value: isPresented)

      card
        .position(x: cardPosition.x, y: cardPosition.y)
        .scaleEffect(isPresented ? 1 : PopoverStyle.scaleBegin, anchor: scaleAnchor)
        .opacity(isPresented ? 1 : 0)
        .animation(AppMotion.snappy(reduceMotion: reduceMotion), value: isPresented)
    }
    .onAppear {
      AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) { isPresented = true }
    }
  }

  private var card: some View {
    let c = theme.colors

    return LiquidGlass.popoverCard(navBarColor: c.navBar) {
      VStack(alignment: .leading, spacing: 10) {
        Text("Cor")
          .font(AppTypography.sectionLabel)
          .foregroundStyle(c.textSecondary)
          .padding(.horizontal, gridPadding)
          .padding(.top, gridPadding)

        LazyVGrid(columns: columns, spacing: rowSpacing) {
          ForEach(PaletteColors.projectHex, id: \.self) { hex in
            let color = AppColors.parseHex(hex)
            let selected = selectedHex == hex
            Button {
              HapticService.selection()
              onSelect(hex)
            } label: {
              Circle()
                .fill(color)
                .frame(width: swatchSize, height: swatchSize)
                .overlay {
                  if selected {
                    StackedIcons.image(.check)
                      .font(.system(size: 11, weight: .bold))
                      .foregroundStyle(AppColors.onColoredFill)
                  }
                }
                .overlay {
                  Circle()
                    .strokeBorder(Color.white.opacity(selected ? 0.45 : 0), lineWidth: 1.5)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cor \(hex)")
            .accessibilityAddTraits(selected ? .isSelected : [])
          }
        }
        .padding(.horizontal, gridPadding)
        .padding(.bottom, gridPadding)
      }
      .frame(width: cardWidth)
    }
  }

  private func dismiss() {
    onDismiss()
  }
}

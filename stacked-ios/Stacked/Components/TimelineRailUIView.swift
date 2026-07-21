import UIKit

/// Trilho + nó desenhados em UIKit (cells split Hoje/Em breve).
final class TimelineRailUIView: UIView {
  var nodeColor: UIColor = UIColor(AppColors.dateDueToday) {
    didSet { setNeedsDisplay() }
  }
  var lineColor: UIColor = UIColor(AppColors.textTertiary).withAlphaComponent(0.32) {
    didSet { setNeedsDisplay() }
  }
  var connectsUp = true {
    didSet { setNeedsDisplay() }
  }
  var connectsDown = true {
    didSet { setNeedsDisplay() }
  }
  var nodeTop: CGFloat = 14 {
    didSet { setNeedsDisplay() }
  }

  private let nodeSize: CGFloat = 10
  private let lineWidth: CGFloat = 2

  override init(frame: CGRect) {
    super.init(frame: frame)
    isOpaque = false
    backgroundColor = .clear
    contentMode = .redraw
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError() }

  override func draw(_ rect: CGRect) {
    guard let ctx = UIGraphicsGetCurrentContext() else { return }
    let midX = bounds.midX
    let nodeCenterY = nodeTop + nodeSize / 2

    ctx.setStrokeColor(lineColor.cgColor)
    ctx.setLineWidth(lineWidth)
    ctx.setLineCap(.round)

    if connectsUp {
      ctx.move(to: CGPoint(x: midX, y: 0))
      ctx.addLine(to: CGPoint(x: midX, y: max(0, nodeCenterY - nodeSize / 2)))
      ctx.strokePath()
    }
    if connectsDown {
      ctx.move(to: CGPoint(x: midX, y: min(bounds.height, nodeCenterY + nodeSize / 2)))
      ctx.addLine(to: CGPoint(x: midX, y: bounds.height))
      ctx.strokePath()
    }

    let nodeRect = CGRect(
      x: midX - nodeSize / 2,
      y: nodeTop,
      width: nodeSize,
      height: nodeSize
    )
    ctx.setFillColor(nodeColor.cgColor)
    ctx.fillEllipse(in: nodeRect)

    // Anel do fundo — separa o nó do trilho.
    ctx.setStrokeColor(UIColor(ThemeManager.shared.colors.background).cgColor)
    ctx.setLineWidth(2)
    ctx.strokeEllipse(in: nodeRect.insetBy(dx: -0.5, dy: -0.5))
  }
}

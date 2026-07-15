import SwiftUI
import UIKit

// Paridade lib/widgets/done_circle.dart — concluído = cor da prioridade (estilo Todoist).
struct DoneCircle: View {
  /// Tamanho do anel de conclusão em linhas de tarefa e subtarefa.
  static let listRowCircleSize: CGFloat = 22

  /// Espessura e preenchimento compartilhados entre tarefa e subtarefa na lista.
  enum RingStyle {
    static let borderWidth: CGFloat = 2
    static let inactiveFillAlpha: CGFloat = 0.08
  }

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let done: Bool
  var size: CGFloat = 22
  var borderWidth: CGFloat = 2
  var tickSize: CGFloat = 13
  var ringColor: Color = Color(hex: 0x6B6E76)
  var ringFillAlpha: CGFloat = 0
  /// UIKit cell + scroll: bitmap estático — `Circle().strokeBorder` “nada” no AA.
  var scrollStable: Bool = false
  /// UIKIT_SCROLL_POLISH: id da row/subtask — reuse com outro done não anima complete.
  var rowIdentity: String = ""

  @State private var fillScale: CGFloat = 1
  @State private var tickScale: CGFloat = 1
  @State private var tickOpacity: Double = 1
  /// Depois do tap de concluir, anima em vetor; no idle volta ao bitmap.
  @State private var preferVector = false
  @State private var boundRowIdentity: String = ""
  /// UIKIT_SCROLL_POLISH: identity+done mudam no mesmo turno no reuse — não anima.
  @State private var suppressDoneAnimation = false

  // UIKIT_SCROLL_POLISH: private static let doneColor = AppColors.success
  private static let completeBeginScale: CGFloat = 0.6

  private var usesRaster: Bool {
    scrollStable && !preferVector
  }

  /// Cor do anel/preenchimento — prioridade; sem prioridade = terciário.
  private var accentColor: Color { ringColor }

  var body: some View {
    Group {
      if usesRaster {
        // UIImageView + nearest: SwiftUI Image com bilinear ainda “treme” em Y fracionário.
        DoneCircleRasterView(
          image: DoneCircleRaster.image(
            done: done,
            size: size,
            borderWidth: borderWidth,
            ringColor: UIColor(accentColor),
            ringFillAlpha: ringFillAlpha,
            tickSize: tickSize
          ),
          size: size
        )
      } else {
        vectorGlyph
      }
    }
    .frame(width: size, height: size)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(done ? "Concluída" : "Não concluída")
    .accessibilityAddTraits(.isImage)
    .onAppear { rebindIdentityIfNeeded() }
    .onChange(of: rowIdentity) { _, _ in rebindIdentityIfNeeded() }
    .onChange(of: done) { wasDone, isDone in
      // UIKIT_SCROLL_POLISH: reuse/reconfigure — só sync; animate só toggle do usuário.
      if suppressDoneAnimation {
        suppressDoneAnimation = false
        preferVector = false
        syncVisualState(animated: false)
        return
      }
      if scrollStable, !rowIdentity.isEmpty, boundRowIdentity != rowIdentity {
        rebindIdentityIfNeeded()
        return
      }
      if isDone && !wasDone {
        if scrollStable { preferVector = true }
        playCompleteAnimation()
      } else if !isDone && wasDone {
        resetVisualState()
        preferVector = false
      }
    }
  }

  private func rebindIdentityIfNeeded() {
    guard !rowIdentity.isEmpty else {
      syncVisualState(animated: false)
      return
    }
    guard boundRowIdentity != rowIdentity else {
      syncVisualState(animated: false)
      return
    }
    boundRowIdentity = rowIdentity
    preferVector = false
    suppressDoneAnimation = true
    syncVisualState(animated: false)
  }

  private var vectorGlyph: some View {
    ZStack {
      if done {
        // Todoist: círculo sólido na cor da prioridade + check branco (mesmo glyph Hugeicons).
        // UIKIT_SCROLL_POLISH / legado: fill verde AppColors.success.opacity(0.15) + stroke/check verdes
        Circle()
          .fill(accentColor)
          .scaleEffect(fillScale)

        StackedIcons.icon(.check, size: tickSize, color: .white)
          .scaleEffect(tickScale)
          .opacity(tickOpacity)
      } else {
        Circle()
          .fill(ringFillAlpha > 0 ? accentColor.opacity(ringFillAlpha) : .clear)
          .overlay(
            Circle().strokeBorder(accentColor, lineWidth: borderWidth)
          )
      }
    }
  }

  private func syncVisualState(animated: Bool) {
    if done {
      fillScale = 1
      tickScale = 1
      tickOpacity = 1
    } else {
      fillScale = 1
      tickScale = 0
      tickOpacity = 0
    }
    _ = animated
  }

  private func resetVisualState() {
    fillScale = 1
    tickScale = 0
    tickOpacity = 0
  }

  private func playCompleteAnimation() {
    fillScale = Self.completeBeginScale
    tickScale = 0.5
    tickOpacity = 0
    // SUBSTITUIDO_FASE5: withAnimation(AppMotion.bouncy) sem reduceMotion
    AppMotion.animate(AppMotion.bouncy, reduceMotion: reduceMotion) {
      fillScale = 1
      tickScale = 1
      tickOpacity = 1
    }
    if scrollStable {
      _Concurrency.Task { @MainActor in
        try? await _Concurrency.Task.sleep(for: .milliseconds(420))
        preferVector = false
      }
    }
  }
}

/// `UIImageView` com filtro nearest — evita shimmer bilinear do `Image` no scroll.
private struct DoneCircleRasterView: UIViewRepresentable {
  let image: UIImage
  let size: CGFloat

  func makeUIView(context: Context) -> UIImageView {
    let view = UIImageView(image: image)
    view.contentMode = .scaleToFill
    view.clipsToBounds = true
    view.isUserInteractionEnabled = false
    view.layer.magnificationFilter = .nearest
    view.layer.minificationFilter = .nearest
    view.setContentHuggingPriority(.required, for: .horizontal)
    view.setContentHuggingPriority(.required, for: .vertical)
    view.setContentCompressionResistancePriority(.required, for: .horizontal)
    view.setContentCompressionResistancePriority(.required, for: .vertical)
    return view
  }

  func updateUIView(_ uiView: UIImageView, context: Context) {
    if uiView.image !== image {
      uiView.image = image
    }
  }

  func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIImageView, context: Context) -> CGSize? {
    CGSize(width: size, height: size)
  }
}

/// Bitmap do anel/check — estável sob `contentOffset` fracionário na lista UIKit.
enum DoneCircleRaster {
  private static var cache: [String: UIImage] = [:]
  // UIKIT_SCROLL_POLISH: private static let doneUIColor = UIColor(AppColors.success)

  static func image(
    done: Bool,
    size: CGFloat,
    borderWidth: CGFloat,
    ringColor: UIColor,
    ringFillAlpha: CGFloat,
    tickSize: CGFloat
  ) -> UIImage {
    let key = [
      done ? "1" : "0",
      "prioFill", // UIKIT_SCROLL_POLISH: invalida cache do estilo verde
      String(format: "%.1f", size),
      String(format: "%.1f", borderWidth),
      String(format: "%.3f", ringFillAlpha),
      String(format: "%.1f", tickSize),
      ringColor.cgColor.components?.map { String(format: "%.3f", $0) }.joined(separator: ",") ?? "x",
    ].joined(separator: "|")
    if let cached = cache[key] { return cached }

    let format = UIGraphicsImageRendererFormat.default()
    format.opaque = false
    format.scale = UIScreen.main.scale
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
    let image = renderer.image { ctx in
      let cg = ctx.cgContext
      let inset = borderWidth / 2
      let ringRect = CGRect(x: inset, y: inset, width: size - borderWidth, height: size - borderWidth)

      if done {
        // Todoist: preenchimento prioridade + check branco.
        ringColor.setFill()
        cg.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))

        UIColor.white.setStroke()
        cg.setLineWidth(max(1.6, borderWidth))
        cg.setLineCap(.round)
        cg.setLineJoin(.round)
        let cx = size / 2
        let cy = size / 2
        let s = tickSize * 0.42
        cg.move(to: CGPoint(x: cx - s * 0.85, y: cy + s * 0.05))
        cg.addLine(to: CGPoint(x: cx - s * 0.15, y: cy + s * 0.7))
        cg.addLine(to: CGPoint(x: cx + s * 0.95, y: cy - s * 0.65))
        cg.strokePath()
      } else {
        if ringFillAlpha > 0 {
          ringColor.withAlphaComponent(ringFillAlpha).setFill()
          cg.fillEllipse(in: ringRect)
        }
        ringColor.setStroke()
        cg.setLineWidth(borderWidth)
        cg.strokeEllipse(in: ringRect)
      }
    }
    cache[key] = image
    return image
  }
}

// SUBSTITUIDO_FASE3A: Group if/else + .animation(AppMotion.snappy(reduceMotion:), value: done)
// Group {
//   if done { Circle()... } else { Circle()... }
// }
// .animation(AppMotion.snappy(reduceMotion: reduceMotion), value: done)

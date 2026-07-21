import SwiftUI
import UIKit
import Hugeicons

/// UIKIT_SCROLL_POLISH: Hugeicons da TaskRow em bitmap nearest — path UIKit only.
@MainActor
enum UIKitRowIconRaster {
  private static let cache = NSCache<NSString, UIImage>()

  static func image(key: StackedIconKey, size: CGFloat, color: UIColor) -> UIImage {
    let scale = DisplayScreen.scale
    let snapped = AppLayout.pixelSnap(size, scale: scale)
    let pixel = Int((snapped * scale).rounded())
    let colorKey = color.cgColor.components?.map { String(format: "%.3f", $0) }.joined(separator: ",") ?? "x"
    let cacheKey = "\(key.rawValue)|\(pixel)|\(colorKey)" as NSString
    if let hit = cache.object(forKey: cacheKey) { return hit }

    let content = StackedIcons.asset(key).image()
      .resizable()
      .renderingMode(.template)
      .scaledToFit()
      .foregroundStyle(Color(color))
      .frame(width: snapped, height: snapped)

    let renderer = ImageRenderer(content: content)
    renderer.scale = scale
    renderer.isOpaque = false
    guard let raw = renderer.uiImage else {
      return UIImage()
    }
    let prepared = raw.preparingForDisplay() ?? raw
    cache.setObject(prepared, forKey: cacheKey)
    return prepared
  }

  /// Pré-aquece combinações comuns das listas (fora do configure).
  @MainActor
  static func warmCommon(textTertiary: UIColor, accent: UIColor) {
    let samples: [(StackedIconKey, CGFloat, UIColor)] = [
      // UIKIT_SCROLL_POLISH: (.chevronDown, 12, textTertiary), — chevron voltou a vetor
      (.clock, 11, textTertiary),
      (.copy, 16, accent),
    ]
    for (key, size, color) in samples {
      _ = image(key: key, size: size, color: color)
    }
  }
}

/// UIImageView + nearest — mesmo padrão do DoneCircleRasterView.
struct UIKitRowIconView: View {
  let key: StackedIconKey
  let size: CGFloat
  let color: Color

  var body: some View {
    UIKitNearestImageView(
      image: UIKitRowIconRaster.image(
        key: key,
        size: size,
        color: UIColor(color)
      ),
      size: AppLayout.pixelSnap(size)
    )
  }
}

struct UIKitNearestImageView: UIViewRepresentable {
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

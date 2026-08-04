import SwiftUI
import UIKit

/// Cache em memória, entre instâncias — evita o "ghost" do avatar: o header
/// (leading toolbar item da Home) fica no mesmo slot do botão voltar dos
/// drill-downs; a struct é recriada a cada pop de navegação e, sem cache, o
/// `AsyncImage` reinicia em `.empty`/placeholder por 1-2 frames bem no meio
/// da transição — o círculo de iniciais "pisca" sobre o botão voltar saindo.
@MainActor
private enum AvatarImageCache {
  private static var store: [URL: UIImage] = [:]

  static func image(for url: URL) -> UIImage? { store[url] }
  static func store(_ image: UIImage, for url: URL) { store[url] = image }
}

// Paridade lib/widgets/settings/user_pill.dart
struct UserAvatarView: View {
  @Environment(ThemeManager.self) private var theme
  @State private var loadedImage: UIImage?

  let url: URL?
  let initials: String
  var size: CGFloat = AppLayout.headerAvatarSize

  /// Lido de forma síncrona no body — se já tiver sido carregado uma vez
  /// (por esta view ou qualquer outra instância), aparece no primeiro frame,
  /// sem passar pelo estado de loading do AsyncImage.
  private var cachedImage: UIImage? {
    guard let url else { return nil }
    return AvatarImageCache.image(for: url) ?? loadedImage
  }

  var body: some View {
    let c = theme.colors
    Group {
      if let cachedImage {
        Image(uiImage: cachedImage)
          .resizable()
          .scaledToFill()
      } else {
        initialsView(c)
      }
    }
    .frame(width: size, height: size)
    .clipShape(Circle())
    .task(id: url) {
      await load()
    }
  }

  @MainActor
  private func load() async {
    guard let url, AvatarImageCache.image(for: url) == nil else { return }
    guard let (data, _) = try? await URLSession.shared.data(from: url),
          let image = UIImage(data: data) else { return }
    AvatarImageCache.store(image, for: url)
    loadedImage = image
  }

  private func initialsView(_ c: AppThemeColors) -> some View {
    ZStack {
      Circle().fill(c.accent.opacity(0.18))
      Text(initials)
        .font(.system(size: size * 0.38, weight: .heavy))
        .foregroundStyle(c.accent)
    }
  }
}

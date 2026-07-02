import SwiftUI

// Paridade lib/widgets/settings/user_pill.dart
struct UserAvatarView: View {
  @Environment(ThemeManager.self) private var theme

  let url: URL?
  let initials: String
  var size: CGFloat = AppLayout.headerAvatarSize

  var body: some View {
    let c = theme.colors
    Group {
      if let url {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image.resizable().scaledToFill()
          case .failure:
            initialsView(c)
          default:
            initialsView(c)
          }
        }
      } else {
        initialsView(c)
      }
    }
    .frame(width: size, height: size)
    .clipShape(Circle())
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

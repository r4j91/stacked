import SwiftUI

/// Miniatura 56×36 — FAB flutuante vs integrado na pill Ilha.
struct FabIntegratedInIslandPreview: View {
  let integrated: Bool
  let colors: AppThemeColors

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(colors.surfaceVariant)
      if integrated {
        integratedPreview
      } else {
        floatingPreview
      }
    }
    .frame(width: 56, height: 36)
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private var floatingPreview: some View {
    ZStack(alignment: .bottomTrailing) {
      Capsule()
        .fill(colors.navBar.opacity(0.55))
        .frame(height: 10)
        .padding(.horizontal, 8)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 4)

      Circle()
        .fill(colors.accent.opacity(0.9))
        .frame(width: 9, height: 9)
        .overlay {
          Image(systemName: "plus")
            .font(.system(size: 6, weight: .bold))
            .foregroundStyle(colors.onAccent)
        }
        .padding(.trailing, 6)
        .padding(.bottom, 10)
    }
    .padding(4)
  }

  private var integratedPreview: some View {
    Capsule()
      .fill(colors.navBar.opacity(0.55))
      .overlay {
        HStack(spacing: 0) {
          HStack(spacing: 2) {
            Circle().fill(colors.accent).frame(width: 3.5, height: 3.5)
            RoundedRectangle(cornerRadius: 1)
              .fill(colors.textSecondary.opacity(0.7))
              .frame(width: 8, height: 2.5)
          }
          .padding(.leading, 5)

          Spacer(minLength: 2)

          Rectangle()
            .fill(colors.textPrimary.opacity(0.12))
            .frame(width: 0.5, height: 7)

          Image(systemName: "plus")
            .font(.system(size: 6, weight: .bold))
            .foregroundStyle(colors.onAccent)
            .frame(width: 10, height: 10)
            .background(Circle().fill(colors.accent.opacity(0.85)))
            .padding(.trailing, 3)
        }
      }
      .frame(height: 12)
      .padding(.horizontal, 6)
      .frame(maxHeight: .infinity, alignment: .bottom)
      .padding(.bottom, 6)
  }
}

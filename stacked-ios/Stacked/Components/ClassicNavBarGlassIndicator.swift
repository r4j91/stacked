import SwiftUI

// Fase 4 — lente Liquid Glass do indicador ativo (estilo Todoist iOS).
enum ClassicNavGlassLayout {
  static let indicatorInset: CGFloat = 2
  static let indicatorCornerRadius: CGFloat = 28
  /// Etapa 2 — distância de fusão do GlassEffectContainer (testar 28–32 se morph pular).
  static let containerSpacing: CGFloat = 24
  static let morphEffectID = "activeTab"
  static let blobGeometryID = "navBlob"
}

/// Lente glass pura (sem tint) — desliza via matchedGeometryEffect do esqueleto BottomNavPill.
struct ClassicNavBarGlassIndicator: View {
  var morphEnabled: Bool
  var blobNamespace: Namespace.ID
  var glassNamespace: Namespace.ID

  var body: some View {
    let lens = Capsule()
      .fill(.clear)
      .glassEffect(.regular.interactive(), in: Capsule())
      .padding(ClassicNavGlassLayout.indicatorInset)
      .matchedGeometryEffect(id: ClassicNavGlassLayout.blobGeometryID, in: blobNamespace)

    if morphEnabled {
      lens.glassEffectID(ClassicNavGlassLayout.morphEffectID, in: glassNamespace)
    } else {
      lens
    }
  }
}

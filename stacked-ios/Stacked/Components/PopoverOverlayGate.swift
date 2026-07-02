import SwiftUI

// Só monta o overlay quando o popover está aberto — evita bloquear FAB/menus.
struct PopoverOverlayGate: View {
  @Bindable private var presenter = PopoverPresenter.shared

  var body: some View {
    if presenter.isPresented {
      PopoverOverlayHost()
    }
  }
}

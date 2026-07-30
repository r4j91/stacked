import SwiftUI

/// Cascata premium ao abrir subtarefas: fade + leve translateY por índice.
/// Só desenho — `opacity`/`offset` não mudam a altura medida pelo `SubtaskExpandReveal`.
///
/// `epoch == 0`: restore/seed do scroll — aparece já opaco (sem cascata).
/// `epoch > 0`: expand manual — dispara entrada (também no `onAppear` se o bump
/// veio antes do host do painel montar).
struct SubtaskCascadeEntrance: ViewModifier {
  let epoch: Int
  let index: Int
  let reduceMotion: Bool

  @State private var shown = false
  @State private var playedEpoch = -1

  private var cascadeDelay: Double {
    Double(min(index, AppMotion.subtaskCascadeMaxIndex)) * AppMotion.subtaskCascadeStepSeconds
  }

  func body(content: Content) -> some View {
    content
      .opacity(shown ? 1 : 0)
      .offset(y: shown ? 0 : AppMotion.subtaskCascadeOffsetY)
      .onAppear { play(epoch) }
      .onChange(of: epoch) { _, newEpoch in
        play(newEpoch)
      }
  }

  private func play(_ epoch: Int) {
    if reduceMotion || epoch == 0 {
      shown = true
      playedEpoch = epoch
      return
    }
    guard epoch != playedEpoch else {
      shown = true
      return
    }
    playedEpoch = epoch
    var reset = Transaction()
    reset.disablesAnimations = true
    withTransaction(reset) {
      shown = false
    }
    withAnimation(AppMotion.subtaskCascade.delay(cascadeDelay)) {
      shown = true
    }
  }
}

extension View {
  func subtaskCascadeEntrance(epoch: Int, index: Int, reduceMotion: Bool) -> some View {
    modifier(SubtaskCascadeEntrance(epoch: epoch, index: index, reduceMotion: reduceMotion))
  }
}

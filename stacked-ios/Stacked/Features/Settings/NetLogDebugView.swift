import SwiftUI

/// NET_FASEC_ETAPA1 — tela escondida (long-press na versão em Settings).
struct NetLogDebugView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme
  @State private var entries: [NetLog.Entry] = []
  @State private var copied = false
  @AppStorage("net.log.skip.reload.delay") private var skipReloadDelay = false
  // PERF_FASEB3 — seções de hitch/T0/legado removidas da UI; T0 fica em Aparência.
  // @AppStorage(FreezeDockGlassWhileScrollingStorage.key) private var t0FreezeDockGlass = true
  // @AppStorage(DockGlassFreezeLegacyStorage.key) private var legacyGlassSwitch = false
  // @State private var hitchSamples: [ScrollHitchProbe.Sample] = []

  var body: some View {
    let c = theme.colors
    List {
      Section {
        Button {
          _ = NetLog.copyToPasteboard()
          copied = true
          HapticService.saved()
        } label: {
          Label(copied ? "Copiado" : "Copiar log", systemImage: "doc.on.doc")
        }
        Button {
          _Concurrency.Task {
            let result = await TaskOptimisticSync.validateClientGeneratedId()
            entries = NetLog.entries()
            let msg: String
            switch result {
            case .some(true): msg = "UUID client: OK"
            case .some(false): msg = "UUID client: REJEITADO — parar e reportar"
            case .none: msg = "UUID client: indeterminado (rede/auth)"
            }
            SyncFeedback.shared.showMessage(msg)
          }
        } label: {
          Label("Probe UUID client (insert+delete)", systemImage: "checkmark.shield")
        }
        Button(role: .destructive) {
          NetLog.clear()
          entries = []
        } label: {
          Label("Limpar", systemImage: "trash")
        }
      }

      Section {
        Toggle("Pular delay 400ms (troca de aba)", isOn: $skipReloadDelay)
      } footer: {
        Text("NET_FASEC_ETAPA5 — toggle interno. Se stutter voltar, desligar. Marcador AJUSTADO_RELOAD_DELAY permanece no código.")
          .font(AppTypography.metaSmall)
      }

      Section("Últimas \(entries.count) entradas") {
        ForEach(entries.reversed()) { entry in
          VStack(alignment: .leading, spacing: 4) {
              Text("[\(entry.step.rawValue)] \(entry.operation)")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(c.textPrimary)
            Text("\(entry.durationMs)ms · \(entry.result.rawValue) · fg+\(entry.msSinceForeground)ms")
              .font(AppTypography.metaSmall)
              .foregroundStyle(c.textSecondary)
            if let detail = entry.detail {
              Text(detail)
                .font(AppTypography.metaSmall)
                .foregroundStyle(c.textTertiary)
                .lineLimit(3)
            }
          }
          .padding(.vertical, 2)
        }
      }
    }
    .navigationTitle("NetLog")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Fechar") { dismiss() }.foregroundStyle(c.accent)
      }
    }
    .onAppear {
      entries = NetLog.entries()
      copied = false
    }
  }
}

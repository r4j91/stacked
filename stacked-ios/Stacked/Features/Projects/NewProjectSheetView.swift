import SwiftUI
import Hugeicons

// Paridade lib/widgets/new_project_sheet.dart
struct NewProjectSheetView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  var onCreated: () -> Void

  @State private var name = ""
  @State private var selectedHex = PaletteColors.defaultHex
  @State private var saving = false
  @State private var error: String?

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

  private var canCreate: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !saving
  }

  var body: some View {
    let c = theme.colors

    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          TextField("Nome do projeto", text: $name)
            .textFieldStyle(.plain)
            .padding(14)
            .background(c.surfaceVariant)
            .clipShape(RoundedRectangle(cornerRadius: 12))

          Text("Cor")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(c.textSecondary)

          LazyVGrid(columns: columns, spacing: 10) {
            ForEach(PaletteColors.projectHex, id: \.self) { hex in
              let color = AppColors.parseHex(hex)
              Button {
                HapticService.selection()
                selectedHex = hex
              } label: {
                Circle()
                  .fill(color)
                  .frame(height: 32)
                  .overlay {
                    if selectedHex == hex {
                      Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                    }
                  }
              }
              .buttonStyle(.plain)
            }
          }

          if let error {
            Text(error).font(.caption).foregroundStyle(AppColors.priorityHigh)
          }

          PrimaryButton(
            title: "Criar projeto",
            action: { _Concurrency.Task { await create() } },
            isLoading: saving,
            isEnabled: canCreate,
            height: 48,
            cornerRadius: 14,
            font: .system(size: 16, weight: .semibold)
          )
        }
        .padding(20)
        .padding(.bottom, 8)
      }
      .background(c.background)
      .navigationTitle("Novo projeto")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancelar") { dismiss() }
        }
      }
    }
  }

  private func create() async {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    saving = true
    do {
      try await ProjectRepository.shared.createProject(name: trimmed, colorHex: selectedHex)
      HapticService.taskCreated()
      onCreated()
      dismiss()
    } catch {
      self.error = error.localizedDescription
      saving = false
    }
  }
}

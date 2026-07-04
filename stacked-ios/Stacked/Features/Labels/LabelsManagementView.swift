import SwiftUI

// Paridade lib/screens/labels_screen.dart
struct LabelsManagementView: View {
  @Environment(ThemeManager.self) private var theme

  @State private var labels: [TaskLabel] = []
  @State private var loading = true
  @State private var editorLabel: EditableLabel?
  @State private var showEditor = false

  var body: some View {
    let c = theme.colors

    Group {
        if loading {
          ProgressView().tint(c.accent)
        } else if labels.isEmpty {
          EmptyStateView(icon: .tag, title: "Nenhuma etiqueta ainda", subtitle: "Toque em + para criar sua primeira etiqueta.")
        } else {
          List {
            Section {
              SettingsCardSurface {
                VStack(spacing: 0) {
                  ForEach(Array(labels.enumerated()), id: \.element.id) { index, label in
                    labelRow(label)
                    if index < labels.count - 1 {
                      SettingsCardDivider(leadingPadding: 44)
                    }
                  }
                }
              }
              .settingsListCardRow(top: 8)
            }
          }
          .settingsDrillDownList(background: c.background)
        }
      }
      .stackedTabletCentered()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(c.background)
      .navigationTitle("Gerenciar Etiquetas")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            openEditor(nil)
          } label: {
            StackedIcons.image(.plus)
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(c.accent)
          }
        }
      }
      .refreshable { await load() }
      .task { await load() }
      .sheet(isPresented: $showEditor) {
        if let editorLabel {
          LabelEditorSheet(label: editorLabel) {
            _Concurrency.Task { await load() }
          }
          .environment(theme)
        }
      }
  }

  private func labelRow(_ label: TaskLabel) -> some View {
    let c = theme.colors

    return HStack(spacing: 12) {
      StackedIcons.image(.tag)
        .font(.system(size: 18))
        .foregroundStyle(label.color)
      Text(label.name)
        .font(AppTypography.body)
        .foregroundStyle(c.textPrimary)
      Spacer()
      Button {
        openEditor(label)
      } label: {
        StackedIcons.image(.edit)
          .font(.system(size: 16))
          .foregroundStyle(c.textSecondary)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Editar etiqueta \(label.name)")
      Button {
        _Concurrency.Task { await deleteLabel(label) }
      } label: {
        StackedIcons.image(.trash)
          .font(.system(size: 16))
          .foregroundStyle(AppColors.priorityHigh)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Excluir etiqueta \(label.name)")
    }
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
  }

  private func openEditor(_ label: TaskLabel?) {
    if let label {
      editorLabel = EditableLabel(id: label.id, name: label.name, colorHex: hexForColor(label.color))
    } else {
      editorLabel = EditableLabel(id: nil, name: "", colorHex: PaletteColors.defaultHex)
    }
    showEditor = true
  }

  private func load() async {
    loading = labels.isEmpty
    defer { loading = false }
    labels = (try? await LabelRepository.shared.fetchLabels()) ?? []
  }

  private func deleteLabel(_ label: TaskLabel) async {
    labels.removeAll { $0.id == label.id }
    do {
      try await LabelRepository.shared.deleteLabel(id: label.id)
      HapticService.taskDeleted()
    } catch {
      await load()
    }
  }

  private func hexForColor(_ color: Color) -> String {
    PaletteColors.projectHex.first(where: { AppColors.parseHex($0) == color }) ?? PaletteColors.defaultHex
  }
}

private struct EditableLabel: Identifiable {
  let id: String?
  var name: String
  var colorHex: String
  var isNew: Bool { id == nil }
}

private struct LabelEditorSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  let label: EditableLabel
  var onSaved: () -> Void

  @State private var name: String
  @State private var selectedHex: String
  @State private var saving = false
  @State private var error: String?

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

  init(label: EditableLabel, onSaved: @escaping () -> Void) {
    self.label = label
    self.onSaved = onSaved
    _name = State(initialValue: label.name)
    _selectedHex = State(initialValue: label.colorHex)
  }

  var body: some View {
    let c = theme.colors

    NavigationStack {
      VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 10) {
          StackedIcons.image(.tag)
            .font(.system(size: 18))
            .foregroundStyle(AppColors.parseHex(selectedHex))
          Text(name.isEmpty ? "Nova etiqueta" : name)
            .font(AppTypography.profileName)
            .foregroundStyle(AppColors.parseHex(selectedHex))
        }

        TextField("Nome da etiqueta", text: $name)
          .textFieldStyle(.plain)
          .padding(14)
          .background(c.surfaceVariant)
          .clipShape(RoundedRectangle(cornerRadius: 10))

        Text("Cor")
          .font(AppTypography.sectionLabel)
          .foregroundStyle(c.textTertiary)

        LazyVGrid(columns: columns, spacing: 10) {
          ForEach(PaletteColors.projectHex, id: \.self) { hex in
            let color = AppColors.parseHex(hex)
            Button {
              HapticService.selection()
              selectedHex = hex
            } label: {
              Circle()
                .fill(color)
                .frame(height: 30)
                .overlay {
                  if selectedHex == hex {
                    Image(systemName: "checkmark")
                      .font(.system(size: 12, weight: .bold))
                      .foregroundStyle(AppColors.onColoredFill)
                  }
                }
            }
            .buttonStyle(.plain)
          }
        }

        if let error {
          Text(error).font(.caption).foregroundStyle(AppColors.priorityHigh)
        }

        Spacer()

        PrimaryButton(
          title: label.isNew ? "Criar etiqueta" : "Salvar",
          action: { _Concurrency.Task { await save() } },
          isLoading: saving,
          isEnabled: !name.trimmingCharacters(in: .whitespaces).isEmpty && !saving,
          height: 48
        )
      }
      .padding(20)
      .background(c.background)
      .navigationTitle(label.isNew ? "Nova etiqueta" : "Editar etiqueta")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancelar") { dismiss() }
        }
      }
    }
    .presentationDetents([.medium, .large])
  }

  private func save() async {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    saving = true
    defer { saving = false }
    do {
      if let id = label.id {
        try await LabelRepository.shared.updateLabel(id: id, name: trimmed, colorHex: selectedHex)
      } else {
        try await LabelRepository.shared.createLabel(name: trimmed, colorHex: selectedHex)
      }
      HapticService.saved()
      onSaved()
      dismiss()
    } catch {
      self.error = error.localizedDescription
    }
  }
}

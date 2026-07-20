import SwiftUI
import Hugeicons

// Paridade lib/widgets/new_project_sheet.dart — painel compacto ancorado ao teclado (como Quick Add)
struct NewProjectSheetView: View {
  @Environment(ThemeManager.self) private var theme
  @Bindable private var colorGridPresenter = ColorGridPopoverPresenter.shared

  var onCreated: () -> Void
  var onDismiss: () -> Void

  @FocusState private var nameFocused: Bool
  @State private var name = ""
  @State private var selectedHex = PaletteColors.defaultHex
  @State private var saving = false
  @State private var error: String?

  private let panelRadius: CGFloat = 22

  private var canCreate: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !saving
  }

  var body: some View {
    let c = theme.colors

    VStack(spacing: 0) {
      header

      Divider().overlay(c.textTertiary.opacity(0.12))

      VStack(alignment: .leading, spacing: 16) {
        TextField(
          "Nome do projeto",
          text: $name,
          prompt: Text("Ex.: Reforma da cozinha").foregroundStyle(c.textTertiary)
        )
        .font(.title3.weight(.semibold))
        .foregroundStyle(c.textPrimary)
        .tint(c.accent)
        .focused($nameFocused)
        .submitLabel(.done)
        .textInputAutocapitalization(.sentences)
        .onSubmit {
          if canCreate { _Concurrency.Task { await create() } }
        }

        colorPickerRow

        if let error {
          Text(error)
            .font(AppTypography.meta)
            .foregroundStyle(AppColors.priorityHigh)
        }

        PrimaryButton(
          title: "Criar projeto",
          action: { _Concurrency.Task { await create() } },
          isLoading: saving,
          isEnabled: canCreate,
          height: 48,
          cornerRadius: 14,
          font: AppTypography.bodySemibold
        )
      }
      .padding(.horizontal, 16)
      .padding(.top, 14)
      .padding(.bottom, 14)
    }
    .background { KeyboardFloatingPanelStyle.chrome(colors: c, cornerRadius: panelRadius) }
    .background { ColorGridWindowOverlayHost(presenter: colorGridPresenter) }
    .onAppear {
      DispatchQueue.main.async { nameFocused = true }
    }
  }

  private var header: some View {
    let c = theme.colors
    return HStack(spacing: 8) {
      Button("Cancelar") { onDismiss() }
        .font(AppTypography.body)
        .foregroundStyle(c.textSecondary)
        .buttonStyle(.plain)

      Spacer()

      Text("Novo projeto")
        .font(AppTypography.sheetPageTitle)
        .foregroundStyle(c.textPrimary)

      Spacer()

      Color.clear.frame(width: 72, height: 1)
    }
    .padding(.horizontal, 14)
    .padding(.top, 12)
    .padding(.bottom, 8)
  }

  private var colorPickerRow: some View {
    let c = theme.colors
    let color = AppColors.parseHex(selectedHex)

    return AnchoredTapButton { rect in
      colorGridPresenter.present(
        anchorRect: rect,
        selectedHex: selectedHex,
        onSelect: { selectedHex = $0 },
        onClose: {
          DispatchQueue.main.async { nameFocused = true }
        }
      )
      DispatchQueue.main.async { nameFocused = true }
    } label: {
      HStack(spacing: 12) {
        StackedIcons.image(.paintbrush)
          .font(.system(size: 18))
          .foregroundStyle(c.textSecondary)
          .frame(width: 20)

        Text("Cor")
          .font(AppTypography.popoverRowLabel)
          .foregroundStyle(c.textPrimary)

        Spacer()

        Circle()
          .fill(color)
          .frame(width: 22, height: 22)
          .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5))

        StackedIcons.image(.chevronRight)
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(c.textTertiary)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 13)
      .background(KeyboardFloatingPanelStyle.chipBackground(c))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Cor do projeto")
    .accessibilityValue(selectedHex)
  }

  private func create() async {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    saving = true
    do {
      try await ProjectRepository.shared.createProject(name: trimmed, colorHex: selectedHex)
      HapticService.taskCreated()
      onCreated()
      onDismiss()
    } catch {
      self.error = error.localizedDescription
      saving = false
    }
  }
}

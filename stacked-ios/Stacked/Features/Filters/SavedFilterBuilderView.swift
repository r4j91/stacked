import SwiftUI
import Hugeicons

struct SavedFilterBuilderView: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.dismiss) private var dismiss
  @Bindable private var colorGridPresenter = ColorGridPopoverPresenter.shared

  var existing: SavedFilter?
  var onSaved: () async -> Void

  @State private var name = ""
  @State private var selectedHex = PaletteColors.defaultHex
  @State private var criteria = FilterCriteria.empty
  @State private var labels: [TaskLabel] = []
  @State private var projects: [Project] = []
  @State private var saving = false
  @State private var error: String?

  private let iconCircleSize: CGFloat = 44
  private let metadataIconSize: CGFloat = 23

  private var canSave: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !saving
  }

  var body: some View {
    let c = theme.colors

    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Nome")
              .font(AppTypography.fieldLabel)
              .foregroundStyle(c.textTertiary)
            TextField("Nome do filtro", text: $name)
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(c.textPrimary)
              .padding(12)
              .background(c.surfaceVariant)
              .clipShape(RoundedRectangle(cornerRadius: 12))
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(c.textTertiary.opacity(0.12), lineWidth: 1)
              )
          }
          .padding(.horizontal, 20)
          .padding(.top, 8)

          Divider()
            .overlay(c.textTertiary.opacity(0.15))
            .padding(.top, 16)
            .padding(.bottom, 4)

          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
              projectChip
              metadataIconButton(
                icon: .tag,
                active: !criteria.labelIds.isEmpty,
                activeColor: labelAccentColor
              ) { showLabelsMenu(anchor: $0) }
              metadataIconButton(
                icon: .flag,
                active: !criteria.priorities.isEmpty,
                activeColor: priorityAccentColor
              ) { showPriorityMenu(anchor: $0) }
              colorIconButton
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("DATA")
              .font(AppTypography.sectionLabel)
              .foregroundStyle(c.textTertiary)
              .padding(.horizontal, 20)

            ForEach(FilterDateScope.allCases, id: \.self) { scope in
              Button {
                HapticService.selection()
                criteria.dateScope = scope
              } label: {
                HStack(spacing: 10) {
                  ZStack {
                    Circle()
                      .stroke(criteria.dateScope == scope ? c.accent : c.textTertiary, lineWidth: 2)
                      .frame(width: 18, height: 18)
                    if criteria.dateScope == scope {
                      Circle()
                        .fill(c.accent)
                        .frame(width: 8, height: 8)
                    }
                  }
                  Text(scope.title)
                    .font(.system(size: 14))
                    .foregroundStyle(criteria.dateScope == scope ? c.textPrimary : c.textSecondary)
                  Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                  criteria.dateScope == scope
                    ? c.accent.opacity(0.08)
                    : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
              }
              .buttonStyle(.plain)
              .padding(.horizontal, 8)
            }
          }
          .padding(.top, 8)
          .padding(.bottom, 24)

          if let error {
            Text(error)
              .font(AppTypography.meta)
              .foregroundStyle(AppColors.priorityHigh)
              .padding(.horizontal, 20)
          }
        }
      }
      .background(c.background)
      .navigationTitle(existing == nil ? "Novo filtro" : "Editar filtro")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancelar") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Salvar") {
            _Concurrency.Task { await save() }
          }
          .disabled(!canSave)
        }
      }
      .task { await loadPickers() }
      .onAppear {
        if let existing {
          name = existing.name
          selectedHex = existing.colorHex ?? PaletteColors.defaultHex
          criteria = existing.criteria
        }
      }
      .background { ColorGridWindowOverlayHost(presenter: colorGridPresenter) }
      .popoverHostScope(
        coordinateSpaceName: "savedFilterBuilder",
        placement: .quickAddSheet,
        windowPreferAbove: false
      )
    }
  }

  private func presentMetadataPopover(
    anchor: CGRect,
    items: [PopoverMenuItem],
    allowsToggle: Bool = false,
    onSelect: @escaping (String?) -> Void
  ) {
    presentAnchoredPopover(
      anchorRect: anchor,
      items: items,
      allowsToggle: allowsToggle,
      preferAbove: false,
      onSelect: onSelect
    )
  }

  private var labelAccentColor: Color {
    labels.first(where: { criteria.labelIds.contains($0.id) })?.color ?? theme.colors.accent
  }

  private var priorityAccentColor: Color {
    criteria.priorities.first?.iconColor ?? theme.colors.accent
  }

  private var projectChip: some View {
    let c = theme.colors
    let active = criteria.projectId != nil
    let dot = projects.first(where: { $0.id == criteria.projectId })?.color ?? c.textSecondary
    let chipLabel = projects.first(where: { $0.id == criteria.projectId })?.name ?? "Projeto"

    return AnchoredTapButton { rect in
      showProjectMenu(anchor: rect)
    } label: {
      HStack(spacing: 6) {
        StackedIcons.icon(.folder, size: 17, color: active ? dot : c.textSecondary)
        Text(chipLabel)
          .font(.system(size: 14.5, weight: .medium))
          .foregroundStyle(active ? dot : c.textSecondary)
          .lineLimit(1)
      }
      .padding(.horizontal, 12)
      .frame(height: iconCircleSize)
      .background(
        active
          ? dot.opacity(0.14)
          : chipBackground(c)
      )
      .clipShape(Capsule())
      .overlay {
        if !active {
          Capsule()
            .strokeBorder(c.textPrimary.opacity(0.06), lineWidth: 0.6)
        }
      }
    }
    .accessibilityLabel("Projeto")
  }

  private var colorIconButton: some View {
    let color = AppColors.parseHex(selectedHex)
    return AnchoredTapButton { rect in
      colorGridPresenter.present(
        anchorRect: rect,
        selectedHex: selectedHex,
        onSelect: { selectedHex = $0 }
      )
    } label: {
      Circle()
        .fill(color)
        .frame(width: 20, height: 20)
        .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5))
        .frame(width: iconCircleSize, height: iconCircleSize)
        .background(chipBackground(theme.colors))
        .clipShape(Circle())
        .overlay {
          Circle()
            .strokeBorder(theme.colors.textPrimary.opacity(0.06), lineWidth: 0.6)
        }
    }
    .accessibilityLabel("Cor do filtro")
  }

  private func metadataIconButton(
    icon: StackedIconKey,
    active: Bool,
    activeColor: Color,
    action: @escaping (CGRect) -> Void
  ) -> some View {
    let c = theme.colors
    let iconColor = active ? activeColor : c.textSecondary

    return AnchoredTapButton(action: action) {
      StackedIcons.icon(icon, size: metadataIconSize, color: iconColor)
        .frame(width: iconCircleSize, height: iconCircleSize)
        .background(active ? activeColor.opacity(0.15) : chipBackground(c))
        .clipShape(Circle())
        .overlay {
          if !active {
            Circle()
              .strokeBorder(c.textPrimary.opacity(0.06), lineWidth: 0.6)
          }
        }
    }
  }

  private func chipBackground(_ c: AppThemeColors) -> Color {
    KeyboardFloatingPanelStyle.chipBackground(c)
  }

  private func showLabelsMenu(anchor: CGRect) {
    let items = labels.map { label in
      PopoverMenuItem(
        id: label.id,
        icon: Hugeicons.tag01,
        label: label.name,
        selected: criteria.labelIds.contains(label.id),
        iconColor: label.color
      )
    }
    presentMetadataPopover(anchor: anchor, items: items, allowsToggle: true) { result in
      guard let result else { return }
      if criteria.labelIds.contains(result) {
        criteria.labelIds.removeAll { $0 == result }
      } else {
        criteria.labelIds.append(result)
      }
    }
  }

  private func showPriorityMenu(anchor: CGRect) {
    let items = FilterPriorityCriteria.allCases.map { p in
      PopoverMenuItem(
        id: p.rawValue,
        icon: Hugeicons.flag01,
        label: p.menuLabel,
        selected: criteria.priorities.contains(p),
        iconColor: p.iconColor
      )
    }
    presentMetadataPopover(anchor: anchor, items: items, allowsToggle: true) { result in
      guard let result, let p = FilterPriorityCriteria(rawValue: result) else { return }
      if criteria.priorities.contains(p) {
        criteria.priorities.removeAll { $0 == p }
      } else {
        criteria.priorities.append(p)
      }
    }
  }

  private func showProjectMenu(anchor: CGRect) {
    var items: [PopoverMenuItem] = [
      PopoverMenuItem(
        id: "any",
        icon: Hugeicons.inbox,
        label: "Qualquer projeto",
        selected: criteria.projectId == nil
      ),
    ]
    for project in projects {
      items.append(PopoverMenuItem(
        id: project.id,
        icon: Hugeicons.folder01,
        label: project.name,
        selected: criteria.projectId == project.id,
        iconColor: project.color
      ))
    }
    presentMetadataPopover(anchor: anchor, items: items) { result in
      guard let result else { return }
      criteria.projectId = result == "any" ? nil : result
    }
  }

  private func loadPickers() async {
    labels = (try? await LabelRepository.shared.fetchLabels()) ?? []
    projects = (try? await ProjectRepository.shared.fetchProjects()) ?? []
  }

  private func save() async {
    saving = true
    error = nil
    do {
      if let existing {
        try await FiltersStore.shared.updateSavedFilter(
          existing,
          name: name,
          colorHex: selectedHex,
          criteria: criteria
        )
      } else {
        try await FiltersStore.shared.createSavedFilter(
          name: name,
          colorHex: selectedHex,
          criteria: criteria
        )
      }
      await onSaved()
      dismiss()
    } catch let err {
      error = err.localizedDescription
    }
    saving = false
  }
}

import SwiftUI

// Paridade lib/widgets/project_options_sheet.dart — menu multi-página estilo Todoist
struct ProjectOptionsSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let project: Project
  var onEdited: () -> Void
  var onDeleted: () -> Void

  @State private var page: SheetPage = .menu
  @State private var name: String
  @State private var selectedHex: String
  @State private var selectedIcon: String
  @State private var saving = false
  @State private var showDeleteConfirm = false
  @State private var error: String?

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

  init(project: Project, onEdited: @escaping () -> Void, onDeleted: @escaping () -> Void) {
    self.project = project
    self.onEdited = onEdited
    self.onDeleted = onDeleted
    _name = State(initialValue: project.name)
    _selectedHex = State(initialValue: Self.hexForProject(project))
    _selectedIcon = State(initialValue: "folder")
  }

  var body: some View {
    let c = theme.colors

    VStack(spacing: 0) {
      handle
      header
      Divider().overlay(c.textTertiary.opacity(0.12))
      Group {
        switch page {
        case .menu: menuPage
        case .name: namePage
        case .icon: iconPage
        case .color: colorPage
        }
      }
      .frame(maxHeight: .infinity, alignment: .top)
    }
    .background(c.background)
    .confirmationDialog("Excluir projeto?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
      Button("Excluir", role: .destructive) { _Concurrency.Task { await deleteProject() } }
      Button("Cancelar", role: .cancel) {}
    } message: {
      Text("Isso excluirá \"\(displayName)\" e todas as suas tarefas permanentemente.")
    }
    .task { await loadDetails() }
  }

  private var displayName: String {
    let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return t.isEmpty ? project.name : t
  }

  private var handle: some View {
    Capsule()
      .fill(theme.colors.textTertiary.opacity(0.3))
      .frame(width: 36, height: 4)
      .padding(.top, 10)
      .padding(.bottom, 6)
  }

  private var header: some View {
    let c = theme.colors
    return HStack(spacing: 8) {
      if page != .menu {
        // SUBSTITUIDO_FASE2: Button { withAnimation { page = .menu } }
        Button { AppMotion.animate(AppMotion.smooth, reduceMotion: reduceMotion) { page = .menu } } label: {
          StackedIcons.image(.arrowLeft).foregroundStyle(c.textSecondary)
        }
        .buttonStyle(.plain)
      }
      Text(pageTitle)
        .font(AppTypography.sheetPageTitle)
        .foregroundStyle(c.textPrimary)
        .lineLimit(1)
      Spacer()
      Button { dismiss() } label: {
        StackedIcons.image(.close).foregroundStyle(c.textTertiary)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 10)
  }

  private var pageTitle: String {
    switch page {
    case .menu: displayName
    case .name: "Nome"
    case .icon: "Ícone"
    case .color: "Cor"
    }
  }

  private var menuPage: some View {
    let c = theme.colors
    return ScrollView {
      VStack(spacing: 0) {
        HStack(spacing: 14) {
          Circle()
            .fill(AppColors.parseHex(selectedHex))
            .frame(width: 44, height: 44)
            .overlay {
              StackedIcons.image(ProjectIcons.asset(for: selectedIcon))
                .font(.system(size: 18))
                .foregroundStyle(c.textSecondary)
            }
          VStack(alignment: .leading, spacing: 4) {
            Text(displayName).font(AppTypography.bodySemibold).foregroundStyle(c.textPrimary)
            Text("Toque abaixo para editar").font(AppTypography.meta).foregroundStyle(c.textTertiary)
          }
          Spacer()
        }
        .padding(14)
        .background(c.surfaceVariant.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
        .padding(.bottom, 16)

        menuRow(icon: .text, label: "Nome", value: displayName) { page = .name }
        divider
        menuRow(icon: .grid, label: "Ícone", trailing: {
          RoundedRectangle(cornerRadius: 8)
            .fill(c.surfaceVariant.opacity(0.5))
            .frame(width: 32, height: 32)
            .overlay {
              StackedIcons.image(ProjectIcons.asset(for: selectedIcon))
                .font(.system(size: 14))
                .foregroundStyle(c.textSecondary)
            }
        }) { page = .icon }
        divider
        menuRow(icon: .paintbrush, label: "Cor", trailing: {
          Circle().fill(AppColors.parseHex(selectedHex)).frame(width: 22, height: 22)
            .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1.5))
        }) { page = .color }
        divider

        Button(role: .destructive) { showDeleteConfirm = true } label: {
          HStack(spacing: 12) {
            StackedIcons.image(.trash).frame(width: 20)
            Text("Excluir projeto")
            Spacer()
          }
          .font(AppTypography.popoverRowLabel)
          .padding(.horizontal, 20)
          .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var namePage: some View {
    let c = theme.colors
    return VStack(spacing: 16) {
      TextField("Nome do projeto", text: $name)
        .textFieldStyle(.plain)
        .font(AppTypography.fieldInput)
        .padding(14)
        .background(c.surfaceVariant)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.top, 12)
      Button("Salvar") { _Concurrency.Task { await persist(dismissToMenu: true) } }
        .font(AppTypography.bodySemibold)
        .foregroundStyle(c.accent)
      Spacer()
    }
  }

  private var iconPage: some View {
    let c = theme.colors
    return ScrollView {
      LazyVGrid(columns: columns, spacing: 12) {
        ForEach(ProjectIcons.pickerKeys, id: \.self) { key in
          let selected = selectedIcon == key
          Button {
            HapticService.selection()
            selectedIcon = key
            _Concurrency.Task { await persist(dismissToMenu: true) }
          } label: {
            RoundedRectangle(cornerRadius: 12)
              .fill(selected ? c.accent.opacity(0.15) : c.surfaceVariant.opacity(0.5))
              .frame(height: 48)
              .overlay {
                StackedIcons.image(ProjectIcons.asset(for: key))
                  .font(.system(size: 20))
                  .foregroundStyle(selected ? c.accent : c.textSecondary)
              }
              .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? c.accent.opacity(0.4) : .clear))
          }
          .buttonStyle(.plain)
        }
      }
      .padding(20)
    }
  }

  private var colorPage: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 10) {
        ForEach(PaletteColors.projectHex, id: \.self) { hex in
          let color = AppColors.parseHex(hex)
          Button {
            HapticService.selection()
            selectedHex = hex
            _Concurrency.Task { await persist(dismissToMenu: true) }
          } label: {
            Circle()
              .fill(color)
              .frame(height: 32)
              .overlay {
                if selectedHex == hex {
                  StackedIcons.image(.check).font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                }
              }
          }
          .buttonStyle(.plain)
        }
      }
      .padding(20)
    }
  }

  private var divider: some View {
    Rectangle().fill(theme.colors.surfaceVariant).frame(height: 1).padding(.leading, 52)
  }

  private func menuRow<Trailing: View>(
    icon: StackedIconKey,
    label: String,
    value: String? = nil,
    @ViewBuilder trailing: () -> Trailing = { EmptyView() },
    action: @escaping () -> Void
  ) -> some View {
    let c = theme.colors
    return Button(action: action) {
      HStack(spacing: 12) {
        StackedIcons.image(icon).font(.system(size: 18)).foregroundStyle(c.textSecondary).frame(width: 20)
        Text(label).font(AppTypography.popoverRowLabel).foregroundStyle(c.textPrimary)
        Spacer()
        if let value {
          Text(value).font(AppTypography.body).foregroundStyle(c.textTertiary).lineLimit(1)
        }
        trailing()
        StackedIcons.image(.chevronRight).font(.system(size: 11, weight: .semibold)).foregroundStyle(c.textTertiary)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 14)
    }
    .buttonStyle(.plain)
  }

  private func loadDetails() async {
    if let details = try? await ProjectRepository.shared.fetchProjectDetails(project.id) {
      if let n = details.name, !n.isEmpty { name = n }
      if let hex = details.colorHex { selectedHex = hex }
      if let icon = details.iconName { selectedIcon = icon }
    }
  }

  private func persist(dismissToMenu: Bool = false) async {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    saving = true
    defer { saving = false }
    do {
      try await ProjectRepository.shared.updateProject(
        id: project.id, name: trimmed, colorHex: selectedHex, iconKey: selectedIcon
      )
      HapticService.saved()
      onEdited()
      // SUBSTITUIDO_FASE2: if dismissToMenu { withAnimation { page = .menu } }
      if dismissToMenu { AppMotion.animate(AppMotion.smooth, reduceMotion: reduceMotion) { page = .menu } }
    } catch {
      self.error = error.localizedDescription
    }
  }

  private func deleteProject() async {
    do {
      try await ProjectRepository.shared.deleteProject(id: project.id)
      HapticService.taskDeleted()
      onDeleted()
      dismiss()
    } catch {
      self.error = error.localizedDescription
    }
  }

  private static func hexForProject(_ project: Project) -> String {
    PaletteColors.projectHex.first(where: { AppColors.parseHex($0) == project.color }) ?? PaletteColors.defaultHex
  }
}

private enum SheetPage { case menu, name, icon, color }

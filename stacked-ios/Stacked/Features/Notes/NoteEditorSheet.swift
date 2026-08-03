import SwiftUI

enum NoteEditorRoute: Identifiable {
  case create
  case edit(Note)

  var id: String {
    switch self {
    case .create: "create"
    case .edit(let note): note.id
    }
  }

  var existing: Note? {
    if case .edit(let note) = self { return note }
    return nil
  }
}

enum NoteTaskBridge {
  @MainActor
  static func convertToTask(_ note: Note) async throws {
    guard let userId = SupabaseService.client.auth.currentUser?.id else {
      throw NoteRepositoryError.notAuthenticated
    }
    let split = note.taskSplit
    let taskId = UUID().uuidString
    let input = TaskRepository.CreateTaskInput(
      title: split.title,
      description: split.description
    )
    try await TaskRepository.shared.insertTaskWithClientId(id: taskId, input: input, userId: userId)
    try await NoteRepository.shared.deleteNote(id: note.id)
  }
}

struct NoteEditorSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  let route: NoteEditorRoute
  var autofocusBody: Bool = false
  var onSaved: () -> Void
  var onConvertedToTask: () -> Void

  @State private var title: String
  @State private var bodyText: String
  @State private var color: NoteColor
  @State private var pinned: Bool
  @State private var saving = false
  @State private var error: String?
  @FocusState private var bodyFocused: Bool

  init(
    route: NoteEditorRoute,
    autofocusBody: Bool = false,
    onSaved: @escaping () -> Void,
    onConvertedToTask: @escaping () -> Void
  ) {
    self.route = route
    self.autofocusBody = autofocusBody
    self.onSaved = onSaved
    self.onConvertedToTask = onConvertedToTask
    let existing = route.existing
    _title = State(initialValue: existing?.title ?? "")
    _bodyText = State(initialValue: existing?.body ?? "")
    _color = State(initialValue: existing?.color ?? .mint)
    _pinned = State(initialValue: existing?.pinned ?? false)
  }

  private var canSave: Bool {
    let hasContent = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      || !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    return hasContent && !saving
  }

  var body: some View {
    let c = theme.colors

    NavigationStack {
      VStack(spacing: 0) {
        SheetDragHandle()

        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            TextField(
              "Título (opcional)",
              text: $title,
              prompt: Text("Título (opcional)").foregroundStyle(c.textTertiary)
            )
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(c.textPrimary)
            .tint(c.accent)

            TextField(
              "Escreva aqui…",
              text: $bodyText,
              prompt: Text("Escreva aqui…").foregroundStyle(c.textTertiary),
              axis: .vertical
            )
            .font(.system(size: 16))
            .foregroundStyle(c.textPrimary)
            .tint(c.accent)
            .lineLimit(8...20)
            .focused($bodyFocused)

            Text("Cor")
              .font(AppTypography.sectionLabel)
              .foregroundStyle(c.textTertiary)

            HStack(spacing: 10) {
              ForEach(NoteColor.allCases) { swatch in
                Button {
                  HapticService.selection()
                  color = swatch
                } label: {
                  Circle()
                    .fill(swatch.fill)
                    .frame(width: 32, height: 32)
                    .overlay {
                      if color == swatch {
                        Circle().strokeBorder(c.accent, lineWidth: 2)
                      }
                    }
                    .overlay {
                      Circle().strokeBorder(swatch.ink.opacity(0.25), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(swatch.label)
              }
            }

            Toggle(isOn: $pinned) {
              Text("Fixar no topo")
                .font(AppTypography.body)
                .foregroundStyle(c.textPrimary)
            }
            .tint(c.accent)

            if let error {
              Text(error)
                .font(AppTypography.meta)
                .foregroundStyle(AppColors.priorityHigh)
            }

            if route.existing != nil {
              VStack(spacing: 10) {
                Button {
                  _Concurrency.Task { await convertToTask() }
                } label: {
                  Text("Virar tarefa")
                    .font(AppTypography.bodySemibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(c.accent)
                    .background(c.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(saving)

                Button(role: .destructive) {
                  _Concurrency.Task { await deleteNote() }
                } label: {
                  Text("Excluir nota")
                    .font(AppTypography.bodySemibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .disabled(saving)
              }
              .padding(.top, 8)
            }
          }
          .padding(.horizontal, 20)
          .padding(.top, 8)
          .padding(.bottom, 24)
        }
      }
      .background(c.background)
      .navigationTitle(route.existing == nil ? "Nova nota" : "Editar nota")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        let isolate = GlassChromePreference.prefersStaticToolbarPills()
        ToolbarItem(id: "stacked-note-cancel", placement: .cancellationAction) {
          StackedToolbarTextButton(title: "Fechar") { dismiss() }
        }
        .stackedToolbarGlassIsolation(isolate)

        ToolbarItem(id: "stacked-note-save", placement: .confirmationAction) {
          StackedToolbarTextButton(title: "Pronto", accent: true, enabled: canSave) {
            _Concurrency.Task { await save() }
          }
        }
        .stackedToolbarGlassIsolation(isolate)
      }
      .task(id: autofocusBody) {
        guard autofocusBody else { return }
        // Sheet precisa assentar antes do focus — senão o teclado não sobe.
        try? await _Concurrency.Task.sleep(for: .milliseconds(350))
        guard !_Concurrency.Task.isCancelled else { return }
        bodyFocused = true
      }
    }
  }

  private func save() async {
    guard canSave else { return }
    saving = true
    defer { saving = false }
    do {
      if let existing = route.existing {
        try await NoteRepository.shared.updateNote(
          id: existing.id,
          title: title,
          body: bodyText,
          color: color,
          pinned: pinned
        )
      } else {
        _ = try await NoteRepository.shared.createNote(
          title: title,
          body: bodyText,
          color: color,
          pinned: pinned
        )
      }
      HapticService.saved()
      onSaved()
      dismiss()
    } catch {
      self.error = error.localizedDescription
    }
  }

  private func convertToTask() async {
    guard let existing = route.existing else { return }
    saving = true
    defer { saving = false }
    do {
      // Persiste edits locais antes de converter.
      try await NoteRepository.shared.updateNote(
        id: existing.id,
        title: title,
        body: bodyText,
        color: color,
        pinned: pinned
      )
      var snapshot = existing
      snapshot.title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : title
      snapshot.body = bodyText
      snapshot.color = color
      snapshot.pinned = pinned
      try await NoteTaskBridge.convertToTask(snapshot)
      HapticService.saved()
      onConvertedToTask()
      dismiss()
    } catch {
      self.error = error.localizedDescription
    }
  }

  private func deleteNote() async {
    guard let existing = route.existing else { return }
    saving = true
    defer { saving = false }
    do {
      try await NoteRepository.shared.deleteNote(id: existing.id)
      HapticService.taskDeleted()
      onSaved()
      dismiss()
    } catch {
      self.error = error.localizedDescription
    }
  }
}

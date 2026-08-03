import SwiftUI

struct NotesBoardView: View {
  @Environment(ThemeManager.self) private var theme
  @AppStorage(NotesDisplayModeStorage.key) private var displayModeRaw = NotesDisplayModeStorage.defaultRawValue

  @State private var notes: [Note] = []
  @State private var loading = true
  @State private var error: String?
  @State private var editorRoute: NoteEditorRoute?
  @State private var convertError: String?

  private var displayMode: NotesDisplayMode {
    NotesDisplayModeStorage.mode(from: displayModeRaw)
  }

  var body: some View {
    let c = theme.colors

    Group {
      if loading && notes.isEmpty {
        ProgressView().tint(c.accent)
      } else if let error, notes.isEmpty {
        LoadErrorView(message: error) {
          _Concurrency.Task { await load() }
        }
      } else if notes.isEmpty {
        EmptyStateView(
          illustration: .labelsEmpty,
          title: "Nenhuma nota ainda",
          subtitle: "Capture ideias soltas. Depois você pode virar tarefa."
        )
        .stackedStandaloneEmptyState()
      } else if displayMode == .mural {
        muralScroll
      } else {
        listScroll
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(c.background)
    .stackedTabletCentered()
    .navigationTitle("Notas")
    .navigationBarTitleDisplayMode(.inline)
    .stackedAdaptiveDrillDownBack()
    .toolbar {
      let isolate = GlassChromePreference.prefersStaticToolbarPills()
      ToolbarItem(id: "stacked-notes-mode", placement: .topBarTrailing) {
        Button {
          HapticService.selection()
          displayModeRaw = displayMode == .mural
            ? NotesDisplayMode.list.rawValue
            : NotesDisplayMode.mural.rawValue
        } label: {
          StackedIcons.image(displayMode == .mural ? .list : .grid)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(c.accent)
        }
        .accessibilityLabel(displayMode == .mural ? "Ver lista" : "Ver mural")
      }
      .stackedToolbarGlassIsolation(isolate)

      ToolbarItem(id: "stacked-notes-add", placement: .topBarTrailing) {
        StackedToolbarIconButton(icon: .plus, accessibilityLabel: "Nova nota", accent: true) {
          editorRoute = .create
        }
      }
      .stackedToolbarGlassIsolation(isolate)
    }
    .refreshable { await load() }
    .task { await load() }
    .onReceive(NotificationCenter.default.publisher(for: .notesDidChange)) { _ in
      _Concurrency.Task { await load() }
    }
    .sheet(item: $editorRoute) { route in
      NoteEditorSheet(
        route: route,
        onSaved: { _Concurrency.Task { await load() } },
        onConvertedToTask: { _Concurrency.Task { await load() } }
      )
      .environment(theme)
      .presentationDetents([.large])
      .stackedEditableSheetPresentation(background: theme.colors.background)
    }
    .alert("Não foi possível criar a tarefa", isPresented: Binding(
      get: { convertError != nil },
      set: { if !$0 { convertError = nil } }
    )) {
      Button("OK", role: .cancel) { convertError = nil }
    } message: {
      Text(convertError ?? "")
    }
  }

  private var muralScroll: some View {
    ScrollView {
      LazyVGrid(
        columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
        spacing: 10
      ) {
        ForEach(notes) { note in
          Button {
            editorRoute = .edit(note)
          } label: {
            NoteStickyCard(note: note, compact: false)
          }
          .buttonStyle(.plain)
          .contextMenu { noteContextMenu(note) }
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 8)
      .padding(.bottom, 100)
    }
  }

  private var listScroll: some View {
    List {
      Section {
        ForEach(notes) { note in
          Button {
            editorRoute = .edit(note)
          } label: {
            NoteListRow(note: note)
          }
          .buttonStyle(.plain)
          .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
          .contextMenu { noteContextMenu(note) }
        }
      }
      Section {
        ListTailSpacer()
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }

  @ViewBuilder
  private func noteContextMenu(_ note: Note) -> some View {
    Button {
      _Concurrency.Task { await togglePin(note) }
    } label: {
      Label(note.pinned ? "Desafixar" : "Fixar", systemImage: note.pinned ? "pin.slash" : "pin")
    }
    Button {
      editorRoute = .edit(note)
    } label: {
      Label("Editar", systemImage: "pencil")
    }
    Button {
      _Concurrency.Task { await convertToTask(note) }
    } label: {
      Label("Virar tarefa", systemImage: "checkmark.circle")
    }
    Button(role: .destructive) {
      _Concurrency.Task { await deleteNote(note) }
    } label: {
      Label("Excluir", systemImage: "trash")
    }
  }

  private func load() async {
    if notes.isEmpty { loading = true }
    defer { loading = false }
    do {
      notes = try await NoteRepository.shared.fetchNotes()
      error = nil
    } catch {
      self.error = error.localizedDescription
    }
  }

  private func togglePin(_ note: Note) async {
    do {
      try await NoteRepository.shared.setPinned(id: note.id, pinned: !note.pinned)
      HapticService.selection()
      await load()
    } catch {
      convertError = error.localizedDescription
    }
  }

  private func deleteNote(_ note: Note) async {
    notes.removeAll { $0.id == note.id }
    do {
      try await NoteRepository.shared.deleteNote(id: note.id)
      HapticService.taskDeleted()
    } catch {
      await load()
      convertError = error.localizedDescription
    }
  }

  private func convertToTask(_ note: Note) async {
    do {
      try await NoteTaskBridge.convertToTask(note)
      notes.removeAll { $0.id == note.id }
      HapticService.saved()
    } catch {
      convertError = error.localizedDescription
      await load()
    }
  }
}

// MARK: - Cards

private struct NoteStickyCard: View {
  let note: Note
  var compact: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top) {
        if note.pinned {
          Image(systemName: "pin.fill")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(note.color.ink.opacity(0.55))
        }
        Spacer(minLength: 0)
        Circle()
          .fill(note.color.ink.opacity(0.18))
          .frame(width: 8, height: 8)
      }

      Text(note.displayTitle)
        .font(.system(size: compact ? 14 : 14.5, weight: .semibold))
        .foregroundStyle(note.color.ink)
        .lineLimit(compact ? 3 : 5)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)

      if !noteBodySecondary.isEmpty {
        Text(noteBodySecondary)
          .font(.system(size: 12.5))
          .foregroundStyle(note.color.ink.opacity(0.72))
          .lineLimit(compact ? 2 : 4)
          .multilineTextAlignment(.leading)
      }

      Spacer(minLength: 0)

      Text(Self.relativeLabel(note.updatedAt))
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(note.color.ink.opacity(0.45))
    }
    .padding(12)
    .frame(maxWidth: .infinity, minHeight: compact ? 96 : 120, alignment: .topLeading)
    .background(note.color.fill)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .shadow(color: .black.opacity(0.28), radius: 10, y: 6)
    .rotationEffect(.degrees(note.color.muralRotation))
  }

  private var noteBodySecondary: String {
    let t = note.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !t.isEmpty else { return "" }
    return note.body.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private static func relativeLabel(_ date: Date) -> String {
    let cal = Calendar.current
    if cal.isDateInToday(date) { return "hoje" }
    if cal.isDateInYesterday(date) { return "ontem" }
    let f = DateFormatter()
    f.locale = Locale(identifier: "pt_BR")
    f.dateFormat = "EEE"
    return f.string(from: date).lowercased()
  }
}

private struct NoteListRow: View {
  let note: Note

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      RoundedRectangle(cornerRadius: 4, style: .continuous)
        .fill(note.color.fill)
        .frame(width: 4)
        .padding(.vertical, 2)

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          if note.pinned {
            Image(systemName: "pin.fill")
              .font(.system(size: 10, weight: .bold))
              .foregroundStyle(ThemeManager.shared.colors.textTertiary)
          }
          Text(note.displayTitle)
            .font(AppTypography.bodySemibold)
            .foregroundStyle(ThemeManager.shared.colors.textPrimary)
            .lineLimit(1)
        }
        let secondary: String = {
          let t = note.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
          let b = note.body.trimmingCharacters(in: .whitespacesAndNewlines)
          if !t.isEmpty { return b }
          // Sem título: preview = resto depois da 1ª linha
          let lines = b.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
          return lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }()
        if !secondary.isEmpty {
          Text(secondary)
            .font(AppTypography.meta)
            .foregroundStyle(ThemeManager.shared.colors.textTertiary)
            .lineLimit(2)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background(ThemeManager.shared.colors.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
  }
}

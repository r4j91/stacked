import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import QuickLook
import Hugeicons

enum AttachmentPickRequest: Equatable {
  case photo
  case file
}

/// Lista de anexos no padrão Subtarefas/Comentários (título bold + chevron).
struct AttachmentsSection: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let taskId: String
  var subtaskId: String? = nil
  @Binding var expanded: Bool
  /// Pai (pílula Anexo) define `.photo` / `.file` após o popover.
  @Binding var pickRequest: AttachmentPickRequest?

  @State private var items: [TaskAttachment] = []
  @State private var busy = false
  @State private var errorMessage: String?
  @State private var showPhotosPicker = false
  @State private var photoItems: [PhotosPickerItem] = []
  @State private var showFileImporter = false
  @State private var previewURL: URL?

  var body: some View {
    let c = theme.colors
    VStack(alignment: .leading, spacing: 10) {
      Button {
        HapticService.selection()
        withAnimation(AppMotion.subtaskExpand(reduceMotion: reduceMotion)) {
          expanded.toggle()
        }
      } label: {
        HStack(spacing: 8) {
          Text("Anexos")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(c.textPrimary)

          if !items.isEmpty {
            Text("\(items.count)")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(c.textSecondary)
              .padding(.horizontal, 7)
              .padding(.vertical, 2)
              .background(c.accent.opacity(0.12))
              .clipShape(Capsule())
          }

          Spacer(minLength: 0)

          SubtaskExpandChevron(expanded: expanded, size: 14)
        }
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(expanded ? "Recolher anexos" : "Expandir anexos")

      if let errorMessage {
        Text(errorMessage)
          .font(.system(size: 12))
          .foregroundStyle(AppColors.priorityHigh)
          .padding(.horizontal, 4)
      }

      if expanded {
        VStack(spacing: 0) {
          if items.isEmpty {
            Text("Nenhum anexo")
              .font(.system(size: 13))
              .foregroundStyle(c.textTertiary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 16)
              .padding(.vertical, 14)
          } else {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
              if index > 0 {
                Rectangle()
                  .fill(c.textTertiary.opacity(0.1))
                  .frame(height: 1)
                  .padding(.leading, 16)
                  .padding(.trailing, 16)
              }
              attachmentRow(item, colors: c)
            }
          }

          if !items.isEmpty {
            Rectangle()
              .fill(c.textTertiary.opacity(0.1))
              .frame(height: 1)
              .padding(.leading, 16)
              .padding(.trailing, 16)
          }

          AnchoredTapButton { rect in
            presentAttachmentSourceMenu(anchor: rect) { request in
              applyPickRequest(request)
            }
          } label: {
            HStack(spacing: 8) {
              StackedIcons.icon(.plus, size: 14, color: c.accent)
              Text("Adicionar anexo…")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(c.accent)
              Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
          }
          .disabled(busy)
        }
        .background(c.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(c.textPrimary.opacity(0.06)))
      }
    }
    .task { await reload() }
    .onChange(of: pickRequest) { _, request in
      guard let request else { return }
      applyPickRequest(request)
      pickRequest = nil
    }
    .photosPicker(
      isPresented: $showPhotosPicker,
      selection: $photoItems,
      maxSelectionCount: 5,
      matching: .images
    )
    .onChange(of: photoItems) { _, newItems in
      guard !newItems.isEmpty else { return }
      _Concurrency.Task {
        await uploadPhotos(newItems)
        photoItems = []
      }
    }
    .fileImporter(
      isPresented: $showFileImporter,
      allowedContentTypes: [.pdf, .image, .jpeg, .png, .webP, .heic],
      allowsMultipleSelection: true
    ) { result in
      switch result {
      case .success(let urls):
        _Concurrency.Task { await uploadFiles(urls) }
      case .failure(let error):
        errorMessage = error.localizedDescription
      }
    }
    .quickLookPreview($previewURL)
  }

  private func applyPickRequest(_ request: AttachmentPickRequest) {
    switch request {
    case .photo:
      showPhotosPicker = true
    case .file:
      showFileImporter = true
    }
  }

  private func attachmentRow(_ item: TaskAttachment, colors: AppThemeColors) -> some View {
    HStack(spacing: 10) {
      Button {
        _Concurrency.Task { await open(item) }
      } label: {
        HStack(spacing: 10) {
          StackedIcons.icon(.attachment, size: 16, color: colors.textSecondary)
          VStack(alignment: .leading, spacing: 2) {
            Text(item.fileName)
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(colors.textPrimary)
              .lineLimit(1)
            Text("\(item.isImage ? "Imagem" : "PDF") · \(item.sizeLabel)")
              .font(.system(size: 11))
              .foregroundStyle(colors.textTertiary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      Button {
        _Concurrency.Task { await remove(item) }
      } label: {
        StackedIcons.icon(.close, size: 14, color: colors.textTertiary)
          .frame(width: 28, height: 28)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .disabled(busy)
      .accessibilityLabel("Excluir \(item.fileName)")
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }

  private func reload() async {
    do {
      if let subtaskId {
        items = try await AttachmentRepository.shared.listForSubtask(subtaskId: subtaskId)
      } else {
        items = try await AttachmentRepository.shared.listForTask(taskId: taskId)
      }
      errorMessage = nil
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func uploadPhotos(_ pickerItems: [PhotosPickerItem]) async {
    busy = true
    defer { busy = false }
    do {
      for item in pickerItems {
        guard let data = try await item.loadTransferable(type: Data.self) else { continue }
        _ = try await AttachmentRepository.shared.upload(
          taskId: taskId,
          subtaskId: subtaskId,
          data: data,
          fileName: "foto-\(UUID().uuidString.prefix(8)).jpg",
          mimeType: "image/jpeg"
        )
      }
      await reload()
      if !items.isEmpty {
        withAnimation(AppMotion.subtaskExpand(reduceMotion: reduceMotion)) {
          expanded = true
        }
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func uploadFiles(_ urls: [URL]) async {
    busy = true
    defer { busy = false }
    do {
      for url in urls {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let mime = mimeType(for: url) ?? "application/octet-stream"
        _ = try await AttachmentRepository.shared.upload(
          taskId: taskId,
          subtaskId: subtaskId,
          data: data,
          fileName: url.lastPathComponent,
          mimeType: mime
        )
      }
      await reload()
      if !items.isEmpty {
        withAnimation(AppMotion.subtaskExpand(reduceMotion: reduceMotion)) {
          expanded = true
        }
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func open(_ item: TaskAttachment) async {
    do {
      let remote = try await AttachmentRepository.shared.signedURL(for: item.storagePath)
      let (data, _) = try await URLSession.shared.data(from: remote)
      let temp = FileManager.default.temporaryDirectory
        .appendingPathComponent(item.fileName)
      try data.write(to: temp, options: .atomic)
      previewURL = temp
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func remove(_ item: TaskAttachment) async {
    busy = true
    defer { busy = false }
    do {
      try await AttachmentRepository.shared.remove(item)
      items.removeAll { $0.id == item.id }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func mimeType(for url: URL) -> String? {
    if let type = UTType(filenameExtension: url.pathExtension) {
      if type.conforms(to: .pdf) { return "application/pdf" }
      if type.conforms(to: .jpeg) { return "image/jpeg" }
      if type.conforms(to: .png) { return "image/png" }
      if type.conforms(to: .webP) { return "image/webp" }
      if type.conforms(to: .heic) { return "image/heic" }
      if type.conforms(to: .image) { return "image/jpeg" }
    }
    return nil
  }
}

@MainActor
func presentAttachmentSourceMenu(
  anchor: CGRect,
  onSelect: @escaping (AttachmentPickRequest) -> Void
) {
  presentAnchoredPopover(
    anchorRect: anchor,
    items: [
      PopoverMenuItem(id: "photo", icon: Hugeicons.image01, label: "Foto da biblioteca"),
      PopoverMenuItem(id: "file", icon: Hugeicons.pdf01, label: "Arquivo (PDF ou imagem)"),
    ]
  ) { result in
    guard let result else { return }
    switch result {
    case "photo": onSelect(.photo)
    case "file": onSelect(.file)
    default: break
    }
  }
}

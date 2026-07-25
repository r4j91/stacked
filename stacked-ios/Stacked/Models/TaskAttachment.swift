import Foundation

struct TaskAttachment: Identifiable, Equatable, Sendable {
  let id: String
  let taskId: String
  let subtaskId: String?
  let fileName: String
  let mimeType: String
  let sizeBytes: Int64
  let storagePath: String
  let createdAt: String

  var isImage: Bool { mimeType.hasPrefix("image/") }
  var isPDF: Bool { mimeType == "application/pdf" }

  var sizeLabel: String {
    if sizeBytes < 1024 { return "\(sizeBytes) B" }
    if sizeBytes < 1024 * 1024 { return "\(sizeBytes / 1024) KB" }
    let mb = Double(sizeBytes) / (1024 * 1024)
    return String(format: "%.1f MB", mb)
  }
}

enum AttachmentLimits {
  static let maxBytes: Int64 = 20 * 1024 * 1024

  static func isAllowedMime(_ mime: String) -> Bool {
    mime.hasPrefix("image/") || mime == "application/pdf"
  }
}

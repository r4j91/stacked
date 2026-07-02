import Foundation

struct ProjectSection: Identifiable, Equatable {
  let id: String
  let projectId: String
  let name: String
  let order: Int
}

struct SectionRowDTO: Decodable {
  let id: String
  let project_id: String
  let name: String
  let order: Int?

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    if let s = try? c.decode(String.self, forKey: .id) { id = s }
    else { id = try c.decode(UUID.self, forKey: .id).uuidString }
    if let s = try? c.decode(String.self, forKey: .project_id) { project_id = s }
    else { project_id = try c.decode(UUID.self, forKey: .project_id).uuidString }
    name = try c.decode(String.self, forKey: .name)
    order = try c.decodeIfPresent(Int.self, forKey: .order)
  }

  private enum CodingKeys: String, CodingKey {
    case id, project_id, name, order
  }

  var model: ProjectSection {
    ProjectSection(id: id, projectId: project_id, name: name, order: order ?? 0)
  }
}

import SwiftUI

struct Project: Identifiable, Equatable {
  let id: String
  let name: String
  let color: Color

  init(id: String, name: String, color: Color) {
    self.id = id
    self.name = name
    self.color = color
  }

  init(row: ProjectRowDTO) {
    id = row.id
    name = row.nome ?? ""
    color = AppColors.parseHex(row.cor, fallback: Color(hex: 0x5FD3DC))
  }
}

struct ProjectRowDTO: Decodable {
  let id: String
  let nome: String?
  let cor: String?
  let icone: String?

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    if let s = try? c.decode(String.self, forKey: .id) {
      id = s
    } else {
      id = try c.decode(UUID.self, forKey: .id).uuidString
    }
    nome = try c.decodeIfPresent(String.self, forKey: .nome)
    cor = try c.decodeIfPresent(String.self, forKey: .cor)
    icone = try c.decodeIfPresent(String.self, forKey: .icone)
  }

  private enum CodingKeys: String, CodingKey { case id, nome, cor, icone }
}

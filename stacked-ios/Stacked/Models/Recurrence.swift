import Foundation

// Paridade lib/models/recurrence.dart (subset para exibição e picker básico)
enum RecurrenceType: String, CaseIterable {
  case daily
  case weekly
  case monthly
  case yearly

  var displayLabel: String {
    switch self {
    case .daily: "Todo dia"
    case .weekly: "Toda semana"
    case .monthly: "Todo mês"
    case .yearly: "Todo ano"
    }
  }

  var jsonTipo: String {
    switch self {
    case .daily: "diario"
    case .weekly: "semanal"
    case .monthly: "mensal"
    case .yearly: "anual"
    }
  }

  static func fromJsonTipo(_ raw: String) -> RecurrenceType? {
    switch raw {
    case "diario", "daily": .daily
    case "semanal", "weekly": .weekly
    case "mensal", "monthly": .monthly
    case "anual", "yearly": .yearly
    default: nil
    }
  }
}

enum RecurrenceCodec {
  static func displayLabel(for json: String?) -> String {
    guard let json, !json.isEmpty,
          let data = json.data(using: .utf8),
          let map = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let tipo = map["tipo"] as? String,
          let type = RecurrenceType.fromJsonTipo(tipo)
    else { return "Nenhuma" }
    return type.displayLabel
  }

  static func type(from json: String?) -> RecurrenceType? {
    guard let json, !json.isEmpty,
          let data = json.data(using: .utf8),
          let map = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let tipo = map["tipo"] as? String
    else { return nil }
    return RecurrenceType.fromJsonTipo(tipo)
  }

  static func json(for type: RecurrenceType?) -> String? {
    guard let type else { return nil }
    let map: [String: String] = ["tipo": type.jsonTipo]
    guard let data = try? JSONSerialization.data(withJSONObject: map),
          let str = String(data: data, encoding: .utf8)
    else { return nil }
    return str
  }
}

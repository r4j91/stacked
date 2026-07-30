import Foundation

/// Ordem de etiquetas no card: última tocada/aplicada primeiro (MRU).
enum LabelIdOrder {
  /// Liga → vai para o início; desliga → remove. Demais mantêm a ordem relativa.
  static func toggle(_ ids: [String], id: String) -> [String] {
    if ids.contains(id) {
      return ids.filter { $0 != id }
    }
    return [id] + ids.filter { $0 != id }
  }

  /// Resolve catálogo na ordem dos ids (não na ordem do catálogo).
  static func resolve<T>(_ ids: [String], from catalog: [T], id: (T) -> String) -> [T] {
    ids.compactMap { wanted in catalog.first(where: { id($0) == wanted }) }
  }
}

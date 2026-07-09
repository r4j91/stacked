import Foundation

enum CalendarPreferences {
  static let importEnabledKey = "calendar_import_enabled"
  static let exportEnabledKey = "calendar_export_enabled"
  static let exportAsAllDayKey = "calendar_export_as_all_day"
  static let selectedCalendarIDsKey = "calendar_import_calendar_ids"

  static var importEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: importEnabledKey) }
    set { UserDefaults.standard.set(newValue, forKey: importEnabledKey) }
  }

  static var exportEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: exportEnabledKey) }
    set { UserDefaults.standard.set(newValue, forKey: exportEnabledKey) }
  }

  /// Evento curto no Calendário — bloco compacto, sem faixa longa de horário.
  static var exportAsAllDay: Bool {
    get { UserDefaults.standard.bool(forKey: exportAsAllDayKey) }
    set { UserDefaults.standard.set(newValue, forKey: exportAsAllDayKey) }
  }

  static var selectedCalendarIDs: Set<String> {
    get {
      let ids = UserDefaults.standard.stringArray(forKey: selectedCalendarIDsKey) ?? []
      return Set(ids)
    }
    set {
      UserDefaults.standard.set(Array(newValue), forKey: selectedCalendarIDsKey)
    }
  }
}

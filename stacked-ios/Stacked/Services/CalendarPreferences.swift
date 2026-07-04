import Foundation

enum CalendarPreferences {
  static let importEnabledKey = "calendar_import_enabled"
  static let exportEnabledKey = "calendar_export_enabled"
  static let selectedCalendarIDsKey = "calendar_import_calendar_ids"

  static var importEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: importEnabledKey) }
    set { UserDefaults.standard.set(newValue, forKey: importEnabledKey) }
  }

  static var exportEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: exportEnabledKey) }
    set { UserDefaults.standard.set(newValue, forKey: exportEnabledKey) }
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

import Foundation

enum CurrencyFormat {
  static func brl(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "pt_BR")
    formatter.currencyCode = "BRL"
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "R$ %.2f", value)
  }
}

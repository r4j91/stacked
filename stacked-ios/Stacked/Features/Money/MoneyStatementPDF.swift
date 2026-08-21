import SwiftUI
import UIKit

enum MoneyStatementPDF {
  static func fileURL(for statement: MoneyMonthStatement) -> URL? {
    let safe = statement.account.name
      .replacingOccurrences(of: "/", with: "-")
      .replacingOccurrences(of: ":", with: "-")
    let period = statement.invoiceDueDate.map { MoneyCalendar.monthId(for: $0) }
      ?? MoneyCalendar.monthId(for: statement.monthStart)
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("Extrato-\(safe)-\(period).pdf")
    let renderer = UIGraphicsPDFRenderer(bounds: MoneyPDF.page)
    do {
      try renderer.writePDF(to: url) { ctx in
        draw(statement, ctx: ctx)
      }
      return url
    } catch {
      return nil
    }
  }

  private static func draw(_ statement: MoneyMonthStatement, ctx: UIGraphicsPDFRendererContext) {
    var y: CGFloat = 0
    var pageNumber = 1
    let caption = "\(statement.account.name)  ·  \(statement.periodTitle)"
    let cols = StatementColumns(amountLabel: statement.amountLabel)

    func startPage(continuation: Bool) {
      ctx.beginPage()
      MoneyPDF.drawTopBar()
      y = MoneyPDF.margin
      if continuation {
        MoneyPDF.text(
          caption,
          x: MoneyPDF.contentMinX,
          y: y,
          width: MoneyPDF.contentWidth - 90,
          font: .systemFont(ofSize: 11, weight: .semibold),
          color: MoneyPDF.ink
        )
        MoneyPDF.text(
          "Continuação",
          x: MoneyPDF.contentMaxX - 90,
          y: y,
          width: 90,
          font: .systemFont(ofSize: 10, weight: .medium),
          color: MoneyPDF.muted,
          align: .right
        )
        y += 20
        MoneyPDF.rule(y: y)
        y += 16
        drawTableHeader(cols, y: &y)
      } else {
        drawCoverHeader(statement, y: &y)
        drawSummary(statement, y: &y)
        MoneyPDF.label(
          statement.usesInvoiceCycle ? "Nesta fatura" : "Lançamentos",
          x: MoneyPDF.contentMinX,
          y: y,
          width: 200
        )
        y += 18
        drawTableHeader(cols, y: &y)
      }
    }

    func newPageIfNeeded(_ needed: CGFloat) {
      if y + needed > MoneyPDF.page.height - MoneyPDF.footerReserve {
        MoneyPDF.drawFooter(page: pageNumber)
        pageNumber += 1
        startPage(continuation: true)
      }
    }

    startPage(continuation: false)

    if statement.lines.isEmpty {
      newPageIfNeeded(28)
      MoneyPDF.text(
        "Nenhum lançamento neste período.",
        x: cols.desc,
        y: y + 4,
        width: cols.descWidth,
        font: .systemFont(ofSize: 11),
        color: MoneyPDF.muted
      )
      y += 28
    } else {
      for (index, line) in statement.lines.enumerated() {
        newPageIfNeeded(StatementColumns.rowHeight)
        drawLine(line, cols: cols, y: y, striped: index.isMultiple(of: 2))
        y += StatementColumns.rowHeight
      }
    }

    newPageIfNeeded(92)
    y += 10
    MoneyPDF.rule(y: y)
    y += 16
    drawTotals(statement, cols: cols, y: &y)
    MoneyPDF.drawFooter(page: pageNumber)
  }

  private static func drawCoverHeader(_ statement: MoneyMonthStatement, y: inout CGFloat) {
    MoneyPDF.brandMark(x: MoneyPDF.contentMinX, y: y)
    MoneyPDF.text(
      statement.periodTitle,
      x: MoneyPDF.contentMaxX - 220,
      y: y,
      width: 220,
      font: .systemFont(ofSize: 11, weight: .semibold),
      color: MoneyPDF.ink,
      align: .right
    )
    y += 22
    MoneyPDF.rule(y: y)
    y += 18
    MoneyPDF.text(
      statement.account.name,
      x: MoneyPDF.contentMinX,
      y: y,
      width: MoneyPDF.contentWidth,
      font: .systemFont(ofSize: 24, weight: .bold),
      color: MoneyPDF.ink,
      height: 30
    )
    y += 32
    MoneyPDF.text(
      "Extrato  ·  \(statement.account.kind.label)",
      x: MoneyPDF.contentMinX,
      y: y,
      width: MoneyPDF.contentWidth,
      font: .systemFont(ofSize: 11, weight: .medium),
      color: MoneyPDF.muted
    )
    y += 16
    if let caption = statement.periodCaption {
      let extra = [caption, statement.dueCaption].compactMap { $0 }.joined(separator: "  ·  ")
      MoneyPDF.text(
        extra,
        x: MoneyPDF.contentMinX,
        y: y,
        width: MoneyPDF.contentWidth,
        font: .systemFont(ofSize: 11, weight: .medium),
        color: MoneyPDF.muted
      )
      y += 16
    }
    y += 12
  }

  private static func drawSummary(_ statement: MoneyMonthStatement, y: inout CGFloat) {
    let items: [(String, String, UIColor)] = [
      ("\(statement.amountLabel) inicial", CurrencyFormat.brl(statement.opening), MoneyPDF.ink),
      ("Entradas", "+\(CurrencyFormat.brl(statement.income))", MoneyPDF.accent),
      ("Saídas", "−\(CurrencyFormat.brl(statement.expense))", MoneyPDF.ink),
      ("\(statement.amountLabel) final", CurrencyFormat.brl(statement.closing), MoneyPDF.ink),
    ]
    let height: CGFloat = 56
    let rect = CGRect(x: MoneyPDF.contentMinX, y: y, width: MoneyPDF.contentWidth, height: height)
    UIBezierPath(roundedRect: rect, cornerRadius: 10).fill(with: MoneyPDF.band)
    let colW = MoneyPDF.contentWidth / CGFloat(items.count)
    for (index, item) in items.enumerated() {
      let x = MoneyPDF.contentMinX + colW * CGFloat(index)
      if index > 0 {
        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: x, y: y + 12))
        divider.addLine(to: CGPoint(x: x, y: y + height - 12))
        MoneyPDF.ruleColor.setStroke()
        divider.lineWidth = 0.5
        divider.stroke()
      }
      MoneyPDF.label(item.0, x: x + 14, y: y + 11, width: colW - 28)
      MoneyPDF.text(
        item.1,
        x: x + 14,
        y: y + 26,
        width: colW - 28,
        font: .monospacedDigitSystemFont(ofSize: 12, weight: .semibold),
        color: item.2
      )
    }
    y += height + 28
  }

  private static func drawTableHeader(_ cols: StatementColumns, y: inout CGFloat) {
    MoneyPDF.label("Data", x: cols.date, y: y, width: cols.dateWidth)
    MoneyPDF.label("Descrição", x: cols.desc, y: y, width: cols.descWidth)
    MoneyPDF.label("Entrada", x: cols.income, y: y, width: cols.moneyWidth, align: .right)
    MoneyPDF.label("Saída", x: cols.expense, y: y, width: cols.moneyWidth, align: .right)
    MoneyPDF.label(cols.amountLabel, x: cols.running, y: y, width: cols.runningWidth, align: .right)
    y += 14
    MoneyPDF.rule(y: y)
    y += 6
  }

  private static func drawLine(
    _ line: MoneyStatementLine,
    cols: StatementColumns,
    y: CGFloat,
    striped: Bool
  ) {
    if striped {
      let row = CGRect(
        x: MoneyPDF.contentMinX,
        y: y,
        width: MoneyPDF.contentWidth,
        height: StatementColumns.rowHeight
      )
      UIBezierPath(roundedRect: row, cornerRadius: 4).fill(with: MoneyPDF.stripe)
    }
    let textY = y + 6
    MoneyPDF.text(
      line.dayLabel,
      x: cols.date,
      y: textY,
      width: cols.dateWidth,
      font: .systemFont(ofSize: 10),
      color: MoneyPDF.muted
    )
    MoneyPDF.text(
      line.caption.map { "\(line.title)  ·  \($0)" } ?? line.title,
      x: cols.desc,
      y: textY,
      width: cols.descWidth,
      font: .systemFont(ofSize: 10.5, weight: .medium),
      color: MoneyPDF.ink
    )
    if line.isIncome {
      MoneyPDF.money(CurrencyFormat.brl(line.amount), x: cols.income, y: textY, width: cols.moneyWidth, color: MoneyPDF.accent)
    } else {
      MoneyPDF.money(CurrencyFormat.brl(line.amount), x: cols.expense, y: textY, width: cols.moneyWidth, color: MoneyPDF.ink)
    }
    MoneyPDF.money(CurrencyFormat.brl(line.running), x: cols.running, y: textY, width: cols.runningWidth, color: MoneyPDF.ink)
  }

  private static func drawTotals(_ statement: MoneyMonthStatement, cols: StatementColumns, y: inout CGFloat) {
    MoneyPDF.text("Entradas", x: cols.desc, y: y, width: cols.descWidth, font: .systemFont(ofSize: 11), color: MoneyPDF.muted)
    MoneyPDF.money(
      CurrencyFormat.brl(statement.income),
      x: cols.income,
      y: y,
      width: cols.moneyWidth,
      color: MoneyPDF.accent,
      weight: .medium
    )
    y += 18
    MoneyPDF.text("Saídas", x: cols.desc, y: y, width: cols.descWidth, font: .systemFont(ofSize: 11), color: MoneyPDF.muted)
    MoneyPDF.money(
      CurrencyFormat.brl(statement.expense),
      x: cols.expense,
      y: y,
      width: cols.moneyWidth,
      color: MoneyPDF.ink,
      weight: .medium
    )
    y += 20
    MoneyPDF.text(
      "\(statement.amountLabel) final",
      x: cols.desc,
      y: y,
      width: cols.descWidth,
      font: .systemFont(ofSize: 12, weight: .semibold),
      color: MoneyPDF.ink
    )
    MoneyPDF.money(
      CurrencyFormat.brl(statement.closing),
      x: cols.running,
      y: y,
      width: cols.runningWidth,
      color: MoneyPDF.ink,
      weight: .semibold,
      size: 12
    )
  }

  private struct StatementColumns {
    static let rowHeight: CGFloat = 24
    let amountLabel: String
    let date: CGFloat
    let dateWidth: CGFloat = 52
    let desc: CGFloat
    let descWidth: CGFloat
    let income: CGFloat
    let expense: CGFloat
    let running: CGFloat
    let moneyWidth: CGFloat = 78
    let runningWidth: CGFloat = 92

    init(amountLabel: String) {
      self.amountLabel = amountLabel
      date = MoneyPDF.contentMinX
      desc = date + dateWidth + 10
      running = MoneyPDF.contentMaxX - runningWidth
      expense = running - 8 - moneyWidth
      income = expense - 8 - moneyWidth
      descWidth = income - 10 - desc
    }
  }
}

enum MoneySharePresenter {
  @MainActor
  static func present(_ url: URL) {
    let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController ?? scene.windows.first?.rootViewController
    else { return }
    var top = root
    while let presented = top.presentedViewController {
      top = presented
    }
    if let popover = controller.popoverPresentationController {
      popover.sourceView = top.view
      popover.sourceRect = CGRect(x: top.view.bounds.midX, y: 48, width: 1, height: 1)
    }
    top.present(controller, animated: true)
  }
}

enum MoneyDuePDF {
  static func fileURL(for group: MoneyMonthGroup, income: Bool = false) -> URL? {
    write(title: periodTitle(for: group), months: [group], income: income)
  }

  static func fileURL(year: Int, months: [MoneyMonthGroup], income: Bool = false) -> URL? {
    write(title: "\(year)", months: months, income: income)
  }

  private static func periodTitle(for group: MoneyMonthGroup) -> String {
    if let year = group.year {
      return "\(group.title) \(year)"
    }
    return group.title
  }

  private static func write(title: String, months: [MoneyMonthGroup], income: Bool) -> URL? {
    let heading = income ? "A receber" : "A pagar"
    let safe = title
      .replacingOccurrences(of: "/", with: "-")
      .replacingOccurrences(of: ":", with: "-")
    let slug = income ? "A-receber" : "A-pagar"
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("\(slug)-\(safe).pdf")
    let renderer = UIGraphicsPDFRenderer(bounds: MoneyPDF.page)
    do {
      try renderer.writePDF(to: url) { ctx in
        let flow = MoneyPDFFlow()
        let caption = "\(heading)  ·  \(title)"
        let cols = DueColumns()

        func startPage(continuation: Bool) {
          ctx.beginPage()
          MoneyPDF.drawTopBar()
          flow.y = MoneyPDF.margin
          if continuation {
            MoneyPDF.text(
              caption,
              x: MoneyPDF.contentMinX,
              y: flow.y,
              width: MoneyPDF.contentWidth - 90,
              font: .systemFont(ofSize: 11, weight: .semibold),
              color: MoneyPDF.ink
            )
            MoneyPDF.text(
              "Continuação",
              x: MoneyPDF.contentMaxX - 90,
              y: flow.y,
              width: 90,
              font: .systemFont(ofSize: 10, weight: .medium),
              color: MoneyPDF.muted,
              align: .right
            )
            flow.y += 20
            MoneyPDF.rule(y: flow.y)
            flow.y += 16
          } else {
            MoneyPDF.brandMark(x: MoneyPDF.contentMinX, y: flow.y)
            MoneyPDF.text(
              title,
              x: MoneyPDF.contentMaxX - 220,
              y: flow.y,
              width: 220,
              font: .systemFont(ofSize: 11, weight: .semibold),
              color: MoneyPDF.ink,
              align: .right
            )
            flow.y += 22
            MoneyPDF.rule(y: flow.y)
            flow.y += 18
            MoneyPDF.text(
              heading,
              x: MoneyPDF.contentMinX,
              y: flow.y,
              width: MoneyPDF.contentWidth,
              font: .systemFont(ofSize: 24, weight: .bold),
              color: MoneyPDF.ink,
              height: 30
            )
            flow.y += 36
          }
        }

        func newPageIfNeeded(_ needed: CGFloat) {
          if flow.y + needed > MoneyPDF.page.height - MoneyPDF.footerReserve {
            MoneyPDF.drawFooter(page: flow.pageNumber)
            flow.pageNumber += 1
            startPage(continuation: true)
          }
        }

        startPage(continuation: false)
        for month in months {
          drawMonth(
            month,
            showMonthTitle: months.count > 1,
            cols: cols,
            flow: flow,
            newPageIfNeeded: newPageIfNeeded,
            income: income
          )
          if !income, let report = MoneyStore.shared.cashFlow(monthId: month.calendarMonthId) {
            MoneyCashFlowPDF.draw(
              report,
              flow: flow,
              newPageIfNeeded: newPageIfNeeded,
              showTitle: true
            )
          }
        }
        MoneyPDF.drawFooter(page: flow.pageNumber)
      }
      return url
    } catch {
      return nil
    }
  }

  private static func drawMonth(
    _ group: MoneyMonthGroup,
    showMonthTitle: Bool,
    cols: DueColumns,
    flow: MoneyPDFFlow,
    newPageIfNeeded: (CGFloat) -> Void,
    income: Bool
  ) {
    if showMonthTitle {
      newPageIfNeeded(36)
      MoneyPDF.text(
        periodTitle(for: group),
        x: MoneyPDF.contentMinX,
        y: flow.y,
        width: MoneyPDF.contentWidth,
        font: .systemFont(ofSize: 13, weight: .semibold),
        color: MoneyPDF.ink
      )
      flow.y += 22
    }

    newPageIfNeeded(28)
    MoneyPDF.label("Data", x: cols.date, y: flow.y, width: cols.dateWidth)
    MoneyPDF.label("Item", x: cols.item, y: flow.y, width: cols.itemWidth)
    MoneyPDF.label("Projeto", x: cols.project, y: flow.y, width: cols.projectWidth)
    MoneyPDF.label("Valor", x: cols.value, y: flow.y, width: cols.valueWidth, align: .right)
    flow.y += 14
    MoneyPDF.rule(y: flow.y)
    flow.y += 6

    if group.items.isEmpty {
      newPageIfNeeded(24)
      MoneyPDF.text(
        income ? "Nada a receber neste mês." : "Nada a pagar neste mês.",
        x: cols.item,
        y: flow.y + 4,
        width: cols.itemWidth,
        font: .systemFont(ofSize: 11),
        color: MoneyPDF.muted
      )
      flow.y += 24
    } else {
      for (index, item) in group.items.enumerated() {
        newPageIfNeeded(DueColumns.rowHeight)
        drawItem(item, cols: cols, y: flow.y, striped: index.isMultiple(of: 2))
        flow.y += DueColumns.rowHeight
      }
    }

    flow.y += 8
    newPageIfNeeded(28)
    MoneyPDF.rule(y: flow.y)
    flow.y += 12
    MoneyPDF.text(
      "Total a pagar",
      x: cols.item,
      y: flow.y,
      width: cols.itemWidth,
      font: .systemFont(ofSize: 12, weight: .semibold),
      color: MoneyPDF.ink
    )
    MoneyPDF.money(
      CurrencyFormat.brl(group.total),
      x: cols.value,
      y: flow.y,
      width: cols.valueWidth,
      color: MoneyPDF.ink,
      weight: .semibold,
      size: 12
    )
    flow.y += 24

    if !group.completedItems.isEmpty {
      newPageIfNeeded(28)
      MoneyPDF.label("Concluído", x: MoneyPDF.contentMinX, y: flow.y, width: 200)
      flow.y += 16
      for (index, item) in group.completedItems.enumerated() {
        newPageIfNeeded(DueColumns.rowHeight)
        drawItem(item, cols: cols, y: flow.y, striped: index.isMultiple(of: 2))
        flow.y += DueColumns.rowHeight
      }
      flow.y += 8
      newPageIfNeeded(24)
      MoneyPDF.text(
        "Total concluído",
        x: cols.item,
        y: flow.y,
        width: cols.itemWidth,
        font: .systemFont(ofSize: 11, weight: .medium),
        color: MoneyPDF.muted
      )
      MoneyPDF.money(
        CurrencyFormat.brl(group.completedTotal),
        x: cols.value,
        y: flow.y,
        width: cols.valueWidth,
        color: MoneyPDF.muted,
        weight: .medium
      )
      flow.y += 24
    }
  }

  private static func drawItem(_ item: MoneyDueItem, cols: DueColumns, y: CGFloat, striped: Bool) {
    if striped {
      let row = CGRect(x: MoneyPDF.contentMinX, y: y, width: MoneyPDF.contentWidth, height: DueColumns.rowHeight)
      UIBezierPath(roundedRect: row, cornerRadius: 4).fill(with: MoneyPDF.stripe)
    }
    let textY = y + 6
    MoneyPDF.text(item.dueLabel, x: cols.date, y: textY, width: cols.dateWidth, font: .systemFont(ofSize: 10), color: MoneyPDF.muted)
    MoneyPDF.text(
      item.title,
      x: cols.item,
      y: textY,
      width: cols.itemWidth,
      font: .systemFont(ofSize: 10.5, weight: .medium),
      color: MoneyPDF.ink
    )
    MoneyPDF.text(item.projectName, x: cols.project, y: textY, width: cols.projectWidth, font: .systemFont(ofSize: 10), color: MoneyPDF.muted)
    MoneyPDF.money(CurrencyFormat.brl(item.valor), x: cols.value, y: textY, width: cols.valueWidth, color: MoneyPDF.ink)
  }

  private struct DueColumns {
    static let rowHeight: CGFloat = 24
    let date = MoneyPDF.contentMinX
    let dateWidth: CGFloat = 52
    let item: CGFloat
    let itemWidth: CGFloat
    let project: CGFloat
    let projectWidth: CGFloat = 130
    let value: CGFloat
    let valueWidth: CGFloat = 92

    init() {
      item = date + dateWidth + 10
      value = MoneyPDF.contentMaxX - valueWidth
      project = value - 10 - projectWidth
      itemWidth = project - 10 - item
    }
  }
}

/// Bloco de fluxo de caixa no rodapé do PDF de A pagar (mês).
enum MoneyCashFlowPDF {
  private static let rowHeight: CGFloat = 22

  static func draw(
    _ report: MoneyCashFlowReport,
    flow: MoneyPDFFlow,
    newPageIfNeeded: (CGFloat) -> Void,
    showTitle: Bool
  ) {
    flow.y += 8
    newPageIfNeeded(120)
    MoneyPDF.rule(y: flow.y)
    flow.y += 18

    if showTitle {
      MoneyPDF.text(
        "Fluxo de caixa",
        x: MoneyPDF.contentMinX,
        y: flow.y,
        width: MoneyPDF.contentWidth,
        font: .systemFont(ofSize: 16, weight: .bold),
        color: MoneyPDF.ink
      )
      flow.y += 22
      MoneyPDF.text(
        report.title,
        x: MoneyPDF.contentMinX,
        y: flow.y,
        width: MoneyPDF.contentWidth,
        font: .systemFont(ofSize: 11, weight: .medium),
        color: MoneyPDF.muted
      )
      flow.y += 18
    }

    drawSummaryBand(report, flow: flow, newPageIfNeeded: newPageIfNeeded)

    let cash = report.cashLines
    newPageIfNeeded(36)
    MoneyPDF.label("Movimentos de caixa", x: MoneyPDF.contentMinX, y: flow.y, width: 220)
    flow.y += 16
    drawTableHeader(flow: flow)

    if cash.isEmpty {
      newPageIfNeeded(rowHeight)
      drawCarryoverLine(report, y: flow.y)
      flow.y += rowHeight
      newPageIfNeeded(24)
      MoneyPDF.text(
        "Nenhum movimento de caixa neste mês.",
        x: MoneyPDF.contentMinX + 62,
        y: flow.y + 4,
        width: 280,
        font: .systemFont(ofSize: 11),
        color: MoneyPDF.muted
      )
      flow.y += 24
    } else {
      newPageIfNeeded(rowHeight)
      drawCarryoverLine(report, y: flow.y)
      flow.y += rowHeight
      var running = report.opening
      for (index, line) in cash.enumerated() {
        newPageIfNeeded(rowHeight)
        running += line.amount
        drawLine(line, running: running, y: flow.y, striped: index.isMultiple(of: 2))
        flow.y += rowHeight
      }
    }

    flow.y += 10
    newPageIfNeeded(72)
    MoneyPDF.rule(y: flow.y)
    flow.y += 12
    drawTotals(report, flow: flow)

    if !report.weeks.isEmpty {
      flow.y += 16
      newPageIfNeeded(40)
      MoneyPDF.label("Por semana (início na segunda)", x: MoneyPDF.contentMinX, y: flow.y, width: 280)
      flow.y += 16
      for week in report.weeks {
        newPageIfNeeded(28)
        drawWeekRow(week, y: flow.y)
        flow.y += 26
      }
    }

    if report.cardPurchases > 0 {
      flow.y += 10
      newPageIfNeeded(28)
      MoneyPDF.text(
        "Compras no cartão (fora do caixa): \(CurrencyFormat.brl(report.cardPurchases))",
        x: MoneyPDF.contentMinX,
        y: flow.y,
        width: MoneyPDF.contentWidth,
        font: .systemFont(ofSize: 10.5),
        color: MoneyPDF.muted
      )
      flow.y += 20
    }

    flow.y += 8
  }

  private static func drawSummaryBand(
    _ report: MoneyCashFlowReport,
    flow: MoneyPDFFlow,
    newPageIfNeeded: (CGFloat) -> Void
  ) {
    newPageIfNeeded(64)
    let items: [(String, String, UIColor)] = [
      (report.openingLabel, CurrencyFormat.brl(report.opening), MoneyPDF.ink),
      ("Entradas", "+\(CurrencyFormat.brl(report.income))", MoneyPDF.accent),
      ("Saídas", "−\(CurrencyFormat.brl(report.expense))", MoneyPDF.ink),
      (
        "Projetado",
        CurrencyFormat.brl(report.closingProjected),
        report.isNegativeProjected
          ? UIColor(red: 220 / 255, green: 76 / 255, blue: 62 / 255, alpha: 1)
          : MoneyPDF.accent
      ),
    ]
    let height: CGFloat = 52
    let rect = CGRect(x: MoneyPDF.contentMinX, y: flow.y, width: MoneyPDF.contentWidth, height: height)
    UIBezierPath(roundedRect: rect, cornerRadius: 10).fill(with: MoneyPDF.band)
    let colW = MoneyPDF.contentWidth / CGFloat(items.count)
    for (index, item) in items.enumerated() {
      let x = MoneyPDF.contentMinX + colW * CGFloat(index)
      if index > 0 {
        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: x, y: flow.y + 10))
        divider.addLine(to: CGPoint(x: x, y: flow.y + height - 10))
        MoneyPDF.ruleColor.setStroke()
        divider.lineWidth = 0.5
        divider.stroke()
      }
      MoneyPDF.label(item.0, x: x + 10, y: flow.y + 9, width: colW - 20)
      MoneyPDF.text(
        item.1,
        x: x + 10,
        y: flow.y + 24,
        width: colW - 20,
        font: .monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
        color: item.2
      )
    }
    flow.y += height + 20
  }

  private static func drawTableHeader(flow: MoneyPDFFlow) {
    let cols = Columns()
    MoneyPDF.label("Data", x: cols.date, y: flow.y, width: cols.dateWidth)
    MoneyPDF.label("Descrição", x: cols.desc, y: flow.y, width: cols.descWidth)
    MoneyPDF.label("Tipo", x: cols.kind, y: flow.y, width: cols.kindWidth)
    MoneyPDF.label("Valor", x: cols.value, y: flow.y, width: cols.valueWidth, align: .right)
    MoneyPDF.label("Saldo", x: cols.running, y: flow.y, width: cols.runningWidth, align: .right)
    flow.y += 14
    MoneyPDF.rule(y: flow.y)
    flow.y += 6
  }

  private static func drawCarryoverLine(_ report: MoneyCashFlowReport, y: CGFloat) {
    let cols = Columns()
    let textY = y + 5
    MoneyPDF.text(
      MoneyCalendar.dayLabel(for: report.monthStart),
      x: cols.date,
      y: textY,
      width: cols.dateWidth,
      font: .systemFont(ofSize: 10),
      color: MoneyPDF.muted
    )
    MoneyPDF.text(
      report.openingLabel,
      x: cols.desc,
      y: textY,
      width: cols.descWidth,
      font: .systemFont(ofSize: 10.5, weight: .medium),
      color: MoneyPDF.ink
    )
    MoneyPDF.text(
      "Anterior",
      x: cols.kind,
      y: textY,
      width: cols.kindWidth,
      font: .systemFont(ofSize: 9.5),
      color: MoneyPDF.muted
    )
    MoneyPDF.money(
      CurrencyFormat.brl(report.opening),
      x: cols.value,
      y: textY,
      width: cols.valueWidth,
      color: MoneyPDF.ink,
      weight: .medium
    )
    MoneyPDF.money(
      CurrencyFormat.brl(report.opening),
      x: cols.running,
      y: textY,
      width: cols.runningWidth,
      color: MoneyPDF.muted,
      weight: .medium
    )
  }

  private static func drawLine(_ line: MoneyCashFlowLine, running: Double, y: CGFloat, striped: Bool) {
    let cols = Columns()
    if striped {
      let row = CGRect(x: MoneyPDF.contentMinX, y: y, width: MoneyPDF.contentWidth, height: rowHeight)
      UIBezierPath(roundedRect: row, cornerRadius: 4).fill(with: MoneyPDF.stripe)
    }
    let textY = y + 5
    MoneyPDF.text(
      line.dayLabel,
      x: cols.date,
      y: textY,
      width: cols.dateWidth,
      font: .systemFont(ofSize: 10),
      color: MoneyPDF.muted
    )
    let title = line.isProjected ? "\(line.title) *" : line.title
    MoneyPDF.text(
      title,
      x: cols.desc,
      y: textY,
      width: cols.descWidth,
      font: .systemFont(ofSize: 10.5, weight: .medium),
      color: MoneyPDF.ink
    )
    MoneyPDF.text(
      line.kind.label,
      x: cols.kind,
      y: textY,
      width: cols.kindWidth,
      font: .systemFont(ofSize: 9.5),
      color: MoneyPDF.muted
    )
    let valueText = line.amount >= 0
      ? "+\(CurrencyFormat.brl(line.amount))"
      : "−\(CurrencyFormat.brl(abs(line.amount)))"
    MoneyPDF.money(
      valueText,
      x: cols.value,
      y: textY,
      width: cols.valueWidth,
      color: line.amount >= 0 ? MoneyPDF.accent : MoneyPDF.ink
    )
    MoneyPDF.money(
      CurrencyFormat.brl(running),
      x: cols.running,
      y: textY,
      width: cols.runningWidth,
      color: MoneyPDF.ink
    )
  }

  private static func drawTotals(_ report: MoneyCashFlowReport, flow: MoneyPDFFlow) {
    let cols = Columns()
    MoneyPDF.text(
      "Caixa realizado",
      x: cols.desc,
      y: flow.y,
      width: cols.descWidth,
      font: .systemFont(ofSize: 11),
      color: MoneyPDF.muted
    )
    MoneyPDF.money(
      CurrencyFormat.brl(report.closingRealized),
      x: cols.running,
      y: flow.y,
      width: cols.runningWidth,
      color: MoneyPDF.ink,
      weight: .medium
    )
    flow.y += 18
    MoneyPDF.text(
      "Caixa projetado",
      x: cols.desc,
      y: flow.y,
      width: cols.descWidth,
      font: .systemFont(ofSize: 12, weight: .semibold),
      color: MoneyPDF.ink
    )
    MoneyPDF.money(
      CurrencyFormat.brl(report.closingProjected),
      x: cols.running,
      y: flow.y,
      width: cols.runningWidth,
      color: report.isNegativeProjected
        ? UIColor(red: 220 / 255, green: 76 / 255, blue: 62 / 255, alpha: 1)
        : MoneyPDF.accent,
      weight: .semibold,
      size: 12
    )
    flow.y += 16
    if report.projectedOut > 0 {
      MoneyPDF.text(
        "* Inclui \(CurrencyFormat.brl(report.projectedOut)) ainda a sair (a pagar e faturas).",
        x: MoneyPDF.contentMinX,
        y: flow.y,
        width: MoneyPDF.contentWidth,
        font: .systemFont(ofSize: 9.5),
        color: MoneyPDF.muted
      )
      flow.y += 14
    }
  }

  private static func drawWeekRow(_ week: MoneyCashFlowWeek, y: CGFloat) {
    MoneyPDF.text(
      "\(week.title)  ·  \(week.rangeLabel)",
      x: MoneyPDF.contentMinX,
      y: y,
      width: 220,
      font: .systemFont(ofSize: 10.5, weight: .medium),
      color: MoneyPDF.ink
    )
    MoneyPDF.text(
      "\(CurrencyFormat.brl(week.opening)) → \(CurrencyFormat.brl(week.closing))",
      x: MoneyPDF.contentMaxX - 200,
      y: y,
      width: 200,
      font: .monospacedDigitSystemFont(ofSize: 10.5, weight: .semibold),
      color: week.isNegative
        ? UIColor(red: 220 / 255, green: 76 / 255, blue: 62 / 255, alpha: 1)
        : MoneyPDF.ink,
      align: .right
    )
  }

  private struct Columns {
    let date = MoneyPDF.contentMinX
    let dateWidth: CGFloat = 52
    let desc: CGFloat
    let descWidth: CGFloat
    let kind: CGFloat
    let kindWidth: CGFloat = 70
    let value: CGFloat
    let valueWidth: CGFloat = 78
    let running: CGFloat
    let runningWidth: CGFloat = 86

    init() {
      running = MoneyPDF.contentMaxX - runningWidth
      value = running - 8 - valueWidth
      kind = value - 8 - kindWidth
      desc = date + dateWidth + 8
      descWidth = kind - 8 - desc
    }
  }
}

final class MoneyPDFFlow {
  var y: CGFloat = 0
  var pageNumber = 1
}

private enum MoneyPDF {
  static let page = CGRect(x: 0, y: 0, width: 595, height: 842)
  static let margin: CGFloat = 44
  static let footerReserve: CGFloat = 56
  static var contentWidth: CGFloat { page.width - margin * 2 }
  static var contentMinX: CGFloat { margin }
  static var contentMaxX: CGFloat { page.width - margin }

  static let ink = UIColor(red: 26 / 255, green: 27 / 255, blue: 30 / 255, alpha: 1)
  static let muted = UIColor(red: 107 / 255, green: 110 / 255, blue: 118 / 255, alpha: 1)
  static let faint = UIColor(red: 146 / 255, green: 150 / 255, blue: 160 / 255, alpha: 1)
  static let ruleColor = UIColor(red: 226 / 255, green: 227 / 255, blue: 232 / 255, alpha: 1)
  static let band = UIColor(red: 245 / 255, green: 246 / 255, blue: 248 / 255, alpha: 1)
  static let stripe = UIColor(red: 248 / 255, green: 249 / 255, blue: 251 / 255, alpha: 1)
  static let accent = UIColor(red: 15 / 255, green: 122 / 255, blue: 130 / 255, alpha: 1)
  static let accentBar = UIColor(red: 95 / 255, green: 211 / 255, blue: 220 / 255, alpha: 1)

  static func drawTopBar() {
    accentBar.setFill()
    UIRectFill(CGRect(x: 0, y: 0, width: page.width, height: 5))
  }

  static func brandMark(x: CGFloat, y: CGFloat) {
    let attrs: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
      .foregroundColor: muted,
      .kern: 1.6,
    ]
    ("STACKED" as NSString).draw(at: CGPoint(x: x, y: y + 2), withAttributes: attrs)
  }

  static func label(
    _ text: String,
    x: CGFloat,
    y: CGFloat,
    width: CGFloat,
    align: NSTextAlignment = .left
  ) {
    self.text(
      text.uppercased(),
      x: x,
      y: y,
      width: width,
      font: .systemFont(ofSize: 8, weight: .semibold),
      color: faint,
      align: align,
      kern: 0.6
    )
  }

  static func money(
    _ text: String,
    x: CGFloat,
    y: CGFloat,
    width: CGFloat,
    color: UIColor,
    weight: UIFont.Weight = .regular,
    size: CGFloat = 10.5
  ) {
    self.text(
      text,
      x: x,
      y: y,
      width: width,
      font: .monospacedDigitSystemFont(ofSize: size, weight: weight),
      color: color,
      align: .right
    )
  }

  @discardableResult
  static func text(
    _ string: String,
    x: CGFloat,
    y: CGFloat,
    width: CGFloat,
    font: UIFont,
    color: UIColor,
    align: NSTextAlignment = .left,
    height: CGFloat? = nil,
    kern: CGFloat? = nil
  ) -> CGFloat {
    let h = height ?? ceil(font.lineHeight + 1)
    let style = NSMutableParagraphStyle()
    style.alignment = align
    style.lineBreakMode = .byTruncatingTail
    var attrs: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: color,
      .paragraphStyle: style,
    ]
    if let kern {
      attrs[.kern] = kern
    }
    (string as NSString).draw(
      with: CGRect(x: x, y: y, width: width, height: h),
      options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
      attributes: attrs,
      context: nil
    )
    return h
  }

  static func rule(y: CGFloat) {
    let path = UIBezierPath()
    path.move(to: CGPoint(x: contentMinX, y: y))
    path.addLine(to: CGPoint(x: contentMaxX, y: y))
    ruleColor.setStroke()
    path.lineWidth = 0.6
    path.stroke()
  }

  static func drawFooter(page: Int) {
    let y = self.page.height - 36
    rule(y: y)
    text(
      generatedLabel(),
      x: contentMinX,
      y: y + 10,
      width: contentWidth * 0.7,
      font: .systemFont(ofSize: 8),
      color: faint
    )
    text(
      "Página \(page)",
      x: contentMaxX - 80,
      y: y + 10,
      width: 80,
      font: .systemFont(ofSize: 8, weight: .medium),
      color: faint,
      align: .right
    )
  }

  private static func generatedLabel() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "pt_BR")
    formatter.dateFormat = "d MMM yyyy"
    return "Gerado em \(formatter.string(from: Date()))"
  }
}

private extension UIBezierPath {
  func fill(with color: UIColor) {
    color.setFill()
    fill()
  }
}

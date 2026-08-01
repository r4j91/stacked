import SwiftUI

/// Estados vazios — "Emblema": glifo em disco, aro com arco de acento e selo opcional.
/// Toda a cor sai do tema ativo; o glifo recebe tingimento de accent (variante "peça em cor").
enum EmptyStateIllustrationKind {
  case inboxZero
  case todayClear
  case upcomingClear
  case projectClear
  case filterClear
  case searchEmpty
  case labelsEmpty
  case logbookEmpty
  case projectsEmpty
  case notificationsEmpty
}

// MARK: - Vocabulário

/// O selo responde ao que a tela permite: conquista, criação, ou nada.
/// Um "+" em "Nenhum resultado" prometeria uma ação que não existe ali.
private enum EmblemSeal {
  case check
  case plus
  case none
}

/// Camada de um glifo Solar: caminho preenchido, com opacidade e regra de
/// preenchimento próprias. O duotone é justamente isso — duas ou mais camadas
/// da mesma cor em opacidades diferentes.
private struct EmblemLayer {
  let path: String
  let opacity: Double
  let evenOdd: Bool

  init(_ path: String, opacity: Double = 1, evenOdd: Bool = false) {
    self.path = path
    self.opacity = opacity
    self.evenOdd = evenOdd
  }
}

private extension EmptyStateIllustrationKind {
  var seal: EmblemSeal {
    switch self {
    case .inboxZero, .todayClear, .upcomingClear, .projectClear, .filterClear: .check
    case .labelsEmpty, .projectsEmpty: .plus
    case .searchEmpty, .logbookEmpty, .notificationsEmpty: .none
    }
  }

  var layers: [EmblemLayer] {
    switch self {
    case .inboxZero:
      [
        EmblemLayer("M1 12c0-5.185 0-7.778 1.61-9.39C4.223 1 6.816 1 12 1s7.778 0 9.39 1.61C23 4.223 23 6.816 23 12s0 7.778-1.61 9.39C19.777 23 17.184 23 12 23s-7.778 0-9.39-1.61C1 19.777 1 17.184 1 12", opacity: 0.5),
        EmblemLayer("M2.61 21.389c1.612 1.61 4.205 1.61 9.39 1.61s7.778 0 9.39-1.61c1.492-1.493 1.601-3.829 1.61-8.29h-3.476c-.996 0-1.494 0-1.931.202c-.438.201-.762.58-1.41 1.335l-.666.777c-.648.756-.972 1.134-1.41 1.335s-.935.202-1.93.202h-.353c-.996 0-1.494 0-1.931-.202c-.438-.2-.762-.579-1.41-1.335l-.666-.777c-.648-.756-.972-1.134-1.41-1.335s-.935-.201-1.93-.201H1c.008 4.46.118 6.796 1.61 8.289"),
      ]
    case .todayClear:
      [
        EmblemLayer("M18 12a6 6 0 1 1-12 0a6 6 0 0 1 12 0"),
        EmblemLayer("M12 1.25a.75.75 0 0 1 .75.75v1a.75.75 0 0 1-1.5 0V2a.75.75 0 0 1 .75-.75M1.25 12a.75.75 0 0 1 .75-.75h1a.75.75 0 0 1 0 1.5H2a.75.75 0 0 1-.75-.75m19 0a.75.75 0 0 1 .75-.75h1a.75.75 0 0 1 0 1.5h-1a.75.75 0 0 1-.75-.75M12 20.25a.75.75 0 0 1 .75.75v1a.75.75 0 0 1-1.5 0v-1a.75.75 0 0 1 .75-.75", evenOdd: true),
        EmblemLayer("M4.398 4.398a.75.75 0 0 1 1.061 0l.393.393a.75.75 0 0 1-1.06 1.06l-.394-.392a.75.75 0 0 1 0-1.06m15.202 0a.75.75 0 0 1 0 1.06l-.392.393a.75.75 0 0 1-1.06-1.06l.392-.393a.75.75 0 0 1 1.06 0m-1.453 13.748a.75.75 0 0 1 1.061 0l.393.393a.75.75 0 0 1-1.06 1.06l-.394-.392a.75.75 0 0 1 0-1.06m-12.295 0a.75.75 0 0 1 0 1.06l-.393.393a.75.75 0 1 1-1.06-1.06l.392-.393a.75.75 0 0 1 1.06 0", opacity: 0.5),
      ]
    case .upcomingClear:
      [
        EmblemLayer("M6.94 2c.416 0 .753.324.753.724v1.46c.668-.012 1.417-.012 2.26-.012h4.015c.842 0 1.591 0 2.259.013v-1.46c0-.4.337-.725.753-.725s.753.324.753.724V4.25c1.445.111 2.394.384 3.09 1.055c.698.67.982 1.582 1.097 2.972L22 9H2v-.724c.116-1.39.4-2.302 1.097-2.972s1.645-.944 3.09-1.055V2.724c0-.4.337-.724.753-.724"),
        EmblemLayer("M22 14v-2c0-.839-.004-2.335-.017-3H2.01c-.013.665-.01 2.161-.01 3v2c0 3.771 0 5.657 1.172 6.828S6.228 22 10 22h4c3.77 0 5.656 0 6.828-1.172S22 17.772 22 14", opacity: 0.5),
        EmblemLayer("M18 17a1 1 0 1 1-2 0a1 1 0 0 1 2 0m0-4a1 1 0 1 1-2 0a1 1 0 0 1 2 0m-5 4a1 1 0 1 1-2 0a1 1 0 0 1 2 0m0-4a1 1 0 1 1-2 0a1 1 0 0 1 2 0m-5 4a1 1 0 1 1-2 0a1 1 0 0 1 2 0m0-4a1 1 0 1 1-2 0a1 1 0 0 1 2 0"),
      ]
    case .projectClear:
      [
        EmblemLayer("M22 14v-2.202c0-2.632 0-3.949-.77-4.804a3 3 0 0 0-.224-.225C20.151 6 18.834 6 16.202 6h-.374c-1.153 0-1.73 0-2.268-.153a4 4 0 0 1-.848-.352C12.224 5.224 11.816 4.815 11 4l-.55-.55c-.274-.274-.41-.41-.554-.53a4 4 0 0 0-2.18-.903C7.53 2 7.336 2 6.95 2c-.883 0-1.324 0-1.692.07A4 4 0 0 0 2.07 5.257C2 5.626 2 6.068 2 6.95V14c0 3.771 0 5.657 1.172 6.828S6.229 22 10 22h4c3.771 0 5.657 0 6.828-1.172S22 17.771 22 14", opacity: 0.5),
        EmblemLayer("M12.25 10a.75.75 0 0 1 .75-.75h5a.75.75 0 0 1 0 1.5h-5a.75.75 0 0 1-.75-.75"),
      ]
    case .filterClear:
      [
        EmblemLayer("M5 3h14L8.816 13.184a2.7 2.7 0 0 0-.778-1.086c-.228-.198-.547-.377-1.183-.736l-2.913-1.64c-.949-.533-1.423-.8-1.682-1.23C2 8.061 2 7.541 2 6.503v-.69c0-1.326 0-1.99.44-2.402C2.878 3 3.585 3 5 3", evenOdd: true),
        EmblemLayer("M22 6.504v-.69c0-1.326 0-1.99-.44-2.402C21.122 3 20.415 3 19 3L8.815 13.184q.075.193.121.403c.064.285.064.619.064 1.286v2.67c0 .909 0 1.364.252 1.718c.252.355.7.53 1.594.88c1.879.734 2.818 1.101 3.486.683S15 19.452 15 17.542v-2.67c0-.666 0-1 .063-1.285a2.68 2.68 0 0 1 .9-1.49c.227-.197.545-.376 1.182-.735l2.913-1.64c.948-.533 1.423-.8 1.682-1.23c.26-.43.26-.95.26-1.988", opacity: 0.5),
      ]
    case .searchEmpty:
      [
        EmblemLayer("M20.313 11.157a9.157 9.157 0 1 1-18.313 0a9.157 9.157 0 0 1 18.313 0", opacity: 0.5),
        EmblemLayer("m17.1 18.122l3.666 3.666a.723.723 0 0 0 1.023-1.022L18.122 17.1a9 9 0 0 1-1.022 1.022"),
      ]
    case .labelsEmpty:
      [
        EmblemLayer("M4.728 16.137c-1.545-1.546-2.318-2.318-2.605-3.321c-.288-1.003-.042-2.068.45-4.197l.283-1.228c.413-1.792.62-2.688 1.233-3.302s1.51-.82 3.302-1.233l1.228-.284c2.13-.491 3.194-.737 4.197-.45c1.003.288 1.775 1.061 3.32 2.606l1.83 1.83C20.657 9.248 22 10.592 22 12.262c0 1.671-1.344 3.015-4.033 5.704c-2.69 2.69-4.034 4.034-5.705 4.034c-1.67 0-3.015-1.344-5.704-4.033z", opacity: 0.5),
        EmblemLayer("M10.124 7.271a2.017 2.017 0 1 1-2.853 2.852a2.017 2.017 0 0 1 2.853-2.852m8.927 4.78l-6.979 6.98a.75.75 0 1 1-1.06-1.06l6.979-6.98a.75.75 0 1 1 1.06 1.06"),
      ]
    case .logbookEmpty:
      [
        EmblemLayer("M3 8c0-2.828 0-4.243.879-5.121C4.757 2 6.172 2 9 2h6c2.828 0 4.243 0 5.121.879C21 3.757 21 5.172 21 8v8c0 2.828 0 4.243-.879 5.121C19.243 22 17.828 22 15 22H9c-2.828 0-4.243 0-5.121-.879C3 20.243 3 18.828 3 16z", opacity: 0.5),
        EmblemLayer("M8.75 2.012v20h-1.5v-20zM1.25 8A.75.75 0 0 1 2 7.25h2a.75.75 0 0 1 0 1.5H2A.75.75 0 0 1 1.25 8m0 4a.75.75 0 0 1 .75-.75h2a.75.75 0 0 1 0 1.5H2a.75.75 0 0 1-.75-.75m0 4a.75.75 0 0 1 .75-.75h2a.75.75 0 0 1 0 1.5H2a.75.75 0 0 1-.75-.75", evenOdd: true),
        EmblemLayer("M10.75 6.5a.75.75 0 0 1 .75-.75h5a.75.75 0 0 1 0 1.5h-5a.75.75 0 0 1-.75-.75m0 3.5a.75.75 0 0 1 .75-.75h5a.75.75 0 0 1 0 1.5h-5a.75.75 0 0 1-.75-.75"),
      ]
    case .projectsEmpty:
      [
        EmblemLayer("M4.979 9.685C2.993 8.891 2 8.494 2 8s.993-.89 2.979-1.685l2.808-1.123C9.773 4.397 10.767 4 12 4s2.227.397 4.213 1.192l2.808 1.123C21.007 7.109 22 7.506 22 8s-.993.89-2.979 1.685l-2.808 1.124C14.227 11.603 13.233 12 12 12s-2.227-.397-4.213-1.191z"),
        EmblemLayer("M2 8c0 .494.993.89 2.979 1.685l2.808 1.124C9.773 11.603 10.767 12 12 12s2.227-.397 4.213-1.191l2.808-1.124C21.007 8.891 22 8.494 22 8s-.993-.89-2.979-1.685l-2.808-1.123C14.227 4.397 13.233 4 12 4s-2.227.397-4.213 1.192L4.98 6.315C2.993 7.109 2 7.506 2 8", evenOdd: true),
        EmblemLayer("m5.766 10l-.787.315C2.993 11.109 2 11.507 2 12s.993.89 2.979 1.685l2.808 1.124C9.773 15.603 10.767 16 12 16s2.227-.397 4.213-1.191l2.808-1.124C21.007 12.891 22 12.493 22 12s-.993-.89-2.979-1.685L18.234 10l-2.021.809C14.227 11.603 13.233 12 12 12s-2.227-.397-4.213-1.191z", opacity: 0.7),
        EmblemLayer("m5.766 14l-.787.315C2.993 15.109 2 15.507 2 16s.993.89 2.979 1.685l2.808 1.124C9.773 19.603 10.767 20 12 20s2.227-.397 4.213-1.192l2.808-1.123C21.007 16.891 22 16.494 22 16c0-.493-.993-.89-2.979-1.685L18.234 14l-2.021.809C14.227 15.603 13.233 16 12 16s-2.227-.397-4.213-1.191z", opacity: 0.4),
      ]
    case .notificationsEmpty:
      [
        EmblemLayer("M18.75 9v.704c0 .845.24 1.671.692 2.374l1.108 1.723c1.011 1.574.239 3.713-1.52 4.21a25.8 25.8 0 0 1-14.06 0c-1.759-.497-2.531-2.636-1.52-4.21l1.108-1.723a4.4 4.4 0 0 0 .693-2.374V9c0-3.866 3.022-7 6.749-7s6.75 3.134 6.75 7", opacity: 0.5),
        EmblemLayer("M7.243 18.545a5.002 5.002 0 0 0 9.513 0c-3.145.59-6.367.59-9.513 0"),
      ]
    }
  }
}

// MARK: - Métricas

/// Derivadas do mockup (disco r=60 numa caixa 240) por um fator único,
/// então mexer só em `discRadius` reescala o emblema inteiro sem distorcer.
private enum EmblemMetrics {
  static let width: CGFloat = 176
  static let height: CGFloat = 172
  static let center = CGPoint(x: width / 2, y: height / 2)

  static let discRadius: CGFloat = 52
  private static let f = discRadius / 60

  static let ringRadius = 74 * f
  static let haloRadius = 94 * f
  /// Os glifos vêm da grade 24 do Solar; a caixa ocupa 48% do diâmetro do disco.
  static let glyphBox: CGFloat = 24
  static let glyphSize = 57.6 * f
  static let glyphScale = glyphSize / glyphBox
  /// O Solar desenha sobre fundo chapado; aqui o glifo cai sobre o disco, que já
  /// é claro. Levantar o piso das camadas secundárias mantém a hierarquia do
  /// duotone sem que peças de massa quase toda secundária (lupa, sino) sumam.
  static func inkOpacity(_ raw: Double) -> Double { pow(raw, 0.62) }

  static let ringWidth = 1 * f
  static let accentArcWidth = 2.2 * f
  static let highlightWidth = 1.1 * f

  static let sealRadius = 16 * f
  static let sealRingWidth = 1.2 * f
  /// Vão entre o aro e o selo — o aro é interrompido, não coberto,
  /// então o emblema não depende da cor de fundo em que for colocado.
  static let sealGapRadius = 21 * f
  static let sealCenter = CGPoint(
    x: center.x + ringRadius * 0.7071,
    y: center.y - ringRadius * 0.7071
  )

  static let shadowOffsetY = 34 * f
  static let shadowSize = CGSize(width: 58 * f, height: 13 * f)
  /// Borrão largo: precisa virar penumbra na base do disco, não uma mancha sob o glifo.
  static let shadowBlur = 9 * f
}

// MARK: - Emblema

struct EmptyStateIllustration: View {
  @Environment(ThemeManager.self) private var theme
  let kind: EmptyStateIllustrationKind

  var body: some View {
    let c = theme.colors
    let dark = c.isDark
    let m = EmblemMetrics.self

    ZStack {
      halo(c: c, dark: dark)
      ring(c: c, dark: dark)
      disc(c: c, dark: dark)
      glyph(c: c)
      seal(c: c, dark: dark)
    }
    .frame(width: m.width, height: m.height)
    .accessibilityHidden(true)
  }

  // MARK: Camadas

  private func halo(c: AppThemeColors, dark: Bool) -> some View {
    Circle()
      .fill(
        RadialGradient(
          stops: [
            .init(color: c.accent.opacity(dark ? 0.22 : 0.17), location: 0),
            .init(color: c.accent.opacity(dark ? 0.05 : 0.04), location: 0.55),
            .init(color: c.accent.opacity(0), location: 1),
          ],
          center: UnitPoint(x: 0.48, y: 0.40),
          startRadius: 0,
          endRadius: EmblemMetrics.haloRadius
        )
      )
      .frame(width: EmblemMetrics.haloRadius * 2, height: EmblemMetrics.haloRadius * 2)
  }

  /// Aro neutro + arco de acento na diagonal oposta ao selo.
  private func ring(c: AppThemeColors, dark: Bool) -> some View {
    let m = EmblemMetrics.self
    let side = m.ringRadius * 2
    let gap = asin(min(1, m.sealGapRadius / m.ringRadius)) / (2 * .pi)
    let sealT: CGFloat = 0.875  // 45° acima da direita, na convenção de trim do Circle
    let hairline = c.textPrimary.opacity(dark ? 0.10 : 0.17)

    return ZStack {
      if kind.seal == .none {
        Circle().stroke(hairline, lineWidth: m.ringWidth)
      } else {
        Circle().trim(from: 0, to: sealT - gap)
          .stroke(hairline, lineWidth: m.ringWidth)
        Circle().trim(from: sealT + gap, to: 1)
          .stroke(hairline, lineWidth: m.ringWidth)
      }

      Circle()
        .trim(from: 118.0 / 360, to: 226.0 / 360)
        .stroke(
          c.accent.opacity(dark ? 0.85 : 0.70),
          style: StrokeStyle(lineWidth: m.accentArcWidth, lineCap: .round)
        )
    }
    .frame(width: side, height: side)
  }

  private func disc(c: AppThemeColors, dark: Bool) -> some View {
    let m = EmblemMetrics.self
    let side = m.discRadius * 2

    return Circle()
      .fill(c.surfaceVariant)
      .overlay {
        // Luz vindo de cima: clareia o topo, escurece a base.
        Circle().fill(
          LinearGradient(
            colors: [
              .white.opacity(dark ? 0.12 : 0.02),
              .black.opacity(dark ? 0.12 : 0.06),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
      }
      .overlay {
        Ellipse()
          .fill(.black.opacity(dark ? 0.30 : 0.10))
          .frame(width: m.shadowSize.width, height: m.shadowSize.height)
          .blur(radius: m.shadowBlur)
          .offset(y: m.shadowOffsetY)
      }
      .overlay {
        Circle().strokeBorder(c.textPrimary.opacity(dark ? 0.08 : 0.16), lineWidth: 1)
      }
      .overlay {
        Circle()
          .trim(from: 0.5, to: 1)
          .stroke(
            dark ? Color.white.opacity(0.12) : Color.black.opacity(0.05),
            lineWidth: m.highlightWidth
          )
      }
      .frame(width: side, height: side)
  }

  /// Duotone: uma única tinta, puxada do tema, e as opacidades que o próprio
  /// ícone traz é que separam as camadas. Misturar accent com o texto primário
  /// mantém a peça legível em accent apagado (Slate) e em accent quente (Ember).
  private func glyph(c: AppThemeColors) -> some View {
    let ink = c.textPrimary.mix(with: c.accent, by: 0.6, in: .device)

    return ZStack {
      ForEach(Array(kind.layers.enumerated()), id: \.offset) { _, layer in
        EmblemPath(command: layer.path)
          .fill(
            ink.opacity(EmblemMetrics.inkOpacity(layer.opacity)),
            style: FillStyle(eoFill: layer.evenOdd)
          )
      }
    }
  }

  @ViewBuilder
  private func seal(c: AppThemeColors, dark: Bool) -> some View {
    let m = EmblemMetrics.self
    if kind.seal != .none {
      Circle()
        .fill(c.accent.opacity(dark ? 0.18 : 0.14))
        .overlay {
          Circle().strokeBorder(
            c.accent.opacity(dark ? 0.62 : 0.50),
            lineWidth: m.sealRingWidth
          )
        }
        .overlay {
          Image(systemName: kind.seal == .check ? "checkmark" : "plus")
            .font(.system(size: m.sealRadius * 0.82, weight: .bold))
            .foregroundStyle(c.accent)
        }
        .frame(width: m.sealRadius * 2, height: m.sealRadius * 2)
        .position(m.sealCenter)
    }
  }
}

// MARK: - Desenho

/// Renderiza um comando de path SVG (grade 24 do Solar) já posicionado na tela do emblema.
private struct EmblemPath: Shape {
  let command: String

  func path(in rect: CGRect) -> Path {
    guard !command.isEmpty else { return Path() }
    let s = EmblemMetrics.glyphScale
    let half = EmblemMetrics.glyphBox / 2 * s
    let transform = CGAffineTransform(scaleX: s, y: s)
      .concatenating(
        CGAffineTransform(translationX: rect.midX - half, y: rect.midY - half)
      )
    return SVGPathReader.path(command).applying(transform)
  }
}

/// Leitor mínimo de comandos SVG (M m L l H h V v C c S s Q q A a Z z).
/// Os glifos são os SVGs originais do Solar; traduzi-los à mão convidaria erro.
private enum SVGPathReader {
  static func path(_ command: String) -> Path {
    var path = Path()
    var scanner = Scanner(command)
    var cursor = CGPoint.zero
    var subpathStart = CGPoint.zero
    var op: Character = "M"
    /// Último ponto de controle, para o reflexo que `S`/`s` exigem.
    var lastControl: CGPoint?

    while true {
      if let next = scanner.command() {
        op = next
      } else if !scanner.startsWithNumber() {
        break
      }

      // O reflexo de `S` só vale logo depois de uma cúbica; qualquer outro
      // comando no meio zera a referência.
      if !"CcSs".contains(op) { lastControl = nil }

      switch op {
      case "M", "m":
        let point = scanner.point(relativeTo: op == "m" ? cursor : .zero)
        path.move(to: point)
        cursor = point
        subpathStart = point
        op = op == "m" ? "l" : "L"  // pares seguintes viram lineto, como manda a spec

      case "L", "l":
        cursor = scanner.point(relativeTo: op == "l" ? cursor : .zero)
        path.addLine(to: cursor)

      case "H", "h":
        let x = scanner.number()
        cursor.x = op == "h" ? cursor.x + x : x
        path.addLine(to: cursor)

      case "V", "v":
        let y = scanner.number()
        cursor.y = op == "v" ? cursor.y + y : y
        path.addLine(to: cursor)

      case "C", "c":
        let origin = op == "c" ? cursor : .zero
        let c1 = scanner.point(relativeTo: origin)
        let c2 = scanner.point(relativeTo: origin)
        cursor = scanner.point(relativeTo: origin)
        path.addCurve(to: cursor, control1: c1, control2: c2)
        lastControl = c2

      case "S", "s":
        let origin = op == "s" ? cursor : .zero
        // Sem controle anterior a spec manda espelhar o próprio ponto atual.
        let c1 = lastControl.map {
          CGPoint(x: 2 * cursor.x - $0.x, y: 2 * cursor.y - $0.y)
        } ?? cursor
        let c2 = scanner.point(relativeTo: origin)
        cursor = scanner.point(relativeTo: origin)
        path.addCurve(to: cursor, control1: c1, control2: c2)
        lastControl = c2

      case "Q", "q":
        let origin = op == "q" ? cursor : .zero
        let control = scanner.point(relativeTo: origin)
        cursor = scanner.point(relativeTo: origin)
        path.addQuadCurve(to: cursor, control: control)

      case "A", "a":
        let radius = scanner.number()
        _ = scanner.number()  // ry — todos os arcos dos glifos são circulares
        _ = scanner.number()  // rotação do eixo x
        let largeArc = scanner.number() != 0
        let sweep = scanner.number() != 0
        let end = scanner.point(relativeTo: op == "a" ? cursor : .zero)
        addArc(from: cursor, to: end, radius: radius, largeArc: largeArc, sweep: sweep, into: &path)
        cursor = end

      case "Z", "z":
        path.closeSubpath()
        cursor = subpathStart

      default:
        return path
      }
    }
    return path
  }

  /// Arco por endpoint (spec SVG F.6.5) aproximado em cúbicas de no máximo 90°.
  private static func addArc(
    from start: CGPoint,
    to end: CGPoint,
    radius: CGFloat,
    largeArc: Bool,
    sweep: Bool,
    into path: inout Path
  ) {
    let halfDX = (start.x - end.x) / 2
    let halfDY = (start.y - end.y) / 2
    let squared = halfDX * halfDX + halfDY * halfDY
    guard radius > 0, squared > 0 else {
      path.addLine(to: end)
      return
    }

    var r = radius
    let lambda = squared / (r * r)
    if lambda > 1 { r *= sqrt(lambda) }

    let sign: CGFloat = largeArc != sweep ? 1 : -1
    let factor = sign * sqrt(max(0, (r * r - squared) / squared))
    let cx = factor * halfDY + (start.x + end.x) / 2
    let cy = -factor * halfDX + (start.y + end.y) / 2

    let from = atan2(start.y - cy, start.x - cx)
    var delta = atan2(end.y - cy, end.x - cx) - from
    if !sweep, delta > 0 { delta -= 2 * .pi }
    if sweep, delta < 0 { delta += 2 * .pi }

    let steps = max(1, Int(ceil(abs(delta) / (.pi / 2))))
    let step = delta / CGFloat(steps)
    let k = 4.0 / 3.0 * tan(step / 4)
    var angle = from

    for _ in 0..<steps {
      let next = angle + step
      let p1 = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
      let p2 = CGPoint(x: cx + r * cos(next), y: cy + r * sin(next))
      path.addCurve(
        to: p2,
        control1: CGPoint(x: p1.x - k * r * sin(angle), y: p1.y + k * r * cos(angle)),
        control2: CGPoint(x: p2.x + k * r * sin(next), y: p2.y - k * r * cos(next))
      )
      angle = next
    }
  }

  private struct Scanner {
    private let characters: [Character]
    private var index = 0

    init(_ text: String) { characters = Array(text) }

    private mutating func skipSeparators() {
      while index < characters.count,
            characters[index] == " " || characters[index] == "," || characters[index] == "\n" {
        index += 1
      }
    }

    mutating func command() -> Character? {
      skipSeparators()
      guard index < characters.count, characters[index].isLetter else { return nil }
      defer { index += 1 }
      return characters[index]
    }

    mutating func startsWithNumber() -> Bool {
      skipSeparators()
      guard index < characters.count else { return false }
      let c = characters[index]
      return c.isNumber || c == "-" || c == "+" || c == "."
    }

    mutating func number() -> CGFloat {
      skipSeparators()
      var text = ""
      if index < characters.count, characters[index] == "-" || characters[index] == "+" {
        text.append(characters[index])
        index += 1
      }
      var sawDot = false
      while index < characters.count {
        let c = characters[index]
        if c.isNumber {
          text.append(c)
        } else if c == ".", !sawDot {
          sawDot = true
          text.append(c)
        } else {
          break
        }
        index += 1
      }
      return CGFloat(Double(text) ?? 0)
    }

    mutating func point(relativeTo origin: CGPoint) -> CGPoint {
      let x = number()
      let y = number()
      return CGPoint(x: origin.x + x, y: origin.y + y)
    }
  }
}

// MARK: - Home all clear (inline)

/// Selo mínimo para "Tudo em dia" na Home — mesma linguagem das empty states, ~28pt.
struct HomeAllClearBadge: View {
  @Environment(ThemeManager.self) private var theme

  var body: some View {
    let c = theme.colors
    let green = AppColors.tagGreen

    ZStack {
      Circle()
        .fill(
          RadialGradient(
            colors: [
              green.opacity(c.isDark ? 0.20 : 0.14),
              green.opacity(c.isDark ? 0.05 : 0.03),
              .clear,
            ],
            center: .center,
            startRadius: 1,
            endRadius: 15
          )
        )
        .frame(width: 30, height: 30)

      Circle()
        .trim(from: 0.06, to: 0.44)
        .stroke(
          green.opacity(c.isDark ? 0.28 : 0.22),
          style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
        )
        .frame(width: 26, height: 26)
        .rotationEffect(.degrees(-108))

      Circle()
        .strokeBorder(green.opacity(c.isDark ? 0.34 : 0.28), lineWidth: 1)
        .frame(width: 22, height: 22)

      Circle()
        .fill(c.surfaceVariant.opacity(c.isDark ? 0.42 : 0.58))
        .overlay {
          Circle()
            .strokeBorder(c.textPrimary.opacity(c.isDark ? 0.05 : 0.07), lineWidth: 0.75)
        }
        .frame(width: 18, height: 18)

      Image(systemName: "checkmark")
        .font(.system(size: 8.5, weight: .bold))
        .foregroundStyle(green.opacity(c.isDark ? 0.90 : 0.78))
    }
    .frame(width: 28, height: 28)
    .accessibilityHidden(true)
  }
}

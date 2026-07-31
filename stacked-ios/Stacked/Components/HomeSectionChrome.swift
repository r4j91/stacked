import SwiftUI

/// Fundo de linha dos estilos com container/cápsula da Home.
/// Vai em `listRowBackground`, então cobre a célula inteira — os insets do card
/// são aplicados aqui, não no conteúdo.
struct HomeSectionRowBackground: View {
  let style: HomeSectionStyle
  let position: HomeSectionRowPosition
  /// Explícito: `listRowBackground` é hospedado pela célula da `List` e não
  /// herda o `ThemeManager` de forma confiável.
  let colors: AppThemeColors

  var body: some View {
    let c = colors
    let m = style.metrics

    switch style {
    case .classic:
      Color.clear
    case .capsule:
      RoundedRectangle(cornerRadius: m.cornerRadius, style: .continuous)
        .fill(c.surface)
        .overlay {
          RoundedRectangle(cornerRadius: m.cornerRadius, style: .continuous)
            .strokeBorder(hairline(c), lineWidth: 1)
        }
        .padding(.horizontal, m.containerInsetH)
        .padding(.vertical, m.capsuleGapV)
    case .container, .quiet:
      ZStack(alignment: .bottom) {
        UnevenRoundedRectangle(
          topLeadingRadius: position.isFirst ? m.cornerRadius : 0,
          bottomLeadingRadius: position.isLast ? m.cornerRadius : 0,
          bottomTrailingRadius: position.isLast ? m.cornerRadius : 0,
          topTrailingRadius: position.isFirst ? m.cornerRadius : 0,
          style: .continuous
        )
        .fill(c.surface)

        if style.drawsBorder {
          HomeContainerBorder(position: position, radius: m.cornerRadius)
            .stroke(hairline(c), lineWidth: 1)
        }

        if style.showsRowDividers, !position.isLast {
          Rectangle()
            .fill(rowDivider(c))
            .frame(height: TaskExpandDividerStyle.listHairlineThickness)
            .padding(.leading, m.dividerLeadingInset)
        }
      }
      .padding(.horizontal, m.containerInsetH)
    }
  }

  private func hairline(_ c: AppThemeColors) -> Color {
    (c.isDark ? Color.white : Color.black).opacity(c.isDark ? 0.08 : 0.06)
  }

  /// Mesma tinta do divisor entre subtarefas no Halo — `textPrimary` bem fraco.
  private func rowDivider(_ c: AppThemeColors) -> Color {
    c.textPrimary.opacity(TaskExpandDividerStyle.cardLightStrokeAlpha)
  }
}

/// Contorno contínuo de um container montado a partir de várias linhas da `List`.
/// Linhas do meio só desenham as laterais — sem costura horizontal nas emendas.
struct HomeContainerBorder: Shape {
  let position: HomeSectionRowPosition
  let radius: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let r = radius
    let isFirst = position.isFirst
    let isLast = position.isLast

    path.move(to: CGPoint(x: rect.minX, y: isFirst ? rect.minY + r : rect.minY))
    path.addLine(to: CGPoint(x: rect.minX, y: isLast ? rect.maxY - r : rect.maxY))

    if isLast {
      path.addQuadCurve(
        to: CGPoint(x: rect.minX + r, y: rect.maxY),
        control: CGPoint(x: rect.minX, y: rect.maxY)
      )
      path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.maxY))
      path.addQuadCurve(
        to: CGPoint(x: rect.maxX, y: rect.maxY - r),
        control: CGPoint(x: rect.maxX, y: rect.maxY)
      )
    } else {
      path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
    }

    path.addLine(to: CGPoint(x: rect.maxX, y: isFirst ? rect.minY + r : rect.minY))

    if isFirst {
      path.addQuadCurve(
        to: CGPoint(x: rect.maxX - r, y: rect.minY),
        control: CGPoint(x: rect.maxX, y: rect.minY)
      )
      path.addLine(to: CGPoint(x: rect.minX + r, y: rect.minY))
      path.addQuadCurve(
        to: CGPoint(x: rect.minX, y: rect.minY + r),
        control: CGPoint(x: rect.minX, y: rect.minY)
      )
    }

    return path
  }
}

/// Header de seção da Home. Reproduz o `ListSectionHeader` quando a escala é `classic`.
struct HomeSectionHeader<Trailing: View>: View {
  @Environment(ThemeManager.self) private var theme
  let text: String
  let style: HomeSectionStyle
  let scale: AppTypeScale
  @ViewBuilder var trailing: () -> Trailing

  var body: some View {
    let c = theme.colors
    let t = scale.metrics
    let m = style.metrics

    HStack(alignment: .center, spacing: 8) {
      Text(t.headerCase.apply(to: text))
        .font(t.headerFont)
        .foregroundStyle(t.headerUsesPrimaryColor ? c.textPrimary : c.textTertiary)
        .tracking(t.headerTracking)
        .textCase(nil)
      Spacer(minLength: 0)
      trailing()
    }
    .padding(.leading, style == .classic ? AppSpacing.xs : 0)
    .padding(.top, m.headerTopPadding)
    .padding(.bottom, m.headerBottomPadding)
  }
}

extension HomeSectionHeader where Trailing == EmptyView {
  init(text: String, style: HomeSectionStyle, scale: AppTypeScale) {
    self.init(text: text, style: style, scale: scale) { EmptyView() }
  }
}

extension View {
  /// Alinha o header ao card. No estilo atual mantém os insets padrão da `List`.
  @ViewBuilder
  func homeSectionHeaderInsets(_ style: HomeSectionStyle) -> some View {
    if style == .classic {
      self
    } else {
      let inset = style.metrics.containerInsetH + 2
      listRowInsets(EdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset))
    }
  }
}


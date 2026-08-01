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
        containerShape(position: position, radius: m.cornerRadius)
          .fill(c.surface)

        if style.drawsBorder {
          // Mesma forma do fill, esticada além da célula nas emendas e recortada:
          // o contorno bate exato com a curva e nenhuma costura horizontal aparece.
          Color.clear
            .overlay {
              containerShape(position: position, radius: m.cornerRadius)
                .strokeBorder(hairline(c), lineWidth: 1)
                .padding(.top, position.isFirst ? 0 : -2)
                .padding(.bottom, position.isLast ? 0 : -2)
            }
            .clipped()
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

  private func containerShape(
    position: HomeSectionRowPosition,
    radius: CGFloat
  ) -> UnevenRoundedRectangle {
    UnevenRoundedRectangle(
      topLeadingRadius: position.isFirst ? radius : 0,
      bottomLeadingRadius: position.isLast ? radius : 0,
      bottomTrailingRadius: position.isLast ? radius : 0,
      topTrailingRadius: position.isFirst ? radius : 0,
      style: .continuous
    )
  }

  private func hairline(_ c: AppThemeColors) -> Color {
    (c.isDark ? Color.white : Color.black).opacity(c.isDark ? 0.08 : 0.06)
  }

  /// Mesma tinta do divisor entre subtarefas no Halo — `textPrimary` bem fraco.
  private func rowDivider(_ c: AppThemeColors) -> Color {
    c.textPrimary.opacity(TaskExpandDividerStyle.cardLightStrokeAlpha)
  }
}

/// Header de seção da Home. Reproduz o `ListSectionHeader` quando a escala é `classic`.
struct HomeSectionHeader<Trailing: View>: View {
  @Environment(ThemeManager.self) private var theme
  let text: String
  let style: HomeSectionStyle
  let scale: AppTypeScale
  /// Primeira seção da tela: nasce colada na navbar e precisa do respiro extra.
  var isFirstSection = false
  @ViewBuilder var trailing: () -> Trailing

  var body: some View {
    let c = theme.colors
    let t = scale.metrics
    let m = style.metrics

    HStack(alignment: .center, spacing: 8) {
      Text(t.headerCase.apply(to: text))
        .font(t.headerFont)
        .foregroundStyle(t.headerUsesPrimaryColor ? c.textPrimary : c.textSecondary)
        .tracking(t.headerTracking)
        .textCase(nil)
      Spacer(minLength: 0)
      trailing()
    }
    .padding(.leading, style == .classic ? AppSpacing.xs : 0)
    .padding(.top, m.headerTopPadding + (isFirstSection ? m.firstSectionExtraTopPadding : 0))
    .padding(.bottom, m.headerBottomPadding)
  }
}

extension HomeSectionHeader where Trailing == EmptyView {
  init(text: String, style: HomeSectionStyle, scale: AppTypeScale, isFirstSection: Bool = false) {
    self.init(text: text, style: style, scale: scale, isFirstSection: isFirstSection) { EmptyView() }
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


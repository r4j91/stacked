import SwiftUI
import UIKit

/// Painel ancorado para editar notas — linguagem dos menus de meta + ações em pílula.
struct AnchoredNotesPopoverOverlay: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let anchorRect: CGRect
  @Binding var text: String
  var hostBounds: CGRect = .zero
  var title: String = "Notas"
  var onTextChange: (() -> Void)?
  let onDismiss: () -> Void

  @FocusState private var focused: Bool
  @State private var isPresented = false
  @State private var isDismissing = false
  @State private var keyboardHeight: CGFloat = 0
  @State private var didCopy = false

  private var cardWidth: CGFloat {
    let screenW = layoutSize.width
    return min(max(PopoverStyle.menuWidth + 20, screenW - 32), 320)
  }

  private var cardHeight: CGFloat { 268 }

  private var localAnchor: CGRect {
    guard hostBounds.width > 1, hostBounds.height > 1 else { return anchorRect }
    return anchorRect.offsetBy(dx: -hostBounds.minX, dy: -hostBounds.minY)
  }

  private var layoutSize: CGSize {
    hostBounds.width > 1 ? hostBounds.size : ScreenMetrics.bounds.size
  }

  private var cardFrame: CGRect {
    let screen = layoutSize
    let w = cardWidth
    let h = cardHeight
    let anchor = localAnchor
    let keyboardTop = screen.height - max(keyboardHeight, 0) - 10
    let maxBottom = min(keyboardTop, screen.height - 12)

    let left = max(12, (screen.width - w) / 2)

    var top = anchor.maxY + 8

    if top + h > maxBottom {
      top = max(56, maxBottom - h)
    }

    top = min(max(top, 56), max(56, maxBottom - h))

    return CGRect(x: left, y: top, width: w, height: h)
  }

  private var cardPosition: CGPoint {
    let f = cardFrame
    return CGPoint(x: f.midX, y: f.midY)
  }

  private var scaleAnchor: UnitPoint { .top }

  private var canCopy: Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    ZStack {
      Color.black.opacity(PopoverStyle.scrimOpacity * (isPresented ? 1 : 0))
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .allowsHitTesting(isPresented && !isDismissing)

      card
        .frame(width: cardFrame.width, height: cardFrame.height)
        .position(x: cardPosition.x, y: cardPosition.y)
        .scaleEffect(isPresented ? 1 : PopoverStyle.scaleBegin, anchor: scaleAnchor)
        .opacity(isPresented ? 1 : 0)
        .compositingGroup()
        .allowsHitTesting(isPresented && !isDismissing)
    }
    .onAppear {
      AppMotion.animate(AppMotion.popoverPresentSpring, reduceMotion: reduceMotion) {
        isPresented = true
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
        guard !isDismissing else { return }
        focused = true
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
      guard !isDismissing else { return }
      updateKeyboardHeight(from: note)
    }
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
      guard !isDismissing else { return }
      keyboardHeight = 0
    }
  }

  private var card: some View {
    let c = theme.colors

    return LiquidGlass.popoverCard(navBarColor: c.navBar) {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 8) {
          StackedIcons.image(.edit)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(c.textSecondary)
            .frame(width: 22)
          Text(title)
            .font(AppTypography.popoverRowLabel)
            .foregroundStyle(c.textPrimary)
          Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)

        TextField("Adicionar notas...", text: $text, axis: .vertical)
          .font(AppTypography.commentBody)
          .foregroundStyle(c.textPrimary)
          .lineLimit(6...12)
          .focused($focused)
          .padding(12)
          .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
          .background(c.surfaceVariant.opacity(0.9))
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          .padding(.horizontal, 12)
          .onChange(of: text) { _, _ in
            onTextChange?()
            if didCopy { didCopy = false }
          }

        HStack(spacing: 10) {
          notesPillButton(
            title: didCopy ? "Copiado" : "Copiar",
            icon: .copy,
            tint: c.textSecondary,
            fill: c.surfaceVariant,
            enabled: canCopy || didCopy
          ) {
            copyAll()
          }
          .disabled(!canCopy && !didCopy)
          .accessibilityLabel(didCopy ? "Descrição copiada" : "Copiar descrição")

          notesPillButton(
            title: "Pronto",
            icon: .check,
            tint: Color.black.opacity(0.82),
            fill: c.accent,
            enabled: true
          ) {
            HapticService.selection()
            dismiss()
          }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 14)
      }
      .frame(width: cardWidth, height: cardHeight, alignment: .top)
      .clipped()
    }
  }

  private func notesPillButton(
    title: String,
    icon: StackedIconKey,
    tint: Color,
    fill: Color,
    enabled: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 6) {
        StackedIcons.image(icon)
          .font(.system(size: 13, weight: .semibold))
        Text(title)
          .font(AppTypography.metadataLabel)
      }
      .foregroundStyle(enabled ? tint : tint.opacity(0.45))
      .frame(maxWidth: .infinity)
      .padding(.vertical, 11)
      .background(fill.opacity(enabled ? 1 : 0.55))
      .clipShape(Capsule())
    }
    .buttonStyle(.plain)
  }

  private func copyAll() {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    UIPasteboard.general.string = text
    HapticService.selection()
    didCopy = true
  }

  private func dismiss() {
    guard !isDismissing else { return }
    isDismissing = true
    focused = false
    // Mesmo padrão dos menus de meta (prioridade/etiquetas): fecha na hora.
    onDismiss()
  }

  private func updateKeyboardHeight(from note: Notification) {
    guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
    let screenH = ScreenMetrics.bounds.height
    keyboardHeight = max(0, screenH - frame.origin.y)
  }
}

/// Trigger de notas sob o título — empty = mesma pílula dos metas; filled = card na largura do meta.
struct DetailNotesTriggerRow: View {
  @Environment(ThemeManager.self) private var theme

  let text: String
  let onOpen: (CGRect) -> Void

  private var trimmed: String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var hasNotes: Bool { !trimmed.isEmpty }

  var body: some View {
    let c = theme.colors

    Group {
      if hasNotes {
        HStack(alignment: .top, spacing: 10) {
          VStack(alignment: .leading, spacing: 6) {
            Text("Notas")
              .font(AppTypography.meta)
              .foregroundStyle(c.textTertiary)
            NotesMarkupText(
              source: trimmed,
              color: c.textSecondary,
              size: 13.5,
              weight: .regular,
              boldWeight: .semibold
            )
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          DisclosureChevron()
            .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(c.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(c.textPrimary.opacity(0.06), lineWidth: 1)
        )
      } else {
        // Espelha `fieldPill` do detail (ícone + label, padding 12/8, surfaceVariant).
        // +16 leading interno: com padding externo 16 fica alinhado às pílulas do meta card.
        HStack {
          HStack(spacing: 6) {
            StackedIcons.image(.edit)
              .font(AppTypography.metaSmall)
            Text("Adicionar notas")
              .font(AppTypography.metadataLabel)
          }
          .foregroundStyle(c.textSecondary)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(c.surfaceVariant)
          .clipShape(Capsule())
          Spacer(minLength: 0)
        }
        .padding(.leading, 16)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
    .overlay {
      ScreenAnchorTapOverlay { rect in
        HapticService.selection()
        onOpen(rect)
      }
    }
    .accessibilityLabel(hasNotes ? "Editar notas" : "Adicionar notas")
    .accessibilityHint("Abre o editor de notas")
    .accessibilityAddTraits(.isButton)
  }
}

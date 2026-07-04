import SwiftUI
import Hugeicons

// Paridade lib/widgets/installment_generator_sheet.dart — layout alinhado a Configurações / Novo projeto
struct InstallmentGeneratorSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  let taskId: String
  let taskTitle: String
  var onGenerated: () -> Void

  @State private var nameBase: String
  @State private var valorText = ""
  @State private var quantity = 12
  @State private var firstDueDate = Date()
  @State private var frequency: InstallmentFrequency = .monthly
  @State private var generating = false
  @State private var errorMessage: String?
  @State private var showDatePicker = false

  @FocusState private var focusedField: Field?

  private enum Field: Hashable {
    case name, valor
  }

  init(taskId: String, taskTitle: String, onGenerated: @escaping () -> Void) {
    self.taskId = taskId
    self.taskTitle = taskTitle
    self.onGenerated = onGenerated
    _nameBase = State(initialValue: taskTitle)
  }

  private var parsedValor: Double? {
    InstallmentGeneratorLogic.parseValor(valorText)
  }

  private var previewDates: [Date] {
    InstallmentGeneratorLogic.generateDates(
      quantity: quantity,
      firstDueDate: firstDueDate,
      frequency: frequency
    )
  }

  private var effectiveNameBase: String {
    let trimmed = nameBase.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "Parcela" : trimmed
  }

  private var canGenerate: Bool {
    !effectiveNameBase.isEmpty && quantity >= 1 && !generating
  }

  var body: some View {
    let c = theme.colors

    NavigationStack {
      List {
        Section {
          HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .fill(c.accent.opacity(0.14))
              .frame(width: 40, height: 40)
              .overlay {
                StackedIcons.icon(.money, size: 20, color: c.accent)
              }
            VStack(alignment: .leading, spacing: 3) {
              Text("Subtarefas com vencimentos automáticos")
                .font(AppTypography.settingsTitle)
                .foregroundStyle(c.textPrimary)
              Text("Gera \(quantity) parcelas a partir do nome e da data inicial.")
                .font(AppTypography.metaSmall)
                .foregroundStyle(c.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          .padding(.vertical, 4)
          .settingsListCardRow(top: 8, bottom: 4)
          .listRowBackground(Color.clear)
        }

        Section {
          SettingsCardSurface {
            VStack(spacing: 0) {
              nameField
              SettingsCardDivider(leadingPadding: 14)
              quantityRow
              SettingsCardDivider(leadingPadding: 14)
              valorRow
              SettingsCardDivider(leadingPadding: 14)
              dueDateRow
            }
          }
          .settingsListCardRow(top: 4, bottom: 4)
        } header: {
          SettingsSectionHeader(text: "Configuração")
        }

        Section {
          SettingsCardSurface {
            frequencySegment
              .padding(6)
          }
          .settingsListCardRow(top: 4, bottom: 4)
        } header: {
          SettingsSectionHeader(text: "Frequência")
        }

        Section {
          SettingsCardSurface {
            previewContent
          }
          .settingsListCardRow(top: 4, bottom: 4)
        } header: {
          SettingsSectionHeader(text: "Preview")
        }

        Section {
          Text("Após gerar, você pode editar o vencimento de qualquer parcela abrindo a subtarefa.")
            .font(AppTypography.metaSmall)
            .foregroundStyle(c.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
            .settingsListCardRow(top: 0, bottom: 8)
            .listRowBackground(Color.clear)

          if let errorMessage {
            Text(errorMessage)
              .font(AppTypography.meta)
              .foregroundStyle(AppColors.priorityHigh)
              .settingsListCardRow(top: 0, bottom: 8)
              .listRowBackground(Color.clear)
          }
        }
      }
      .settingsDrillDownList(background: c.background)
      .listSectionSpacing(16)
      .navigationTitle("Gerar Parcelas")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancelar") { dismiss() }
            .foregroundStyle(c.textSecondary)
        }
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        footerBar
      }
      .stackedTaskDatePickerSheet(
        isPresented: $showDatePicker,
        initialDate: firstDueDate,
        showRecurrence: false
      ) { date, _ in
        if let date { firstDueDate = date }
      }
    }
  }

  // MARK: - Campos

  private var nameField: some View {
    let c = theme.colors
    return VStack(alignment: .leading, spacing: 8) {
      Text("Nome base")
        .font(AppTypography.fieldLabel)
        .foregroundStyle(c.textSecondary)
      TextField("Ex: Aluguel", text: $nameBase)
        .font(AppTypography.fieldInput)
        .foregroundStyle(c.textPrimary)
        .focused($focusedField, equals: .name)
        .submitLabel(.next)
        .onSubmit { focusedField = .valor }
    }
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
  }

  private var quantityRow: some View {
    let c = theme.colors
    return HStack(spacing: 12) {
      Text("Nº de parcelas")
        .font(AppTypography.settingsTitle)
        .foregroundStyle(c.textPrimary)
      Spacer(minLength: 8)
      HStack(spacing: 4) {
        stepperButton(systemName: "minus") {
          quantity = max(1, quantity - 1)
        }
        Text("\(quantity)")
          .font(AppTypography.bodySemibold)
          .foregroundStyle(c.textPrimary)
          .monospacedDigit()
          .frame(minWidth: 36)
          .multilineTextAlignment(.center)
        stepperButton(systemName: "plus") {
          quantity = min(360, quantity + 1)
        }
      }
      .padding(4)
      .background(c.surface.opacity(0.6))
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
  }

  private var valorRow: some View {
    let c = theme.colors
    return HStack(spacing: 12) {
      Text("Valor (R$)")
        .font(AppTypography.settingsTitle)
        .foregroundStyle(c.textPrimary)
        .frame(width: 96, alignment: .leading)
      TextField("0,00", text: $valorText)
        .font(AppTypography.fieldInput)
        .foregroundStyle(c.textPrimary)
        .keyboardType(.decimalPad)
        .multilineTextAlignment(.trailing)
        .focused($focusedField, equals: .valor)
    }
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
  }

  private var dueDateRow: some View {
    let c = theme.colors
    return Button {
      focusedField = nil
      showDatePicker = true
    } label: {
      HStack(spacing: 12) {
        StackedIcons.image(.calendar)
          .font(.system(size: 18))
          .foregroundStyle(c.textSecondary)
          .frame(width: 24)
        VStack(alignment: .leading, spacing: 2) {
          Text("1ª parcela")
            .font(AppTypography.settingsTitle)
            .foregroundStyle(c.textPrimary)
          Text(InstallmentGeneratorLogic.formatDate(firstDueDate))
            .font(AppTypography.metaSmall)
            .foregroundStyle(c.textTertiary)
        }
        Spacer(minLength: 0)
        StackedIcons.image(.chevronRight)
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(c.textTertiary)
      }
      .padding(.horizontal, SettingsChrome.rowPaddingH)
      .padding(.vertical, SettingsChrome.rowPaddingV)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
    let c = theme.colors
    return Button {
      HapticService.selection()
      action()
    } label: {
      Image(systemName: systemName)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(c.textSecondary)
        .frame(width: 32, height: 32)
        .background(c.surfaceVariant.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  // MARK: - Frequência

  private var frequencySegment: some View {
    let c = theme.colors
    return HStack(spacing: 4) {
      ForEach(InstallmentFrequency.allCases) { option in
        let selected = frequency == option
        Button {
          HapticService.selection()
          frequency = option
        } label: {
          Text(option.label)
            .font(AppTypography.metaSmall.weight(.semibold))
            .foregroundStyle(selected ? c.onAccent : c.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
              RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(selected ? c.accent : Color.clear)
            }
        }
        .buttonStyle(.plain)
      }
    }
  }

  // MARK: - Preview

  private var previewContent: some View {
    let c = theme.colors
    let visible = Array(previewDates.prefix(3))
    let remaining = max(0, quantity - visible.count)

    return VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text("\(quantity) subtarefas")
          .font(AppTypography.cardHeading)
          .foregroundStyle(c.textPrimary)
        Spacer()
        if remaining > 0 {
          Text("+\(remaining) mais")
            .font(AppTypography.metaSmall)
            .foregroundStyle(c.textTertiary)
        }
      }
      .padding(.horizontal, SettingsChrome.rowPaddingH)
      .padding(.top, SettingsChrome.rowPaddingV)
      .padding(.bottom, 8)

      ForEach(Array(visible.enumerated()), id: \.offset) { index, date in
        if index > 0 {
          SettingsCardDivider(leadingPadding: 52)
        }
        previewRow(index: index + 1, date: date)
      }

      if visible.isEmpty {
        Text("Ajuste a quantidade para ver o preview.")
          .font(AppTypography.metaSmall)
          .foregroundStyle(c.textTertiary)
          .padding(.horizontal, SettingsChrome.rowPaddingH)
          .padding(.vertical, SettingsChrome.rowPaddingV)
      }
    }
    .padding(.bottom, 4)
  }

  private func previewRow(index: Int, date: Date) -> some View {
    let c = theme.colors
    return HStack(alignment: .top, spacing: 12) {
      RoundedRectangle(cornerRadius: 5, style: .continuous)
        .strokeBorder(c.textTertiary.opacity(0.45), lineWidth: 1.5)
        .frame(width: 18, height: 18)
        .padding(.top, 2)

      VStack(alignment: .leading, spacing: 4) {
        Text("\(effectiveNameBase) / Parcela \(index)")
          .font(AppTypography.settingsTitle)
          .foregroundStyle(c.textPrimary)
          .lineLimit(2)

        HStack(spacing: 8) {
          Text(InstallmentGeneratorLogic.formatDate(date))
            .font(AppTypography.metaSmall)
            .foregroundStyle(c.textSecondary)
          if let parsedValor {
            Text(formatCurrency(parsedValor))
              .font(AppTypography.metaSmall.weight(.semibold))
              .foregroundStyle(c.accent)
          }
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, 10)
  }

  // MARK: - Footer

  private var footerBar: some View {
    let c = theme.colors
    return VStack(spacing: 0) {
      Divider().overlay(c.textTertiary.opacity(0.12))
      PrimaryButton(
        title: "Gerar \(quantity) parcelas",
        action: { _Concurrency.Task { await generate() } },
        colors: c,
        isLoading: generating,
        isEnabled: canGenerate,
        height: 50,
        cornerRadius: 14
      )
      .padding(.horizontal, SettingsChrome.horizontalPadding)
      .padding(.top, 12)
      .padding(.bottom, 12)
      .background(c.background.opacity(0.98))
    }
  }

  // MARK: - Actions

  private func formatCurrency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "pt_BR")
    formatter.currencyCode = "BRL"
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "R$ %.2f", value)
  }

  private func generate() async {
    let base = nameBase.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !base.isEmpty, quantity >= 1, !generating else { return }

    generating = true
    errorMessage = nil
    focusedField = nil

    let dates = previewDates
    let valor = parsedValor

    let rows = (0..<quantity).map { index in
      SubtaskRepository.InstallmentSubtaskInsert(
        task_id: taskId,
        titulo: "\(base) / Parcela \(index + 1)",
        data_vencimento: InstallmentGeneratorLogic.isoDueDate(dates[index]),
        valor: valor,
        concluida: false,
        ordem: index
      )
    }

    do {
      try await SubtaskRepository.shared.createSubtasksBatch(rows)
      HapticService.success()
      onGenerated()
      dismiss()
    } catch {
      errorMessage = "Erro ao gerar parcelas: \(error.localizedDescription)"
      generating = false
    }
  }
}

extension View {
  func installmentGeneratorSheet(
    route: Binding<InstallmentGeneratorRoute?>,
    onGenerated: @escaping () -> Void
  ) -> some View {
    sheet(item: route) { item in
      InstallmentGeneratorSheet(
        taskId: item.taskId,
        taskTitle: item.taskTitle,
        onGenerated: onGenerated
      )
      .environment(ThemeManager.shared)
      .presentationDetents([.medium, .large])
      .presentationDragIndicator(.visible)
      .presentationBackground(ThemeManager.shared.colors.background)
      .presentationCornerRadius(20)
    }
  }
}

struct InstallmentGeneratorRoute: Identifiable {
  let id = UUID()
  let taskId: String
  let taskTitle: String
}

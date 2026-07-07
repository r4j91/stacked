import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tokens tipográficos de linhas de tarefa/subtarefa (paridade iOS AppTypography).
abstract final class AppTypography {
  // ── Título ────────────────────────────────────────────────────────────────
  static const double taskTitleSize = 15.5;
  static const FontWeight taskTitleWeight = FontWeight.w600;
  static const double taskTitleLetterSpacing = -0.2;
  static const double taskTitleHeight = 1.3;

  /// Subtarefas usam a mesma escala de título que tarefas pai.
  static const double subtaskTitleSize = taskTitleSize;
  static const FontWeight subtaskTitleWeight = taskTitleWeight;

  // ── Descrição ─────────────────────────────────────────────────────────────
  static const double taskDescriptionSize = 14;
  static const double taskDescriptionHeight = 1.4;

  static const double subtaskDescriptionSize = taskDescriptionSize;

  // ── Círculo de conclusão ──────────────────────────────────────────────────
  static const double taskCircleSize = 20;
  static const double taskCircleBorderWidth = 2.5;
  static const double taskCircleTickSize = 13;

  static const double subtaskCircleSize = taskCircleSize;
  static const double subtaskCircleBorderWidth = 2;
  static const double subtaskCircleTickSize = taskCircleTickSize;

  static TextStyle taskTitle({required bool done, required bool strikethrough}) {
    return TextStyle(
      fontSize: taskTitleSize,
      fontWeight: taskTitleWeight,
      color: strikethrough ? AppColors.textTertiary : AppColors.textPrimary,
      decoration: strikethrough ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: AppColors.textTertiary,
      height: taskTitleHeight,
      letterSpacing: taskTitleLetterSpacing,
    );
  }

  static TextStyle subtaskTitle({required bool done}) {
    return TextStyle(
      fontSize: subtaskTitleSize,
      fontWeight: subtaskTitleWeight,
      color: done ? AppColors.textTertiary : AppColors.textPrimary,
      decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: AppColors.textTertiary,
      height: taskTitleHeight,
      letterSpacing: taskTitleLetterSpacing,
    );
  }

  static TextStyle taskDescription({Color? color}) {
    return TextStyle(
      fontSize: taskDescriptionSize,
      color: color ?? AppColors.textSecondary,
      height: taskDescriptionHeight,
    );
  }

  static TextStyle subtaskDescription({required bool done}) {
    return TextStyle(
      fontSize: subtaskDescriptionSize,
      color: AppColors.textSecondary.withValues(alpha: done ? 0.55 : 0.85),
      height: taskDescriptionHeight,
    );
  }
}

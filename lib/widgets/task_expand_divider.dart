import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Linhas entre tarefa pai e subtarefas (estilo Todoist: inset após o círculo).
abstract final class TaskExpandDividerStyle {
  static const double thickness = 0.5;
  static const double alpha = 0.12;

  static Color color([double? alphaOverride]) =>
      AppColors.textTertiary.withValues(alpha: alphaOverride ?? alpha);

  /// Card — após PriorityDot (16 + 12 + 20).
  static const double cardParentInset = 48;

  /// Card — após círculo da subtarefa (36 + 4 + 20).
  static const double cardSubtaskInset = 60;

  /// Lista — após PriorityDot (18 + 12 + 20).
  static const double listParentInset = 50;

  /// Lista — após círculo da subtarefa (padding da row + diâmetro).
  static double listSubtaskInset(double rowLeadingPadding) =>
      rowLeadingPadding + AppTypography.subtaskCircleSize;
}

class TaskExpandDivider extends StatelessWidget {
  final double indent;
  final Color? color;
  final double? thickness;

  const TaskExpandDivider({
    super.key,
    required this.indent,
    this.color,
    this.thickness,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Divider(
        height: 1,
        thickness: thickness ?? TaskExpandDividerStyle.thickness,
        color: color ?? TaskExpandDividerStyle.color(),
      ),
    );
  }
}

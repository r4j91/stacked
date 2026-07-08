import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../theme/app_colors.dart';
import '../../theme/project_display_mode.dart';
import '../pressable.dart';

class ProjectDisplayModePicker extends StatelessWidget {
  final ProjectDisplayMode selected;
  final ValueChanged<ProjectDisplayMode> onSelected;

  const ProjectDisplayModePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.textTertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Exibição',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final mode in ProjectDisplayMode.values) ...[
                if (mode != ProjectDisplayMode.values.first) const SizedBox(width: 6),
                Expanded(
                  child: _ModeCell(
                    mode: mode,
                    selected: selected == mode,
                    onTap: () => onSelected(mode),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeCell extends StatelessWidget {
  final ProjectDisplayMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCell({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: _modeIcon(mode),
              size: 17,
              color: selected ? AppColors.accent : AppColors.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              mode.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<List<dynamic>> _modeIcon(ProjectDisplayMode mode) => switch (mode) {
  ProjectDisplayMode.cards => HugeIcons.strokeRoundedGrid,
  ProjectDisplayMode.cardsRefined => HugeIcons.strokeRoundedLayoutGrid,
  ProjectDisplayMode.list => HugeIcons.strokeRoundedListView,
};

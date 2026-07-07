import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_context_menu.dart';

class SwipeableTaskTile extends StatelessWidget {
  final Task task;
  final Widget child;
  final VoidCallback? onCompleted;
  final VoidCallback? onDeleteRequested;
  final VoidCallback? onEdit;
  final VoidCallback? onRefresh;

  const SwipeableTaskTile({
    super.key,
    required this.task,
    required this.child,
    this.onCompleted,
    this.onDeleteRequested,
    this.onEdit,
    this.onRefresh,
  });

  Future<void> _openContextMenu(BuildContext context, Offset tapPosition) {
    return showTaskContextMenu(
      context,
      task: task,
      tapPosition: tapPosition,
      onEdit: onEdit,
      onComplete: onCompleted,
      onDelete: onDeleteRequested,
      onRefresh: onRefresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (d) => _openContextMenu(context, d.globalPosition),
      onSecondaryTapDown: (d) => _openContextMenu(context, d.globalPosition),
      child: child,
    );
  }
}

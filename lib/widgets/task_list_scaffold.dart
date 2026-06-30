import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import 'scroll_fade_overlay.dart';

/// Scroll + fade + bottom inset + optional pull-to-refresh para telas de lista.
class TaskListScaffold extends StatelessWidget {
  final ScrollController? scrollController;
  final Future<void> Function()? onRefresh;
  final List<Widget> slivers;

  const TaskListScaffold({
    super.key,
    required this.slivers,
    this.scrollController,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = AppLayout.bottomListInset(context);
    final scrollView = ScrollFadeOverlay(
      scrollController: scrollController,
      child: CustomScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          ...slivers,
          SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
        ],
      ),
    );

    if (onRefresh == null) return scrollView;

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: onRefresh!,
      child: scrollView,
    );
  }
}

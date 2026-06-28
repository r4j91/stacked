import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class EmptyState extends StatefulWidget {
  final List<List<dynamic>> hugeIcon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.hugeIcon,
    required this.title,
    this.subtitle,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _iconAnim;
  late final Animation<double> _titleAnim;
  late final Animation<double> _subtitleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 540),
      vsync: this,
    );

    _iconAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.00, 0.55, curve: Curves.easeOutCubic),
    );
    _titleAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.11, 0.66, curve: Curves.easeOutCubic),
    );
    _subtitleAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.22, 0.78, curve: Curves.easeOutCubic),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.hero - 8,
          vertical: AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _iconAnim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.7, end: 1.0).animate(_iconAnim),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceVariant,
                        ),
                        child: HugeIcon(
                          icon: widget.hugeIcon,
                          size: 34,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.xl),

            FadeTransition(
              opacity: _titleAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(_titleAnim),
                child: Text(
                  widget.title,
                  style: textTheme.titleLarge?.copyWith(height: 1.3),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (widget.subtitle != null) ...[
              SizedBox(height: AppSpacing.sm),

              FadeTransition(
                opacity: _subtitleAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(_subtitleAnim),
                  child: Text(
                    widget.subtitle!,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

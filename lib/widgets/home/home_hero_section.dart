import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/home_hero_style.dart';
import '../load_error_view.dart';
import '../pressable.dart';
import 'home_hero_illustrations.dart';

class HomeHeroSection extends StatelessWidget {
  final HomeHeroStyle style;
  final bool loading;
  final String? error;
  final int overdueCount;
  final String firstName;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenOverdue;

  const HomeHeroSection({
    super.key,
    required this.style,
    required this.loading,
    this.error,
    required this.overdueCount,
    required this.firstName,
    this.onRetry,
    this.onOpenOverdue,
  });

  bool get _isOverdue => overdueCount > 0;
  String get _statusLabel => homeStatusLabel(overdueCount);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (error != null) {
      return LoadErrorView(onRetry: onRetry ?? () {});
    }

    return Padding(
      padding: _outerPadding,
      child: switch (style) {
        HomeHeroStyle.classic => _classic(context),
        HomeHeroStyle.orbital => _wrapOverdue(_orbital(context)),
        HomeHeroStyle.orbitalOpen => _wrapOverdue(_orbitalOpen(context)),
        HomeHeroStyle.horizon => _wrapOverdue(_horizon(context)),
        HomeHeroStyle.capsule => _wrapOverdue(_capsule(context)),
        HomeHeroStyle.openType => _wrapOverdue(_openType(context)),
        HomeHeroStyle.focus => _wrapOverdue(
          _focus(context),
          semanticsLabel: '${homeFocusHeroTitle(overdueCount)}. ${homeFocusHeroSubtitle(overdueCount)}',
          semanticsWhenClear: true,
        ),
      },
    );
  }

  EdgeInsets get _outerPadding {
    if (style == HomeHeroStyle.classic ||
        style == HomeHeroStyle.openType ||
        style == HomeHeroStyle.orbitalOpen) {
      return const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm,
      );
    }
    return const EdgeInsets.fromLTRB(
      AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm,
    );
  }

  Widget _wrapOverdue(
    Widget child, {
    String? semanticsLabel,
    bool semanticsWhenClear = false,
  }) {
    final label = semanticsLabel ?? _statusLabel;
    if (!_isOverdue) {
      if (semanticsWhenClear) {
        return Semantics(label: label, child: child);
      }
      return child;
    }
    return Pressable(
      onTap: onOpenOverdue,
      child: Semantics(
        button: true,
        label: label,
        child: child,
      ),
    );
  }

  Widget _classic(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          homeGreetingLine(firstName),
          style: textTheme.headlineMedium?.copyWith(letterSpacing: -0.3),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Vamos focar no que realmente importa hoje.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_isOverdue) _classicOverdue(context) else _classicClear(),
      ],
    );
  }

  Widget _classicClear() {
    return Semantics(
      label: 'Tudo em dia',
      child: Row(
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedTick01, size: 16, color: AppColors.onTrackMuted),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Tudo em dia',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onTrackMuted),
          ),
        ],
      ),
    );
  }

  Widget _classicOverdue(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Pressable(
      onTap: onOpenOverdue,
      child: Semantics(
        button: true,
        label: _statusLabel,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.overdue.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.overdue.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedAlert02, size: 18, color: AppColors.overdue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _statusLabel,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.overdue),
                ),
              ),
              HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 14, color: AppColors.overdue.withValues(alpha: 0.85)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orbital(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isOverdue
              ? AppColors.overdue.withValues(alpha: 0.16)
              : AppColors.textPrimary.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          HomeOrbitalStackIllustration(isOverdue: _isOverdue, overdueCount: overdueCount),
          const SizedBox(width: 14),
          Expanded(child: _greetingColumn(nameSize: 20)),
          if (_isOverdue)
            HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 14, color: AppColors.overdue.withValues(alpha: 0.7)),
        ],
      ),
    );
  }

  Widget _orbitalOpen(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HomeOrbitalStackIllustration(isOverdue: _isOverdue, overdueCount: overdueCount),
            const SizedBox(width: 12),
            Expanded(child: _greetingColumn(nameSize: 22)),
            if (_isOverdue)
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 14,
                color: AppColors.overdue.withValues(alpha: 0.7),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 1,
          color: _isOverdue
              ? AppColors.overdue.withValues(alpha: 0.12)
              : AppColors.textPrimary.withValues(alpha: 0.06),
        ),
      ],
    );
  }

  Widget _horizon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isOverdue
              ? AppColors.overdue.withValues(alpha: 0.14)
              : AppColors.textPrimary.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _greetingColumn(nameSize: 20)),
          HomeHorizonGlyphIllustration(
            timeOfDay: homeTimeOfDayNow(),
            isOverdue: _isOverdue,
            overdueCount: overdueCount,
          ),
          if (_isOverdue) ...[
            const SizedBox(width: 4),
            HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 14, color: AppColors.overdue.withValues(alpha: 0.7)),
          ],
        ],
      ),
    );
  }

  Widget _capsule(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isOverdue
              ? AppColors.overdue.withValues(alpha: 0.14)
              : AppColors.textPrimary.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(homeGreetingPhrase(), style: _phraseStyle),
              const Spacer(),
              _statusCapsule(),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (firstName.isNotEmpty)
                Text(
                  firstName,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
              const Spacer(),
              if (_isOverdue)
                HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 14, color: AppColors.overdue.withValues(alpha: 0.7)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _focus(BuildContext context) {
    final title = homeFocusHeroTitle(overdueCount);
    final subtitle = homeFocusHeroSubtitle(overdueCount);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isOverdue
              ? AppColors.overdue.withValues(alpha: 0.18)
              : AppColors.textPrimary.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          HomeFocusInboxIllustration(isOverdue: _isOverdue, overdueCount: overdueCount),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _isOverdue ? AppColors.overdue : AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (_isOverdue)
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 14,
              color: AppColors.overdue.withValues(alpha: 0.75),
            ),
        ],
      ),
    );
  }

  Widget _openType(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(homeGreetingPhrase(), style: _phraseStyle),
        Row(
          children: [
            if (firstName.isNotEmpty)
              Expanded(
                child: Text(
                  firstName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
              ),
            if (_isOverdue)
              HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 14, color: AppColors.overdue.withValues(alpha: 0.7)),
          ],
        ),
        const SizedBox(height: 8),
        _AccentLine(isOverdue: _isOverdue),
        const SizedBox(height: 8),
        _statusLine(),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: _isOverdue
              ? AppColors.overdue.withValues(alpha: 0.15)
              : AppColors.textPrimary.withValues(alpha: 0.06),
        ),
      ],
    );
  }

  Widget _greetingColumn({required double nameSize}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(homeGreetingPhrase(), style: _phraseStyle),
        if (firstName.isNotEmpty)
          Text(
            firstName,
            style: TextStyle(
              fontSize: nameSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
        const SizedBox(height: 2),
        _statusLine(),
      ],
    );
  }

  Widget _statusLine() {
    final color = _isOverdue ? AppColors.overdue : AppColors.tagGreen;
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          _statusLabel,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _statusCapsule() {
    final color = _isOverdue ? AppColors.overdue : AppColors.tagGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        _statusLabel,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  TextStyle get _phraseStyle => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: -0.1,
  );
}

class _AccentLine extends StatefulWidget {
  final bool isOverdue;
  const _AccentLine({required this.isOverdue});

  @override
  State<_AccentLine> createState() => _AccentLineState();
}

class _AccentLineState extends State<_AccentLine> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isOverdue ? AppColors.overdue : AppColors.accent;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: LinearGradient(
              colors: [
                base.withValues(alpha: 0.38 + (t * 0.12)),
                base.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}

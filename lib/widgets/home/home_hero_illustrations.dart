import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/home_hero_style.dart';

class HomeOrbitalStackIllustration extends StatefulWidget {
  final bool isOverdue;
  final int overdueCount;

  const HomeOrbitalStackIllustration({
    super.key,
    required this.isOverdue,
    required this.overdueCount,
  });

  @override
  State<HomeOrbitalStackIllustration> createState() => _HomeOrbitalStackIllustrationState();
}

class _HomeOrbitalStackIllustrationState extends State<HomeOrbitalStackIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
  }

  @override
  void didUpdateWidget(covariant HomeOrbitalStackIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeAnimate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeAnimate();
  }

  void _maybeAnimate() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final haloColor = widget.isOverdue ? AppColors.overdue : AppColors.accent;

    return SizedBox(
      width: 48,
      height: 48,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final scale = 1 + (t * 0.06);
          final floatY = t * -2;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52 * scale,
                height: 52 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      haloColor.withValues(alpha: isDark ? 0.2 : 0.14),
                      haloColor.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, floatY),
                child: _stackLayers(isDark),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: _badge(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _badge() {
    if (widget.isOverdue) {
      final label = widget.overdueCount > 9 ? '9+' : '${widget.overdueCount}';
      return _miniBadge(
        label: label,
        color: AppColors.overdue,
        isText: true,
      );
    }
    return _miniBadge(label: '✓', color: AppColors.tagGreen, isText: false);
  }

  Widget _miniBadge({required String label, required Color color, required bool isText}) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.22),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: isText ? 8 : 7,
          fontWeight: FontWeight.w800,
          color: color,
          height: 1,
        ),
      ),
    );
  }

  Widget _stackLayers(bool isDark) {
    return SizedBox(
      width: 36,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _layer(bottom: 0, rotation: -0.05, opacity: 0.5, isTop: false, isDark: isDark),
          _layer(bottom: 7, rotation: 0.035, opacity: 0.7, isTop: false, isDark: isDark),
          _layer(
            bottom: 14,
            rotation: widget.isOverdue ? 0.12 : -0.02,
            opacity: 1,
            isTop: true,
            isDark: isDark,
            dx: widget.isOverdue ? 2 : 0,
          ),
        ],
      ),
    );
  }

  Widget _layer({
    required double bottom,
    required double rotation,
    required double opacity,
    required bool isTop,
    required bool isDark,
    double dx = 0,
  }) {
    final borderColor = isTop
        ? (widget.isOverdue
            ? AppColors.overdue.withValues(alpha: 0.35)
            : AppColors.accent.withValues(alpha: 0.28))
        : AppColors.textPrimary.withValues(alpha: isDark ? 0.1 : 0.08);
    final fill = isTop
        ? (widget.isOverdue
            ? AppColors.overdue.withValues(alpha: 0.1)
            : AppColors.accent.withValues(alpha: 0.09))
        : AppColors.surfaceVariant;

    return Positioned(
      left: 3 + dx,
      bottom: bottom,
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 30,
            height: 18,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: borderColor),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeHorizonGlyphIllustration extends StatefulWidget {
  final HomeTimeOfDay timeOfDay;
  final bool isOverdue;
  final int overdueCount;

  const HomeHorizonGlyphIllustration({
    super.key,
    required this.timeOfDay,
    required this.isOverdue,
    required this.overdueCount,
  });

  @override
  State<HomeHorizonGlyphIllustration> createState() => _HomeHorizonGlyphIllustrationState();
}

class _HomeHorizonGlyphIllustrationState extends State<HomeHorizonGlyphIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glow = widget.isOverdue ? AppColors.overdue : AppColors.accent;
    final orb = _orbSpec();

    return SizedBox(
      width: 44,
      height: 44,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final scale = 1 + (_controller.value * 0.05);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44 * scale,
                height: 44 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glow.withValues(alpha: isDark ? 0.14 : 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  width: 28,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 6,
                right: 6,
                child: Container(height: 1, color: AppColors.textPrimary.withValues(alpha: 0.12)),
              ),
              Positioned(
                left: 22 + orb.dx,
                top: 22 + orb.dy,
                child: Container(
                  width: orb.size,
                  height: orb.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: orb.color,
                    boxShadow: [BoxShadow(color: orb.shadow, blurRadius: 4)],
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: widget.isOverdue
                    ? _flagBadge(
                        widget.overdueCount > 9 ? '9+' : '${widget.overdueCount}',
                        AppColors.overdue,
                      )
                    : _flagBadge('✓', AppColors.tagGreen),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _flagBadge(String label, Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: color, height: 1),
      ),
    );
  }

  ({double dx, double dy, double size, Color color, Color shadow}) _orbSpec() {
    if (widget.isOverdue) {
      return (
        dx: 0,
        dy: 2,
        size: 8,
        color: AppColors.overdue.withValues(alpha: 0.75),
        shadow: AppColors.overdue.withValues(alpha: 0.35),
      );
    }
    return switch (widget.timeOfDay) {
      HomeTimeOfDay.morning => (
        dx: -10,
        dy: 4,
        size: 8,
        color: AppColors.accent.withValues(alpha: 0.65),
        shadow: AppColors.accent.withValues(alpha: 0.4),
      ),
      HomeTimeOfDay.afternoon => (
        dx: 0,
        dy: -6,
        size: 8,
        color: const Color(0xFFF5A623).withValues(alpha: 0.75),
        shadow: const Color(0xFFF5A623).withValues(alpha: 0.35),
      ),
      HomeTimeOfDay.night => (
        dx: 10,
        dy: 4,
        size: 6,
        color: const Color(0xFFB18CF5).withValues(alpha: 0.7),
        shadow: const Color(0xFFB18CF5).withValues(alpha: 0.3),
      ),
    };
  }
}

class HomeFocusInboxIllustration extends StatelessWidget {
  final bool isOverdue;
  final int overdueCount;

  const HomeFocusInboxIllustration({
    super.key,
    required this.isOverdue,
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = AppColors.textTertiary.withValues(alpha: isDark ? 0.38 : 0.32);
    final fill = AppColors.surfaceVariant.withValues(alpha: isDark ? 0.55 : 0.72);

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isOverdue
                    ? [AppColors.overdue.withValues(alpha: isDark ? 0.14 : 0.1), Colors.transparent]
                    : [AppColors.accent.withValues(alpha: isDark ? 0.16 : 0.11), Colors.transparent],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, 2),
            child: Container(
              width: 30,
              height: 20,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: line.withValues(alpha: 0.85)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 4),
                  Container(
                    width: 14,
                    height: 2,
                    decoration: BoxDecoration(
                      color: line.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 9,
                    height: 2,
                    decoration: BoxDecoration(
                      color: line.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: isOverdue ? _overdueBadge() : _clearBadge(),
          ),
        ],
      ),
    );
  }

  Widget _clearBadge() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.tagGreen.withValues(alpha: 0.22),
        border: Border.all(color: AppColors.tagGreen.withValues(alpha: 0.38)),
      ),
      alignment: Alignment.center,
      child: Text(
        '✓',
        style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: AppColors.tagGreen, height: 1),
      ),
    );
  }

  Widget _overdueBadge() {
    final label = overdueCount > 9 ? '9+' : '$overdueCount';
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.overdue,
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
      ),
    );
  }
}

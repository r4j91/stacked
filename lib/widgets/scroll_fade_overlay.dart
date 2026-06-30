// SCROLL-FADE-V1
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import 'bottom_nav_scope.dart';

/// Scrim gradients on scroll edges so content dissolves smoothly under
/// the status bar (top, scroll-aware) and floating nav pill + FAB (bottom).
///
/// Uses opaque background overlays (not alpha-mask on content) for a
/// stronger hide than [ShaderMask] alone.
class ScrollFadeOverlay extends StatefulWidget {
  const ScrollFadeOverlay({
    super.key,
    required this.child,
    this.scrollController,
    this.fadeHeight,
    this.showTopFade = true,
  });

  final Widget child;
  final ScrollController? scrollController;

  /// Height of the bottom scrim. Defaults to nav chrome + extra buffer.
  final double? fadeHeight;

  /// Fade at top edge while scrolling up. Requires [scrollController].
  final bool showTopFade;

  /// Scroll distance over which the top fade ramps from 0 → 1.
  static const topFadeScrollRange = 48.0;

  @override
  State<ScrollFadeOverlay> createState() => _ScrollFadeOverlayState();
}

class _ScrollFadeOverlayState extends State<ScrollFadeOverlay> {
  double _topFadeT = 0;

  ScrollController? get _ctrl => widget.scrollController;

  @override
  void initState() {
    super.initState();
    _ctrl?.addListener(_onScroll);
    if (_ctrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncTopFade());
    }
  }

  @override
  void didUpdateWidget(ScrollFadeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != _ctrl) {
      oldWidget.scrollController?.removeListener(_onScroll);
      _ctrl?.addListener(_onScroll);
      _syncTopFade();
    }
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() => _syncTopFade();

  void _syncTopFade() {
    if (!mounted) return;
    if (!widget.showTopFade || _ctrl == null) {
      if (_topFadeT != 0) setState(() => _topFadeT = 0);
      return;
    }
    if (!_ctrl!.hasClients) {
      if (_topFadeT != 0) setState(() => _topFadeT = 0);
      return;
    }
    final t = (_ctrl!.offset / ScrollFadeOverlay.topFadeScrollRange)
        .clamp(0.0, 1.0);
    if (t != _topFadeT) setState(() => _topFadeT = t);
  }

  @override
  Widget build(BuildContext context) {
    if (AppLayout.isDesktop(context)) return widget.child;
    if (!BottomNavScope.isVisible(context)) return widget.child;

    final bg = AppColors.background;
    final bottomHeight =
        widget.fadeHeight ?? AppLayout.totalBottomChromeHeight(context) + 28;
    final topHeight = MediaQuery.paddingOf(context).top + 20;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (widget.showTopFade && _topFadeT > 0)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topHeight,
            child: IgnorePointer(
              child: Opacity(
                opacity: _topFadeT,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        bg,
                        bg.withValues(alpha: 0.96),
                        bg.withValues(alpha: 0.82),
                        bg.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.28, 0.62, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomHeight,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bg.withValues(alpha: 0),
                    bg.withValues(alpha: 0.82),
                    bg.withValues(alpha: 0.96),
                    bg,
                  ],
                  stops: const [0.0, 0.38, 0.72, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

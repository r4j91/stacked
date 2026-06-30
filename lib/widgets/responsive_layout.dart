import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../screens/task_detail_sheet.dart';
import '../screens/search_screen.dart';
import '../services/haptic_service.dart';
import '../theme/app_layout.dart';
import '../theme/app_durations.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_motion.dart';
import 'bottom_nav_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/new_project_sheet.dart';
import 'desktop_shell/desktop_app_shell.dart';
import 'pressable.dart';
import 'package:hugeicons/hugeicons.dart';

class _NavItem {
  final List<List<dynamic>> hugeIcon;
  final String label;
  final double iconSize;

  const _NavItem({
    required this.hugeIcon,
    required this.label,
    this.iconSize = AppIconSize.nav,
  });
}

final _navItems = [
  _NavItem(hugeIcon: HugeIcons.strokeRoundedHome01, label: 'Navegar'),
  _NavItem(hugeIcon: HugeIcons.strokeRoundedInbox, label: 'Inbox'),
  // Calendar02 tem mais padding interno no SVG — +2px para peso visual igual.
  _NavItem(
    hugeIcon: HugeIcons.strokeRoundedCalendar02,
    label: 'Hoje',
    iconSize: AppIconSize.xl,
  ),
  _NavItem(hugeIcon: HugeIcons.strokeRoundedCalendar03, label: 'Em breve'),
  _NavItem(hugeIcon: HugeIcons.strokeRoundedFilterHorizontal, label: 'Filtros'),
];

class ResponsiveLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final VoidCallback? onTaskCreated;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProjectCreated;
  final void Function(int filterIndex)? onDesktopFilterTap;

  const ResponsiveLayout({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.onTaskCreated,
    this.onSearchTap,
    this.onProjectCreated,
    this.onDesktopFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Builder(builder: (context) {
      void openNewTask() => showNewTaskSheet(context, onSaved: onTaskCreated);
      void openSearch() => showSearchScreen(context);
      void openNewProject() => unawaited(
            showNewProjectSheet(context, onCreated: onProjectCreated),
          );

      // ── Desktop ───────────────────────────────────────────────────────────
      if (AppLayout.isDesktop(context)) {
        return DesktopAppShell(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          body: body,
          onNewTask: openNewTask,
          onSearch: openSearch,
          onProjectCreated: onProjectCreated,
          onFilterTap: onDesktopFilterTap,
        );
      }

      final adaptedBody = _adaptBodyForScreenWidth(body, screenWidth);

      // ── Mobile / Tablet ─────────────────────────────────────────────────────
      final bottomPadding = MediaQuery.of(context).padding.bottom;
      const sideMargin = AppLayout.fabSideMargin;
      final pillMarginBottom = bottomPadding + AppLayout.bottomNavPillMargin;
      final totalBarHeight = AppLayout.totalBottomChromeHeight(context);

      return Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: BottomNavScope(
            visible: true,
            child: adaptedBody,
          ),
        ),
        bottomNavigationBar: Material(
          color: Colors.transparent,
          child: SizedBox(
            height: totalBarHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Liquid Glass pill ────────────────────────────────────────
                Positioned(
                  left: sideMargin,
                  right: sideMargin,
                  bottom: pillMarginBottom,
                  height: AppLayout.bottomNavPillHeight,
                  child: _LiquidGlassPill(
                    items: _navItems,
                    selectedIndex: selectedIndex,
                    onSelected: onDestinationSelected,
                  ),
                ),
                // ── FAB — expandable menu, above pill ───────────────────────
                Positioned(
                  right: sideMargin,
                  bottom: pillMarginBottom + AppLayout.bottomNavPillHeight + AppLayout.fabGap,
                  width: AppLayout.fabSize,
                  height: AppLayout.fabSize,
                  child: _ExpandableFAB(
                    onNewTask: openNewTask,
                    onNewProject: openNewProject,
                    onSearch: openSearch,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Tablet: center content with readable max width. Phone: full bleed.
Widget _adaptBodyForScreenWidth(Widget body, double screenWidth) {
  if (screenWidth < AppLayout.breakpointPhone) return body;
  return Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: AppLayout.tabletContentMaxWidth(screenWidth)),
      child: body,
    ),
  );
}

// ── FAB action descriptor ─────────────────────────────────────────────────────

class _FabAction {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onTap;
  const _FabAction({required this.icon, required this.label, this.onTap});
}

// ── Expandable FAB ────────────────────────────────────────────────────────────

class _ExpandableFAB extends StatefulWidget {
  final VoidCallback onNewTask;
  final VoidCallback? onNewProject;
  final VoidCallback? onSearch;

  const _ExpandableFAB({required this.onNewTask, this.onNewProject, this.onSearch});

  @override
  State<_ExpandableFAB> createState() => _ExpandableFABState();
}

class _ExpandableFABState extends State<_ExpandableFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotCtrl;
  late final Animation<double> _rotation;
  OverlayEntry? _overlay;
  bool _open = false;

  static const _fabGap = AppLayout.fabGap;
  static const _sideMargin = AppLayout.fabSideMargin;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
        vsync: this, duration: AppDurations.medium);
    _rotation = Tween<double>(begin: 0.0, end: 0.125)
        .animate(CurvedAnimation(parent: _rotCtrl, curve: AppCurves.easeOutCubic));
  }

  @override
  void dispose() {
    _close();
    _rotCtrl.dispose();
    super.dispose();
  }

  void _toggle() => _open ? _close() : _openMenu();

  void _openMenu() {
    HapticService().fabOpened();
    final mq = MediaQuery.of(context);
    final fabBottom = mq.padding.bottom + AppLayout.bottomNavPillMargin + AppLayout.bottomNavPillHeight + _fabGap;

    _overlay = OverlayEntry(
      builder: (_) => _FabOverlay(
        fabBottom: fabBottom,
        fabRight: _sideMargin,
        onDismiss: _close,
        actions: [
          _FabAction(
            icon: HugeIcons.strokeRoundedTaskAdd01,
            label: 'Nova tarefa',
            onTap: () { _close(); widget.onNewTask(); },
          ),
          _FabAction(
            icon: HugeIcons.strokeRoundedFolder01,
            label: 'Novo projeto',
            onTap: () { _close(); widget.onNewProject?.call(); },
          ),
          _FabAction(
            icon: HugeIcons.strokeRoundedSearch01,
            label: 'Buscar',
            onTap: () { _close(); widget.onSearch?.call(); },
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlay!);
    _rotCtrl.forward();
    setState(() => _open = true);
  }

  void _close() {
    if (!_open && _overlay == null) return;
    _overlay?.remove();
    _overlay = null;
    _rotCtrl.reverse();
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _open ? 'Fechar menu de ações' : 'Criar novo',
      hint: _open ? null : 'Abre opções de nova tarefa, projeto e busca',
      child: Pressable(
      pressedScale: 0.92,
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (_, child) =>
            Transform.rotate(angle: _rotation.value * 2 * math.pi, child: child),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent,
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Center(
            child: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 27, color: AppColors.background),
          ),
        ),
      ),
    ),
    );
  }
}

// ── FAB overlay: backdrop + action items ──────────────────────────────────────

class _FabOverlay extends StatefulWidget {
  final double fabBottom;
  final double fabRight;
  final VoidCallback onDismiss;
  final List<_FabAction> actions;

  const _FabOverlay({
    required this.fabBottom,
    required this.fabRight,
    required this.onDismiss,
    required this.actions,
  });

  @override
  State<_FabOverlay> createState() => _FabOverlayState();
}

class _FabOverlayState extends State<_FabOverlay> with TickerProviderStateMixin {
  late final AnimationController _barrierCtrl;
  late final List<AnimationController> _itemCtrls;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;
  bool _animationsStarted = false;

  void _startAnimations() {
    if (_animationsStarted) return;
    _animationsStarted = true;

    final motion = AppMotion.enabled(context);
    final barrierMs = AppMotion.milliseconds(context, AppDurations.normal.inMilliseconds);
    final itemMs = AppMotion.milliseconds(context, AppDurations.medium.inMilliseconds);

    _barrierCtrl = AnimationController(vsync: this, duration: barrierMs)
      ..forward();

    _itemCtrls = List.generate(
      widget.actions.length,
      (_) => AnimationController(vsync: this, duration: itemMs),
    );

    _fades = _itemCtrls
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut)
            as Animation<double>)
        .toList();

    _slides = _itemCtrls
        .map((c) => Tween<Offset>(
                    begin: const Offset(0, 0.25), end: Offset.zero)
                .animate(
                    CurvedAnimation(parent: c, curve: AppCurves.easeOutCubic)))
        .toList();

    if (motion) {
      for (var i = 0; i < _itemCtrls.length; i++) {
        Future.delayed(Duration(milliseconds: i * 45), () {
          if (mounted) _itemCtrls[i].forward();
        });
      }
    } else {
      for (final c in _itemCtrls) {
        c.value = 1.0;
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startAnimations();
  }

  @override
  void dispose() {
    if (_animationsStarted) {
      _barrierCtrl.dispose();
      for (final c in _itemCtrls) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_animationsStarted) return const SizedBox.shrink();
    const fabSize = 56.0;
    const itemH = 44.0;
    const itemGap = 12.0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark backdrop — tap to dismiss
          Positioned.fill(
            child: FadeTransition(
              opacity: _barrierCtrl,
              child: GestureDetector(
                onTap: widget.onDismiss,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),

          // Action rows: stacked bottom→top (index 0 = closest to FAB)
          ...widget.actions.asMap().entries.map((e) {
            final i = e.key;
            final action = e.value;
            final bottomOffset =
                widget.fabBottom + fabSize + 14 + i * (itemH + itemGap);

            return Positioned(
              right: widget.fabRight,
              bottom: bottomOffset,
              child: FadeTransition(
                opacity: _fades[i],
                child: SlideTransition(
                  position: _slides[i],
                  child: _FabMenuItem(
                    icon: action.icon,
                    label: action.label,
                    onTap: action.onTap,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Single action row ──────────────────────────────────────────────────────────

class _FabMenuItem extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onTap;
  const _FabMenuItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
      onTap: () {
        HapticService().selectionClick();
        onTap?.call();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
              ),
            ),
            child: HugeIcon(icon: icon, size: 20, color: AppColors.accent),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Liquid Glass pill ─────────────────────────────────────────────────────────

class _LiquidGlassPill extends StatefulWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _LiquidGlassPill({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<_LiquidGlassPill> createState() => _LiquidGlassPillState();
}

class _LiquidGlassPillState extends State<_LiquidGlassPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _itemWidth = 0;
  bool _laid = false;

  static const _spring = SpringDescription(mass: 1, stiffness: 600, damping: 32);

  // Sem blur quando reduced motion — menos custo GPU + alinhado a a11y.
  bool _useSimulatedBlur(BuildContext context) => !AppMotion.enabled(context);

  // Indicator color: enough contrast on both dark and light themes
  Color get _indicatorColor => AppColors.navBar.computeLuminance() > 0.5
      ? AppColors.background   // light theme: tinted background for contrast
      : AppColors.surfaceVariant; // dark theme: lighter surface

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _springTo(double target) {
    if (!AppMotion.enabled(context)) {
      _ctrl.value = target;
      return;
    }
    final sim = SpringSimulation(_spring, _ctrl.value, target, _ctrl.velocity);
    _ctrl.animateWith(sim);
  }

  @override
  void didUpdateWidget(_LiquidGlassPill old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex && _laid) {
      _springTo(widget.selectedIndex * _itemWidth);
    }
  }

  @override
  Widget build(BuildContext context) {
    // NAVBAR-PERF-OLD: sem RepaintBoundary, sigmaX/Y: 24
    return RepaintBoundary(
      child: ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: _useSimulatedBlur(context)
          // NAVBAR-PERF-V1: simulação de blur sem custo de GPU — usado só
          // pra teste A/B de performance, não é o comportamento padrão.
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.navBar.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.textPrimary.withValues(alpha: 0.06),
                  width: 0.8,
                ),
              ),
              child: _buildPillContent(),
            )
          : BackdropFilter(
        // NAVBAR-PERF-V1: sigma 24->16 — imperceptível em movimento, mais barato
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16, tileMode: TileMode.clamp),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.navBar.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              width: 0.8,
            ),
          ),
          child: _buildPillContent(),
        ),
      ),
      ),
    );
  }

  // NAVBAR-PERF-V1: extraído pra ser compartilhado entre o ramo com
  // BackdropFilter real e o ramo simulado (_useSimulatedBlur).
  Widget _buildPillContent() {
    return LayoutBuilder(builder: (_, constraints) {
      final itemWidth = constraints.maxWidth / widget.items.length;
      const inset = 5.0;

      // Set initial position on first layout without animation
      if (!_laid || _itemWidth != itemWidth) {
        _itemWidth = itemWidth;
        _laid = true;
        _ctrl.value = widget.selectedIndex * itemWidth;
      }

      return Stack(
        children: [
          // Spring-animated active indicator
          AnimatedBuilder(
            animation: _ctrl,
            builder: (ctx, child) => Positioned(
              left: _ctrl.value + inset,
              top: inset,
              bottom: inset,
              width: itemWidth - inset * 2,
              child: Container(
                decoration: BoxDecoration(
                  color: _indicatorColor,
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ),
          // Nav items
          Row(
            children: widget.items
                .asMap()
                .entries
                .map((e) => Expanded(
                      child: _PillItem(
                        hugeIcon: e.value.hugeIcon,
                        iconSize: e.value.iconSize,
                        label: e.value.label,
                        selected: widget.selectedIndex == e.key,
                        onTap: () {
                          HapticService().tabChanged();
                          widget.onSelected(e.key);
                        },
                      ),
                    ))
                .toList(),
          ),
        ],
      );
    });
  }
}

// ── Single pill item with bounce on selection ─────────────────────────────────

class _PillItem extends StatefulWidget {
  final List<List<dynamic>> hugeIcon;
  final double iconSize;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillItem({
    required this.hugeIcon,
    required this.iconSize,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PillItem> createState() => _PillItemState();
}

class _PillItemState extends State<_PillItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      duration: AppDurations.medium,
      vsync: this,
    );
    _bounce = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.12)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.12, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 60),
    ]).animate(_bounceCtrl);
  }

  @override
  void didUpdateWidget(_PillItem old) {
    super.didUpdateWidget(old);
    if (!old.selected && widget.selected && AppMotion.enabled(context)) {
      _bounceCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      hint: widget.selected ? 'Aba atual' : 'Ir para ${widget.label}',
      child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: SizedBox(
        height: AppLayout.bottomNavPillHeight,
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: AnimatedBuilder(
            animation: _bounce,
            builder: (context, child) =>
                Transform.scale(scale: AppMotion.enabled(context) ? _bounce.value : 1.0, child: child),
            child: AnimatedSwitcher(
              duration: AppMotion.duration(context, AppDurations.normal),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: HugeIcon(
                icon: widget.hugeIcon,
                key: ValueKey(widget.selected),
                size: widget.iconSize,
                color: widget.selected
                    ? AppColors.accent
                    : AppColors.textTertiary,
              ),
            ),
          ),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: AppMotion.duration(context, AppDurations.normal),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight:
                  widget.selected ? FontWeight.w600 : FontWeight.w400,
              color: widget.selected
                  ? AppColors.accent
                  : AppColors.textTertiary,
              letterSpacing: 0,
              height: 1.1,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(widget.label, maxLines: 1),
            ),
          ),
        ],
        ),
      ),
      ),
    );
  }
}

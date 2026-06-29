import 'package:flutter/widgets.dart';

/// Marca telas que exibem o navbar flutuante (pill + FAB) do [ResponsiveLayout].
///
/// [ScrollFadeOverlay] e [AppLayout.bottomListInset] consultam este scope
/// para não aplicar scrim/padding de nav em rotas empilhadas (ex.: detalhe
/// de projeto, busca, registro).
class BottomNavScope extends InheritedWidget {
  const BottomNavScope({
    super.key,
    required this.visible,
    required super.child,
  });

  final bool visible;

  static bool isVisible(BuildContext context) {
    return maybeOf(context)?.visible ?? false;
  }

  static BottomNavScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BottomNavScope>();
  }

  @override
  bool updateShouldNotify(BottomNavScope oldWidget) =>
      oldWidget.visible != visible;
}

// SCROLL-FADE-V1
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Aplica um gradiente de fade na borda inferior de um widget scrollável,
/// simulando o efeito do Todoist onde o conteúdo dissolve antes da navbar.
///
/// Uso:
///   ScrollFadeOverlay(
///     fadeHeight: 80,
///     child: ListView(...),
///   )
///
/// Sem efeito em desktop (breakpoint >= 1024, igual ResponsiveLayout) —
/// lá não há navbar flutuante por baixo da qual o conteúdo precise dissolver.
class ScrollFadeOverlay extends StatelessWidget {
  const ScrollFadeOverlay({
    super.key,
    required this.child,
    this.fadeHeight = 150.0,
  });

  final Widget child;

  /// Altura em pixels do gradiente de fade na borda inferior.
  /// Deve ser próximo à altura da navbar + safe area.
  final double fadeHeight;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width >= 1024) return child;

    final bg = AppColors.background;

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        final fadeStart = 1.0 - (fadeHeight / bounds.height).clamp(0.0, 0.55);
        final fadeMid = 1.0 - (fadeHeight / bounds.height * 0.35).clamp(0.0, 0.25);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bg,
            bg,
            bg.withValues(alpha: 0.55),
            bg.withValues(alpha: 0),
          ],
          stops: [
            0.0,
            fadeStart,
            fadeMid,
            1.0,
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}

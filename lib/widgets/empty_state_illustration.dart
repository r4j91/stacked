import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum EmptyStateIllustrationKind { inboxZero, todayClear }

class EmptyStateIllustration extends StatelessWidget {
  final EmptyStateIllustrationKind kind;

  const EmptyStateIllustration({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 168,
      height: 128,
      child: CustomPaint(
        painter: switch (kind) {
          EmptyStateIllustrationKind.inboxZero =>
            _InboxZeroPainter(isDark: isDark),
          EmptyStateIllustrationKind.todayClear =>
            _TodayClearPainter(isDark: isDark),
        },
      ),
    );
  }
}

class _InboxZeroPainter extends CustomPainter {
  final bool isDark;

  _InboxZeroPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    _radialGlow(
      canvas,
      Offset(cx, cy),
      58,
      [
        AppColors.accent.withValues(alpha: isDark ? 0.20 : 0.14),
        AppColors.accent.withValues(alpha: isDark ? 0.06 : 0.04),
        AppColors.accent.withValues(alpha: 0),
      ],
    );

    canvas.drawCircle(
      Offset(cx, cy),
      44,
      Paint()..color = AppColors.surfaceVariant.withValues(alpha: isDark ? 0.42 : 0.72),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      44,
      Paint()
        ..color = AppColors.textPrimary.withValues(alpha: isDark ? 0.06 : 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final line = AppColors.textTertiary.withValues(alpha: isDark ? 0.38 : 0.32);
    final trayCenter = Offset(cx, cy + 6);
    final tray = RRect.fromRectAndRadius(
      Rect.fromCenter(center: trayCenter, width: 68, height: 44),
      const Radius.circular(13),
    );
    canvas.drawRRect(
      tray,
      Paint()..color = AppColors.surface.withValues(alpha: isDark ? 0.78 : 0.96),
    );
    canvas.drawRRect(
      tray,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.35,
    );

    final lid = Path()
      ..moveTo(cx - 28, cy - 2)
      ..quadraticBezierTo(cx, cy - 18, cx + 28, cy - 2);
    canvas.drawPath(
      lid,
      Paint()
        ..color = line.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.35
        ..strokeCap = StrokeCap.round,
    );

    for (final (w, dy, alpha) in [(34.0, 14.0, 0.22), (22.0, 22.0, 0.14)]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy + dy), width: w, height: 3),
          const Radius.circular(99),
        ),
        Paint()
          ..color = AppColors.textTertiary.withValues(alpha: isDark ? alpha : alpha * 0.75),
      );
    }

    final sealY = cy - 8;
    canvas.drawCircle(
      Offset(cx, sealY),
      15,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx - 10, sealY - 10),
          Offset(cx + 10, sealY + 10),
          [
            AppColors.accent.withValues(alpha: isDark ? 0.28 : 0.20),
            AppColors.accent.withValues(alpha: isDark ? 0.16 : 0.12),
          ],
        ),
    );
    canvas.drawCircle(
      Offset(cx, sealY),
      15,
      Paint()
        ..color = AppColors.accent.withValues(alpha: isDark ? 0.35 : 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final check = Path()
      ..moveTo(cx - 6, sealY)
      ..lineTo(cx - 1, sealY + 5)
      ..lineTo(cx + 7, sealY - 5);
    canvas.drawPath(
      check,
      Paint()
        ..color = AppColors.accent.withValues(alpha: isDark ? 0.92 : 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _radialGlow(Canvas canvas, Offset c, double r, List<Color> colors) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(c, r, colors, [0.0, 0.55, 1.0]),
    );
  }

  @override
  bool shouldRepaint(covariant _InboxZeroPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _TodayClearPainter extends CustomPainter {
  final bool isDark;

  _TodayClearPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    _radialGlow(
      canvas,
      Offset(cx, cy - 4),
      56,
      [
        AppColors.accent.withValues(alpha: isDark ? 0.16 : 0.11),
        AppColors.accent.withValues(alpha: isDark ? 0.04 : 0.03),
        AppColors.accent.withValues(alpha: 0),
      ],
    );

    canvas.drawCircle(
      Offset(cx, cy + 2),
      42,
      Paint()..color = AppColors.surfaceVariant.withValues(alpha: isDark ? 0.38 : 0.68),
    );
    canvas.drawCircle(
      Offset(cx, cy + 2),
      42,
      Paint()
        ..color = AppColors.textPrimary.withValues(alpha: isDark ? 0.05 : 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final arcRect = Rect.fromCenter(
      center: Offset(cx, cy - 22),
      width: 46,
      height: 46,
    );
    canvas.drawArc(
      arcRect,
      math.pi * 1.14,
      math.pi * 0.72,
      false,
      Paint()
        ..color = AppColors.accent.withValues(alpha: isDark ? 0.48 : 0.36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      Offset(cx, cy - 44),
      3.5,
      Paint()..color = AppColors.accent.withValues(alpha: isDark ? 0.62 : 0.48),
    );

    final line = AppColors.textTertiary.withValues(alpha: isDark ? 0.34 : 0.28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 18), width: 88, height: 2),
        const Radius.circular(99),
      ),
      Paint()..color = line.withValues(alpha: 0.55),
    );

    _hill(canvas, Offset(cx - 22, cy + 12), 42, 14, isDark ? 0.14 : 0.10);
    _hill(canvas, Offset(cx + 18, cy + 14), 30, 10, isDark ? 0.09 : 0.07);

    canvas.drawCircle(
      Offset(cx + 38, cy + 26),
      12,
      Paint()..color = AppColors.tagGreen.withValues(alpha: isDark ? 0.18 : 0.14),
    );
  }

  void _radialGlow(Canvas canvas, Offset c, double r, List<Color> colors) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(c, r, colors, [0.0, 0.55, 1.0]),
    );
  }

  void _hill(Canvas canvas, Offset base, double w, double h, double alpha) {
    final path = Path()
      ..moveTo(base.dx - w / 2, base.dy + h / 2)
      ..quadraticBezierTo(base.dx, base.dy - h / 2, base.dx + w / 2, base.dy + h / 2)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = AppColors.textTertiary.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(covariant _TodayClearPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

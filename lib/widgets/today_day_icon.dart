import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Ícone "Hoje": calendário HugeIcons + número do dia centralizado.
/// Usado na Home e no nav inferior para manter o mesmo padrão visual.
class TodayDayIcon extends StatelessWidget {
  final Color color;
  final double size;

  const TodayDayIcon({
    super.key,
    required this.color,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    final day = DateTime.now().day;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCalendar02,
            size: size,
            color: color,
          ),
          Positioned(
            bottom: size * 0.18,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

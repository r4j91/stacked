import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/home_hero_style.dart';

class HomeHeroStylePreview extends StatelessWidget {
  final HomeHeroStyle style;
  final bool selected;

  const HomeHeroStylePreview({
    super.key,
    required this.style,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? AppColors.accent : Colors.white.withValues(alpha: 0.08),
          width: selected ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: _content(),
    );
  }

  Widget _content() {
    return switch (style) {
      HomeHeroStyle.classic => _classic(),
      HomeHeroStyle.orbital => _orbital(),
      HomeHeroStyle.orbitalOpen => _orbitalOpen(),
      HomeHeroStyle.horizon => _horizon(),
      HomeHeroStyle.capsule => _capsule(),
      HomeHeroStyle.openType => _open(),
      HomeHeroStyle.focus => _focus(),
    };
  }

  Widget _line(double w, double h, Color c) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(1)),
  );

  Widget _classic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _line(28, 4, AppColors.textPrimary.withValues(alpha: 0.85)),
        const SizedBox(height: 3),
        _line(36, 2, AppColors.textSecondary.withValues(alpha: 0.5)),
        const SizedBox(height: 3),
        Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.tagGreen.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 3),
            _line(18, 2, AppColors.tagGreen.withValues(alpha: 0.6)),
          ],
        ),
      ],
    );
  }

  Widget _orbital() {
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 12,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -2),
              child: Container(
                width: 9,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(16, 2, AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 2),
              _line(22, 3, AppColors.textPrimary.withValues(alpha: 0.8)),
              const SizedBox(height: 2),
              _line(14, 2, AppColors.tagGreen.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _orbitalOpen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -2),
                    child: Container(
                      width: 9,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _line(16, 2, AppColors.textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(height: 2),
                    _line(22, 3, AppColors.textPrimary.withValues(alpha: 0.8)),
                    const SizedBox(height: 2),
                    _line(14, 2, AppColors.tagGreen.withValues(alpha: 0.6)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ],
    );
  }

  Widget _horizon() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(14, 2, AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 2),
              _line(20, 3, AppColors.textPrimary.withValues(alpha: 0.8)),
            ],
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.25),
              ),
            ),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _capsule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _line(12, 2, AppColors.textSecondary.withValues(alpha: 0.5)),
            const Spacer(),
            Container(
              width: 14,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.tagGreen.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        _line(24, 4, AppColors.textPrimary.withValues(alpha: 0.85)),
      ],
    );
  }

  Widget _focus() {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 10,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.3)),
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.tagGreen.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(22, 3, AppColors.textPrimary.withValues(alpha: 0.85)),
              const SizedBox(height: 2),
              _line(28, 2, AppColors.textTertiary.withValues(alpha: 0.45)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _open() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _line(14, 2, AppColors.textSecondary.withValues(alpha: 0.5)),
        const SizedBox(height: 3),
        _line(26, 4, AppColors.textPrimary.withValues(alpha: 0.85)),
        const SizedBox(height: 3),
        Container(
          width: 34,
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: LinearGradient(
              colors: [AppColors.accent.withValues(alpha: 0.5), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

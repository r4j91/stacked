import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/project_icons.dart';

/// Preview visual das opções de linha de projeto na Home — não usado em produção.
class ProjectRowPreviewScreen extends StatelessWidget {
  const ProjectRowPreviewScreen({super.key});

  static const _samples = [
    _SampleProject('Trabalho', 'work', Color(0xFF5FD3DC), 0),
    _SampleProject('Rodrigo', 'code', Color(0xFF4D9FEC), 4),
    _SampleProject('Pessoais', 'folder', Color(0xFFF5A623), 1),
  ];

  BoxDecoration _cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : AppColors.surfaceVariant.withValues(alpha: 0.6),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : AppColors.textTertiary.withValues(alpha: 0.15),
      ),
      borderRadius: BorderRadius.circular(AppRadius.xl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 18, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Preview: linhas de projeto',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 120),
        children: [
          Text(
            'Compare as opções abaixo. Toque em uma seção para destacá-la.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.xl),
          _OptionBlock(
            title: 'Hoje (atual)',
            subtitle: 'Barra + quadrado colorido + ícone colorido + chevron',
            badge: 'baseline',
            child: _PreviewCard(
              decoration: _cardDecoration(context),
              children: [
                for (int i = 0; i < _samples.length; i++) ...[
                  if (i > 0) _divider,
                  _CurrentRow(p: _samples[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _OptionBlock(
            title: '1 — Anel + ícone neutro',
            subtitle: 'Cor só no anel fino; ícone cinza; pill de contagem',
            badge: 'recomendada',
            accentBadge: true,
            child: _PreviewCard(
              decoration: _cardDecoration(context),
              children: [
                for (int i = 0; i < _samples.length; i++) ...[
                  if (i > 0) _divider,
                  _RingNeutralRow(p: _samples[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _OptionBlock(
            title: '2 — Só o dot',
            subtitle: 'Minimal Things 3 — bolinha colorida, sem ícone',
            child: _PreviewCard(
              decoration: _cardDecoration(context),
              children: [
                for (int i = 0; i < _samples.length; i++) ...[
                  if (i > 0) _divider,
                  _DotOnlyRow(p: _samples[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _OptionBlock(
            title: '3 — Estilo Browse',
            subtitle: 'Faixa fina + container neutro (consistente com aba Navegar)',
            child: _PreviewCard(
              decoration: _cardDecoration(context),
              children: [
                for (int i = 0; i < _samples.length; i++) ...[
                  if (i > 0) _divider,
                  _BrowseStyleRow(p: _samples[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _OptionBlock(
            title: '4 — Chips horizontais',
            subtitle: 'Compacto; wrap quando houver muitos projetos',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _samples.map((p) => _ProjectChip(p: p)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static final _divider = Divider(
    height: 1,
    thickness: 1,
    color: AppColors.textTertiary.withValues(alpha: 0.12),
  );
}

class _SampleProject {
  final String name;
  final String iconName;
  final Color color;
  final int taskCount;
  const _SampleProject(this.name, this.iconName, this.color, this.taskCount);
}

class _OptionBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final bool accentBadge;
  final Widget child;

  const _OptionBlock({
    required this.title,
    required this.subtitle,
    required this.child,
    this.badge,
    this.accentBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentBadge
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : AppColors.textTertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                  border: accentBadge ? Border.all(color: AppColors.accent.withValues(alpha: 0.35)) : null,
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: accentBadge ? AppColors.accent : AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final BoxDecoration decoration;
  final List<Widget> children;

  const _PreviewCard({required this.decoration, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 1, vertical: AppSpacing.sm),
      child: Column(children: children),
    );
  }
}

// ── Baseline (Home atual) ───────────────────────────────────────────────────

class _CurrentRow extends StatelessWidget {
  final _SampleProject p;
  const _CurrentRow({required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(color: p.color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm + 1),
            ),
            child: HugeIcon(icon: ProjectIcons.resolve(p.iconName), size: 18, color: p.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(p.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ),
          if (p.taskCount > 0)
            Text('${p.taskCount}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

// ── Opção 1: anel + ícone neutro ────────────────────────────────────────────

class _RingNeutralRow extends StatelessWidget {
  final _SampleProject p;
  const _RingNeutralRow({required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceVariant.withValues(alpha: 0.45),
              border: Border.all(color: p.color.withValues(alpha: 0.75), width: 2),
            ),
            child: Center(
              child: HugeIcon(
                icon: ProjectIcons.resolve(p.iconName),
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(p.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ),
          if (p.taskCount > 0) _CountPill(count: p.taskCount),
        ],
      ),
    );
  }
}

// ── Opção 2: só dot ───────────────────────────────────────────────────────────

class _DotOnlyRow extends StatelessWidget {
  final _SampleProject p;
  const _DotOnlyRow({required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(p.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ),
          if (p.taskCount > 0)
            Text('${p.taskCount}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

// ── Opção 3: estilo Browse ────────────────────────────────────────────────────

class _BrowseStyleRow extends StatelessWidget {
  final _SampleProject p;
  const _BrowseStyleRow({required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: p.color.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.12)),
            ),
            child: HugeIcon(
              icon: ProjectIcons.resolve(p.iconName),
              size: 16,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(p.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ),
          if (p.taskCount > 0) _CountPill(count: p.taskCount),
        ],
      ),
    );
  }
}

// ── Opção 4: chips ──────────────────────────────────────────────────────────

class _ProjectChip extends StatelessWidget {
  final _SampleProject p;
  const _ProjectChip({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.color.withValues(alpha: 0.12),
              border: Border.all(color: p.color.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: HugeIcon(icon: ProjectIcons.resolve(p.iconName), size: 15, color: p.color),
            ),
          ),
          const SizedBox(width: 8),
          Text(p.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          if (p.taskCount > 0) ...[
            const SizedBox(width: 6),
            Text('${p.taskCount}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
          ],
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textTertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
      ),
    );
  }
}

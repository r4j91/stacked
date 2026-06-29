import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/haptic_service.dart';
import '../services/supabase_client.dart';
import '../theme/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';

// SQL para rodar no Supabase antes de usar:
// ALTER TABLE profiles ADD COLUMN IF NOT EXISTS apelido text;
// ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url text;
// ALTER TABLE profiles ADD COLUMN IF NOT EXISTS meta_diaria integer DEFAULT 5;

Future<void> showProductivitySheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ProductivitySheet(),
  );
}

class _ProductivitySheet extends StatefulWidget {
  const _ProductivitySheet();
  @override
  State<_ProductivitySheet> createState() => _ProductivitySheetState();
}

class _ProductivitySheetState extends State<_ProductivitySheet> {
  int _tab = 0; // 0=Diário, 1=Semanal
  bool _loading = true;

  // Dados brutos do Supabase
  List<DateTime> _completionDates = [];
  int _totalCompleted = 0;

  // Perfil
  String _displayName = '';
  String? _avatarPath;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    _load();
    // Recarrega quando o perfil é salvo (foto, nome, apelido)
    _authSub = supabase.auth.onAuthStateChange.listen((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final taskRows = await supabase
          .from('tasks')
          .select('data_vencimento')
          .eq('concluida', true)
          .not('data_vencimento', 'is', null)
          .order('data_vencimento', ascending: false);

      // Carregar nome dos user metadata (sem tabela profiles)
      final meta = supabase.auth.currentUser?.userMetadata ?? {};
      final apelido = (meta['apelido'] as String? ?? '').trim();
      final nome = (meta['nome'] as String? ?? '').trim();
      _displayName = apelido.isNotEmpty
          ? apelido
          : nome.isNotEmpty
              ? nome.split(' ').first
              : supabase.auth.currentUser?.email?.split('@').first ?? '';
      _avatarPath = meta['avatar_url'] as String?;

      _completionDates = taskRows
          .map((r) => DateTime.tryParse(r['data_vencimento'] as String? ?? ''))
          .whereType<DateTime>()
          .toList();
      _totalCompleted = _completionDates.length;
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  // ── Métricas ───────────────────────────────────────────────────────────────

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  int get _todayCount => _completionDates
      .where((d) => DateTime(d.year, d.month, d.day) == _today)
      .length;

  List<int> get _last7Days {
    return List.generate(7, (i) {
      final day = _today.subtract(Duration(days: 6 - i));
      return _completionDates
          .where((d) => DateTime(d.year, d.month, d.day) == day)
          .length;
    });
  }

  int get _thisWeekTotal {
    final monday = _today.subtract(Duration(days: _today.weekday - 1));
    return _completionDates
        .where((d) => !DateTime(d.year, d.month, d.day).isBefore(monday))
        .length;
  }

  int get _lastWeekTotal {
    final thisMonday = _today.subtract(Duration(days: _today.weekday - 1));
    final lastMonday = thisMonday.subtract(const Duration(days: 7));
    return _completionDates.where((d) {
      final day = DateTime(d.year, d.month, d.day);
      return !day.isBefore(lastMonday) && day.isBefore(thisMonday);
    }).length;
  }

  List<int> get _weekByDay {
    final monday = _today.subtract(Duration(days: _today.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return _completionDates
          .where((d) => DateTime(d.year, d.month, d.day) == day)
          .length;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Container(
      height: mq.size.height * 0.92,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header: chips + fechar
          _buildHeader(context),
          // Body
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
                : _buildContent(mq),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Text('Relatório', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16, color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(MediaQueryData mq) {
    return CustomScrollView(
      slivers: [
        // Card de perfil
        SliverToBoxAdapter(child: _buildProfileCard()),
        // Segmented control
        SliverToBoxAdapter(child: _buildSegmentedControl()),
        // Conteúdo da aba
        SliverToBoxAdapter(child: _buildTabContent(mq)),
        SliverToBoxAdapter(child: SizedBox(height: mq.padding.bottom + 24)),
      ],
    );
  }

  Widget _buildProfileCard() {
    final email = supabase.auth.currentUser?.email ?? '';
    final initials = _displayName.isNotEmpty
        ? _displayName.substring(0, math.min(2, _displayName.length)).toUpperCase()
        : email.substring(0, math.min(2, email.length)).toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _AvatarWidget(path: _avatarPath, initials: initials, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName.isNotEmpty ? _displayName : email.split('@').first,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_totalCompleted tarefas concluídas',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    const tabs = ['Diário', 'Semanal'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final active = _tab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () { HapticService().tabChanged(); setState(() => _tab = i); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppColors.surfaceVariant : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    tabs[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? AppColors.textPrimary : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabContent(MediaQueryData mq) {
    switch (_tab) {
      case 0:
        return _buildDailyTab();
      case 1:
        return _buildWeeklyTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Aba Diária ─────────────────────────────────────────────────────────────

  Widget _buildDailyTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedTaskDone01,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Concluídas hoje',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$_todayCount',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _todayCount == 1 ? 'tarefa' : 'tarefas',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Últimos 7 dias',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _HorizontalBarChart(
                  values: _last7Days,
                  maxValue: math.max(1, _last7Days.reduce(math.max)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Aba Semanal ────────────────────────────────────────────────────────────

  Widget _buildWeeklyTab() {
    final thisWeek = _thisWeekTotal;
    final lastWeek = _lastWeekTotal;
    final diff = lastWeek == 0 ? null : ((thisWeek - lastWeek) / lastWeek * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Totais semana
          Row(
            children: [
              Expanded(
                child: _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Esta semana', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                      const SizedBox(height: 6),
                      Text('$thisWeek', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1)),
                      Text('tarefas', style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Semana anterior', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                      const SizedBox(height: 6),
                      Text('$lastWeek', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1)),
                      if (diff != null)
                        Row(
                          children: [
                            HugeIcon(
                              icon: diff >= 0
                                  ? HugeIcons.strokeRoundedArrowUp01
                                  : HugeIcons.strokeRoundedArrowDown01,
                              size: 13,
                              color: diff >= 0 ? AppColors.tagGreen : AppColors.priorityHigh,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${diff.abs()}%',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: diff >= 0 ? AppColors.textSecondary : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        )
                      else
                        Text('—', style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Por dia da semana', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                _HorizontalBarChart(
                  values: _weekByDay,
                  maxValue: math.max(1, _weekByDay.reduce(math.max)),
                  labels: const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

// ── Gráfico de barras horizontais ─────────────────────────────────────────────

class _HorizontalBarChart extends StatelessWidget {
  final List<int> values;
  final int maxValue;
  final List<String>? labels;

  const _HorizontalBarChart({
    required this.values,
    required this.maxValue,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    // Default: últimos 7 dias
    final defaultLabels = List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      return dayNames[day.weekday - 1];
    });
    final usedLabels = labels ?? defaultLabels;

    return Column(
      children: List.generate(values.length, (i) {
        final val = values[i];
        final ratio = maxValue > 0 ? val / maxValue : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  usedLabels[i],
                  style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, constraints) => Stack(
                    children: [
                      // Background track
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Filled bar with gradient
                      AnimatedContainer(
                        duration: Duration(milliseconds: 400 + i * 60),
                        curve: Curves.easeOutCubic,
                        height: 20,
                        width: constraints.maxWidth * ratio,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          // COLORS-OLD: colors: [Color(0xFF4CAF50), Color(0xFF5FD3DC)]
                          // 0xFF5FD3DC duplicava AppColors.accent hardcoded —
                          // quebra ao trocar tema. 0xFF4CAF50 é stop decorativo
                          // único, sem token equivalente — mantido fixo.
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent.withValues(alpha: 0.45),
                              AppColors.accent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                child: Text(
                  '$val',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: val > 0 ? AppColors.textSecondary : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Widgets menores ───────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final String? path;
  final String initials;
  final double size;
  const _AvatarWidget({this.path, required this.initials, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = path != null && File(path!).existsSync();
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent.withValues(alpha: 0.15),
        image: hasPhoto
            ? DecorationImage(image: FileImage(File(path!)), fit: BoxFit.cover)
            : null,
      ),
      child: hasPhoto
          ? null
          : Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../services/supabase_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../app_sheet.dart';
import '../empty_state.dart';
import '../skeleton_loader.dart';

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  static void show(BuildContext context) {
    showAppSheet(
      context: context,
      title: 'Próximas',
      trailingAction: IconButton(
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedCancel01,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        visualDensity: VisualDensity.compact,
      ),
      scrollable: true,
      child: const NotificationsSheet(),
    );
  }

  @override
  State<NotificationsSheet> createState() => NotificationsSheetState();
}

class NotificationsSheetState extends State<NotificationsSheet> {
  List<Map<String, dynamic>> _upcoming = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final now = DateTime.now().toIso8601String().substring(0, 10);
      final rows = await supabase
          .from('tasks')
          .select('id, titulo, data_vencimento')
          .eq('user_id', userId)
          .eq('concluida', false)
          .gte('data_vencimento', now)
          .order('data_vencimento')
          .limit(20);
      if (mounted) {
        setState(() {
          _upcoming = List<Map<String, dynamic>>.from(rows);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 220,
        child: SkeletonLoader(itemCount: 3),
      );
    }

    if (_upcoming.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: EmptyState(
          hugeIcon: HugeIcons.strokeRoundedNotification01,
          title: 'Nenhuma notificação agendada',
          subtitle: 'Tarefas com data futura aparecem aqui',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: _upcoming.map((item) {
          final due = DateTime.tryParse(item['data_vencimento'] ?? '');
          final today = DateTime.now();
          final diff = due == null
              ? null
              : DateTime(due.year, due.month, due.day)
                  .difference(DateTime(today.year, today.month, today.day))
                  .inDays;
          final label = diff == null
              ? ''
              : diff == 0
                  ? 'Hoje'
                  : diff == 1
                      ? 'Amanhã'
                      : 'Em $diff dias';
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedNotification01,
              color: AppColors.accent,
              size: 20,
            ),
            title: Text(
              item['titulo'] ?? '',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: label.isNotEmpty
                ? Text(
                    label,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  )
                : null,
            dense: true,
          );
        }).toList(),
      ),
    );
  }
}

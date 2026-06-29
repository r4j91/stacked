import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_sheet.dart';
import 'package:hugeicons/hugeicons.dart';

/// Shared body for notification preferences — used in sheet and full screen.
class NotificationsSettingsContent extends StatefulWidget {
  const NotificationsSettingsContent({super.key});

  @override
  State<NotificationsSettingsContent> createState() =>
      _NotificationsSettingsContentState();
}

class _NotificationsSettingsContentState
    extends State<NotificationsSettingsContent> {
  final _svc = NotificationService();

  bool _enabled = false;
  int _hour = 9;
  int _minute = 0;
  bool _dailySummary = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _svc.isEnabled;
    final time = await _svc.defaultTime;
    final daily = await _svc.dailySummaryEnabled;
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _hour = time.hour;
        _minute = time.minute;
        _dailySummary = daily;
        _loading = false;
      });
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    if (value) {
      final granted = await _svc.requestPermission();
      if (mounted) setState(() => _enabled = granted);
    } else {
      await _svc.setEnabled(false);
      if (mounted) setState(() => _enabled = false);
    }
  }

  Future<void> _pickTime() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        var tempH = _hour;
        var tempM = _minute;
        return Container(
          height: 280,
          color: AppColors.surface,
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              CupertinoButton(
                child: Text('Cancelar',
                    style: TextStyle(color: AppColors.textSecondary)),
                onPressed: () => Navigator.pop(ctx),
              ),
              CupertinoButton(
                child: Text('OK',
                    style: TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w600)),
                onPressed: () async {
                  await _svc.setDefaultTime(tempH, tempM);
                  if (mounted) {
                    setState(() {
                      _hour = tempH;
                      _minute = tempM;
                    });
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ]),
            Expanded(
              child: Row(children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController:
                        FixedExtentScrollController(initialItem: _hour),
                    itemExtent: 44,
                    onSelectedItemChanged: (v) => tempH = v,
                    children: List.generate(
                      24,
                      (i) => Center(
                        child: Text(
                          '${i.toString().padLeft(2, '0')}h',
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                        initialItem: _minute ~/ 15),
                    itemExtent: 44,
                    onSelectedItemChanged: (v) => tempM = v * 15,
                    children: [0, 15, 30, 45]
                        .map((m) => Center(
                              child: Text(
                                '${m.toString().padLeft(2, '0')}min',
                                style: TextStyle(
                                    color: AppColors.textPrimary, fontSize: 16),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Section(children: [
            _Row(
              hugeIcon: HugeIcons.strokeRoundedNotification01,
              label: 'Ativar notificações',
              trailing: Switch.adaptive(
                value: _enabled,
                onChanged: _toggleEnabled,
                activeThumbColor: AppColors.accent,
              ),
            ),
          ]),
          if (_enabled) ...[
            const SizedBox(height: AppSpacing.lg),
            _Section(children: [
              _Row(
                hugeIcon: HugeIcons.strokeRoundedClock01,
                label: 'Horário padrão',
                trailing: GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 15),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            _Section(children: [
              _Row(
                hugeIcon: HugeIcons.strokeRoundedSun01,
                label: 'Resumo diário',
                sublabel: 'Resumo das tarefas do dia às 8h da manhã',
                trailing: Switch.adaptive(
                  value: _dailySummary,
                  onChanged: (v) async {
                    await _svc.setDailySummaryEnabled(v);
                    if (mounted) setState(() => _dailySummary = v);
                  },
                  activeThumbColor: AppColors.accent,
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'As notificações são agendadas automaticamente quando você salva uma tarefa com data de vencimento.',
              style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text('Notificações', style: appSheetTitleStyle(context)),
        leading: IconButton(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xl),
        child: NotificationsSettingsContent(),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
      {required this.hugeIcon,
      required this.label,
      this.sublabel,
      required this.trailing});
  final List<List<dynamic>> hugeIcon;
  final String label;
  final String? sublabel;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md - 2),
      child: Row(children: [
        HugeIcon(icon: hugeIcon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                if (sublabel != null) ...[
                  const SizedBox(height: 2),
                  Text(sublabel!,
                      style: TextStyle(
                          color: AppColors.textTertiary, fontSize: 12)),
                ],
              ]),
        ),
        trailing,
      ]),
    );
  }
}

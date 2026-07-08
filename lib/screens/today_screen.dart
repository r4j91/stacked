import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/anchored_select_menu.dart';
import '../widgets/app_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/empty_state_illustration.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/swipeable_task_tile.dart';
import '../widgets/task_tile.dart';
import '../services/notification_service.dart';
import '../services/task_repository.dart';
import '../services/task_sync.dart';
import '../services/supabase_client.dart';
import '../services/label_repository.dart';
import 'task_detail_sheet.dart';
import '../widgets/load_error_view.dart';
import '../widgets/task_list_scaffold.dart';
import '../widgets/screen_header.dart';
import 'package:hugeicons/hugeicons.dart';

const _kShowCompletedKey = 'today_show_completed';

// Top-level constants — avoids allocating new lists on every _formatDate call.
const _kWeekdays = [
  'Segunda-feira', 'Terça-feira', 'Quarta-feira',
  'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo',
];
const _kMonths = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => TodayScreenState();
}

class TodayScreenState extends State<TodayScreen> {
  static const _labelRepo = LabelRepository();
  final _repo = const TaskRepository();
  List<Task> _tasks = [];
  List<Task> _completedTasks = [];
  List<TaskLabel> _allLabels = [];
  bool _loading = true;
  String? _error;
  late final ScrollController _scrollCtrl;
  final _optionsKey = GlobalKey();

  // SharedPreferences-backed preferences
  bool _showCompleted = true;   // section visible (toggle from menu)
  bool _completedExpanded = false; // section collapsed/expanded

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _loadPrefs();
    _loadTasks();
    TaskSync.instance.addListener(_loadTasks);
  }

  void scrollToTop() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showCompleted = prefs.getBool(_kShowCompletedKey) ?? true;
      });
    }
  }

  Future<void> _setShowCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowCompletedKey, value);
    if (mounted) setState(() => _showCompleted = value);
  }

  @override
  void dispose() {
    TaskSync.instance.removeListener(_loadTasks);
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> loadTasks() => _loadTasks();

  Future<void> _loadTasks() async {
    try {
      final repo = TaskRepository();
      final results = await Future.wait([
        repo.fetchTodayTasks(),
        repo.fetchCompletedTodayTasks(),
        _labelRepo.fetchLabels(),
      ]);
      if (mounted) {
        setState(() {
          _tasks = results[0] as List<Task>;
          _completedTasks = results[1] as List<Task>;
          _allLabels = results[2] as List<TaskLabel>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _toggleDone(int taskIndex) {
    final task = _tasks[taskIndex];
    if (task.done) return; // already completing via animation, ignore
    final newDone = !task.done;
    setState(() => _tasks[taskIndex] = task.copyWith(done: newDone));
    _repo.completeTask(task).catchError((_) {
      if (mounted) setState(() => _tasks[taskIndex] = task);
      return null;
    });
    if (newDone) {
      NotificationService().cancelTaskNotification(task.id);
      // Removal is handled by TaskTile.onDismissed after animation completes.
    }
  }

  Future<void> _deleteTask(int index) async {
    if (!mounted) return;
    final task = _tasks[index];
    setState(() => _tasks.removeAt(index));

    bool undone = false;
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = messenger.showSnackBar(SnackBar(
      content: Text('"${task.title}" excluída'),
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      action: SnackBarAction(
        label: 'Desfazer',
        textColor: AppColors.accent,
        onPressed: () {
          undone = true;
          if (mounted) setState(() => _tasks.insert(index.clamp(0, _tasks.length), task));
        },
      ),
    ));

    await ctrl.closed;
    if (!undone) {
      try {
        await _repo.deleteTask(task.id);
        NotificationService().cancelTaskNotification(task.id);
      } catch (e) {
        if (mounted) {
          setState(() => _tasks.insert(index.clamp(0, _tasks.length), task));
          messenger.showSnackBar(SnackBar(
            content: Text('Erro ao excluir: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.priorityHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ));
        }
      }
    }
  }

  void _toggleUndone(int index) {
    final task = _completedTasks[index];
    final updated = task.copyWith(done: false);
    setState(() {
      _completedTasks.removeAt(index);
      _tasks.add(updated);
    });
    supabase.from('tasks').update({'concluida': false}).eq('id', task.id).catchError((_) {
      if (mounted) {
        setState(() {
          _tasks.removeWhere((t) => t.id == task.id);
          _completedTasks.insert(index.clamp(0, _completedTasks.length), task);
        });
      }
    });
  }

  Future<void> _deleteCompletedTask(int index) async {
    if (!mounted) return;
    final task = _completedTasks[index];
    setState(() => _completedTasks.removeAt(index));

    bool undone = false;
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = messenger.showSnackBar(SnackBar(
      content: Text('"${task.title}" excluída'),
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      action: SnackBarAction(
        label: 'Desfazer',
        textColor: AppColors.accent,
        onPressed: () {
          undone = true;
          if (mounted) setState(() => _completedTasks.insert(index.clamp(0, _completedTasks.length), task));
        },
      ),
    ));

    await ctrl.closed;
    if (!undone) {
      try {
        await _repo.deleteTask(task.id);
      } catch (e) {
        if (mounted) {
          setState(() => _completedTasks.insert(index.clamp(0, _completedTasks.length), task));
          messenger.showSnackBar(SnackBar(
            content: Text('Erro ao excluir: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.priorityHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ));
        }
      }
    }
  }

  void _toggleSubtask(int taskIndex, int subtaskIndex) {
    final task = _tasks[taskIndex];
    final updated = List<Subtask>.from(task.subtasks);
    updated[subtaskIndex] = updated[subtaskIndex].copyWith(done: !updated[subtaskIndex].done);
    // copyWith preserves all fields (done, recurrence, projectId, createdAt, updatedAt)
    setState(() {
      _tasks[taskIndex] = task.copyWith(subtasks: updated);
    });
    final sub = updated[subtaskIndex];
    supabase
        .from('subtasks')
        .select('id')
        .eq('task_id', task.id)
        .order('ordem')
        .then((rows) {
      if (subtaskIndex < rows.length) {
        supabase
            .from('subtasks')
            .update({'concluida': sub.done})
            .eq('id', rows[subtaskIndex]['id']);
      }
    }).catchError((_) {});
  }

  Future<void> _showOptionsMenu() async {
    final result = await showAnchoredSelectMenu(
      context: context,
      anchorKey: _optionsKey,
      items: [
        AnchoredMenuItem(
          id: 'toggle_completed',
          label: _showCompleted ? 'Ocultar concluídas' : 'Mostrar concluídas',
          hugeIcon: _showCompleted
              ? HugeIcons.strokeRoundedViewOff
              : HugeIcons.strokeRoundedView,
          iconColor: AppColors.textSecondary,
        ),
      ],
    );
    if (result == 'toggle_completed') {
      _setShowCompleted(!_showCompleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SkeletonLoader();

    if (_error != null) {
      return LoadErrorView(
        onRetry: () {
          setState(() {
            _loading = true;
            _error = null;
          });
          _loadTasks();
        },
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateLabel = _formatDate(now);

    // Split into overdue (before today) and today.
    // Precompute index map to avoid O(n) indexOf inside the SliverList builder.
    final overdue = <Task>[];
    final todayTasks = <Task>[];
    final taskIndexMap = <String, int>{};
    for (var i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      taskIndexMap[t.id] = i;
      if (t.dueDate != null && t.dueDate!.isBefore(today)) {
        overdue.add(t);
      } else if (t.dueDate != null) {
        todayTasks.add(t);
      }
    }

    return TaskListScaffold(
      scrollController: _scrollCtrl,
      onRefresh: _loadTasks,
      slivers: [
        // ── Header ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: ScreenHeader(
            title: 'Hoje',
            subtitle: dateLabel,
            trailing: IconButton(
              key: _optionsKey,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedMoreHorizontal,
                color: AppColors.textSecondary,
              ),
              onPressed: _showOptionsMenu,
              tooltip: 'Opções',
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

        // ── Empty state ───────────────────────────────────────────────────────
        if (_tasks.isEmpty && _completedTasks.isEmpty)
          const EmptyStateSliver(
            child: EmptyState.illustrated(
              illustration: EmptyStateIllustrationKind.todayClear,
              title: 'Dia livre',
              subtitle: 'Nada agendado para hoje. Aproveite o momento.',
            ),
          ),

        // ── Atrasadas ─────────────────────────────────────────────────────────
        if (overdue.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: AppSectionLabel(
              'ATRASADAS',
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final task = overdue[i];
                final idx = taskIndexMap[task.id]!;
                return RepaintBoundary(
                  key: ValueKey('rb_${task.id}'),
                  child: SwipeableTaskTile(
                    key: ValueKey(task.id),
                    task: task,
                    onCompleted: () => _toggleDone(idx),
                    onDeleteRequested: () => _deleteTask(idx),
                    onEdit: () => showTaskDetailSheet(context, task, onSaved: _loadTasks),
                    onRefresh: _loadTasks,
                    child: TaskTile(
                      task: task,
                      allLabels: _allLabels,
                      onSubtaskToggled: (si) => _toggleSubtask(idx, si),
                      onCompleted: () => _toggleDone(idx),
                      onTap: () => showTaskDetailSheet(context, task, onSaved: _loadTasks),
                      onDismissed: () {
                        if (!mounted) return;
                        final t = task;
                        setState(() {
                          _tasks.removeWhere((x) => x.id == t.id);
                          if (!_completedTasks.any((x) => x.id == t.id)) {
                            _completedTasks = [t.copyWith(done: true), ..._completedTasks];
                          }
                        });
                      },
                    ),
                  ),
                );
              },
              findChildIndexCallback: (key) {
                final id = (key as ValueKey<String>).value;
                final i = overdue.indexWhere((t) => t.id == id);
                return i == -1 ? null : i;
              },
              childCount: overdue.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],

        // ── Hoje ─────────────────────────────────────────────────────────────
        if (todayTasks.isNotEmpty) ...[
          if (overdue.isNotEmpty)
            SliverToBoxAdapter(
              child: AppSectionLabel(
                'HOJE',
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final task = todayTasks[i];
                final idx = taskIndexMap[task.id]!;
                return RepaintBoundary(
                  key: ValueKey('rb_${task.id}'),
                  child: SwipeableTaskTile(
                    key: ValueKey(task.id),
                    task: task,
                    onCompleted: () => _toggleDone(idx),
                    onDeleteRequested: () => _deleteTask(idx),
                    onEdit: () => showTaskDetailSheet(context, task, onSaved: _loadTasks),
                    onRefresh: _loadTasks,
                    child: TaskTile(
                      task: task,
                      allLabels: _allLabels,
                      onSubtaskToggled: (si) => _toggleSubtask(idx, si),
                      onCompleted: () => _toggleDone(idx),
                      onTap: () => showTaskDetailSheet(context, task, onSaved: _loadTasks),
                      onDismissed: () {
                        if (!mounted) return;
                        final t = task;
                        setState(() {
                          _tasks.removeWhere((x) => x.id == t.id);
                          if (!_completedTasks.any((x) => x.id == t.id)) {
                            _completedTasks = [t.copyWith(done: true), ..._completedTasks];
                          }
                        });
                      },
                    ),
                  ),
                );
              },
              findChildIndexCallback: (key) {
                final id = (key as ValueKey<String>).value;
                final i = todayTasks.indexWhere((t) => t.id == id);
                return i == -1 ? null : i;
              },
              childCount: todayTasks.length,
            ),
          ),
        ],

        // ── Completed section ────────────────────────────────────────────────
        if (_showCompleted && _completedTasks.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: CompletedSectionHeader(
              count: _completedTasks.length,
              expanded: _completedExpanded,
              onTap: () => setState(() => _completedExpanded = !_completedExpanded),
            ),
          ),
          if (_completedExpanded)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => RepaintBoundary(
                  key: ValueKey('rb_${_completedTasks[i].id}'),
                  child: SwipeableTaskTile(
                    task: _completedTasks[i],
                    onDeleteRequested: () => _deleteCompletedTask(i),
                    onEdit: () => showTaskDetailSheet(context, _completedTasks[i], onSaved: _loadTasks),
                    onRefresh: _loadTasks,
                    child: TaskTile(
                      task: _completedTasks[i],
                      allLabels: _allLabels,
                      onSubtaskToggled: (_) {},
                      onCompleted: () => _toggleUndone(i),
                      onTap: () => showTaskDetailSheet(context, _completedTasks[i], onSaved: _loadTasks),
                    ),
                  ),
                ),
                childCount: _completedTasks.length,
              ),
            ),
        ],

      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${_kWeekdays[date.weekday - 1]}, ${date.day} de ${_kMonths[date.month - 1]}';
}


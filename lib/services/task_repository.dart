import 'package:flutter/foundation.dart';

import '../models/task.dart';
import 'supabase_client.dart';
import 'task_sync.dart';

/// SELECT unificado de tarefas — única fonte para listas e detalhe resumido.
const kTaskSelect = '''
  id,
  titulo,
  descricao,
  prioridade,
  hora,
  ordem,
  concluida,
  data_vencimento,
  recorrencia,
  project_id,
  section_id,
  projects ( nome ),
  subtasks ( id, titulo, descricao, concluida, ordem, prioridade, valor, data_vencimento, label_ids ),
  task_labels ( labels ( id, nome, cor ) ),
  task_comments ( count )
''';

/// Resumo do card "Hoje" na home.
class HomeTaskSummary {
  final List<Task> todayTasks;
  final int overdueCount;

  const HomeTaskSummary({
    required this.todayTasks,
    required this.overdueCount,
  });

  int get todayTotal => todayTasks.length;
  int get todayDone => todayTasks.where((t) => t.done).length;
  int get todayPending => todayTotal - todayDone;
}

/// Contagens do dashboard de filtros.
class FilterDashboardCounts {
  final int overdue;
  final int today;
  final int week;
  final int completedToday;

  const FilterDashboardCounts({
    required this.overdue,
    required this.today,
    required this.week,
    required this.completedToday,
  });
}

enum TaskFilterKind { overdue, today, week, completedToday }

class TaskRepository {
  const TaskRepository();

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<List<Task>> fetchTodayTasks() async {
    final todayStr = _dateStr(DateTime.now());
    final rows = await supabase
        .from('tasks')
        .select(kTaskSelect)
        .eq('concluida', false)
        .lte('data_vencimento', todayStr)
        .order('data_vencimento', ascending: true)
        .order('ordem', ascending: true)
        // ADICIONADO_ORDEM_ESTAVEL: tiebreaker para 'ordem' duplicado/nulo,
        // evita reordenação não-determinística entre recargas da lista.
        .order('id', ascending: true);
    return _mapList(rows);
  }

  Future<List<Task>> fetchInboxTasks() async {
    final rows = await supabase
        .from('tasks')
        .select(kTaskSelect)
        .eq('concluida', false)
        .isFilter('data_vencimento', null)
        .isFilter('project_id', null)
        .order('ordem', ascending: true)
        // ADICIONADO_ORDEM_ESTAVEL: tiebreaker para 'ordem' duplicado/nulo,
        // evita reordenação não-determinística entre recargas da lista.
        .order('id', ascending: true);
    return _mapList(rows);
  }

  Future<List<Task>> fetchCompletedInboxTasks() async {
    final rows = await supabase
        .from('tasks')
        .select(kTaskSelect)
        .eq('concluida', true)
        .isFilter('data_vencimento', null)
        .isFilter('project_id', null)
        .order('ordem', ascending: true)
        // ADICIONADO_ORDEM_ESTAVEL: tiebreaker para 'ordem' duplicado/nulo,
        // evita reordenação não-determinística entre recargas da lista.
        .order('id', ascending: true);
    return _mapList(rows);
  }

  Future<List<Task>> fetchCompletedTodayTasks() async {
    final todayStr = _dateStr(DateTime.now());
    final rows = await supabase
        .from('tasks')
        .select(kTaskSelect)
        .eq('concluida', true)
        .or('data_vencimento.is.null,data_vencimento.eq.$todayStr')
        .order('ordem', ascending: true)
        // ADICIONADO_ORDEM_ESTAVEL: tiebreaker para 'ordem' duplicado/nulo,
        // evita reordenação não-determinística entre recargas da lista.
        .order('id', ascending: true);
    return _mapList(rows);
  }

  Future<List<Task>> fetchUpcomingTasks() async {
    final todayStr = _dateStr(DateTime.now());
    final rows = await supabase
        .from('tasks')
        .select(kTaskSelect)
        .eq('concluida', false)
        .gt('data_vencimento', todayStr)
        .order('data_vencimento', ascending: true)
        .order('ordem', ascending: true)
        // ADICIONADO_ORDEM_ESTAVEL: tiebreaker para 'ordem' duplicado/nulo,
        // evita reordenação não-determinística entre recargas da lista.
        .order('id', ascending: true);
    return _mapList(rows);
  }

  Future<List<Task>> fetchTasksByProject(String projectId) async {
    final rows = await supabase
        .from('tasks')
        .select(kTaskSelect)
        .eq('project_id', projectId)
        .eq('concluida', false)
        .order('ordem', ascending: true)
        // ADICIONADO_ORDEM_ESTAVEL: tiebreaker para 'ordem' duplicado/nulo,
        // evita reordenação não-determinística entre recargas da lista.
        .order('id', ascending: true);
    return _mapList(rows);
  }

  Future<List<Task>> fetchCompletedTasksByProject(String projectId) async {
    final rows = await supabase
        .from('tasks')
        .select(kTaskSelect)
        .eq('project_id', projectId)
        .eq('concluida', true)
        .order('ordem', ascending: true)
        // ADICIONADO_ORDEM_ESTAVEL: tiebreaker para 'ordem' duplicado/nulo,
        // evita reordenação não-determinística entre recargas da lista.
        .order('id', ascending: true);
    return _mapList(rows);
  }

  Future<Task?> fetchTaskById(String id) async {
    final rows = await supabase
        .from('tasks')
        .select(kTaskSelect)
        .eq('id', id)
        .limit(1);
    final list = _mapList(rows);
    return list.isEmpty ? null : list.first;
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<void> toggleTaskDone(String id, bool done) async {
    await supabase.from('tasks').update({'concluida': done}).eq('id', id);
  }

  /// Marca concluída e cria próxima ocorrência quando aplicável.
  Future<String?> completeTask(Task task) async {
    await toggleTaskDone(task.id, true);
    final newId = await createNextOccurrence(task);
    TaskSync.instance.notifyChanged();
    return newId;
  }

  Future<String?> createNextOccurrence(Task task) async {
    if (task.recurrence == null || task.dueDate == null) return null;
    final nextDate = task.recurrence!.nextDate(task.dueDate!);
    if (nextDate == null) return null;

    final userId = supabase.auth.currentUser?.id;
    final dateStr = _dateStr(nextDate);
    final prioStr = switch (task.priority) {
      Priority.high => 'high',
      Priority.medium => 'medium',
      Priority.low => 'low',
      null => null,
    };

    int? ordem;
    try {
      final row = await supabase
          .from('tasks')
          .select('ordem')
          .eq('id', task.id)
          .maybeSingle();
      ordem = row?['ordem'] as int?;
    } catch (_) {}

    try {
      final inserted = await supabase
          .from('tasks')
          .insert({
            'titulo': task.title,
            'descricao': task.description,
            'prioridade': prioStr,
            'hora': task.time,
            'concluida': false,
            'data_vencimento': dateStr,
            'recorrencia': task.recurrence!.toJsonString(),
            if (task.projectId != null) 'project_id': task.projectId,
            if (task.sectionId != null) 'section_id': task.sectionId,
            if (ordem != null) 'ordem': ordem,
            if (userId != null) 'user_id': userId,
          })
          .select('id')
          .single();

      final newId = inserted['id'].toString();

      if (task.labels.isNotEmpty) {
        await supabase.from('task_labels').insert(
          task.labels.map((l) => {'task_id': newId, 'label_id': l.id}).toList(),
        );
      }

      return newId;
    } catch (e) {
      debugPrint('[Recurrence] erro ao criar próxima ocorrência: $e');
      return null;
    }
  }

  Future<void> updateTaskPriority(String id, Priority priority) async {
    await supabase
        .from('tasks')
        .update({'prioridade': priority.name})
        .eq('id', id);
  }

  Future<void> updateTaskProject(String id, String? projectId) async {
    await supabase
        .from('tasks')
        .update({'project_id': projectId})
        .eq('id', id);
  }

  Future<void> updateTaskDate(String id, String? isoDate) async {
    await supabase
        .from('tasks')
        .update({'data_vencimento': isoDate})
        .eq('id', id);
    TaskSync.instance.notifyChanged();
  }

  Future<void> deleteTask(String id) async {
    await supabase.from('tasks').delete().eq('id', id);
    TaskSync.instance.notifyChanged();
  }

  // ── Home / browse aggregates ───────────────────────────────────────────────

  Future<HomeTaskSummary> fetchHomeTaskSummary({
    required String userId,
    required String todayStr,
  }) async {
    final results = await Future.wait([
      supabase
          .from('tasks')
          .select(kTaskSelect)
          .eq('user_id', userId)
          .eq('data_vencimento', todayStr),
      supabase
          .from('tasks')
          .select('id')
          .eq('user_id', userId)
          .eq('concluida', false)
          .lt('data_vencimento', todayStr),
    ]);

    final todayTasks = _mapList(results[0]);
    final overdueCount = (results[1] as List).length;

    return HomeTaskSummary(todayTasks: todayTasks, overdueCount: overdueCount);
  }

  /// Linhas `{project_id}` de tarefas pendentes — para contagem por projeto/inbox.
  Future<List<Map<String, dynamic>>> fetchPendingTaskProjectIds(String userId) async {
    final rows = await supabase
        .from('tasks')
        .select('project_id')
        .eq('user_id', userId)
        .eq('concluida', false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<int> countUpcomingTasks(String userId, String todayStr) async {
    final rows = await supabase
        .from('tasks')
        .select('id')
        .eq('user_id', userId)
        .eq('concluida', false)
        .gt('data_vencimento', todayStr);
    return (rows as List).length;
  }

  // ── Filters dashboard + drill-down ───────────────────────────────────────────

  Future<FilterDashboardCounts> fetchFilterDashboardCounts({
    required String todayStr,
    required String weekStr,
  }) async {
    final results = await Future.wait([
      supabase
          .from('tasks')
          .select('id')
          .eq('concluida', false)
          .lt('data_vencimento', todayStr),
      supabase
          .from('tasks')
          .select('id')
          .eq('concluida', false)
          .eq('data_vencimento', todayStr),
      supabase
          .from('tasks')
          .select('id')
          .eq('concluida', false)
          .gt('data_vencimento', todayStr)
          .lte('data_vencimento', weekStr),
      supabase
          .from('tasks')
          .select('id')
          .eq('concluida', true)
          .eq('data_vencimento', todayStr),
    ]);

    return FilterDashboardCounts(
      overdue: (results[0] as List).length,
      today: (results[1] as List).length,
      week: (results[2] as List).length,
      completedToday: (results[3] as List).length,
    );
  }

  Future<List<Task>> fetchFilteredTasks({
    required TaskFilterKind kind,
    required String todayStr,
    required String weekStr,
  }) async {
    var q = supabase.from('tasks').select(kTaskSelect);

    switch (kind) {
      case TaskFilterKind.overdue:
        q = q.eq('concluida', false).lt('data_vencimento', todayStr);
      case TaskFilterKind.today:
        q = q.eq('concluida', false).eq('data_vencimento', todayStr);
      case TaskFilterKind.week:
        q = q
            .eq('concluida', false)
            .gt('data_vencimento', todayStr)
            .lte('data_vencimento', weekStr);
      case TaskFilterKind.completedToday:
        q = q.eq('concluida', true).eq('data_vencimento', todayStr);
    }

    final rows = await q.order('data_vencimento', ascending: true).order('ordem');
    return _mapList(rows);
  }

  Future<void> toggleTaskDoneById(String id, bool done) async {
    await supabase.from('tasks').update({'concluida': done}).eq('id', id);
    TaskSync.instance.notifyChanged();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static List<Task> _mapList(dynamic rows) =>
      (rows as List).map((r) => Task.fromJson(r as Map<String, dynamic>)).toList();

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Keep static for backward compat with existing callers
  static Task mapRow(Map<String, dynamic> row) => Task.fromJson(row);
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_item.dart';

/// Mengelola daftar tugas (tasks) dari Supabase,
/// termasuk status isDone per user.
class TaskProvider extends ChangeNotifier {
  final List<TaskItem> _tasks = [];
  bool _isLoading = false;

  List<TaskItem> get tasks => _tasks;
  bool get isLoading => _isLoading;

  List<TaskItem> get upcoming => _tasks
      .where((t) => !t.isDone)
      .toList()
    ..sort((a, b) => a.deadline.compareTo(b.deadline));

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  /// === FETCH DATA DARI SUPABASE ===

  Future<void> loadData() async {
    final userId = _userId;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch semua tasks
      final taskRows = await _client
          .from('tasks')
          .select('id, roadmap_id, course_title, title, description, deadline, urgency, type')
          .order('created_at');

      // 2. Fetch user_tasks milik user saat ini
      final userTaskRows = await _client
          .from('user_tasks')
          .select('task_id, is_done')
          .eq('user_id', userId);

      // Build lookup set
      final doneTaskIds = <String>{};
      for (final row in userTaskRows) {
        if (row['is_done'] == true) {
          doneTaskIds.add(row['task_id'] as String);
        }
      }

      // 3. Build model objects
      _tasks.clear();

      for (final row in taskRows) {
        final taskId = row['id'] as String;
        final urgencyStr = row['urgency'] as String? ?? 'mendatang';
        final typeStr = row['type'] as String? ?? 'praktik';

        _tasks.add(TaskItem(
          id: taskId,
          courseTitle: row['course_title'] as String? ?? '',
          title: row['title'] as String,
          description: row['description'] as String? ?? '',
          deadline: row['deadline'] != null
              ? DateTime.parse(row['deadline'] as String)
              : DateTime.now().add(const Duration(days: 7)),
          urgency: urgencyStr == 'mendesak'
              ? TaskUrgency.mendesak
              : TaskUrgency.mendatang,
          type: typeStr == 'kuis' ? TaskType.kuis : TaskType.praktik,
          isDone: doneTaskIds.contains(taskId),
          roadmapId: row['roadmap_id'] as String?,
        ));
      }

      _isLoading = false;
    } catch (_) {
      _isLoading = false;
    }

    notifyListeners();
  }

  /// === TANDAI TUGAS SELESAI ===

  Future<void> markDone(String taskId) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _client.from('user_tasks').upsert({
        'user_id': userId,
        'task_id': taskId,
        'is_done': true,
      }, onConflict: 'user_id,task_id');

      // Update in-memory
      final task = _tasks.firstWhere((t) => t.id == taskId);
      task.isDone = true;
      notifyListeners();
    } catch (_) {
      // Silent fail — UI tetap update optimistically
    }
  }

  /// === ADMIN CRUD ===

  Future<void> addTask({
    required String roadmapId,
    required String courseTitle,
    required String title,
    required String description,
    required DateTime deadline,
    required String urgency,
    required String type,
  }) async {
    await _client.from('tasks').insert({
      'roadmap_id': roadmapId,
      'course_title': courseTitle,
      'title': title,
      'description': description,
      'deadline': deadline.toUtc().toIso8601String(),
      'urgency': urgency,
      'type': type,
    });
  }

  Future<void> updateTask({
    required String id,
    required String roadmapId,
    required String courseTitle,
    required String title,
    required String description,
    required DateTime deadline,
    required String urgency,
    required String type,
  }) async {
    await _client.from('tasks').update({
      'roadmap_id': roadmapId,
      'course_title': courseTitle,
      'title': title,
      'description': description,
      'deadline': deadline.toUtc().toIso8601String(),
      'urgency': urgency,
      'type': type,
    }).eq('id', id);
  }

  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }
}

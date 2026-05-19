import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<TaskListModel> _lists = [];
  bool _isLoaded = false;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<TaskListModel> get lists => List.unmodifiable(_lists);
  bool get isLoaded => _isLoaded;

  // My Day: non-completed tasks (today + no-date tasks)
  List<Task> get myDayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
      if (t.status == TaskStatus.completed) return false;
      if (t.dueDate == null) return true;
      return !t.dueDate!.isAfter(today.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) {
        if (a.status == TaskStatus.overdue && b.status != TaskStatus.overdue) return -1;
        if (b.status == TaskStatus.overdue && a.status != TaskStatus.overdue) return 1;
        if (a.priority.index > b.priority.index) return -1;
        if (a.priority.index < b.priority.index) return 1;
        return 0;
      });
  }

  List<Task> get overdueTasks =>
      _tasks.where((t) => t.status == TaskStatus.overdue).toList();

  // Completed today
  List<Task> get completedToday {
    final now = DateTime.now();
    return _tasks
        .where((t) =>
            t.status == TaskStatus.completed &&
            t.completedAt != null &&
            t.completedAt!.year == now.year &&
            t.completedAt!.month == now.month &&
            t.completedAt!.day == now.day)
        .toList()
      ..sort((a, b) => (b.completedAt ?? DateTime(0))
          .compareTo(a.completedAt ?? DateTime(0)));
  }

  // Completed yesterday
  List<Task> get completedYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _tasks
        .where((t) =>
            t.status == TaskStatus.completed &&
            t.completedAt != null &&
            t.completedAt!.year == yesterday.year &&
            t.completedAt!.month == yesterday.month &&
            t.completedAt!.day == yesterday.day)
        .toList()
      ..sort((a, b) => (b.completedAt ?? DateTime(0))
          .compareTo(a.completedAt ?? DateTime(0)));
  }

  // All completed (for Done screen)
  List<Task> get allCompleted =>
      _tasks.where((t) => t.status == TaskStatus.completed).toList()
        ..sort((a, b) => (b.completedAt ?? DateTime(0))
            .compareTo(a.completedAt ?? DateTime(0)));

  // Today's progress
  double get todayProgress {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayAll = _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == today.year &&
          t.dueDate!.month == today.month &&
          t.dueDate!.day == today.day;
    }).toList();
    if (todayAll.isEmpty) return 0.0;
    final done = todayAll.where((t) => t.status == TaskStatus.completed).length;
    return done / todayAll.length;
  }

  // Tasks for a specific date
  List<Task> tasksForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      final td = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return td == d;
    }).toList();
  }

  // 7-day completed chart data (oldest → today)
  List<int> get weeklyCompletedCounts {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day - (6 - i));
      return _tasks
          .where((t) =>
              t.status == TaskStatus.completed &&
              t.completedAt != null &&
              t.completedAt!.year == day.year &&
              t.completedAt!.month == day.month &&
              t.completedAt!.day == day.day)
          .length;
    });
  }

  // Task count per list
  int taskCountForList(String listId) =>
      _tasks.where((t) => t.listId == listId).length;

  int completedCountForList(String listId) => _tasks
      .where((t) => t.listId == listId && t.status == TaskStatus.completed)
      .length;

  // Search
  List<Task> search(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    return _tasks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            (t.notes?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    _updateOverdueStatuses();
    notifyListeners();
    await _save();
  }

  Future<void> updateTask(Task updated) async {
    final idx = _tasks.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    _tasks[idx] = updated;
    _updateOverdueStatuses();
    notifyListeners();
    await _save();
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> toggleComplete(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final task = _tasks[idx];

    if (task.status == TaskStatus.completed) {
      _tasks[idx] = task.copyWith(
        status: task.isOverdue ? TaskStatus.overdue : TaskStatus.pending,
        completedAt: null,
      );
    } else {
      _tasks[idx] = task.copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
      );
      if (task.recurrence != RecurrenceType.none) {
        _spawnNextOccurrence(task);
      }
    }
    notifyListeners();
    await _save();
  }

  /// Creates the next instance of a recurring [task].
  void _spawnNextOccurrence(Task task) {
    final base     = task.dueDate ?? DateTime.now();
    final nextDate = nextOccurrence(base, task.recurrence);
    final freshSubs = task.subtasks
        .map((s) => SubTask(id: generateId(), title: s.title))
        .toList();
    _tasks.add(Task(
      id:         generateId(),
      title:      task.title,
      notes:      task.notes,
      listId:     task.listId,
      priority:   task.priority,
      status:     TaskStatus.pending,
      dueDate:    nextDate,
      dueTime:    task.dueTime,
      reminder:   task.reminder,
      isStarred:  false,
      subtasks:   freshSubs,
      colorTag:   task.colorTag,
      recurrence: task.recurrence,
    ));
  }

  Future<void> toggleStar(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _tasks[idx] = _tasks[idx].copyWith(isStarred: !_tasks[idx].isStarred);
    notifyListeners();
    await _save();
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final tIdx = _tasks.indexWhere((t) => t.id == taskId);
    if (tIdx == -1) return;
    final task = _tasks[tIdx];
    final updated = task.subtasks.map((s) {
      if (s.id == subtaskId) return s.copyWith(isCompleted: !s.isCompleted);
      return s;
    }).toList();
    _tasks[tIdx] = task.copyWith(subtasks: updated);
    notifyListeners();
    await _save();
  }

  // ─── Lists CRUD ───────────────────────────────────────────────────────────

  Future<void> addList(TaskListModel list) async {
    _lists.add(list);
    notifyListeners();
    await _save();
  }

  Future<void> reorderLists(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _lists.removeAt(oldIndex);
    _lists.insert(newIndex, item);
    for (int i = 0; i < _lists.length; i++) {
      _lists[i] = _lists[i].copyWith(sortOrder: i);
    }
    notifyListeners();
    await _save();
  }

  Future<void> deleteList(String id) async {
    _lists.removeWhere((l) => l.id == id);
    // Unassign tasks from this list
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].listId == id) {
        _tasks[i] = _tasks[i].copyWith(listId: null);
      }
    }
    notifyListeners();
    await _save();
  }

  // ─── Persistence ──────────────────────────────────────────────────────────

  Future<void> init() async {
    await _load();
    _updateOverdueStatuses();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString('tasks');
    final listsJson = prefs.getString('lists');

    if (tasksJson != null) {
      final decoded = jsonDecode(tasksJson) as List<dynamic>;
      _tasks = decoded
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _tasks = defaultTasks();
    }

    if (listsJson != null) {
      final decoded = jsonDecode(listsJson) as List<dynamic>;
      _lists = decoded
          .map((e) => TaskListModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } else {
      _lists = defaultLists();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'tasks', jsonEncode(_tasks.map((t) => t.toJson()).toList()));
    await prefs.setString(
        'lists', jsonEncode(_lists.map((l) => l.toJson()).toList()));
  }

  void _updateOverdueStatuses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      if (t.status == TaskStatus.completed) continue;
      if (t.dueDate != null) {
        final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        if (due.isBefore(today)) {
          _tasks[i] = _tasks[i].copyWith(status: TaskStatus.overdue);
        }
      }
    }
  }

  // Generate unique ID
  String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      (1000 + (DateTime.now().microsecond % 9000)).toString();
}
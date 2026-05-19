enum TaskPriority { none, low, medium, high }
enum TaskStatus   { pending, completed, overdue }

/// How often a task repeats after completion.
enum RecurrenceType { none, daily, weekly, monthly }

// ─── helpers ──────────────────────────────────────────────────────────────────

String recurrenceLabel(RecurrenceType r) {
  switch (r) {
    case RecurrenceType.none:    return 'None';
    case RecurrenceType.daily:   return 'Daily';
    case RecurrenceType.weekly:  return 'Weekly';
    case RecurrenceType.monthly: return 'Monthly';
  }
}

/// Returns the next due date for [base] given [r].
/// Monthly clamping: e.g. Jan 31 → Feb 28/29.
DateTime nextOccurrence(DateTime base, RecurrenceType r) {
  switch (r) {
    case RecurrenceType.none:
      return base;
    case RecurrenceType.daily:
      return base.add(const Duration(days: 1));
    case RecurrenceType.weekly:
      return base.add(const Duration(days: 7));
    case RecurrenceType.monthly:
      final nextMonth = base.month == 12 ? 1  : base.month + 1;
      final nextYear  = base.month == 12 ? base.year + 1 : base.year;
      final lastDay   = DateTime(nextYear, nextMonth + 1, 0).day;
      return DateTime(nextYear, nextMonth, base.day.clamp(1, lastDay));
  }
}

// ─── SubTask ──────────────────────────────────────────────────────────────────

class SubTask {
  String id;
  String title;
  bool isCompleted;

  SubTask({required this.id, required this.title, this.isCompleted = false});

  SubTask copyWith({String? id, String? title, bool? isCompleted}) => SubTask(
        id: id ?? this.id,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'isCompleted': isCompleted};

  factory SubTask.fromJson(Map<String, dynamic> j) => SubTask(
        id: j['id'] as String,
        title: j['title'] as String,
        isCompleted: j['isCompleted'] as bool? ?? false,
      );
}

// ─── Task ─────────────────────────────────────────────────────────────────────

class Task {
  String id;
  String title;
  String? notes;
  String? listId;
  TaskPriority priority;
  TaskStatus status;
  DateTime? dueDate;
  String? dueTime;
  String? reminder;
  bool isStarred;
  List<SubTask> subtasks;
  String? colorTag;
  DateTime createdAt;
  DateTime? completedAt;
  RecurrenceType recurrence;

  Task({
    required this.id,
    required this.title,
    this.notes,
    this.listId,
    this.priority    = TaskPriority.none,
    this.status      = TaskStatus.pending,
    this.dueDate,
    this.dueTime,
    this.reminder,
    this.isStarred   = false,
    List<SubTask>? subtasks,
    this.colorTag,
    DateTime? createdAt,
    this.completedAt,
    this.recurrence  = RecurrenceType.none,
  })  : subtasks  = subtasks ?? [],
        createdAt = createdAt ?? DateTime.now();

  // copyWith — note: completedAt uses an explicit sentinel so it can be
  // cleared to null (passing null normally would be ignored).
  Task copyWith({
    String? id,
    String? title,
    String? notes,
    String? listId,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    String? dueTime,
    String? reminder,
    bool? isStarred,
    List<SubTask>? subtasks,
    String? colorTag,
    Object? completedAt = _keep,   // sentinel trick
    RecurrenceType? recurrence,
  }) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        listId: listId ?? this.listId,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        dueDate: dueDate ?? this.dueDate,
        dueTime: dueTime ?? this.dueTime,
        reminder: reminder ?? this.reminder,
        isStarred: isStarred ?? this.isStarred,
        subtasks: subtasks ?? this.subtasks,
        colorTag: colorTag ?? this.colorTag,
        createdAt: createdAt,
        completedAt: identical(completedAt, _keep)
            ? this.completedAt
            : completedAt as DateTime?,
        recurrence: recurrence ?? this.recurrence,
      );

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) return false;
    final now = DateTime.now();
    return dueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  int get completedSubtasks => subtasks.where((s) => s.isCompleted).length;

  /// True when this task repeats after completion.
  bool get isRecurring => recurrence != RecurrenceType.none;

  /// Alias kept for compatibility with provider / tile code.
  RecurrenceType get effectiveRecurrence => recurrence;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'listId': listId,
        'priority': priority.index,
        'status': status.index,
        'dueDate': dueDate?.toIso8601String(),
        'dueTime': dueTime,
        'reminder': reminder,
        'isStarred': isStarred,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'colorTag': colorTag,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'recurrence': effectiveRecurrence.index,
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        title: j['title'] as String,
        notes: j['notes'] as String?,
        listId: j['listId'] as String?,
        priority: TaskPriority.values[j['priority'] as int? ?? 0],
        status: TaskStatus.values[j['status'] as int? ?? 0],
        dueDate: j['dueDate'] != null ? DateTime.parse(j['dueDate']) : null,
        dueTime: j['dueTime'] as String?,
        reminder: j['reminder'] as String?,
        isStarred: j['isStarred'] as bool? ?? false,
        subtasks: (j['subtasks'] as List<dynamic>? ?? [])
            .map((s) => SubTask.fromJson(s as Map<String, dynamic>))
            .toList(),
        colorTag: j['colorTag'] as String?,
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'])
            : DateTime.now(),
        completedAt: j['completedAt'] != null
            ? DateTime.parse(j['completedAt'])
            : null,
        recurrence: _parseRecurrence(j['recurrence']),
      );
}


// Safely parse recurrence from JSON — old tasks without the key get RecurrenceType.none.
RecurrenceType _parseRecurrence(dynamic v) {
  if (v == null) return RecurrenceType.none;
  if (v is! int) return RecurrenceType.none;
  if (v < 0 || v >= RecurrenceType.values.length) return RecurrenceType.none;
  return RecurrenceType.values[v];
}

// Sentinel object used in copyWith to distinguish "keep current value" from
// "explicitly set to null" for nullable DateTime fields.
const Object _keep = Object();

// ─── TaskListModel ────────────────────────────────────────────────────────────

class TaskListModel {
  String id;
  String name;
  String description;
  int colorValue;
  String iconCodePoint;
  int sortOrder;

  TaskListModel({
    required this.id,
    required this.name,
    required this.description,
    required this.colorValue,
    required this.iconCodePoint,
    required this.sortOrder,
  });

  TaskListModel copyWith({
    String? name,
    String? description,
    int? colorValue,
    String? iconCodePoint,
    int? sortOrder,
  }) =>
      TaskListModel(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        colorValue: colorValue ?? this.colorValue,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'colorValue': colorValue,
        'iconCodePoint': iconCodePoint,
        'sortOrder': sortOrder,
      };

  factory TaskListModel.fromJson(Map<String, dynamic> j) => TaskListModel(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        colorValue: j['colorValue'] as int,
        iconCodePoint: j['iconCodePoint'] as String,
        sortOrder: j['sortOrder'] as int? ?? 0,
      );
}

// ─── Default seed data ────────────────────────────────────────────────────────

List<TaskListModel> defaultLists() => [
      TaskListModel(id: 'work',      name: 'Work',         description: 'Professional goals, project milestones, and meeting agendas.', colorValue: 0xFFEEEDFE, iconCodePoint: 'e8f9', sortOrder: 0),
      TaskListModel(id: 'personal',  name: 'Personal',     description: 'Health, hobbies & life',   colorValue: 0xFFE6F1FB, iconCodePoint: 'e7fd', sortOrder: 1),
      TaskListModel(id: 'groceries', name: 'Groceries',    description: 'Weekly restocking',         colorValue: 0xFFFFEBEE, iconCodePoint: 'e547', sortOrder: 2),
      TaskListModel(id: 'travel',    name: 'Travel Plans', description: "Itinerary for Italy 2024. Don't forget the passport!", colorValue: 0xFF1C1C1E, iconCodePoint: 'e539', sortOrder: 3),
    ];

List<Task> defaultTasks() {
  final now       = DateTime.now();
  final today     = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  return [
    Task(id: 'seed-1', title: 'Design the Fluid Architect System',           listId: 'work',      priority: TaskPriority.high,   status: TaskStatus.overdue,    dueDate: today.subtract(const Duration(days: 2))),
    Task(id: 'seed-2', title: 'Review architectural sketches with engineering', dueDate: today,    dueTime: '14:00', priority: TaskPriority.medium, status: TaskStatus.pending),
    Task(id: 'seed-3', title: 'Order ergonomic studio equipment',             listId: 'personal',  status: TaskStatus.pending, isStarred: true, dueDate: today),
    Task(id: 'seed-4', title: 'Morning meditation and focus ritual',          status: TaskStatus.completed, completedAt: DateTime(now.year, now.month, now.day, 7, 30),
         recurrence: RecurrenceType.daily),   // ← demo recurring seed
    Task(id: 'seed-5', title: 'Finalize Q3 Marketing Strategy',              listId: 'work',      priority: TaskPriority.high,   status: TaskStatus.completed,  completedAt: DateTime(now.year, now.month, now.day, 10, 45)),
    Task(id: 'seed-6', title: 'Review candidate portfolio – Senior UX',      listId: 'work',      status: TaskStatus.completed,  completedAt: DateTime(now.year, now.month, now.day, 9, 15)),
    Task(id: 'seed-7', title: 'Buy artisanal coffee beans',                  listId: 'groceries', status: TaskStatus.completed,  completedAt: DateTime(now.year, now.month, now.day, 8, 30)),
    Task(id: 'seed-8', title: 'Deep Work Session: UI Refactor',              listId: 'work',      priority: TaskPriority.high,   status: TaskStatus.completed,  completedAt: DateTime(yesterday.year, yesterday.month, yesterday.day, 16, 0)),
    Task(id: 'seed-9', title: 'Update Figma component libraries',            listId: 'work',      status: TaskStatus.completed,  completedAt: DateTime(yesterday.year, yesterday.month, yesterday.day, 14, 30),
         subtasks: [SubTask(id: 'ss-1', title: 'Color tokens', isCompleted: true), SubTask(id: 'ss-2', title: 'Typography scale', isCompleted: true), SubTask(id: 'ss-3', title: 'Component variants', isCompleted: false)]),
    Task(id: 'seed-10', title: 'Quarterly Brand Strategy',                   listId: 'work',      priority: TaskPriority.high,   status: TaskStatus.pending,
         dueDate: today.add(const Duration(days: 1)), dueTime: '10:00', reminder: '30 mins before',
         notes: 'Review the initial concepts from the design team.\nNeed to ensure the "Fluid Architect" naming aligns with our broader product narrative.',
         subtasks: [SubTask(id: 'st-1', title: 'Finalize project timeline', isCompleted: true), SubTask(id: 'st-2', title: 'Invite stakeholders to FigJam', isCompleted: true), SubTask(id: 'st-3', title: 'Draft executive summary', isCompleted: false), SubTask(id: 'st-4', title: 'Sketch the visual language', isCompleted: false), SubTask(id: 'st-5', title: 'Schedule design crit', isCompleted: false)]),
  ];
}
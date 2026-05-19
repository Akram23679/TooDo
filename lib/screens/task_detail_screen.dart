import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _notesCtrl;
  late Task _task;
  bool _initialized = false;
  bool _saving = false;
  late RecurrenceType _recurrence;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = context.read<TaskProvider>();
      final found = provider.tasks.firstWhere(
        (t) => t.id == widget.taskId,
        orElse: () => Task(id: widget.taskId, title: ''),
      );
      _task = found;
      _titleCtrl = TextEditingController(text: _task.title);
      _notesCtrl = TextEditingController(text: _task.notes ?? '');
      _recurrence = _task.recurrence;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedSubs = _task.completedSubtasks;
    final totalSubs = _task.subtasks.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Task Detail'),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.primary)),
        ),
        leadingWidth: 72,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title + list + status badges
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800),
                    maxLines: null,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Task title…'),
                    onChanged: (v) =>
                        setState(() => _task = _task.copyWith(title: v)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (_task.listId != null)
                        _Badge(
                            label: _task.listId!,
                            bgColor: AppColors.primary.withValues(alpha: 0.1),
                            textColor: AppColors.primary),
                      if (_task.status == TaskStatus.overdue)
                        _Badge(
                            label: 'OVERDUE',
                            bgColor: AppColors.overdueRed.withValues(alpha: 0.1),
                            textColor: AppColors.overdueRed),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Priority selector (UX improvement #10)
            _SectionCard(
              title: 'PRIORITY',
              child: Row(
                children: TaskPriority.values.map((p) {
                  final isSelected = _task.priority == p;
                  final color = _priorityColor(p);
                  final label = _priorityLabel(p);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() =>
                          _task = _task.copyWith(priority: p)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : Theme.of(context)
                                  .scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : Theme.of(context).dividerColor,
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? color
                                    : AppColors.textSecondary)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // ── Due date + reminder
            Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  _MetaRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'DUE DATE',
                    value: _task.dueDate != null
                        ? DateFormat('MMM d, y').format(_task.dueDate!)
                        : 'No date',
                    onTap: _pickDate,
                  ),
                  Divider(
                      height: 0.5,
                      color: Theme.of(context).dividerColor,
                      indent: 48),
                  _MetaRow(
                    icon: Icons.access_time_rounded,
                    label: 'TIME',
                    value: _task.dueTime ?? 'No time',
                    onTap: _pickTime,
                  ),
                  Divider(
                      height: 0.5,
                      color: Theme.of(context).dividerColor,
                      indent: 48),
                  _MetaRow(
                    icon: Icons.notifications_none_rounded,
                    label: 'REMINDER',
                    value: _task.reminder ?? 'None',
                    onTap: _pickReminder,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Notes
            _SectionCard(
              title: 'NOTES',
              child: TextField(
                controller: _notesCtrl,
                style: const TextStyle(fontSize: 14, height: 1.5),
                maxLines: null,
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Add notes…'),
                onChanged: (v) =>
                    setState(() => _task = _task.copyWith(notes: v)),
              ),
            ),

            const SizedBox(height: 12),

            // ── Subtasks
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SUBTASKS',
                          style:
                              Theme.of(context).textTheme.labelSmall),
                      Text(
                          '$completedSubs/$totalSubs COMPLETE',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.primary)),
                    ],
                  ),
                  if (totalSubs > 0) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: totalSubs == 0
                            ? 0
                            : completedSubs / totalSubs,
                        minHeight: 3,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ..._task.subtasks.map((st) => _SubtaskRow(
                        subtask: st,
                        onToggle: () {
                          setState(() {
                            final idx = _task.subtasks
                                .indexWhere((s) => s.id == st.id);
                            if (idx == -1) return;
                            final updated = List<SubTask>.from(
                                _task.subtasks);
                            updated[idx] = st.copyWith(
                                isCompleted: !st.isCompleted);
                            _task = _task.copyWith(subtasks: updated);
                          });
                        },
                        onDelete: () {
                          setState(() {
                            final updated = _task.subtasks
                                .where((s) => s.id != st.id)
                                .toList();
                            _task = _task.copyWith(subtasks: updated);
                          });
                        },
                      )),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _addSubtask,
                    child: const Row(children: [
                       Icon(Icons.add_circle_outline_rounded,
                          size: 18, color: AppColors.primary),
                       SizedBox(width: 8),
                       Text('Add subtask',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Delete button
            GestureDetector(
              onTap: _deleteTask,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color:
                      AppColors.overdueRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('Delete Task',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.overdueRed)),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: GestureDetector(
            onTap: _save,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14)),
              child: const Center(
                child: Text('Save Changes',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title cannot be empty.')));
      return;
    }
    setState(() => _saving = true);
    final updated = _task.copyWith(
      title: _titleCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      recurrence: _recurrence,
    );
    await context.read<TaskProvider>().updateTask(updated);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _task.dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _task = _task.copyWith(dueDate: picked));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _task = _task.copyWith(
          dueTime: picked.format(context)));
    }
  }

  void _pickReminder() {
    const options = [
      'None',
      'At time of task',
      '5 mins before',
      '15 mins before',
      '30 mins before',
      '1 hour before',
      '1 day before',
    ];
    int selectedIdx =
        options.indexOf(_task.reminder ?? 'None').clamp(0, options.length - 1);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 260,
        color: Theme.of(context).cardColor,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context)),
                const Text('Reminder',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Done',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    onPressed: () {
                      setState(() => _task = _task.copyWith(
                          reminder: options[selectedIdx] == 'None'
                              ? null
                              : options[selectedIdx]));
                      Navigator.pop(context);
                    }),
              ],
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              itemExtent: 40,
              scrollController: FixedExtentScrollController(
                  initialItem: selectedIdx),
              onSelectedItemChanged: (i) => selectedIdx = i,
              children: options
                  .map((o) => Center(
                      child: Text(o, style: const TextStyle(fontSize: 16))))
                  .toList(),
            ),
          ),
        ]),
      ),
    );
  }

  void pickRecurrence() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2))),
            const Text('Repeat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...RecurrenceType.values.map((r) {
              final isSelected = _recurrence == r;
              return GestureDetector(
                onTap: () {
                  setState(() => _recurrence = r);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : Theme.of(context).dividerColor,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_recurrenceIcon(r),
                          size: 20,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(recurrenceLabel(r),
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary)),
                      if (isSelected) ...[
                        const Spacer(),
                        const Icon(Icons.check_rounded,
                            size: 18, color: AppColors.primary),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _recurrenceIcon(RecurrenceType r) {
    switch (r) {
      case RecurrenceType.none:    return Icons.block_rounded;
      case RecurrenceType.daily:   return Icons.wb_sunny_outlined;
      case RecurrenceType.weekly:  return Icons.view_week_outlined;
      case RecurrenceType.monthly: return Icons.calendar_month_outlined;
    }
  }

  void _addSubtask() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Subtask'),
        content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration:
                const InputDecoration(hintText: 'Subtask title…')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  setState(() {
                    final updated = List<SubTask>.from(_task.subtasks)
                      ..add(SubTask(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          title: ctrl.text.trim()));
                    _task = _task.copyWith(subtasks: updated);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add',
                  style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }

  void _deleteTask() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete task?'),
        content:
            Text('"${_task.title}" will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await context
                    .read<TaskProvider>()
                    .deleteTask(_task.id);
                if (mounted) Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.overdueRed),
              child: const Text('Delete')),
        ],
      ),
    );
  }

  Color _priorityColor(TaskPriority p) =>
      AppColors.priorityColor(p);

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.none:
        return 'None';
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 1),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  final SubTask subtask;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SubtaskRow(
      {required this.subtask,
      required this.onToggle,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: subtask.isCompleted
                  ? AppColors.primary
                  : Colors.transparent,
              border: subtask.isCompleted
                  ? null
                  : Border.all(
                      color: Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(5),
            ),
            child: subtask.isCompleted
                ? const Icon(Icons.check_rounded,
                    size: 13, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(subtask.title,
              style: TextStyle(
                  fontSize: 14,
                  color: subtask.isCompleted
                      ? AppColors.textSecondary
                      : Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .color,
                  decoration: subtask.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: AppColors.textSecondary)),
        ),
        GestureDetector(
          onTap: onDelete,
          child: const Icon(Icons.close_rounded,
              size: 16, color: AppColors.textSecondary),
        ),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _Badge(
      {required this.label,
      required this.bgColor,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor)),
    );
  }
}
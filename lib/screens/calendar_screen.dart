import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import 'task_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  bool _showFullMonth = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _expandAnim = CurvedAnimation(
        parent: _expandCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggleMonth() {
    setState(() => _showFullMonth = !_showFullMonth);
    if (_showFullMonth) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(builder: (ctx, provider, _) {
      final today = DateTime.now();
      final tasks = provider.tasksForDate(_selectedDate);

      // Build task count map for week strip
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final Map<DateTime, int> taskCounts = {};
      for (int i = 0; i < 7; i++) {
        final d = weekStart.add(Duration(days: i));
        final key = DateTime(d.year, d.month, d.day);
        taskCounts[key] = provider.tasksForDate(d).length;
      }

      return Scaffold(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        body: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(children: [
                    CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            const Color(0xFF1C1C1E).withValues(alpha: 0.85),
                        child: const Text('A',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white))),
                    const SizedBox(width: 10),
                    const Text('Too Do',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.add_rounded, size: 24),
                        color: AppColors.primary,
                        onPressed: () =>
                            _showAddTaskForDate(ctx, provider)),
                  ]),
                ),
              ),
            ),

            // Month title + toggle
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: _toggleMonth,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(
                                  fontSize: 30, fontWeight: FontWeight.w800)),
                          Text(
                              '${provider.tasksForDate(today).length} tasks today',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _showFullMonth ? 0.5 : 0,
                      duration: const Duration(milliseconds: 280),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 28, color: AppColors.textSecondary),
                    ),
                  ]),
                ),
              ),
            ),

            // Week strip (UX improvement #8)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: WeekStrip(
                  selectedDate: _selectedDate,
                  taskCounts: taskCounts,
                  onDateSelected: (d) => setState(() => _selectedDate = d),
                ),
              ),
            ),

            // Full month calendar (collapsible)
            SliverToBoxAdapter(
              child: SizeTransition(
                sizeFactor: _expandAnim,
                child: FadeTransition(
                  opacity: _expandAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _FullMonthGrid(
                      displayMonth: DateTime(
                          _selectedDate.year, _selectedDate.month),
                      selectedDate: _selectedDate,
                      onSelect: (d) => setState(() {
                        _selectedDate = d;
                        _toggleMonth();
                      }),
                      taskCounts: taskCounts,
                      provider: provider,
                    ),
                  ),
                ),
              ),
            ),

            // Selected day header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('EEEE, MMM d').format(_selectedDate),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    if (tasks.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${tasks.length} task${tasks.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                      ),
                  ],
                ),
              ),
            ),

            // Task list for selected day
            if (tasks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _PlanAheadCard(
                      onSchedule: () =>
                          _showAddTaskForDate(ctx, provider)),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _CalendarTaskRow(
                      task: tasks[i],
                      onToggle: () => provider.toggleComplete(tasks[i].id),
                      onTap: () => Navigator.push(ctx,
                          MaterialPageRoute(
                              builder: (_) =>
                                  TaskDetailScreen(taskId: tasks[i].id))),
                    ),
                  ),
                  childCount: tasks.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      );
    });
  }

  void _showAddTaskForDate(BuildContext ctx, TaskProvider provider) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title:
            Text('Add for ${DateFormat('MMM d').format(_selectedDate)}'),
        content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration:
                const InputDecoration(hintText: 'Task title…')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () async {
                if (ctrl.text.trim().isNotEmpty) {
                  await provider.addTask(Task(
                    id: provider.generateId(),
                    title: ctrl.text.trim(),
                    dueDate: _selectedDate,
                  ));
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add')),
        ],
      ),
    );
  }
}

// ─── Full Month Grid ──────────────────────────────────────────────────────────

class _FullMonthGrid extends StatelessWidget {
  final DateTime displayMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;
  final Map<DateTime, int> taskCounts;
  final TaskProvider provider;

  const _FullMonthGrid({
    required this.displayMonth,
    required this.selectedDate,
    required this.onSelect,
    required this.taskCounts,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    const headers = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final first = DateTime(displayMonth.year, displayMonth.month, 1);
    final startOffset = first.weekday - 1;
    final daysInMonth =
        DateTime(displayMonth.year, displayMonth.month + 1, 0).day;
    final totalCells =
        ((startOffset + daysInMonth) / 7).ceil() * 7;
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          children: headers
              .map((h) => Expanded(
                    child: Center(
                      child: Text(h,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: AppColors.textSecondary)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        ...List.generate((totalCells / 7).ceil(), (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIdx = row * 7 + col;
              if (cellIdx < startOffset ||
                  cellIdx >= startOffset + daysInMonth) {
                return const Expanded(child: SizedBox(height: 44));
              }
              final day = cellIdx - startOffset + 1;
              final date = DateTime(
                  displayMonth.year, displayMonth.month, day);
              final isSelected = date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final count =
                  provider.tasksForDate(date).length;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(date),
                  child: SizedBox(
                    height: 44,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : isToday
                                    ? AppColors.primary.withValues(alpha: 0.7)
                                    : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('$day',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color)),
                          ),
                        ),
                        if (count > 0)
                          Container(
                            width: 4, height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Calendar Task Row ────────────────────────────────────────────────────────

class _CalendarTaskRow extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _CalendarTaskRow(
      {required this.task, required this.onToggle, required this.onTap});

  Color get _labelColor {
    switch (task.listId) {
      case 'work':
        return AppColors.primary;
      case 'personal':
        return AppColors.priorityLow;
      default:
        return AppColors.priorityMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.completed;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 44,
              decoration: BoxDecoration(
                color: _labelColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(task.title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null)),
                    ),
                    if (task.listId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _labelColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(task.listId!.toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _labelColor,
                                letterSpacing: 0.5)),
                      ),
                  ]),
                  if (task.dueTime != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.access_time_outlined,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(task.dueTime!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ]),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    size: 16,
                    color: isDone
                        ? AppColors.primary
                        : Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Plan Ahead Card ──────────────────────────────────────────────────────────

class _PlanAheadCard extends StatelessWidget {
  final VoidCallback onSchedule;
  const _PlanAheadCard({required this.onSchedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).dividerColor,
            style: BorderStyle.solid,
            width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 32, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text('Planning Ahead?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('No tasks scheduled for this day yet.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onSchedule,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30)),
              child: const Text('Schedule Task',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
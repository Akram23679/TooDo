import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import 'task_detail_screen.dart';
import 'search_screen.dart';

class MyDayScreen extends StatelessWidget {
  const MyDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (ctx, provider, _) {
        final overdue = provider.overdueTasks;
        final pending = provider.myDayTasks
            .where((t) => t.status != TaskStatus.overdue)
            .toList();
        final completed = provider.completedToday;
        final progress = provider.todayProgress;

        return Scaffold(
          backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              // ── App Bar
              SliverToBoxAdapter(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(children: [
                      CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: const Text('A',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary))),
                      const SizedBox(width: 10),
                      const Text('Too Do',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      // Focus Mode icon button (UX improvement #11)
                      IconButton(
                          icon: const Icon(Icons.timer_outlined, size: 22),
                          color: AppColors.primary,
                          tooltip: 'Focus Mode',
                          onPressed: () => _showFocusMode(ctx)),
                      // Search icon (UX improvement #2)
                      IconButton(
                          icon: const Icon(Icons.search_rounded, size: 22),
                          color: AppColors.textSecondary,
                          onPressed: () => Navigator.push(ctx,
                              MaterialPageRoute(
                                  builder: (_) => const SearchScreen()))),
                    ]),
                  ),
                ),
              ),

              // ── Greeting + Date (UX improvement #3)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      const Text('My Day',
                          style: TextStyle(
                              fontSize: 36, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(_todayLabel(),
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),

              // ── Day Progress Bar (UX improvement #3)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${completed.length} of ${completed.length + pending.length + overdue.length} tasks done',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary)),
                          Text('${(progress * 100).round()}%',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (_, val, __) => LinearProgressIndicator(
                            value: val,
                            minHeight: 5,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Add Task Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: _AddTaskBar(
                    onAdd: (title) async {
                      await provider.addTask(Task(
                        id: provider.generateId(),
                        title: title,
                        dueDate: DateTime.now(),
                      ));
                    },
                  ),
                ),
              ),

              // ── Overdue Section
              if (overdue.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: AppColors.overdueRed),
                      const SizedBox(width: 6),
                      Text(
                          '${overdue.length} OVERDUE',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: AppColors.overdueRed)),
                    ]),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: OverdueTaskCard(
                        task: overdue[i],
                        onToggle: () => provider.toggleComplete(overdue[i].id),
                        onTap: () => _openDetail(ctx, overdue[i]),
                        onDelete: () {
                          provider.deleteTask(overdue[i].id);
                          _showUndoSnackbar(ctx, overdue[i], provider);
                        },
                      ),
                    ),
                    childCount: overdue.length,
                  ),
                ),
              ],

              // ── Planned Section
              if (pending.isNotEmpty || completed.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                    child: Text('PLANNED',
                        style: Theme.of(ctx).textTheme.labelSmall),
                  ),
                ),

              if (pending.isNotEmpty || completed.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          ...pending.asMap().entries.map((e) => TaskTile(
                                task: e.value,
                                showDivider: e.key < pending.length - 1 ||
                                    completed.isNotEmpty,
                                onToggle: () =>
                                    provider.toggleComplete(e.value.id),
                                onTap: () => _openDetail(ctx, e.value),
                                onDelete: () {
                                  provider.deleteTask(e.value.id);
                                  _showUndoSnackbar(ctx, e.value, provider);
                                },
                                onToggleStar: () =>
                                    provider.toggleStar(e.value.id),
                              )),
                          ...completed.asMap().entries.map((e) => TaskTile(
                                task: e.value,
                                showDivider: e.key < completed.length - 1,
                                onToggle: () =>
                                    provider.toggleComplete(e.value.id),
                                onTap: () => _openDetail(ctx, e.value),
                                onDelete: () =>
                                    provider.deleteTask(e.value.id),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning, Alex';
    if (h < 17) return 'Good afternoon, Alex';
    return 'Good evening, Alex';
  }

  String _todayLabel() {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  void _openDetail(BuildContext ctx, Task task) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)));
  }

  void _showUndoSnackbar(BuildContext ctx, Task task, TaskProvider provider) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text('"${task.title}" deleted'),
      action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primary,
          onPressed: () => provider.addTask(task)),
    ));
  }

  void _showFocusMode(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Theme.of(ctx).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.timer_outlined,
                  size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('Focus Mode',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Block distractions and enter a deep work session.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Focus Mode started! 25 min session begun.')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Start 25-min Session',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─── Add Task Bar ──────────────────────────────────────────────────────────────

class _AddTaskBar extends StatefulWidget {
  final Future<void> Function(String) onAdd;
  const _AddTaskBar({required this.onAdd});

  @override
  State<_AddTaskBar> createState() => _AddTaskBarState();
}

class _AddTaskBarState extends State<_AddTaskBar> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          GestureDetector(
            onTap: _submit,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10)),
              child: _loading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                  hintText: 'Add a task to My Day…',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8)),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await widget.onAdd(_ctrl.text.trim());
    _ctrl.clear();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
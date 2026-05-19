import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import 'task_detail_screen.dart';

class DoneScreen extends StatelessWidget {
  const DoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(builder: (ctx, provider, _) {
      final today = provider.completedToday;
      final yesterday = provider.completedYesterday;
      final counts = provider.weeklyCompletedCounts;
      final total = provider.allCompleted.length;
      final allTasks = provider.tasks.length;
      final progress = allTasks == 0 ? 0.0 : total / allTasks;

      // Day labels for chart
      final now = DateTime.now();
      final dayLabels = List.generate(7, (i) {
        final d = now.subtract(Duration(days: 6 - i));
        return DateFormat('E').format(d).substring(0, 1);
      });

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
                    const CircleAvatar(
                        radius: 18,
                        backgroundColor:  Color(0xFFD4A574),
                        child:  Text('A',
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
                        icon: const Icon(Icons.settings_outlined, size: 22),
                        color: AppColors.textSecondary,
                        onPressed: () {}),
                  ]),
                ),
              ),
            ),

            // Progress Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).cardColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Ring
                      ProgressRing(
                        progress: progress,
                        size: 110,
                        strokeWidth: 10,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${(progress * 100).round()}%',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800)),
                              const Text('DONE',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(_motivationText(today.length),
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                          "You've cleared $total task${total != 1 ? 's' : ''} total.\n${today.length} completed today.",
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.6),
                          textAlign: TextAlign.center),

                      // 7-day chart (UX improvement #9)
                      if (counts.any((c) => c > 0)) ...[
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('THIS WEEK',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: AppColors.textSecondary)),
                        ),
                        const SizedBox(height: 10),
                        WeekBarChart(counts: counts, labels: dayLabels),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Today Section
            if (today.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Today',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      _CountBadge(count: today.length),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _DoneTaskCard(
                      task: today[i],
                      onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                              builder: (_) =>
                                  TaskDetailScreen(taskId: today[i].id))),
                      onUndo: () =>
                          provider.toggleComplete(today[i].id),
                    ),
                  ),
                  childCount: today.length,
                ),
              ),
            ],

            // Yesterday Section
            if (yesterday.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Yesterday',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      _CountBadge(count: yesterday.length),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _DoneTaskCard(
                      task: yesterday[i],
                      onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                              builder: (_) => TaskDetailScreen(
                                  taskId: yesterday[i].id))),
                      onUndo: () =>
                          provider.toggleComplete(yesterday[i].id),
                    ),
                  ),
                  childCount: yesterday.length,
                ),
              ),
            ],

            // Empty state
            if (today.isEmpty && yesterday.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 48,
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    const Text('No completed tasks yet.',
                        style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary)),
                    const Text('Start checking things off!',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ]),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      );
    });
  }

  String _motivationText(int todayCount) {
    if (todayCount == 0) return 'Ready to go!';
    if (todayCount < 3) return 'Nice start.';
    if (todayCount < 6) return 'On a roll!';
    return 'Unstoppable.';
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$count task${count != 1 ? 's' : ''}',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
    );
  }
}

class _DoneTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onUndo;

  const _DoneTaskCard(
      {required this.task, required this.onTap, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.textSecondary)),
                  if (task.completedAt != null)
                    Text(
                        'Completed at ${DateFormat('h:mm a').format(task.completedAt!)}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (task.listId != null || task.priority != TaskPriority.none) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    task.listId != null
                        ? _capitalize(task.listId!)
                        : _priorityLabel(task.priority),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
      default:
        return '';
    }
  }
}
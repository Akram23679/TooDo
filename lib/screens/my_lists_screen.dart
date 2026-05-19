import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import 'task_detail_screen.dart';

class MyListsScreen extends StatelessWidget {
  const MyListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(builder: (ctx, provider, _) {
      return Scaffold(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        body: CustomScrollView(
          slivers: [
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
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 22),
                        color: AppColors.textSecondary,
                        onPressed: () {}),
                  ]),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding:  EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text('My Lists',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
                     Text('Organize your thoughts into focus areas.',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _ReorderableListView(
                  lists: provider.lists,
                  provider: provider,
                  onTapList: (list) => _openList(ctx, list),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddList(context, provider),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      );
    });
  }

  void _openList(BuildContext ctx, TaskListModel list) {
    Navigator.push(ctx,
        MaterialPageRoute(builder: (_) => _ListDetailScreen(list: list)));
  }

  void _showAddList(BuildContext ctx, TaskProvider provider) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Theme.of(ctx).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2))),
            const Text('New List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'List name',
                filled: true,
                fillColor: Theme.of(sheetCtx).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                filled: true,
                fillColor: Theme.of(sheetCtx).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  await provider.addList(TaskListModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    colorValue: 0xFFEEEDFE,
                    iconCodePoint: 'e7fd',
                    sortOrder: provider.lists.length,
                  ));
                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create List',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reorderable List View ────────────────────────────────────────────────────

class _ReorderableListView extends StatelessWidget {
  final List<TaskListModel> lists;
  final TaskProvider provider;
  final void Function(TaskListModel) onTapList;

  const _ReorderableListView({
    required this.lists,
    required this.provider,
    required this.onTapList,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lists.length,
      onReorder: (oldIdx, newIdx) => provider.reorderLists(oldIdx, newIdx),
      buildDefaultDragHandles: false,
      proxyDecorator: (child, _, __) => Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: child),
      itemBuilder: (ctx, i) => _ListCard(
        key: ValueKey(lists[i].id),
        list: lists[i],
        taskCount: provider.taskCountForList(lists[i].id),
        completedCount: provider.completedCountForList(lists[i].id),
        index: i,
        onTap: () => onTapList(lists[i]),
        onDelete: () => _confirmDelete(ctx, lists[i], provider),
      ),
    );
  }

  void _confirmDelete(
      BuildContext ctx, TaskListModel list, TaskProvider provider) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete list?'),
        content: Text(
            '"${list.name}" tasks will be unassigned but not deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.deleteList(list.id);
              },
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.overdueRed),
              child: const Text('Delete')),
        ],
      ),
    );
  }
}

// ─── List Card ────────────────────────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  final TaskListModel list;
  final int taskCount;
  final int completedCount;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ListCard({
    super.key,
    required this.list,
    required this.taskCount,
    required this.completedCount,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = list.colorValue == 0xFF1C1C1E;
    // FIX: use double literal 1.0 so alpha type is correct
    final iconBg = Color(list.colorValue).withValues(alpha: 1.0);
    final iconColor = isDark ? Colors.white : AppColors.primary;
    final progress = taskCount == 0 ? 0.0 : completedCount / taskCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForList(list.id), color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  // Name + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(list.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        if (list.description.isNotEmpty)
                          Text(list.description,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Task count badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (taskCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('$taskCount',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ),
                      const SizedBox(height: 4),
                      Text('$completedCount done',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Drag handle
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle_rounded,
                        color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
              // Per-list progress bar
              if (taskCount > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (_, val, __) => LinearProgressIndicator(
                      value: val,
                      minHeight: 4,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForList(String id) {
    switch (id) {
      case 'work':
        return Icons.work_outline_rounded;
      case 'personal':
        return Icons.person_outline_rounded;
      case 'groceries':
        return Icons.shopping_basket_outlined;
      case 'travel':
        return Icons.flight_outlined;
      default:
        return Icons.list_alt_rounded;
    }
  }
}

// ─── List Detail Screen ───────────────────────────────────────────────────────

class _ListDetailScreen extends StatelessWidget {
  final TaskListModel list;
  const _ListDetailScreen({required this.list});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(builder: (ctx, provider, _) {
      final listTasks =
          provider.tasks.where((t) => t.listId == list.id).toList();
      return Scaffold(
        appBar: AppBar(title: Text(list.name)),
        body: listTasks.isEmpty
            ? const Center(
                child: Text('No tasks in this list yet.',
                    style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                itemCount: listTasks.length,
                itemBuilder: (_, i) => TaskTile(
                  task: listTasks[i],
                  showDivider: i < listTasks.length - 1,
                  onToggle: () => provider.toggleComplete(listTasks[i].id),
                  onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                          builder: (_) =>
                              TaskDetailScreen(taskId: listTasks[i].id))),
                  onDelete: () => provider.deleteTask(listTasks[i].id),
                  onToggleStar: () => provider.toggleStar(listTasks[i].id),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addTask(ctx, provider),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      );
    });
  }

  void _addTask(BuildContext ctx, TaskProvider provider) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Add to ${list.name}'),
        content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Task title…')),
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
                    listId: list.id,
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
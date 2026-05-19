import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import 'celebration_overlay.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onToggleStar;
  final bool showDivider;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    this.onToggleStar,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDone       = task.status == TaskStatus.completed;
    final priorityColor = AppColors.priorityColor(task.priority);
    final textPrimary  = Theme.of(context).textTheme.bodyLarge!.color!;
    final textSecondary = Theme.of(context).textTheme.bodyMedium!.color!;

    return Dismissible(
      key: ValueKey(task.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: AppColors.priorityLow,
        child: const Icon(Icons.check_circle_outline_rounded,
            color: Colors.white, size: 26),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.overdueRed,
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onToggle();
          return false;
        }
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete task?'),
                content:
                    Text('"${task.title}" will be permanently removed.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.overdueRed),
                      child: const Text('Delete')),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    bottom: BorderSide(
                        color: Theme.of(context).dividerColor, width: 0.5))
                : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Priority stripe
                Container(
                  width: 3,
                  decoration: BoxDecoration(color: priorityColor),
                ),
                // ── Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        // ── Checkbox with celebration trigger
                        _CelebrationCheckbox(
                          isDone: isDone,
                          isOverdue:
                              task.status == TaskStatus.overdue,
                          onToggle: onToggle,
                        ),
                        const SizedBox(width: 12),
                        // ── Title + meta
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDone
                                      ? textSecondary
                                      : textPrimary,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: textSecondary,
                                ),
                              ),
                              if (task.dueTime != null ||
                                  task.listId != null ||
                                  task.subtasks.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    if (task.dueTime != null)
                                      _MetaChip(
                                        icon: Icons.access_time_rounded,
                                        label: task.dueTime!,
                                        color: task.status ==
                                                TaskStatus.overdue
                                            ? AppColors.overdueRed
                                            : textSecondary,
                                      ),
                                    if (task.dueTime != null &&
                                        task.listId != null)
                                      const SizedBox(width: 8),
                                    if (task.listId != null)
                                      _MetaChip(
                                        icon: Icons.circle,
                                        label: task.listId!,
                                        color: textSecondary,
                                        iconSize: 5,
                                      ),
                                    if (task.subtasks.isNotEmpty)
                                      _MetaChip(
                                        icon: Icons.check_box_outline_blank_rounded,
                                        label:
                                            '${task.completedSubtasks}/${task.subtasks.length}',
                                        color: textSecondary,
                                      ),
                                    if (task.recurrence != RecurrenceType.none)
                                      _MetaChip(
                                        icon: Icons.repeat_rounded,
                                        label: _recurrenceShort(task.recurrence),
                                        color: AppColors.primary,
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        // ── Star
                        if (onToggleStar != null)
                          GestureDetector(
                            onTap: onToggleStar,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                task.isStarred
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 20,
                                color: task.isStarred
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Checkbox that knows its own screen position ──────────────────────────────

class _CelebrationCheckbox extends StatelessWidget {
  final bool isDone;
  final bool isOverdue;
  final VoidCallback onToggle;

  const _CelebrationCheckbox({
    required this.isDone,
    required this.isOverdue,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Builder gives us a context rooted at this exact widget in the tree,
    // so findRenderObject() returns this box's RenderBox — not a parent's.
    return Builder(
      builder: (localCtx) => GestureDetector(
        onTap: () {
          // Fire celebration only when marking complete (not un-completing)
          if (!isDone) {
            final box =
                localCtx.findRenderObject() as RenderBox?;
            if (box != null) {
              final origin = box.localToGlobal(
                Offset(box.size.width / 2, box.size.height / 2),
              );
              CelebrationOverlay.show(localCtx, origin);
            }
          } else {
            // Un-completing: just a light tap feedback
            HapticFeedback.selectionClick();
          }
          onToggle();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            border: isDone
                ? null
                : Border.all(
                    color: isOverdue
                        ? AppColors.overdueRed
                        : Colors.grey.shade300,
                    width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: isDone
              ? const Icon(Icons.check_rounded,
                  size: 14, color: AppColors.primary)
              : null,
        ),
      ),
    );
  }
}

// ─── Meta chip ────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double iconSize;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    this.iconSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Overdue card (used on My Day screen) ─────────────────────────────────────

class OverdueTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const OverdueTaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).cardColor;

    return Dismissible(
      key: ValueKey('overdue-${task.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
            color: AppColors.priorityLow,
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.check_circle_outline_rounded,
            color: Colors.white, size: 26),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: AppColors.overdueRed,
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          onToggle();
          return false;
        }
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete task?'),
                content:
                    Text('"${task.title}" will be permanently removed.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.overdueRed),
                      child: const Text('Delete')),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: cardBg, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox with celebration
                  _CelebrationCheckbox(
                    isDone: false,
                    isOverdue: true,
                    onToggle: onToggle,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        if (task.listId != null) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.label_outline_rounded,
                                size: 13,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                                '${task.listId}  •  '
                                '${_priorityLabel(task.priority)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(
                    width: 44,
                    height: 24,
                    child: Stack(clipBehavior: Clip.none, children: [
                       CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFFD4A574)),
                       Positioned(
                        left: 16,
                        child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(0xFF2D2D2D)),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.overdueRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('OVERDUE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.overdueRed,
                            letterSpacing: 0.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:   return 'High Priority';
      case TaskPriority.medium: return 'Medium Priority';
      case TaskPriority.low:    return 'Low Priority';
      case TaskPriority.none:   return '';
    }
  }
}

String _recurrenceShort(RecurrenceType r) {
  switch (r) {
    case RecurrenceType.none:    return '';
    case RecurrenceType.daily:   return 'Daily';
    case RecurrenceType.weekly:  return 'Weekly';
    case RecurrenceType.monthly: return 'Monthly';
  }
}
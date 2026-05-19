import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'my_day_screen.dart';
import 'my_lists_screen.dart';
import 'calendar_screen.dart';
import 'done_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // NOTE: 'final' not 'static const' — avoids const-constructor cascade issues
  final List<Widget> _screens = const [
    MyDayScreen(),
    MyListsScreen(),
    CalendarScreen(),
    DoneScreen(),
  ];

  static const _navItems = [
    _NavData(icon: Icons.calendar_today_outlined,  activeIcon: Icons.calendar_today,           label: 'MY DAY'),
    _NavData(icon: Icons.format_list_bulleted_rounded, activeIcon: Icons.format_list_bulleted_rounded, label: 'LISTS'),
    _NavData(icon: Icons.calendar_month_outlined,  activeIcon: Icons.calendar_month,           label: 'CALENDAR'),
    _NavData(icon: Icons.check_circle_outline_rounded, activeIcon: Icons.check_circle_rounded, label: 'DONE'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg  = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: _index != 3
          ? FloatingActionButton(
              onPressed: _showAddTask,
              backgroundColor: AppColors.primary,
              elevation: 4,
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: barBg,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final isActive = i == _index;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _index = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            isActive ? _navItems[i].activeIcon : _navItems[i].icon,
                            key: ValueKey(isActive),
                            size: isActive ? 23 : 21,
                            color: isActive ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _navItems[i].label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isActive ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTask() {
    Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskSheet()),
    ).then((result) {
      if (result == null) return;
      if (!mounted) return;
      final provider = context.read<TaskProvider>();
      provider.addTask(Task(
        id: provider.generateId(),
        title: result['title'] as String,
        priority: result['priority'] as TaskPriority,
        dueDate: DateTime.now(),
      ));
    });
  }
}

// ─── Nav item data ────────────────────────────────────────────────────────────

class _NavData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavData({required this.icon, required this.activeIcon, required this.label});
}

// ─── Quick Add Task Sheet ─────────────────────────────────────────────────────

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});
  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _ctrl = TextEditingController();
  TaskPriority _priority = TaskPriority.none;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('New Task'),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.primary)),
        ),
        leadingWidth: 72,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Add',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14)),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                    hintText: 'Task title…',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero),
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('PRIORITY',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: TaskPriority.values
                  .map((p) => _PriorityChip(
                        label: _priorityLabel(p),
                        value: p,
                        selected: _priority,
                        onTap: (v) => setState(() => _priority = v),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_ctrl.text.trim().isEmpty) return;
    Navigator.pop(context, {'title': _ctrl.text.trim(), 'priority': _priority});
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.none:   return 'None';
      case TaskPriority.low:    return 'Low';
      case TaskPriority.medium: return 'Medium';
      case TaskPriority.high:   return 'High';
    }
  }
}

// ─── Priority chip ────────────────────────────────────────────────────────────

class _PriorityChip extends StatelessWidget {
  final String label;
  final TaskPriority value;
  final TaskPriority selected;
  final ValueChanged<TaskPriority> onTap;

  const _PriorityChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  Color _color(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:   return AppColors.priorityHigh;
      case TaskPriority.medium: return AppColors.priorityMedium;
      case TaskPriority.low:    return AppColors.priorityLow;
      case TaskPriority.none:   return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    final color = _color(value);
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? color : Theme.of(context).dividerColor,
              width: isSelected ? 1.5 : 0.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppColors.textSecondary)),
      ),
    );
  }
}
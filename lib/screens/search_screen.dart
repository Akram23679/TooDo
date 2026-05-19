import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import 'task_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<Task> _results = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onQuery);
  }

  void _onQuery() {
    final provider = context.read<TaskProvider>();
    setState(() {
      _hasSearched = _ctrl.text.isNotEmpty;
      _results = provider.search(_ctrl.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppColors.primary,
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Search tasks, notes…',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AppColors.textSecondary,
              onPressed: () {
                _ctrl.clear();
                setState(() {
                  _results = [];
                  _hasSearched = false;
                });
              },
            ),
        ],
      ),
      body: !_hasSearched
          ? _EmptySearch()
          : _results.isEmpty
              ? _NoResults(query: _ctrl.text)
              : _ResultsList(results: _results),
    );
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onQuery);
    _ctrl.dispose();
    super.dispose();
  }
}

class _EmptySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_rounded,
            size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        const Text('Search all your tasks',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        const Text('Tasks, notes, lists',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off_rounded,
            size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text('No results for "$query"',
            style: const TextStyle(
                fontSize: 16, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        const Text('Try different keywords',
            style:
                TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<Task> results;
  const _ResultsList({required this.results});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TaskProvider>();
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: results.length,
      itemBuilder: (ctx, i) => TaskTile(
        task: results[i],
        showDivider: i < results.length - 1,
        onToggle: () => provider.toggleComplete(results[i].id),
        onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (_) =>
                    TaskDetailScreen(taskId: results[i].id))),
        onDelete: () => provider.deleteTask(results[i].id),
        onToggleStar: () => provider.toggleStar(results[i].id),
      ),
    );
  }
}
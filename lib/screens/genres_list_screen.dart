import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/genre_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';

class GenresListScreen extends StatefulWidget {
  const GenresListScreen({super.key});

  @override
  State<GenresListScreen> createState() => _GenresListScreenState();
}

class _GenresListScreenState extends State<GenresListScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      context.read<GenreListNotifier>().load();
    }
  }

  Future<bool> _confirm(String text) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('OK')),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<GenreListNotifier>();

    final body = switch (n.status) {
      LoadStatus.loading => const Center(child: CircularProgressIndicator()),
      LoadStatus.error => ErrorView(message: n.error ?? 'Ошибка', onRetry: n.load),
      LoadStatus.success => n.items.isEmpty
          ? const EmptyView(message: 'Жанров нет')
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: n.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final g = n.items[i];
                return Card(
                  child: ListTile(
                    title: Text(g.isDeleted ? '${g.name} (удалено)' : g.name),
                    onTap: () => context.go('/genres/${g.id}'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Редактировать',
                          onPressed: () => context.go('/genres/${g.id}/edit'),
                          icon: const Icon(Icons.edit),
                        ),
                        if (!g.isDeleted)
                          IconButton(
                            tooltip: 'Удалить (логически)',
                            onPressed: () async {
                              final ok = await _confirm('Удалить жанр "${g.name}"?');
                              if (!ok) return;
                              await n.softDelete(g.id);
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        if (g.isDeleted)
                          IconButton(
                            tooltip: 'Восстановить',
                            onPressed: () => n.restore(g.id),
                            icon: const Icon(Icons.restore),
                          ),
                        IconButton(
                          tooltip: 'Удалить навсегда',
                          onPressed: () async {
                            final ok = await _confirm('Удалить НАВСЕГДА жанр "${g.name}"?');
                            if (!ok) return;
                            await n.hardDelete(g.id);
                          },
                          icon: const Icon(Icons.delete_forever),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      _ => const SizedBox.shrink(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Жанры'),
        actions: [
          Row(
            children: [
              Checkbox(
                value: n.includeDeleted,
                onChanged: (v) => n.setIncludeDeleted(v ?? false),
              ),
              const Text('Удалённые'),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/genres/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
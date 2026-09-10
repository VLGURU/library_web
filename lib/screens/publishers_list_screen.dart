import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/book_query.dart';
import '../repositories/book_repository.dart';
import '../state/load_status.dart';
import '../state/publisher_list_notifier.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';

class PublishersListScreen extends StatefulWidget {
  const PublishersListScreen({super.key});

  @override
  State<PublishersListScreen> createState() => _PublishersListScreenState();
}

class _PublishersListScreenState extends State<PublishersListScreen> {
  var _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      context.read<PublisherListNotifier>().load();
    }
  }

  Future<bool> _confirm(BuildContext context, String text) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
        ],
      ),
    );
    return res ?? false;
  }

  Future<int> _linkedBooksCount(BuildContext context, int publisherId) async {
    final repo = context.read<BookRepository>();
    final res = await repo.find(
      BookQuery(
        publisherId: publisherId,
        includeDeleted: true,
        page: 1,
        size: 1,
      ),
    );
    return res.total;
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<PublisherListNotifier>();

    final body = switch (n.status) {
      LoadStatus.loading => const Center(child: CircularProgressIndicator()),
      LoadStatus.error => ErrorView(message: n.error ?? 'Ошибка', onRetry: n.load),
      LoadStatus.success => n.items.isEmpty
          ? const EmptyView(message: 'Издательств нет')
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: n.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = n.items[i];
                return Card(
                  child: ListTile(
                    title: Text(p.isDeleted ? '${p.name} (удалено)' : p.name),
                    onTap: () => context.go('/publishers/${p.id}'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Редактировать',
                          onPressed: () => context.go('/publishers/${p.id}/edit'),
                          icon: const Icon(Icons.edit),
                        ),
                        if (!p.isDeleted)
                          IconButton(
                            tooltip: 'Удалить (логически)',
                            onPressed: () async {
                              final count = await _linkedBooksCount(context, p.id);
                              if (count > 0) {
                                if (!context.mounted) return;
                                await showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Нельзя удалить'),
                                    content: Text('На издательство "${p.name}" ссылаются книги: $count'),
                                    actions: [
                                      FilledButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              final ok = await _confirm(context, 'Удалить издательство "${p.name}"?');
                              if (!ok) return;
                              await n.softDelete(p.id);
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        if (p.isDeleted)
                          IconButton(
                            tooltip: 'Восстановить',
                            onPressed: () => n.restore(p.id),
                            icon: const Icon(Icons.restore),
                          ),
                        IconButton(
                          tooltip: 'Удалить навсегда',
                          onPressed: () async {
                            final count = await _linkedBooksCount(context, p.id);
                            if (count > 0) {
                              if (!context.mounted) return;
                              await showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Нельзя удалить'),
                                  content: Text('На издательство "${p.name}" ссылаются книги: $count'),
                                  actions: [
                                    FilledButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            final ok = await _confirm(context, 'Удалить НАВСЕГДА издательство "${p.name}"?');
                            if (!ok) return;
                            await n.hardDelete(p.id);
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
        title: const Text('Издательства'),
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
        onPressed: () => context.go('/publishers/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
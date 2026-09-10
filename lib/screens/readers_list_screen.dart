import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/load_status.dart';
import '../state/reader_list_notifier.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';

class ReadersListScreen extends StatefulWidget {
  const ReadersListScreen({super.key});

  @override
  State<ReadersListScreen> createState() => _ReadersListScreenState();
}

class _ReadersListScreenState extends State<ReadersListScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      context.read<ReaderListNotifier>().load();
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
    final n = context.watch<ReaderListNotifier>();

    final body = switch (n.status) {
      LoadStatus.loading => const Center(child: CircularProgressIndicator()),
      LoadStatus.error => ErrorView(message: n.error ?? 'Ошибка', onRetry: n.load),
      LoadStatus.success => n.items.isEmpty
          ? const EmptyView(message: 'Читателей нет')
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: n.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = n.items[i];
                return Card(
                  child: ListTile(
                    title: Text(r.isDeleted ? '${r.lastName} ${r.firstName} (удалено)' : '${r.lastName} ${r.firstName}'),
                    subtitle: Text('Email: ${r.email} • Билет: ${r.card.number}'),
                    onTap: () => context.go('/readers/${r.id}'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Редактировать',
                          onPressed: () => context.go('/readers/${r.id}/edit'),
                          icon: const Icon(Icons.edit),
                        ),
                        if (!r.isDeleted)
                          IconButton(
                            tooltip: 'Удалить (логически)',
                            onPressed: () async {
                              final ok = await _confirm('Удалить читателя "${r.lastName} ${r.firstName}"?');
                              if (!ok) return;
                              await n.softDelete(r.id);
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        if (r.isDeleted)
                          IconButton(
                            tooltip: 'Восстановить',
                            onPressed: () => n.restore(r.id),
                            icon: const Icon(Icons.restore),
                          ),
                        IconButton(
                          tooltip: 'Удалить навсегда',
                          onPressed: () async {
                            final ok = await _confirm('Удалить НАВСЕГДА читателя "${r.lastName} ${r.firstName}"?');
                            if (!ok) return;
                            await n.hardDelete(r.id);
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
        title: const Text('Читатели'),
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
        onPressed: () => context.go('/readers/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
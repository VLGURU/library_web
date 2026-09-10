import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/load_status.dart';
import '../state/reader_details_notifier.dart';
import '../widgets/error_view.dart';

class ReaderDetailsScreen extends StatelessWidget {
  const ReaderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final n = context.watch<ReaderDetailsNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Читатель'),
        actions: [
          if (n.reader != null)
            IconButton(
              tooltip: 'Редактировать',
              onPressed: () => context.go('/readers/${n.reader!.id}/edit'),
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: switch (n.status) {
        LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        LoadStatus.error => ErrorView(message: n.error ?? 'Ошибка', onRetry: n.load),
        LoadStatus.success => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Builder(
                    builder: (context) {
                      final r = n.reader!;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r.lastName} ${r.firstName}${r.isDeleted ? ' (удалено)' : ''}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text('Email: ${r.email}'),
                          const SizedBox(height: 12),
                          Text('Билет: ${r.card.number}'),
                          Text('Выдан: ${r.card.issuedAt.toIso8601String().substring(0, 10)}'),
                          Text('Действует до: ${r.card.expiresAt.toIso8601String().substring(0, 10)}'),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
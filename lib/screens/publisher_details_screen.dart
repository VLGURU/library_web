import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/load_status.dart';
import '../state/publisher_details_notifier.dart';
import '../widgets/error_view.dart';

class PublisherDetailsScreen extends StatelessWidget {
  const PublisherDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final n = context.watch<PublisherDetailsNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Издательство'),
        actions: [
          if (n.publisher != null)
            IconButton(
              tooltip: 'Редактировать',
              onPressed: () => context.go('/publishers/${n.publisher!.id}/edit'),
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: switch (n.status) {
        LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        LoadStatus.error => ErrorView(message: n.error ?? 'Ошибка', onRetry: n.load),
        LoadStatus.success => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    n.publisher!.isDeleted ? '${n.publisher!.name} (удалено)' : n.publisher!.name,
                    style: Theme.of(context).textTheme.titleLarge,
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
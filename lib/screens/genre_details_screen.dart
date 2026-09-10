import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/genre_details_notifier.dart';
import '../state/load_status.dart';
import '../widgets/error_view.dart';

class GenreDetailsScreen extends StatelessWidget {
  const GenreDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final n = context.watch<GenreDetailsNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Жанр'),
        actions: [
          if (n.genre != null)
            IconButton(
              tooltip: 'Редактировать',
              onPressed: () => context.go('/genres/${n.genre!.id}/edit'),
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
                    n.genre!.isDeleted ? '${n.genre!.name} (удалено)' : n.genre!.name,
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
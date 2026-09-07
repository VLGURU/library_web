import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/author_details_notifier.dart';
import '../state/load_status.dart';
import '../widgets/error_view.dart';

class AuthorDetailsScreen extends StatelessWidget {
  const AuthorDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final n = context.watch<AuthorDetailsNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Карточка автора')),
      body: switch (n.status) {
        LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        LoadStatus.error => ErrorView(message: n.error ?? 'Ошибка', onRetry: n.load),
        LoadStatus.success => _buildCard(context, n),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildCard(BuildContext context, AuthorDetailsNotifier n) {
    final a = n.author!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${a.lastName} ${a.firstName}', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text('Страна: ${a.country}'),
                  if (a.isDeleted)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('Статус: УДАЛЕНО', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
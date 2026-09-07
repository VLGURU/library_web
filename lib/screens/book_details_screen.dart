import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../seed/seed_data.dart';
import '../state/book_details_notifier.dart';
import '../state/load_status.dart';
import '../widgets/error_view.dart';

class BookDetailsScreen extends StatelessWidget {
  const BookDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final n = context.watch<BookDetailsNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Карточка книги')),
      body: switch (n.status) {
        LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        LoadStatus.error => ErrorView(message: n.error ?? 'Ошибка', onRetry: n.load),
        LoadStatus.success => _buildCard(context, n),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildCard(BuildContext context, BookDetailsNotifier n) {
    final b = n.book!;
    final authors = b.authorIds.map(authorShortName).join(', ');
    final genres = b.genreIds.map((id) => genreById[id]?.name ?? '#$id').join(', ');
    final publisher = publisherById[b.publisherId]?.name ?? '—';

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
                  Text(b.title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text('ISBN: ${b.isbn}'),
                  Text('Год: ${b.year}'),
                  Text('Страниц: ${b.pages}'),
                  Text('Издательство: $publisher'),
                  Text('Жанры: $genres'),
                  Text('Авторы: $authors'),
                  Text('Экземпляры: ${b.copiesAvailable}/${b.copiesTotal}'),
                  if (b.isDeleted)
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
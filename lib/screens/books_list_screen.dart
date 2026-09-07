import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../models/book_query.dart';
import '../seed/seed_data.dart';
import '../state/book_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/empty_view.dart';
import '../widgets/entity_table.dart';
import '../widgets/error_view.dart';
import '../widgets/pager.dart';

class BooksListScreen extends StatefulWidget {
  final BookQuery urlQuery;
  const BooksListScreen({super.key, required this.urlQuery});

  @override
  State<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends State<BooksListScreen> {
  final _searchCtrl = TextEditingController();
  final _yearFromCtrl = TextEditingController();
  final _yearToCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _applyControllersFromQuery(widget.urlQuery);

    // ВАЖНО: первая загрузка при первом открытии /books
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookListNotifier>().applyQuery(widget.urlQuery);
    });
  }

  @override
  void didUpdateWidget(covariant BooksListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.urlQuery != oldWidget.urlQuery) {
      _applyControllersFromQuery(widget.urlQuery);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<BookListNotifier>().applyQuery(widget.urlQuery);
      });
    }
  }

  void _applyControllersFromQuery(BookQuery q) {
    _searchCtrl.text = q.search;
    _yearFromCtrl.text = q.yearFrom?.toString() ?? '';
    _yearToCtrl.text = q.yearTo?.toString() ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _yearFromCtrl.dispose();
    _yearToCtrl.dispose();
    super.dispose();
  }

  void _go(BookQuery q) {
    final uri = Uri(path: '/books', queryParameters: q.toQueryParameters());
    context.go(uri.toString());
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

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();

    final body = switch (notifier.status) {
      LoadStatus.loading => const Center(child: CircularProgressIndicator()),
      LoadStatus.error => ErrorView(message: notifier.error ?? 'Неизвестная ошибка', onRetry: notifier.load),
      LoadStatus.success => notifier.result.items.isEmpty
          ? const EmptyView(message: 'Ничего не найдено')
          : _buildSuccess(context, notifier),
      _ => const SizedBox.shrink(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Книги'),
        actions: [
          TextButton(onPressed: () => context.go('/authors'), child: const Text('Авторы')),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(context, notifier),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, BookListNotifier notifier) {
    final q = widget.urlQuery;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Поиск (title / isbn)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (text) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 350), () {
                      _go(q.copyWith(search: text));
                    });
                  },
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int?>(
                  value: q.genreId,
                  decoration: const InputDecoration(labelText: 'Жанр', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все жанры')),
                    ...seedGenres.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))),
                  ],
                  onChanged: (v) => _go(q.copyWith(genreId: v)),
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int?>(
                  value: q.publisherId,
                  decoration: const InputDecoration(labelText: 'Издательство', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все издательства')),
                    ...seedPublishers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                  ],
                  onChanged: (v) => _go(q.copyWith(publisherId: v)),
                ),
              ),
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _yearFromCtrl,
                  decoration: const InputDecoration(labelText: 'Год от', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) {
                    final v = int.tryParse(_yearFromCtrl.text.trim());
                    _go(q.copyWith(yearFrom: v));
                  },
                ),
              ),
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _yearToCtrl,
                  decoration: const InputDecoration(labelText: 'Год до', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) {
                    final v = int.tryParse(_yearToCtrl.text.trim());
                    _go(q.copyWith(yearTo: v));
                  },
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(value: q.includeDeleted, onChanged: (v) => _go(q.copyWith(includeDeleted: v ?? false))),
                  const Text('Показывать удалённые'),
                ],
              ),
              if (notifier.hasSelection)
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final ok = await _confirm(context, 'Удалить выбранные книги (логически)?');
                    if (!ok) return;
                    await notifier.deleteSelected();
                  },
                  icon: const Icon(Icons.delete),
                  label: Text('Удалить выбранные (${notifier.selected.length})'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, BookListNotifier notifier) {
    final q = widget.urlQuery;
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 600;

    final onSort = (String field) {
      final nextAsc = field == q.sortField ? !q.sortAscending : true;
      _go(q.copyWith(sortField: field, sortAscending: nextAsc));
    };

    final pager = Padding(
      padding: const EdgeInsets.all(12),
      child: Pager(
        page: notifier.result.page,
        totalPages: notifier.result.totalPages,
        totalItems: notifier.result.total,
        size: notifier.result.size,
        onPage: (p) => _go(q.copyWith(page: p)),
        onSize: (s) => _go(q.copyWith(size: s)),
      ),
    );

    if (isNarrow) {
      return Column(
        children: [
          pager,
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: notifier.result.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final b = notifier.result.items[i];
                final selected = notifier.selected.contains(b.id);

                return Card(
                  child: ListTile(
                    leading: Checkbox(value: selected, onChanged: (_) => notifier.toggleSelection(b.id)),
                    title: Text(b.title),
                    subtitle: Text('ISBN: ${b.isbn} • ${b.year} • стр. ${b.pages}${b.isDeleted ? ' • УДАЛЕНО' : ''}'),
                    onTap: () => context.go('/books/${b.id}'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        if (!b.isDeleted)
                          IconButton(
                            tooltip: 'Удалить (логически)',
                            onPressed: () async {
                              final ok = await _confirm(context, 'Логически удалить "${b.title}"?');
                              if (!ok) return;
                              await notifier.softDelete(b.id);
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        if (b.isDeleted)
                          IconButton(
                            tooltip: 'Восстановить',
                            onPressed: () => notifier.restore(b.id),
                            icon: const Icon(Icons.restore),
                          ),
                        IconButton(
                          tooltip: 'Удалить навсегда',
                          onPressed: () async {
                            final ok = await _confirm(context, 'Удалить НАВСЕГДА "${b.title}"?');
                            if (!ok) return;
                            await notifier.hardDelete(b.id);
                          },
                          icon: const Icon(Icons.delete_forever),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        pager,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: EntityTable<Book>(
              items: notifier.result.items,
              idOf: (b) => b.id,
              selected: notifier.selected,
              onToggleSelect: notifier.toggleSelection,
              sortField: q.sortField,
              sortAscending: q.sortAscending,
              onSort: onSort,
              columns: [
                TableColumnSpec(
                  label: 'Название',
                  sortField: 'title',
                  build: (b) => Text(
                    b.isDeleted ? '${b.title} (удалено)' : b.title,
                    style: TextStyle(color: b.isDeleted ? Theme.of(context).colorScheme.error : null),
                  ),
                ),
                TableColumnSpec(label: 'ISBN', sortField: 'isbn', build: (b) => Text(b.isbn)),
                TableColumnSpec(label: 'Год', sortField: 'year', numeric: true, build: (b) => Text('${b.year}')),
                TableColumnSpec(label: 'Страниц', sortField: 'pages', numeric: true, build: (b) => Text('${b.pages}')),
                TableColumnSpec(label: 'Издательство', build: (b) => Text(publisherById[b.publisherId]?.name ?? '—')),
              ],
              actions: (b) => [
                IconButton(
                  tooltip: 'Открыть',
                  onPressed: () => context.go('/books/${b.id}'),
                  icon: const Icon(Icons.open_in_new),
                ),
                if (!b.isDeleted)
                  IconButton(
                    tooltip: 'Удалить (логически)',
                    onPressed: () async {
                      final ok = await _confirm(context, 'Логически удалить "${b.title}"?');
                      if (!ok) return;
                      await notifier.softDelete(b.id);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                if (b.isDeleted)
                  IconButton(
                    tooltip: 'Восстановить',
                    onPressed: () => notifier.restore(b.id),
                    icon: const Icon(Icons.restore),
                  ),
                IconButton(
                  tooltip: 'Удалить навсегда',
                  onPressed: () async {
                    final ok = await _confirm(context, 'Удалить НАВСЕГДА "${b.title}"?');
                    if (!ok) return;
                    await notifier.hardDelete(b.id);
                  },
                  icon: const Icon(Icons.delete_forever),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
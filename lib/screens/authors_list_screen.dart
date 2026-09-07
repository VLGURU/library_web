import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../models/author_query.dart';
import '../seed/seed_data.dart';
import '../state/author_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/empty_view.dart';
import '../widgets/entity_table.dart';
import '../widgets/error_view.dart';
import '../widgets/pager.dart';

class AuthorsListScreen extends StatefulWidget {
  final AuthorQuery urlQuery;
  const AuthorsListScreen({super.key, required this.urlQuery});

  @override
  State<AuthorsListScreen> createState() => _AuthorsListScreenState();
}

class _AuthorsListScreenState extends State<AuthorsListScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.urlQuery.search;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthorListNotifier>().applyQuery(widget.urlQuery);
    });
  }

  @override
  void didUpdateWidget(covariant AuthorsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.urlQuery != oldWidget.urlQuery) {
      _searchCtrl.text = widget.urlQuery.search;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuthorListNotifier>().applyQuery(widget.urlQuery);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _go(AuthorQuery q) {
    final uri = Uri(path: '/authors', queryParameters: q.toQueryParameters());
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
    final notifier = context.watch<AuthorListNotifier>();

    final body = switch (notifier.status) {
      LoadStatus.loading => const Center(child: CircularProgressIndicator()),
      LoadStatus.error => ErrorView(message: notifier.error ?? 'Неизвестная ошибка', onRetry: notifier.load),
      LoadStatus.success => notifier.result.items.isEmpty ? const EmptyView(message: 'Ничего не найдено') : _buildSuccess(context, notifier),
      _ => const SizedBox.shrink(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Авторы'),
        actions: [
          TextButton(onPressed: () => context.go('/books'), child: const Text('Книги')),
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

  Widget _buildFilters(BuildContext context, AuthorListNotifier notifier) {
    final q = widget.urlQuery;
    final countries = seedAuthors.map((a) => a.country).toSet().toList()..sort();

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
                  decoration: const InputDecoration(labelText: 'Поиск (фамилия / страна)', border: OutlineInputBorder()),
                  onChanged: (text) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 350), () {
                      _go(q.copyWith(search: text));
                    });
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  value: q.country,
                  decoration: const InputDecoration(labelText: 'Страна', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все страны')),
                    ...countries.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => _go(q.copyWith(country: v)),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(value: q.includeDeleted, onChanged: (v) => _go(q.copyWith(includeDeleted: v ?? false))),
                  const Text('Показывать удалённых'),
                ],
              ),
              if (notifier.hasSelection)
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final ok = await _confirm(context, 'Удалить выбранных авторов (логически)?');
                    if (!ok) return;
                    await notifier.deleteSelected();
                  },
                  icon: const Icon(Icons.delete),
                  label: Text('Удалить выбранных (${notifier.selected.length})'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, AuthorListNotifier notifier) {
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
                final a = notifier.result.items[i];
                final selected = notifier.selected.contains(a.id);

                return Card(
                  child: ListTile(
                    leading: Checkbox(value: selected, onChanged: (_) => notifier.toggleSelection(a.id)),
                    title: Text('${a.lastName} ${a.firstName}${a.isDeleted ? ' (удалено)' : ''}'),
                    subtitle: Text('Страна: ${a.country}'),
                    onTap: () => context.go('/authors/${a.id}'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        if (!a.isDeleted)
                          IconButton(
                            tooltip: 'Удалить (логически)',
                            onPressed: () async {
                              final ok = await _confirm(context, 'Логически удалить ${a.lastName}?');
                              if (!ok) return;
                              await notifier.softDelete(a.id);
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        if (a.isDeleted)
                          IconButton(
                            tooltip: 'Восстановить',
                            onPressed: () => notifier.restore(a.id),
                            icon: const Icon(Icons.restore),
                          ),
                        IconButton(
                          tooltip: 'Удалить навсегда',
                          onPressed: () async {
                            final ok = await _confirm(context, 'Удалить НАВСЕГДА ${a.lastName}?');
                            if (!ok) return;
                            await notifier.hardDelete(a.id);
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
            child: EntityTable<Author>(
              items: notifier.result.items,
              idOf: (a) => a.id,
              selected: notifier.selected,
              onToggleSelect: notifier.toggleSelection,
              sortField: q.sortField,
              sortAscending: q.sortAscending,
              onSort: onSort,
              columns: [
                TableColumnSpec(label: 'Фамилия', sortField: 'lastName', build: (a) => Text(a.lastName)),
                TableColumnSpec(label: 'Имя', sortField: 'firstName', build: (a) => Text(a.firstName)),
                TableColumnSpec(label: 'Страна', sortField: 'country', build: (a) => Text(a.country)),
              ],
              actions: (a) => [
                IconButton(
                  tooltip: 'Открыть',
                  onPressed: () => context.go('/authors/${a.id}'),
                  icon: const Icon(Icons.open_in_new),
                ),
                if (!a.isDeleted)
                  IconButton(
                    tooltip: 'Удалить (логически)',
                    onPressed: () async {
                      final ok = await _confirm(context, 'Логически удалить ${a.lastName}?');
                      if (!ok) return;
                      await notifier.softDelete(a.id);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                if (a.isDeleted)
                  IconButton(
                    tooltip: 'Восстановить',
                    onPressed: () => notifier.restore(a.id),
                    icon: const Icon(Icons.restore),
                  ),
                IconButton(
                  tooltip: 'Удалить навсегда',
                  onPressed: () async {
                    final ok = await _confirm(context, 'Удалить НАВСЕГДА ${a.lastName}?');
                    if (!ok) return;
                    await notifier.hardDelete(a.id);
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
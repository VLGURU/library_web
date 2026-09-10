import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author_query.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';
import '../validators/validators.dart';

class BookFormScreen extends StatefulWidget {
  final int? id;
  const BookFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _isbnCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _pagesCtrl = TextEditingController();
  final _copiesTotalCtrl = TextEditingController();
  final _copiesAvailableCtrl = TextEditingController();

  int? _publisherId;
  List<int> _authorIds = [];
  List<int> _genreIds = [];

  bool _loading = false;
  String? _loadError;
  bool _dirty = false;

  String? _isbnUniqueError;

  List<Publisher> _publishers = [];
  List<Genre> _genres = [];
  List<(int id, String label)> _authors = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _isbnCtrl.dispose();
    _yearCtrl.dispose();
    _pagesCtrl.dispose();
    _copiesTotalCtrl.dispose();
    _copiesAvailableCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final pubRepo = context.read<PublisherRepository>();
      final genreRepo = context.read<GenreRepository>();
      final authorRepo = context.read<AuthorRepository>();

      _publishers = await pubRepo.all(includeDeleted: true);
      _genres = await genreRepo.all(includeDeleted: true);

      final authorsPage = await authorRepo.find(const AuthorQuery(size: 1000, includeDeleted: true));
      _authors = authorsPage.items.map((a) => (a.id, '${a.lastName} ${a.firstName}')).toList();

      if (widget.isEditing) {
        final bookRepo = context.read<BookRepository>();
        final b = await bookRepo.findById(widget.id!);
        if (b == null) {
          _loadError = 'Книга не найдена';
        } else {
          _titleCtrl.text = b.title;
          _isbnCtrl.text = b.isbn;
          _yearCtrl.text = '${b.year}';
          _pagesCtrl.text = '${b.pages}';
          _copiesTotalCtrl.text = '${b.copiesTotal}';
          _copiesAvailableCtrl.text = '${b.copiesAvailable}';
          _publisherId = b.publisherId;
          _authorIds = [...b.authorIds];
          _genreIds = [...b.genreIds];
        }
      } else {
        // дефолты
        if (_publishers.isNotEmpty) _publisherId = _publishers.first.id;
        _copiesTotalCtrl.text = '1';
        _copiesAvailableCtrl.text = '1';
      }
    } catch (e) {
      _loadError = 'Ошибка загрузки: $e';
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<bool> _confirmLeave() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text('Уйти со страницы без сохранения?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Остаться')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Уйти')),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _handlePop() async {
    final ok = await _confirmLeave();
    if (!ok) return;
    if (!mounted) return;
    context.pop();
  }

  Future<void> _submit() async {
    setState(() => _isbnUniqueError = null);

    if (!_formKey.currentState!.validate()) return;

    final bookRepo = context.read<BookRepository>();

    final title = _titleCtrl.text.trim();
    final isbnText = _isbnCtrl.text.trim();

    final year = int.parse(_yearCtrl.text.trim());
    final pages = int.parse(_pagesCtrl.text.trim());
    final copiesTotal = int.parse(_copiesTotalCtrl.text.trim());
    final copiesAvailable = int.parse(_copiesAvailableCtrl.text.trim());

    // уникальность ISBN
    final all = await bookRepo.find(BookQuery(page: 1, size: 10000, includeDeleted: true));
    final exists = all.items.any((b) => b.isbn == isbnText && b.id != (widget.id ?? 0));
    if (exists) {
      setState(() => _isbnUniqueError = 'Этот ISBN уже существует');
      _formKey.currentState!.validate();
      return;
    }

    if (_publisherId == null) return;

    if (widget.isEditing) {
      final existing = await bookRepo.findById(widget.id!);
      if (existing == null) return;

      await bookRepo.update(
        existing.copyWith(
          title: title,
          isbn: isbnText,
          year: year,
          pages: pages,
          publisherId: _publisherId,
          authorIds: _authorIds,
          genreIds: _genreIds,
          copiesTotal: copiesTotal,
          copiesAvailable: copiesAvailable,
        ),
      );
    } else {
      await bookRepo.create(
        Book(
          id: 0,
          title: title,
          isbn: isbnText,
          year: year,
          pages: pages,
          publisherId: _publisherId!,
          authorIds: _authorIds,
          genreIds: _genreIds,
          copiesTotal: copiesTotal,
          copiesAvailable: copiesAvailable,
        ),
      );
    }

    _dirty = false;
    if (!mounted) return;
    context.go('/books');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.isEditing ? 'Редактировать книгу' : 'Новая книга')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? Text(_loadError!)
                      : Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _titleCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Название',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => _dirty = true,
                                  validator: (v) => combine([
                                    () => requiredText(v),
                                    () => minLen(v, 2),
                                    () => maxLen(v, 200),
                                  ]),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _isbnCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'ISBN',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) {
                                    _dirty = true;
                                    if (_isbnUniqueError != null) {
                                      setState(() => _isbnUniqueError = null);
                                    }
                                  },
                                  validator: (v) {
                                    final base = isbn(v);
                                    if (base != null) return base;
                                    return _isbnUniqueError;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _yearCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Год',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => _dirty = true,
                                        validator: (v) => combine([
                                          () => intRequired(v),
                                          () => intRange(v, 1400, 2100),
                                        ]),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _pagesCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Страниц',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => _dirty = true,
                                        validator: (v) => combine([
                                          () => intRequired(v),
                                          () => intRange(v, 1, 5000),
                                        ]),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<int>(
                                  initialValue: _publisherId,
                                  decoration: const InputDecoration(
                                    labelText: 'Издательство',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _publishers
                                      .map((p) => DropdownMenuItem<int>(
                                            value: p.id,
                                            child: Text(p.isDeleted ? '${p.name} (удалено)' : p.name),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() => _publisherId = v);
                                    _dirty = true;
                                  },
                                  validator: (v) => v == null ? 'Выберите издательство' : null,
                                ),
                                const SizedBox(height: 12),

                                FormField<List<int>>(
                                  initialValue: _authorIds,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Выберите хотя бы одного автора' : null,
                                  builder: (field) {
                                    return InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Авторы (M:M)',
                                        border: const OutlineInputBorder(),
                                        errorText: field.errorText,
                                      ),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _authors.map((a) {
                                          final selected = field.value!.contains(a.$1);
                                          return FilterChip(
                                            label: Text(a.$2),
                                            selected: selected,
                                            onSelected: (_) {
                                              final next = [...field.value!];
                                              selected ? next.remove(a.$1) : next.add(a.$1);
                                              field.didChange(next);
                                              setState(() => _authorIds = next);
                                              _dirty = true;
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 12),

                                FormField<List<int>>(
                                  initialValue: _genreIds,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Выберите хотя бы один жанр' : null,
                                  builder: (field) {
                                    return InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Жанры (M:M)',
                                        border: const OutlineInputBorder(),
                                        errorText: field.errorText,
                                      ),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _genres.map((g) {
                                          final selected = field.value!.contains(g.id);
                                          return FilterChip(
                                            label: Text(g.isDeleted ? '${g.name} (удалено)' : g.name),
                                            selected: selected,
                                            onSelected: (_) {
                                              final next = [...field.value!];
                                              selected ? next.remove(g.id) : next.add(g.id);
                                              field.didChange(next);
                                              setState(() => _genreIds = next);
                                              _dirty = true;
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _copiesTotalCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Всего экземпляров',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => _dirty = true,
                                        validator: (v) => combine([
                                          () => intRequired(v),
                                          () => intRange(v, 1, 100000),
                                        ]),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _copiesAvailableCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Доступно',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => _dirty = true,
                                        validator: (v) {
                                          final base = combine([
                                            () => intRequired(v),
                                            () => intRange(v, 0, 100000),
                                          ]);
                                          if (base != null) return base;

                                          final total = int.tryParse(_copiesTotalCtrl.text.trim());
                                          final avail = int.tryParse(_copiesAvailableCtrl.text.trim());
                                          if (total != null && avail != null && avail > total) {
                                            return 'Доступно не может быть больше общего числа';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _submit,
                                    child: Text(widget.isEditing ? 'Сохранить' : 'Создать'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
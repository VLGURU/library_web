import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/genre.dart';
import '../repositories/genre_repository.dart';
import '../validators/validators.dart';

class GenreFormScreen extends StatefulWidget {
  final int? id;
  const GenreFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<GenreFormScreen> createState() => _GenreFormScreenState();
}

class _GenreFormScreenState extends State<GenreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  bool _loading = false;
  String? _loadError;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final repo = context.read<GenreRepository>();
      final g = await repo.findById(widget.id!);
      if (g == null) {
        _loadError = 'Жанр не найден';
      } else {
        _nameCtrl.text = g.name;
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
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<GenreRepository>();
    final name = _nameCtrl.text.trim();

    if (widget.isEditing) {
      final existing = await repo.findById(widget.id!);
      if (existing == null) return;
      await repo.update(existing.copyWith(name: name));
    } else {
      await repo.create(Genre(id: 0, name: name));
    }

    _dirty = false;
    if (!mounted) return;
    context.go('/genres');
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
        appBar: AppBar(title: Text(widget.isEditing ? 'Редактировать жанр' : 'Новый жанр')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? Text(_loadError!)
                      : Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Название',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => _dirty = true,
                                validator: (v) => combine([
                                  () => requiredText(v),
                                  () => minLen(v, 2),
                                  () => maxLen(v, 50),
                                ]),
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
    );
  }
}
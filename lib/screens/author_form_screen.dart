import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../repositories/author_repository.dart';
import '../validators/validators.dart';

class AuthorFormScreen extends StatefulWidget {
  final int? id;
  const AuthorFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

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
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final repo = context.read<AuthorRepository>();
      final a = await repo.findById(widget.id!);
      if (a == null) {
        _loadError = 'Автор не найден';
      } else {
        _firstNameCtrl.text = a.firstName;
        _lastNameCtrl.text = a.lastName;
        _countryCtrl.text = a.country;
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

    final repo = context.read<AuthorRepository>();

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final country = _countryCtrl.text.trim();

    if (widget.isEditing) {
      final existing = await repo.findById(widget.id!);
      if (existing == null) return;
      await repo.update(existing.copyWith(firstName: firstName, lastName: lastName, country: country));
    } else {
      await repo.create(Author(id: 0, firstName: firstName, lastName: lastName, country: country));
    }

    _dirty = false;
    if (!mounted) return;
    context.go('/authors');
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
        appBar: AppBar(title: Text(widget.isEditing ? 'Редактировать автора' : 'Новый автор')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
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
                                controller: _firstNameCtrl,
                                decoration: const InputDecoration(labelText: 'Имя', border: OutlineInputBorder()),
                                onChanged: (_) => _dirty = true,
                                validator: (v) => combine([
                                  () => requiredText(v),
                                  () => minLen(v, 2),
                                  () => maxLen(v, 50),
                                ]),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _lastNameCtrl,
                                decoration: const InputDecoration(labelText: 'Фамилия', border: OutlineInputBorder()),
                                onChanged: (_) => _dirty = true,
                                validator: (v) => combine([
                                  () => requiredText(v),
                                  () => minLen(v, 2),
                                  () => maxLen(v, 50),
                                ]),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _countryCtrl,
                                decoration: const InputDecoration(labelText: 'Страна', border: OutlineInputBorder()),
                                onChanged: (_) => _dirty = true,
                                validator: (v) => combine([
                                  () => requiredText(v),
                                  () => minLen(v, 2),
                                  () => maxLen(v, 60),
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
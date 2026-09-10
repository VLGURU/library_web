import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/library_card.dart';
import '../models/reader.dart';
import '../repositories/reader_repository.dart';
import '../validators/validators.dart';

class ReaderFormScreen extends StatefulWidget {
  final int? id;
  const ReaderFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _cardNumberCtrl = TextEditingController();
  final _issuedAtCtrl = TextEditingController();  // yyyy-mm-dd
  final _expiresAtCtrl = TextEditingController(); // yyyy-mm-dd

  bool _loading = false;
  String? _loadError;
  bool _dirty = false;

  String? _emailUniqueError;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _load();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _cardNumberCtrl.dispose();
    _issuedAtCtrl.dispose();
    _expiresAtCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final repo = context.read<ReaderRepository>();
      final r = await repo.findById(widget.id!);
      if (r == null) {
        _loadError = 'Читатель не найден';
      } else {
        _firstNameCtrl.text = r.firstName;
        _lastNameCtrl.text = r.lastName;
        _emailCtrl.text = r.email;

        _cardNumberCtrl.text = r.card.number;
        _issuedAtCtrl.text = r.card.issuedAt.toIso8601String().substring(0, 10);
        _expiresAtCtrl.text = r.card.expiresAt.toIso8601String().substring(0, 10);
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
    setState(() => _emailUniqueError = null);

    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<ReaderRepository>();

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final emailText = _emailCtrl.text.trim();

    // проверка уникальности email
    final all = await repo.all(includeDeleted: true);
    final exists = all.any((r) =>
        r.email.toLowerCase() == emailText.toLowerCase() &&
        r.id != (widget.id ?? 0));
    if (exists) {
      setState(() => _emailUniqueError = 'Этот email уже используется');
      _formKey.currentState!.validate();
      return;
    }

    final card = LibraryCard(
      number: _cardNumberCtrl.text.trim(),
      issuedAt: DateTime.parse(_issuedAtCtrl.text.trim()),
      expiresAt: DateTime.parse(_expiresAtCtrl.text.trim()),
    );

    if (widget.isEditing) {
      final existing = await repo.findById(widget.id!);
      if (existing == null) return;
      await repo.update(
        existing.copyWith(
          firstName: firstName,
          lastName: lastName,
          email: emailText,
          card: card,
        ),
      );
    } else {
      await repo.create(
        Reader(
          id: 0,
          firstName: firstName,
          lastName: lastName,
          email: emailText,
          card: card,
        ),
      );
    }

    _dirty = false;
    if (!mounted) return;
    context.go('/readers');
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
        appBar: AppBar(title: Text(widget.isEditing ? 'Редактировать читателя' : 'Новый читатель')),
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
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _firstNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Имя',
                                    border: OutlineInputBorder(),
                                  ),
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
                                  decoration: const InputDecoration(
                                    labelText: 'Фамилия',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => _dirty = true,
                                  validator: (v) => combine([
                                    () => requiredText(v),
                                    () => minLen(v, 2),
                                    () => maxLen(v, 50),
                                  ]),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) {
                                    _dirty = true;
                                    if (_emailUniqueError != null) {
                                      setState(() => _emailUniqueError = null);
                                    }
                                  },
                                  validator: (v) {
                                    final base = email(v);
                                    if (base != null) return base;
                                    return _emailUniqueError;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Билет (1:1)', style: Theme.of(context).textTheme.titleMedium),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _cardNumberCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Номер билета',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => _dirty = true,
                                  validator: (v) => combine([
                                    () => requiredText(v),
                                    () => minLen(v, 3),
                                    () => maxLen(v, 20),
                                  ]),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _issuedAtCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Дата выдачи (yyyy-mm-dd)',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => _dirty = true,
                                  validator: dateYmd,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _expiresAtCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Дата окончания (yyyy-mm-dd)',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => _dirty = true,
                                  validator: dateYmd,
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
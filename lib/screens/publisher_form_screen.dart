import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/publisher.dart';
import '../repositories/publisher_repository.dart';
import '../validators/validators.dart';

class PublisherFormScreen extends StatefulWidget {
  final int? id;
  const PublisherFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<PublisherFormScreen> createState() => _PublisherFormScreenState();
}

class _PublisherFormScreenState extends State<PublisherFormScreen> {
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
      final repo = context.read<PublisherRepository>();
      final p = await repo.findById(widget.id!);
      if (p == null) {
        setState(() => _loadError = 'Издательство не найдено');
      } else {
        _nameCtrl.text = p.name;
      }
    } catch (e) {
      setState(() => _loadError = 'Ошибка загрузки: $e');
    }

    setState(() => _loading = false);
  }

  Future<bool> _confirmLeave() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text('Уйти со страницы без сохранения?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Остаться')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Уйти')),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<PublisherRepository>();
    final name = _nameCtrl.text.trim();

    if (widget.isEditing) {
      final existing = await repo.findById(widget.id!);
      if (existing == null) return;
      await repo.update(existing.copyWith(name: name));
    } else {
      await repo.create(Publisher(id: 0, name: name));
    }

    _dirty = false;
    if (mounted) context.go('/publishers');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final ok = await _confirmLeave();
        if (ok && mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.isEditing ? 'Редактировать издательство' : 'Новое издательство')),
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
                                  () => maxLen(v, 80),
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
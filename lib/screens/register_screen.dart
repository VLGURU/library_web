import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../state/auth_notifier.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;

  bool _lenOk = false;
  bool _digitOk = false;
  bool _specOk = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(_checkPassword);
    _checkPassword();
  }

  void _checkPassword() {
    final p = _password.text;
    setState(() {
      _lenOk = p.length >= 8;
      _digitOk = RegExp(r'\d').hasMatch(p);
      _specOk = RegExp(r'[^a-zA-Z0-9]').hasMatch(p);
    });
  }

  @override
  void dispose() {
    _username.dispose();
    _fullName.dispose();
    _password.dispose();
    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String? _validatePassword(String? v) {
    final p = v ?? '';
    if (p.isEmpty) return 'Введите пароль';
    if (!_lenOk) return 'Минимум 8 символов';
    if (!_digitOk) return 'Нужна хотя бы одна цифра';
    if (!_specOk) return 'Нужен спецсимвол';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await context.read<AuthNotifier>().register(
            username: _username.text,
            password: _password.text,
            fullName: _fullName.text,
          );

      if (!mounted) return;
      context.go('/');
    } on ValidationException catch (e) {
      _snack('${e.message}: ${e.errors.values.join(', ')}');
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = [
      'Пароль должен содержать:',
      '- минимум 8 символов: ${_lenOk ? "OK" : "нет"}',
      '- цифру: ${_digitOk ? "OK" : "нет"}',
      '- спецсимвол: ${_specOk ? "OK" : "нет"}',
    ].join('\n');

    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Center(
        child: SizedBox(
          width: 420,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _username,
                    decoration: const InputDecoration(labelText: 'Логин'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите логин' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fullName,
                    decoration: const InputDecoration(labelText: 'Имя'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Пароль'),
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: Text(rules)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(_loading ? 'Создание...' : 'Создать'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : () => context.go('/login'),
                    child: const Text('Назад ко входу'),
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
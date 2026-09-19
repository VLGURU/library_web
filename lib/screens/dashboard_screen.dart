import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/permissions.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    final role = user?.role ?? Role.reader;

    return Scaffold(
      appBar: AppBar(
        title: Text(user == null ? 'Библиотека' : 'Библиотека — ${user.fullName}'),
        actions: [
          if (auth.isAuthenticated)
            TextButton(
              onPressed: () => auth.logout(),
              child: const Text('Выход'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: () => context.go('/books'),
              child: const Text('Каталог книг'),
            ),
            if (user != null && canViewMyCards(role))
              FilledButton(
                onPressed: () => context.go('/my-cards'),
                child: const Text('Мои выдачи (READER)'),
              ),
            if (user != null && canManageDirectories(role))
              FilledButton(
                onPressed: () => context.go('/authors'),
                child: const Text('Авторы (LIBRARIAN+)'),
              ),
            if (user != null && canManageDirectories(role))
              FilledButton(
                onPressed: () => context.go('/genres'),
                child: const Text('Жанры (LIBRARIAN+)'),
              ),
            if (user != null && canManageDirectories(role))
              FilledButton(
                onPressed: () => context.go('/publishers'),
                child: const Text('Издатели (LIBRARIAN+)'),
              ),
            if (user != null && canManageReaders(role))
              FilledButton(
                onPressed: () => context.go('/readers'),
                child: const Text('Читатели (LIBRARIAN+)'),
              ),
            if (user != null && canAdminUsers(role))
              FilledButton(
                onPressed: () => context.go('/admin/users'),
                child: const Text('Пользователи (ADMIN)'),
              ),
          ],
        ),
      ),
    );
  }
}
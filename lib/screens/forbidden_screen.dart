import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Доступ запрещён')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('У вас недостаточно прав для этого раздела.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => context.go('/'), child: const Text('На главную')),
          ],
        ),
      ),
    );
  }
}
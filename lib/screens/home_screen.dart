import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget btn(String text, String path) => SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => context.go(path),
            child: Text(text),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Библиотека')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                btn('Книги', '/books'),
                const SizedBox(height: 12),
                btn('Авторы', '/authors'),
                const SizedBox(height: 12),
                btn('Жанры', '/genres'),
                const SizedBox(height: 12),
                btn('Издательства', '/publishers'),
                const SizedBox(height: 12),
                btn('Читатели', '/readers'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
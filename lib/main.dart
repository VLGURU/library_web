import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/in_memory_author_repository.dart';
import 'repositories/in_memory_book_repository.dart';
import 'router.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';

void main() {
  usePathUrlStrategy();

  runApp(
    MultiProvider(
      providers: [
        Provider<BookRepository>(create: (_) => InMemoryBookRepository()),
        Provider<AuthorRepository>(create: (_) => InMemoryAuthorRepository()),
        ChangeNotifierProvider(create: (c) => BookListNotifier(c.read<BookRepository>())),
        ChangeNotifierProvider(create: (c) => AuthorListNotifier(c.read<AuthorRepository>())),
      ],
      child: const LibraryApp(),
    ),
  );
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Библиотека',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
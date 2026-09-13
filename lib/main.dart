import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';

import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';

import 'repositories/api_author_repository.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_publisher_repository.dart';
import 'repositories/api_reader_repository.dart';

import 'router.dart';

import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>(create: (_) => buildDio()),

        ProxyProvider<Dio, BookRepository>(
          update: (_, dio, __) => ApiBookRepository(dio),
        ),
        ProxyProvider<Dio, AuthorRepository>(
          update: (_, dio, __) => ApiAuthorRepository(dio),
        ),
        ProxyProvider<Dio, GenreRepository>(
          update: (_, dio, __) => ApiGenreRepository(dio),
        ),
        ProxyProvider<Dio, PublisherRepository>(
          update: (_, dio, __) => ApiPublisherRepository(dio),
        ),
        ProxyProvider<Dio, ReaderRepository>(
          update: (_, dio, __) => ApiReaderRepository(dio),
        ),

        ChangeNotifierProvider(
          create: (c) => BookListNotifier(c.read<BookRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => AuthorListNotifier(c.read<AuthorRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => GenreListNotifier(c.read<GenreRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => PublisherListNotifier(c.read<PublisherRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => ReaderListNotifier(c.read<ReaderRepository>()),
        ),
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
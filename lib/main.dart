import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';

import 'repositories/persistent_author_repository.dart';
import 'repositories/persistent_book_repository.dart';
import 'repositories/persistent_genre_repository.dart';
import 'repositories/persistent_publisher_repository.dart';
import 'repositories/persistent_reader_repository.dart';

import 'router.dart';

import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        Provider<BookRepository>(create: (_) => PersistentBookRepository(prefs)),
        Provider<AuthorRepository>(create: (_) => PersistentAuthorRepository(prefs)),
        Provider<GenreRepository>(create: (_) => PersistentGenreRepository(prefs)),
        Provider<PublisherRepository>(create: (_) => PersistentPublisherRepository(prefs)),
        Provider<ReaderRepository>(create: (_) => PersistentReaderRepository(prefs)),

        ChangeNotifierProvider(create: (c) => BookListNotifier(c.read<BookRepository>())),
        ChangeNotifierProvider(create: (c) => AuthorListNotifier(c.read<AuthorRepository>())),
        ChangeNotifierProvider(create: (c) => GenreListNotifier(c.read<GenreRepository>())),
        ChangeNotifierProvider(create: (c) => PublisherListNotifier(c.read<PublisherRepository>())),
        ChangeNotifierProvider(create: (c) => ReaderListNotifier(c.read<ReaderRepository>())),
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
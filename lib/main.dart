import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'core/api_client.dart';
import 'core/auth_api.dart';

import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/library_card_repository.dart';

import 'repositories/api_author_repository.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_publisher_repository.dart';
import 'repositories/api_reader_repository.dart';
import 'repositories/api_user_repository.dart';
import 'repositories/api_library_card_repository.dart';

import 'router.dart';

import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';
import 'state/auth_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();

  final authDio = buildDio();

  final authApi = AuthApi(authDio);
  final auth = AuthNotifier(prefs, authApi);
  await auth.restore();

  final apiDio = buildDio(
    tokenProvider: () => auth.accessToken,
    refreshTokens: () => auth.refreshTokens(),
    logout: () => auth.logout(),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        ChangeNotifierProvider<AuthNotifier>.value(value: auth),

        Provider<Dio>.value(value: apiDio),

        ProxyProvider<Dio, BookRepository>(update: (_, dio, __) => ApiBookRepository(dio)),
        ProxyProvider<Dio, AuthorRepository>(update: (_, dio, __) => ApiAuthorRepository(dio)),
        ProxyProvider<Dio, GenreRepository>(update: (_, dio, __) => ApiGenreRepository(dio)),
        ProxyProvider<Dio, PublisherRepository>(update: (_, dio, __) => ApiPublisherRepository(dio)),
        ProxyProvider<Dio, ReaderRepository>(update: (_, dio, __) => ApiReaderRepository(dio)),

        ProxyProvider<Dio, UserRepository>(update: (_, dio, __) => ApiUserRepository(dio)),
        ProxyProvider<Dio, LibraryCardRepository>(update: (_, dio, __) => ApiLibraryCardRepository(dio)),

        ChangeNotifierProvider(create: (c) => BookListNotifier(c.read<BookRepository>())),
        ChangeNotifierProvider(create: (c) => AuthorListNotifier(c.read<AuthorRepository>())),
        ChangeNotifierProvider(create: (c) => GenreListNotifier(c.read<GenreRepository>())),
        ChangeNotifierProvider(create: (c) => PublisherListNotifier(c.read<PublisherRepository>())),
        ChangeNotifierProvider(create: (c) => ReaderListNotifier(c.read<ReaderRepository>())),
      ],
      child: LibraryApp(router: buildRouter(auth)),
    ),
  );
}

class LibraryApp extends StatelessWidget {
  final GoRouter router;
  const LibraryApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Библиотека',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
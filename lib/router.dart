import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/author_query.dart';
import 'models/book_query.dart';

import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';

import 'screens/home_screen.dart';
import 'screens/not_found_screen.dart';

import 'screens/books_list_screen.dart';
import 'screens/book_details_screen.dart';
import 'screens/book_form_screen.dart';
import 'state/book_details_notifier.dart';

import 'screens/authors_list_screen.dart';
import 'screens/author_details_screen.dart';
import 'screens/author_form_screen.dart';
import 'state/author_details_notifier.dart';

import 'screens/genres_list_screen.dart';
import 'screens/genre_details_screen.dart';
import 'screens/genre_form_screen.dart';
import 'state/genre_details_notifier.dart';

import 'screens/publishers_list_screen.dart';
import 'screens/publisher_details_screen.dart';
import 'screens/publisher_form_screen.dart';
import 'state/publisher_details_notifier.dart';

import 'screens/readers_list_screen.dart';
import 'screens/reader_details_screen.dart';
import 'screens/reader_form_screen.dart';
import 'state/reader_details_notifier.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),

    GoRoute(
      path: '/books',
      builder: (context, state) => BooksListScreen(urlQuery: BookQuery.fromUri(state.uri)),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const BookFormScreen(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) return NotFoundScreen(location: state.uri.toString());
            return ChangeNotifierProvider(
              create: (c) => BookDetailsNotifier(c.read<BookRepository>(), id)..load(),
              child: const BookDetailsScreen(),
            );
          },
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                if (id == null) return NotFoundScreen(location: state.uri.toString());
                return BookFormScreen(id: id);
              },
            ),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/authors',
      builder: (context, state) => AuthorsListScreen(urlQuery: AuthorQuery.fromUri(state.uri)),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const AuthorFormScreen(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) return NotFoundScreen(location: state.uri.toString());
            return ChangeNotifierProvider(
              create: (c) => AuthorDetailsNotifier(c.read<AuthorRepository>(), id)..load(),
              child: const AuthorDetailsScreen(),
            );
          },
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                if (id == null) return NotFoundScreen(location: state.uri.toString());
                return AuthorFormScreen(id: id);
              },
            ),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/genres',
      builder: (context, state) => const GenresListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const GenreFormScreen(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) return NotFoundScreen(location: state.uri.toString());
            return ChangeNotifierProvider(
              create: (c) => GenreDetailsNotifier(c.read<GenreRepository>(), id)..load(),
              child: const GenreDetailsScreen(),
            );
          },
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                if (id == null) return NotFoundScreen(location: state.uri.toString());
                return GenreFormScreen(id: id);
              },
            ),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/publishers',
      builder: (context, state) => const PublishersListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const PublisherFormScreen(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) return NotFoundScreen(location: state.uri.toString());
            return ChangeNotifierProvider(
              create: (c) => PublisherDetailsNotifier(c.read<PublisherRepository>(), id)..load(),
              child: const PublisherDetailsScreen(),
            );
          },
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                if (id == null) return NotFoundScreen(location: state.uri.toString());
                return PublisherFormScreen(id: id);
              },
            ),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/readers',
      builder: (context, state) => const ReadersListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const ReaderFormScreen(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) return NotFoundScreen(location: state.uri.toString());
            return ChangeNotifierProvider(
              create: (c) => ReaderDetailsNotifier(c.read<ReaderRepository>(), id)..load(),
              child: const ReaderDetailsScreen(),
            );
          },
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                if (id == null) return NotFoundScreen(location: state.uri.toString());
                return ReaderFormScreen(id: id);
              },
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => NotFoundScreen(location: state.uri.toString()),
);
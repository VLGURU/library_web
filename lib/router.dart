import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/author_query.dart';
import 'models/book_query.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'screens/author_details_screen.dart';
import 'screens/authors_list_screen.dart';
import 'screens/book_details_screen.dart';
import 'screens/books_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/not_found_screen.dart';
import 'state/author_details_notifier.dart';
import 'state/book_details_notifier.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/books',
      builder: (context, state) {
        final q = BookQuery.fromUri(state.uri);
        return BooksListScreen(urlQuery: q);
      },
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) return NotFoundScreen(location: state.uri.toString());

            return ChangeNotifierProvider(
              create: (ctx) => BookDetailsNotifier(ctx.read<BookRepository>(), id)..load(),
              child: const BookDetailsScreen(),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/authors',
      builder: (context, state) {
        final q = AuthorQuery.fromUri(state.uri);
        return AuthorsListScreen(urlQuery: q);
      },
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) return NotFoundScreen(location: state.uri.toString());

            return ChangeNotifierProvider(
              create: (ctx) => AuthorDetailsNotifier(ctx.read<AuthorRepository>(), id)..load(),
              child: const AuthorDetailsScreen(),
            );
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => NotFoundScreen(location: state.uri.toString()),
);
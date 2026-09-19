import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/permissions.dart';
import 'models/author_query.dart';
import 'models/book_query.dart';
import 'models/role.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';
import 'screens/author_details_screen.dart';
import 'screens/author_form_screen.dart';
import 'screens/authors_list_screen.dart';
import 'screens/book_details_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/books_list_screen.dart';
import 'screens/genre_details_screen.dart';
import 'screens/genre_form_screen.dart';
import 'screens/genres_list_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/publisher_details_screen.dart';
import 'screens/publisher_form_screen.dart';
import 'screens/publishers_list_screen.dart';
import 'screens/reader_details_screen.dart';
import 'screens/reader_form_screen.dart';
import 'screens/readers_list_screen.dart';
import 'state/author_details_notifier.dart';
import 'state/book_details_notifier.dart';
import 'state/genre_details_notifier.dart';
import 'state/publisher_details_notifier.dart';
import 'state/reader_details_notifier.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/users_screen.dart';
import 'screens/my_cards_screen.dart';
import 'state/auth_notifier.dart';

GoRouter buildRouter(AuthNotifier auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }

      if (loggedIn && isPublic) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),

      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),

      // READER screen
      GoRoute(
        path: '/my-cards',
        redirect: (context, state) {
          final role = auth.user?.role ?? Role.reader;
          return canViewMyCards(role) ? null : '/forbidden';
        },
        builder: (context, state) => const MyCardsScreen(),
      ),

      // ADMIN screen
      GoRoute(
        path: '/admin/users',
        redirect: (context, state) {
          final role = auth.user?.role ?? Role.reader;
          return canAdminUsers(role) ? null : '/forbidden';
        },
        builder: (context, state) => const UsersScreen(),
      ),

      // BOOKS: доступен всем вошедшим, но new/edit только librarian+
      GoRoute(
        path: '/books',
        builder: (context, state) => BooksListScreen(urlQuery: BookQuery.fromUri(state.uri)),
        routes: [
          GoRoute(
            path: 'new',
            redirect: (context, state) {
              final role = auth.user?.role ?? Role.reader;
              return canManageBooks(role) ? null : '/forbidden';
            },
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
                redirect: (context, state) {
                  final role = auth.user?.role ?? Role.reader;
                  return canManageBooks(role) ? null : '/forbidden';
                },
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

      // Librarian-only directories and readers
      GoRoute(
        path: '/authors',
        redirect: (context, state) {
          final role = auth.user?.role ?? Role.reader;
          return canManageDirectories(role) ? null : '/forbidden';
        },
        builder: (context, state) => AuthorsListScreen(urlQuery: AuthorQuery.fromUri(state.uri)),
        routes: [
          GoRoute(path: 'new', builder: (context, state) => const AuthorFormScreen()),
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
        redirect: (context, state) {
          final role = auth.user?.role ?? Role.reader;
          return canManageDirectories(role) ? null : '/forbidden';
        },
        builder: (context, state) => const GenresListScreen(),
        routes: [
          GoRoute(path: 'new', builder: (context, state) => const GenreFormScreen()),
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
        redirect: (context, state) {
          final role = auth.user?.role ?? Role.reader;
          return canManageDirectories(role) ? null : '/forbidden';
        },
        builder: (context, state) => const PublishersListScreen(),
        routes: [
          GoRoute(path: 'new', builder: (context, state) => const PublisherFormScreen()),
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
        redirect: (context, state) {
          final role = auth.user?.role ?? Role.reader;
          return canManageReaders(role) ? null : '/forbidden';
        },
        builder: (context, state) => const ReadersListScreen(),
        routes: [
          GoRoute(path: 'new', builder: (context, state) => const ReaderFormScreen()),
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
}
import 'package:go_router/go_router.dart';
import '../../features/auth/ui/splash_screen.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/books/ui/book_list_screen.dart';
import '../../features/books/ui/add_book_screen.dart';

import '../../features/books/ui/book_detail_screen.dart';
import '../../features/books/models/book_model.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/books',
      builder: (context, state) => const BookListScreen(),
    ),
    GoRoute(
      path: '/add-book',
      builder: (context, state) {
        final bookToEdit = state.extra as BookModel?;
        return AddBookScreen(bookToEdit: bookToEdit);
      },
    ),
    GoRoute(
      path: '/book-detail',
      builder: (context, state) {
        final book = state.extra as BookModel;
        return BookDetailScreen(book: book);
      },
    ),
  ],
);

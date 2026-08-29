import 'package:go_router/go_router.dart';
import '../../features/auth/ui/splash_screen.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/home/ui/partner_home_screen.dart';
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
      path: '/partner-home',
      builder: (context, state) => const PartnerHomeScreen(),
    ),
    GoRoute(
      path: '/partner-books',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return BookListScreen(
          partnerId: extra?['partnerId'] as String?,
          partnerName: extra?['partnerName'] as String?,
          isReadOnly: true,
        );
      },
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
        if (state.extra is Map<String, dynamic>) {
          final extra = state.extra as Map<String, dynamic>;
          final book = extra['book'] as BookModel;
          final isReadOnly = (extra['isReadOnly'] as bool?) ?? false;
          return BookDetailScreen(book: book, isReadOnly: isReadOnly);
        } else {
          final book = state.extra as BookModel;
          return BookDetailScreen(book: book);
        }
      },
    ),
  ],
);

import 'package:go_router/go_router.dart';
import '../../features/auth/ui/splash_screen.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/home/ui/partner_home_screen.dart';
import '../../features/profile/ui/edit_account_screen.dart';
import '../../features/books/ui/book_list_screen.dart';
import '../../features/books/ui/add_book_screen.dart';
import '../../features/books/ui/book_detail_screen.dart';
import '../../features/books/models/book_model.dart';
import '../../features/notes/ui/note_list_screen.dart';
import '../../features/notes/ui/add_note_screen.dart';
import '../../features/notes/ui/note_detail_screen.dart';
import '../../features/notes/models/note_model.dart';
import '../../features/reminders/ui/reminder_list_screen.dart';
import '../../features/reminders/ui/add_reminder_screen.dart';
import '../../features/reminders/models/reminder_model.dart';
import '../../features/recipes/ui/recipe_list_screen.dart';
import '../../features/recipes/ui/add_recipe_screen.dart';
import '../../features/recipes/ui/recipe_detail_screen.dart';
import '../../features/recipes/models/recipe_model.dart';
import '../../features/history/ui/history_screen.dart';
import '../../features/vacations/ui/vacation_list_screen.dart';
import '../../features/vacations/ui/add_vacation_screen.dart';
import '../../features/vacations/ui/vacation_detail_screen.dart';
import '../../features/vacations/ui/add_vacation_activity_screen.dart';
import '../../features/vacations/models/vacation_model.dart';
import '../../features/vacations/models/vacation_activity_model.dart';

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
      path: '/profile',
      builder: (context, state) => const HomeScreen(initialIndex: 1),
    ),
    GoRoute(
      path: '/edit-account',
      builder: (context, state) => const EditAccountScreen(),
    ),

    // --- BOOKS MODULE ---
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

    // --- NOTES MODULE ---
    GoRoute(
      path: '/notes',
      builder: (context, state) => const NoteListScreen(),
    ),
    GoRoute(
      path: '/partner-notes',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return NoteListScreen(
          partnerId: extra?['partnerId'] as String?,
          partnerName: extra?['partnerName'] as String?,
          isReadOnly: true,
        );
      },
    ),
    GoRoute(
      path: '/add-note',
      builder: (context, state) {
        final noteToEdit = state.extra as NoteModel?;
        return AddNoteScreen(noteToEdit: noteToEdit);
      },
    ),
    GoRoute(
      path: '/note-detail',
      builder: (context, state) {
        if (state.extra is Map<String, dynamic>) {
          final extra = state.extra as Map<String, dynamic>;
          final note = extra['note'] as NoteModel;
          final isReadOnly = (extra['isReadOnly'] as bool?) ?? false;
          return NoteDetailScreen(note: note, isReadOnly: isReadOnly);
        } else {
          final note = state.extra as NoteModel;
          return NoteDetailScreen(note: note);
        }
      },
    ),

    // --- REMINDERS MODULE ---
    GoRoute(
      path: '/reminders',
      builder: (context, state) => const ReminderListScreen(),
    ),
    GoRoute(
      path: '/partner-reminders',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ReminderListScreen(
          partnerId: extra?['partnerId'] as String?,
          partnerName: extra?['partnerName'] as String?,
          isReadOnly: true,
        );
      },
    ),
    GoRoute(
      path: '/add-reminder',
      builder: (context, state) {
        final reminderToEdit = state.extra as ReminderModel?;
        return AddReminderScreen(reminderToEdit: reminderToEdit);
      },
    ),

    // --- RECIPES MODULE ---
    GoRoute(
      path: '/recipes',
      builder: (context, state) => const RecipeListScreen(),
    ),
    GoRoute(
      path: '/partner-recipes',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return RecipeListScreen(
          partnerId: extra?['partnerId'] as String?,
          partnerName: extra?['partnerName'] as String?,
          isReadOnly: true,
        );
      },
    ),
    GoRoute(
      path: '/add-recipe',
      builder: (context, state) {
        final recipeToEdit = state.extra as RecipeModel?;
        return AddRecipeScreen(recipeToEdit: recipeToEdit);
      },
    ),
    GoRoute(
      path: '/recipe-detail',
      builder: (context, state) {
        if (state.extra is Map<String, dynamic>) {
          final extra = state.extra as Map<String, dynamic>;
          final recipe = extra['recipe'] as RecipeModel;
          final isReadOnly = (extra['isReadOnly'] as bool?) ?? false;
          return RecipeDetailScreen(recipe: recipe, isReadOnly: isReadOnly);
        } else {
          final recipe = state.extra as RecipeModel;
          return RecipeDetailScreen(recipe: recipe);
        }
      },
    ),

    // --- HISTORY / RIWAYAT MODULE ---
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),

    // --- VACATIONS / LIBURAN MODULE ---
    GoRoute(
      path: '/vacations',
      builder: (context, state) => const VacationListScreen(),
    ),
    GoRoute(
      path: '/partner-vacations',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return VacationListScreen(
          targetUserId: extra?['targetUserId'] as String?,
          isReadOnly: true,
        );
      },
    ),
    GoRoute(
      path: '/add-vacation',
      builder: (context, state) {
        final vacationToEdit = state.extra as VacationModel?;
        return AddVacationScreen(initialVacation: vacationToEdit);
      },
    ),
    GoRoute(
      path: '/vacation-detail',
      builder: (context, state) {
        if (state.extra is Map<String, dynamic>) {
          final extra = state.extra as Map<String, dynamic>;
          final vacationId = extra['vacationId'] as String;
          final isReadOnly = (extra['isReadOnly'] as bool?) ?? false;
          return VacationDetailScreen(
            vacationId: vacationId,
            isReadOnly: isReadOnly,
          );
        } else {
          final vacationId = state.extra as String;
          return VacationDetailScreen(vacationId: vacationId);
        }
      },
    ),
    GoRoute(
      path: '/add-vacation-activity',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final vacationId = extra['vacationId'] as String;
        final initialActivity =
            extra['initialActivity'] as VacationActivityModel?;
        final defaultDate = extra['defaultDate'] as DateTime?;
        final vacationTitle = extra['vacationTitle'] as String?;
        return AddVacationActivityScreen(
          vacationId: vacationId,
          initialActivity: initialActivity,
          defaultDate: defaultDate,
          vacationTitle: vacationTitle,
        );
      },
    ),
  ],
);

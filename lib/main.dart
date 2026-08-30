import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/network/supabase_client.dart';
import 'core/services/notification_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/books/providers/book_provider.dart';
import 'features/notes/providers/note_provider.dart';
import 'features/reminders/providers/reminder_provider.dart';
import 'features/recipes/providers/recipe_provider.dart';
import 'features/history/providers/history_provider.dart';
import 'features/vacations/providers/vacation_provider.dart';

import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await SupabaseNetwork.initialize();

  // Initialize Local Notifications
  await NotificationService.initialize();

  runApp(const KitaStoryApp());
}

class KitaStoryApp extends StatelessWidget {
  const KitaStoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => VacationProvider()),
      ],
      child: MaterialApp.router(
        title: 'DayTale',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}

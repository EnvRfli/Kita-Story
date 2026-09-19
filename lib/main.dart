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
import 'features/finances/providers/finance_provider.dart';
import 'features/credentials/providers/credential_security_provider.dart';
import 'features/credentials/providers/credential_provider.dart';
import 'features/games/ludo/models/ludo_game_state.dart';
import 'features/games/ludo/providers/ludo_game_provider.dart';
import 'features/games/ludo/providers/ludo_invite_provider.dart';
import 'features/games/ludo/ui/ludo_game_screen.dart';
import 'features/games/ludo/widgets/ludo_invite_banner.dart';

import 'core/router/app_router.dart';
import 'core/services/finance_widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await SupabaseNetwork.initialize();

  // Initialize Local Notifications
  await NotificationService.initialize();

  // Initialize Android Home Screen Widget Service & Listen for Quick Actions
  FinanceWidgetService.initialize();
  FinanceWidgetService.onWidgetAction.listen((action) {
    if (action.isEmpty) return;
    final location =
        appRouter.routerDelegate.currentConfiguration.uri.toString();
    if (location == '/') {
      // Still on splash screen! SplashScreen._checkAuth() will handle navigation after auth.
      return;
    }
    if (location.startsWith('/finance')) {
      // Already on finance screen; FinanceScreen's internal listener handles the modal directly
      return;
    }
    if (action == 'open') {
      appRouter.push('/finance');
    } else {
      appRouter.push('/finance?action=$action');
    }
  });

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
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => CredentialSecurityProvider()),
        ChangeNotifierProvider(create: (_) => CredentialProvider()),
        ChangeNotifierProvider(create: (_) => LudoGameProvider()),
        ChangeNotifierProvider(create: (_) => LudoInviteProvider()),
      ],
      child: MaterialApp.router(
        title: 'DayTale',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        builder: (context, child) {
          return _GlobalLudoInviteOverlay(child: child ?? const SizedBox());
        },
      ),
    );
  }
}

class _GlobalLudoInviteOverlay extends StatefulWidget {
  final Widget child;
  const _GlobalLudoInviteOverlay({required this.child});

  @override
  State<_GlobalLudoInviteOverlay> createState() =>
      _GlobalLudoInviteOverlayState();
}

class _GlobalLudoInviteOverlayState extends State<_GlobalLudoInviteOverlay> {
  String? _lastInitializedUser;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUserProfile;
    final partner = auth.partnerProfile;
    final inviteProvider = context.watch<LudoInviteProvider>();

    if (user != null && user.id != _lastInitializedUser) {
      _lastInitializedUser = user.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        inviteProvider.initialize(
          currentUserId: user.id,
          partnerId: partner?.id,
          partnerName: partner?.name,
        );
      });
    }

    final invite = inviteProvider.pendingInvite;

    return Stack(
      children: [
        widget.child,
        if (invite != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: LudoInviteBanner(
                partnerName: inviteProvider.partnerName ?? 'Pasangan',
                onAccept: () async {
                  final acceptedMatch = await inviteProvider.acceptInvite();
                  if (acceptedMatch != null && context.mounted) {
                    final gameProvider = context.read<LudoGameProvider>();
                    final initialGameState = LudoGameState.fromJson(
                      acceptedMatch.gameState,
                    );
                    await gameProvider.startOnlineGame(
                      matchId: acceptedMatch.id,
                      currentUserId: user?.id ?? '',
                      partnerId: partner?.id,
                      myColor: acceptedMatch.guestColor,
                      initialState: initialGameState,
                    );
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LudoGameScreen(),
                        ),
                      );
                    }
                  }
                },
                onReject: () => inviteProvider.rejectInvite(),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kita_story/features/games/sudoku/engine/sudoku_engine.dart';
import 'package:kita_story/features/games/sudoku/providers/sudoku_provider.dart';
import 'package:kita_story/features/games/sudoku/ui/sudoku_game_screen.dart';
import 'package:kita_story/features/games/sudoku/widgets/game_won_overlay.dart';
import 'package:kita_story/features/games/sudoku/widgets/sudoku_history_bottom_sheet.dart';
import 'package:kita_story/features/games/sudoku/widgets/sudoku_mode_bottom_sheet.dart';
import 'package:provider/provider.dart';

void main() {
  test('revealing a hint spends it before the answer is applied', () {
    final provider = SudokuProvider()..startGame('sangat_mudah');
    addTearDown(provider.dispose);

    final hint = provider.getHint();

    expect(hint, isNotNull);
    expect(provider.hintsLeft, 2);

    provider.applyHint(hint!);
    expect(provider.hintsLeft, 2);
  });

  test('testing difficulty leaves at most six cells empty', () {
    final grid = SudokuEngine().generatePuzzle('sangat_mudah');
    final emptyCells =
        grid.expand((row) => row).where((cell) => cell.value == 0).length;

    expect(emptyCells, inInclusiveRange(4, 6));
  });

  test('testing difficulty cannot award points', () {
    final provider = SudokuProvider()..startGame('sangat_mudah');
    addTearDown(provider.dispose);

    expect(provider.pointsForDifficulty, 0);
  });

  test('each playable difficulty awards the configured points', () {
    final provider = SudokuProvider();
    addTearDown(provider.dispose);

    const expectedPoints = {
      'mudah': 10,
      'normal': 25,
      'susah': 50,
      'sangat_susah': 100,
    };

    for (final entry in expectedPoints.entries) {
      provider.startGame(entry.key);
      expect(provider.pointsForDifficulty, entry.value,
          reason: 'Poin ${entry.key} tidak sesuai');
    }
  });

  testWidgets('mode selector shows the reward for every difficulty',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SudokuModeBottomSheet())),
    );

    expect(find.text('0 poin'), findsOneWidget);
    expect(find.text('10 poin'), findsOneWidget);
    expect(find.text('25 poin'), findsOneWidget);
    expect(find.text('50 poin'), findsOneWidget);
    expect(find.text('100 poin'), findsOneWidget);
  });

  testWidgets('app bar back asks for confirmation during an active game',
      (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SizedBox()),
        GoRoute(
          path: '/game',
          builder: (_, __) => ChangeNotifierProvider(
            create: (_) => SudokuProvider()..startGame('sangat_mudah'),
            child: const SudokuGameScreen(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/game');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Keluar dari permainan?'), findsOneWidget);
    expect(find.text('Lanjut Bermain'), findsOneWidget);
    expect(find.text('Keluar Permainan'), findsOneWidget);
  });

  testWidgets('system back asks for confirmation during an active game',
      (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SizedBox()),
        GoRoute(
          path: '/game',
          builder: (_, __) => ChangeNotifierProvider(
            create: (_) => SudokuProvider()..startGame('sangat_mudah'),
            child: const SudokuGameScreen(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/game');
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Keluar dari permainan?'), findsOneWidget);
  });

  testWidgets('leaderboard ranks each person by their fastest completion',
      (tester) async {
    final now = DateTime(2026, 9, 16);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SudokuHistoryBottomSheet(
            difficulty: 'Mudah',
            currentUserId: 'me',
            entries: [
              SudokuHistoryEntry(
                userId: 'me',
                userName: 'Saya',
                durationSeconds: 240,
                completedAt: now,
              ),
              SudokuHistoryEntry(
                userId: 'partner',
                userName: 'Pasangan',
                durationSeconds: 201,
                completedAt: now.subtract(const Duration(days: 1)),
              ),
              SudokuHistoryEntry(
                userId: 'me',
                userName: 'Saya',
                durationSeconds: 180,
                completedAt: now.subtract(const Duration(days: 2)),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('#1'), findsOneWidget);
    expect(find.text('Saya (Kamu)'), findsNWidgets(3));
    expect(find.text('3 menit'), findsNWidgets(2));
    expect(find.text('3 menit 21 detik'), findsNWidgets(2));
  });

  testWidgets('winning overlay presents a playful result summary',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              GameWonOverlay(points: 125, onHome: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Sudoku Selesai!'), findsOneWidget);
    expect(find.text('Statistik Permainan'), findsOneWidget);
    expect(find.text('Kembali ke Beranda'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

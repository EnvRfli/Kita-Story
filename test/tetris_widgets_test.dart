import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/tetris/engine/tetris_engine.dart';
import 'package:kita_story/features/games/tetris/models/tetris_game_state.dart';
import 'package:kita_story/features/games/tetris/models/tetris_snapshot.dart';
import 'package:kita_story/features/games/tetris/models/tetromino.dart';
import 'package:kita_story/features/games/tetris/providers/tetris_provider.dart';
import 'package:kita_story/features/games/tetris/repositories/tetris_repository.dart';
import 'package:kita_story/features/games/tetris/services/tetris_local_storage.dart';
import 'package:kita_story/features/games/tetris/ui/tetris_game_screen.dart';
import 'package:kita_story/features/games/tetris/ui/tetris_start_screen.dart';
import 'package:kita_story/features/games/tetris/widgets/tetris_board.dart';
import 'package:kita_story/features/games/tetris/widgets/tetris_controls.dart';
import 'package:kita_story/features/games/tetris/widgets/tetris_gamification_sheet.dart';
import 'package:kita_story/features/games/tetris/widgets/tetris_history_bottom_sheet.dart';
import 'package:kita_story/features/games/tetris/widgets/tetris_next_preview.dart';
import 'package:kita_story/features/games/tetris/widgets/tetris_result_overlay.dart';
import 'package:kita_story/features/games/ui/games_screen.dart';
import 'package:provider/provider.dart';

class WidgetMemoryStorage extends TetrisLocalStorage {
  TetrisSnapshot? activeSnapshot;
  int bestScore = 0;

  @override
  Future<TetrisSnapshot?> load() async => activeSnapshot;

  @override
  Future<void> save(TetrisSnapshot snapshot) async {
    activeSnapshot = snapshot;
  }

  @override
  Future<void> clear() async => activeSnapshot = null;

  @override
  Future<int> loadBestScore() async => bestScore;

  @override
  Future<void> saveBestScore(int score) async {
    if (score > bestScore) bestScore = score;
  }
}

class WidgetRepository extends TetrisRepository {
  WidgetRepository({
    this.leaderboard = const [],
    this.claimed = const {},
    this.failSave = false,
  });

  final List<TetrisLeaderboardEntry> leaderboard;
  final Set<int> claimed;
  final bool failSave;
  int saveCount = 0;

  @override
  Future<List<TetrisLeaderboardEntry>> fetchLeaderboard() async => leaderboard;

  @override
  Future<Set<int>> fetchClaimedMilestones(String userId) async => claimed;

  @override
  Future<Set<int>> claimMilestones(Set<int> candidates) async => const {};

  @override
  Future<TetrisResult> saveResult({
    required String runId,
    required int score,
    required int linesCleared,
    required int levelReached,
    required int piecesPlaced,
    required int durationSeconds,
  }) async {
    saveCount++;
    if (failSave) throw StateError('offline');
    return TetrisResult(
      id: runId,
      userId: 'me',
      partnerId: null,
      score: score,
      linesCleared: linesCleared,
      levelReached: levelReached,
      piecesPlaced: piecesPlaced,
      durationSeconds: durationSeconds,
      completedAt: DateTime.utc(2026, 11, 19),
    );
  }
}

TetrisEngine deterministicEngine() => TetrisEngine(
      bagGenerator: () => const [
        TetrominoType.o,
        TetrominoType.i,
        TetrominoType.t,
        TetrominoType.s,
        TetrominoType.z,
        TetrominoType.j,
        TetrominoType.l,
      ],
    );

TetrisProvider buildProvider({
  WidgetMemoryStorage? storage,
  WidgetRepository? repository,
  TetrisEngine? engine,
}) =>
    TetrisProvider(
      engine: engine ?? deterministicEngine(),
      storage: storage ?? WidgetMemoryStorage(),
      repository: repository ?? WidgetRepository(),
      autoGravity: false,
    );

TetrisSnapshot activeSnapshot() {
  final board = TetrisGameState.emptyBoard();
  board[19][0] = TetrominoType.t.index;
  return TetrisSnapshot(
    schemaVersion: TetrisSnapshot.currentSchemaVersion,
    board: board,
    activePiece: const TetrisPiece(
      type: TetrominoType.o,
      rotation: 0,
      row: 0,
      col: 4,
    ),
    nextQueue: const [
      TetrominoType.i,
      TetrominoType.t,
      TetrominoType.s,
      TetrominoType.z,
      TetrominoType.j,
      TetrominoType.l,
    ],
    score: 1200,
    bestScore: 2400,
    lines: 12,
    level: 2,
    piecesPlaced: 42,
    elapsedSeconds: 90,
    clearingRows: const [],
    pendingMilestones: const [],
    startedAt: DateTime.utc(2026, 11, 19),
  );
}

TetrisSnapshot pendingSnapshot() => TetrisSnapshot(
      schemaVersion: TetrisSnapshot.currentSchemaVersion,
      board: TetrisGameState.emptyBoard(),
      activePiece: null,
      nextQueue: const [
        TetrominoType.i,
        TetrominoType.t,
        TetrominoType.s,
        TetrominoType.z,
        TetrominoType.j,
        TetrominoType.l,
      ],
      score: 3200,
      bestScore: 3200,
      lines: 28,
      level: 3,
      piecesPlaced: 80,
      elapsedSeconds: 300,
      clearingRows: const [],
      pendingMilestones: const [],
      startedAt: DateTime.utc(2026, 11, 19),
      pendingFinalization: const TetrisPendingFinalization(
        runId: '11111111-1111-4111-8111-111111111111',
        score: 3200,
        lines: 28,
        level: 3,
        piecesPlaced: 80,
        durationSeconds: 300,
        resultConfirmed: false,
      ),
    );

Widget gameHarness(TetrisProvider provider) => MaterialApp(
      home: ChangeNotifierProvider<TetrisProvider>.value(
        value: provider,
        child: const TetrisGameScreen(),
      ),
    );

Widget startHarness({
  required WidgetMemoryStorage storage,
  required WidgetRepository repository,
}) =>
    MaterialApp(
      home: TetrisStartScreen(
        storage: storage,
        repository: repository,
        currentUserId: 'me',
      ),
    );

void main() {
  testWidgets('Tetris card opens the playable start screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GamesScreen()));

    await tester.tap(find.text('Tetris'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TetrisStartScreen), findsOneWidget);
    expect(find.text('Sedang Dikembangkan'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.ensureVisible(find.text('Minesweeper'));
    await tester.tap(find.text('Minesweeper'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sedang Dikembangkan'), findsOneWidget);
  });

  testWidgets('board renders every cell and its active piece', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: TetrisBoard(
                board: TetrisGameState.emptyBoard(),
                activePiece: const TetrisPiece(
                  type: TetrominoType.t,
                  rotation: 0,
                  row: 2,
                  col: 3,
                ),
                ghostRow: 16,
                clearingRows: const [],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(TetrisBoard), findsOneWidget);
    expect(find.byKey(const ValueKey('tetris-cell-0-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('tetris-cell-19-9')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('next preview renders the queued tetrominoes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TetrisNextPreview(
            queue: [
              TetrominoType.i,
              TetrominoType.o,
              TetrominoType.t,
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('tetris-next-preview')), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('controls dispatch every action', (tester) async {
    var left = 0;
    var right = 0;
    var rotate = 0;
    var soft = 0;
    var hard = 0;
    var pause = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: TetrisControls(
              onLeft: () => left++,
              onRight: () => right++,
              onRotate: () => rotate++,
              onSoftDrop: () => soft++,
              onHardDrop: () => hard++,
              onPause: () => pause++,
            ),
          ),
        ),
      ),
    );

    for (final key in [
      'tetris-control-left',
      'tetris-control-right',
      'tetris-control-rotate',
      'tetris-control-soft-drop',
      'tetris-control-hard-drop',
      'tetris-control-pause',
    ]) {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pump();
    }

    expect(left, 1);
    expect(right, 1);
    expect(rotate, 1);
    expect(soft, 1);
    expect(hard, 1);
    expect(pause, 1);
  });

  testWidgets('active game shows HUD and protects the back action',
      (tester) async {
    final provider = buildProvider();
    addTearDown(provider.dispose);
    await provider.newGame();

    await tester.pumpWidget(gameHarness(provider));
    await tester.pumpAndSettle();

    expect(find.text('Tetris'), findsOneWidget);
    expect(find.text('SKOR'), findsOneWidget);
    expect(find.text('Garis'), findsWidgets);
    expect(find.text('Level'), findsWidgets);
    expect(find.byType(TetrisBoard), findsOneWidget);
    expect(find.byType(TetrisControls), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tetris-back-button')));
    await tester.pumpAndSettle();

    expect(find.text('Keluar dari permainan?'), findsOneWidget);
    expect(find.text('Lanjut Bermain'), findsOneWidget);
    expect(find.text('Simpan & Keluar'), findsOneWidget);
    expect(find.text('Akhiri Permainan'), findsOneWidget);
    expect(provider.status, TetrisStatus.paused);

    await tester.tap(find.text('Lanjut Bermain'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari permainan?'), findsNothing);
    expect(provider.status, TetrisStatus.playing);
  });

  testWidgets('board gestures move, rotate, and soft drop the active piece',
      (tester) async {
    final provider = buildProvider();
    addTearDown(provider.dispose);
    await provider.newGame();
    final startCol = provider.activePiece!.col;

    await tester.pumpWidget(gameHarness(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TetrisBoard));
    await tester.pump();
    expect(provider.activePiece?.rotation, 1);

    await tester.drag(find.byType(TetrisBoard), const Offset(90, 0));
    await tester.pump();
    expect(provider.activePiece?.col, greaterThan(startCol));

    final rowBefore = provider.activePiece!.row;
    await tester.drag(find.byType(TetrisBoard), const Offset(0, 60));
    await tester.pump();
    expect(provider.activePiece?.row, greaterThan(rowBefore));
  });

  testWidgets('pause overlay resumes the game', (tester) async {
    final provider = buildProvider();
    addTearDown(provider.dispose);
    await provider.newGame();
    provider.pause();

    await tester.pumpWidget(gameHarness(provider));
    await tester.pumpAndSettle();

    expect(find.text('Jeda Sebentar'), findsOneWidget);
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(provider.status, TetrisStatus.playing);
    expect(find.text('Jeda Sebentar'), findsNothing);
  });

  testWidgets('game over overlay shows the final run and can be replayed',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              TetrisGameOverOverlay(
                score: 12300,
                lines: 42,
                level: 5,
                isNewRecord: true,
                pointsEarned: 5,
                onPlayAgain: () {},
                onBack: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Rekor Baru!'), findsOneWidget);
    expect(find.text('Statistik Permainan'), findsOneWidget);
    expect(find.text('12.300'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Main Lagi'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.byKey(const ValueKey('tetris-confetti')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('start screen shows one Mulai action without a snapshot',
      (tester) async {
    await tester.pumpWidget(
      startHarness(
        storage: WidgetMemoryStorage(),
        repository: WidgetRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mulai'), findsOneWidget);
    expect(find.text('Lanjutkan'), findsNothing);
    expect(find.text('Hingga +50 poin'), findsOneWidget);
  });

  testWidgets('start screen offers resume and replacement with a snapshot',
      (tester) async {
    await tester.pumpWidget(
      startHarness(
        storage: WidgetMemoryStorage()..activeSnapshot = activeSnapshot(),
        repository: WidgetRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lanjutkan'), findsOneWidget);
    expect(find.text('Mulai Baru'), findsOneWidget);
    expect(find.text('Rekor Terbaik'), findsOneWidget);

    await tester.tap(find.text('Mulai Baru'));
    await tester.pumpAndSettle();
    expect(find.text('Mulai permainan baru?'), findsOneWidget);
    expect(find.text('Simpanannya akan diganti.'), findsOneWidget);
  });

  testWidgets('pending finalization blocks a new run with a retry action',
      (tester) async {
    await tester.pumpWidget(
      startHarness(
        storage: WidgetMemoryStorage()..activeSnapshot = pendingSnapshot(),
        repository: WidgetRepository(failSave: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hasil permainan belum tersimpan'), findsOneWidget);
    expect(find.text('Coba Simpan Lagi'), findsOneWidget);
    expect(find.text('Mulai'), findsNothing);
    expect(find.text('Lanjutkan'), findsNothing);
  });

  testWidgets('starting a fresh run works from the start screen',
      (tester) async {
    await tester.pumpWidget(
      startHarness(
        storage: WidgetMemoryStorage(),
        repository: WidgetRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tetris-start')));
    await tester.pumpAndSettle();

    expect(find.byType(TetrisGameScreen), findsOneWidget);
    expect(find.text('Tetris'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('tetris-back-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akhiri Permainan'));
    await tester.pumpAndSettle();

    expect(find.byType(TetrisStartScreen), findsOneWidget);
  });

  testWidgets('gamification sheet shows claimed achievement progress',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TetrisGamificationBottomSheet(
            claimedMilestones: {10, 25},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Poin Tetris'), findsOneWidget);
    expect(find.text('Achievement sekali per akun'), findsOneWidget);
    expect(find.text('5 / 50 Poin'), findsOneWidget);
    expect(find.text('2 dari 6 achievement berhasil dicapai'), findsOneWidget);
    expect(find.text('Diklaim'), findsNWidgets(2));
    expect(find.text('Belum'), findsNWidgets(4));
  });

  testWidgets('history sheet labels the current user and ranks best runs',
      (tester) async {
    final now = DateTime.utc(2026, 11, 19);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TetrisHistoryBottomSheet(
            currentUserId: 'me',
            entries: [
              TetrisLeaderboardEntry(
                userId: 'me',
                userName: 'Alya',
                score: 1200,
                linesCleared: 12,
                levelReached: 2,
                piecesPlaced: 42,
                durationSeconds: 90,
                completedAt: now,
              ),
              TetrisLeaderboardEntry(
                userId: 'partner',
                userName: 'Bima',
                score: 2400,
                linesCleared: 20,
                levelReached: 3,
                piecesPlaced: 70,
                durationSeconds: 120,
                completedAt: now.subtract(const Duration(days: 1)),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Papan Skor Tetris'), findsOneWidget);
    expect(find.text('Alya (Kamu)'), findsWidgets);
    expect(find.text('Bima'), findsWidgets);
    expect(find.text('2.400'), findsWidgets);
  });

  testWidgets('game screen has no overflow at 343 by 775', (tester) async {
    final provider = buildProvider();
    addTearDown(provider.dispose);
    await provider.newGame();

    await tester.binding.setSurfaceSize(const Size(343, 775));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(gameHarness(provider));
    await tester.pumpAndSettle();

    expect(find.byType(TetrisBoard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

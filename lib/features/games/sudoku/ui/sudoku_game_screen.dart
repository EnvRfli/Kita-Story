import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kita_story/features/games/sudoku/providers/sudoku_provider.dart';
import 'package:kita_story/features/games/sudoku/widgets/sudoku_grid.dart';
import 'package:kita_story/features/games/sudoku/widgets/sudoku_numpad.dart';
import 'package:kita_story/features/games/sudoku/widgets/game_won_overlay.dart';

class SudokuGameScreen extends StatelessWidget {
  const SudokuGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Consumer<SudokuProvider>(
          builder: (context, provider, _) {
            // Handle Game Won / Lost side effects visually if needed
            // Normally you'd use a listener in initState or didChangeDependencies,
            // but for simplicity we can show dialogs here or just update UI.

            return PopScope(
              canPop: provider.gameState != SudokuGameState.playing,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) {
                  _requestExit(context, provider);
                }
              },
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(context, provider),
                      _buildInfoBar(provider),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Sudoku Grid
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Center(
                                  child: SudokuGrid(
                                    grid: provider.grid,
                                    selectedCell: provider.selectedCell,
                                    currentHint: provider.currentHint,
                                    onCellTap: provider.selectCell,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // NumPad
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: SudokuNumPad(
                                  onNumberSelected: provider.inputNumber,
                                  onErase: provider.eraseSelected,
                                  onHint: () => _handleHint(context, provider),
                                  hintsLeft: provider.hintsLeft,
                                  isNumberCompleted: provider.isNumberCompleted,
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Show overlays if game ended
                  if (provider.gameState == SudokuGameState.won)
                    GameWonOverlay(
                      points: provider.pointsForDifficulty,
                      elapsedSeconds: provider.elapsedSeconds,
                      difficulty: provider.difficulty,
                      isTestingMode: provider.isTestingDifficulty,
                      onHome: () => context.pop(),
                    ),
                  if (provider.gameState == SudokuGameState.lost)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildGameResult(context, false, 0),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SudokuProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF1E293B), size: 22),
            onPressed: () => _requestExit(context, provider),
          ),
          const Expanded(
            child: Text(
              'Sudoku',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance symmetry
        ],
      ),
    );
  }

  Future<void> _requestExit(
    BuildContext context,
    SudokuProvider provider,
  ) async {
    if (provider.gameState != SudokuGameState.playing) {
      context.pop();
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        icon: Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF3E8),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.sports_esports_rounded,
            color: Color(0xFFFF7A00),
            size: 30,
          ),
        ),
        title: const Text(
          'Keluar dari permainan?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Progres permainan ini akan hilang jika kamu keluar sekarang.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), height: 1.45),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Lanjut Bermain'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Keluar Permainan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      context.pop();
    }
  }

  Widget _buildInfoBar(SudokuProvider provider) {
    String timeStr =
        '${(provider.elapsedSeconds ~/ 60)}:${(provider.elapsedSeconds % 60).toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Difficulty
          Row(
            children: [
              const Icon(Icons.wb_sunny_rounded,
                  color: Color(0xFFFFB020), size: 20),
              const SizedBox(width: 8),
              Text(
                provider.difficulty.substring(0, 1).toUpperCase() +
                    provider.difficulty.substring(1),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              timeStr,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF0088FF),
              ),
            ),
          ),
          // Lives
          Row(
            children: List.generate(3, (index) {
              bool isLost = index < provider.mistakes;
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.favorite_rounded,
                  color: isLost
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFFF4D4F),
                  size: 20,
                ),
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildGameResult(BuildContext context, bool isWon, int points) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
          ]),
      child: Column(
        children: [
          Text(
            isWon ? 'Selamat!' : 'Game Over',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isWon ? const Color(0xFF0088FF) : const Color(0xFFFF4D4F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isWon ? 'Kamu memenangkan +$points Poin!' : 'Kamu kehabisan nyawa.',
            style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0088FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Kembali',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  void _handleHint(BuildContext context, SudokuProvider provider) {
    if (provider.hintsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hint sudah habis!')),
      );
      return;
    }

    final hint = provider.getHint();
    if (hint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak ada deduksi dasar yang ditemukan saat ini.')),
      );
      return;
    }

    // Show Bottom Sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: Color(0xFF0088FF)),
                  const SizedBox(width: 8),
                  Text(
                    hint.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                hint.reason,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    provider.applyHint(hint);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0088FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Terapkan Angka',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      // Clear hint state when dialog is closed (either by tapping outside, dragging down, or applying)
      provider.clearHint();
    });
  }
}

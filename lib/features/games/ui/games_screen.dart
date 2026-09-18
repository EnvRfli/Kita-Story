import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kita_story/features/games/2048/ui/game_2048_start_screen.dart';
import 'package:kita_story/features/games/sudoku/ui/sudoku_start_screen.dart';

class _GameItem {
  final String title;
  final String assetPath;
  final List<Color> gradientColors;
  final String description;

  const _GameItem({
    required this.title,
    required this.assetPath,
    required this.gradientColors,
    required this.description,
  });
}

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  static const List<_GameItem> _games = [
    _GameItem(
      title: 'Sudoku',
      assetPath: 'lib/assets/game screen/image 83.png',
      gradientColors: [Color(0xFFFF9DD3), Color(0xFFFF7F90)],
      description:
          'Asah otak dan logika dengan mengisi angka 1-9 pada grid 9x9 tanpa duplikasi!',
    ),
    _GameItem(
      title: 'Nonogram',
      assetPath: 'lib/assets/game screen/Frame 1984078794.png',
      gradientColors: [Color(0xFFFDB470), Color(0xFFFD7070)],
      description:
          'Pecahkan teka-teki gambar tersembunyi dengan mengikuti petunjuk angka baris dan kolom!',
    ),
    _GameItem(
      title: '2048',
      assetPath: 'lib/assets/game screen/Frame 1984078794 (1).png',
      gradientColors: [Color(0xFFD5B8FA), Color(0xFFA07BFE)],
      description:
          'Geser dan gabungkan ubin dengan angka yang sama hingga mencapai ubin 2048 legendaris!',
    ),
    _GameItem(
      title: 'Minesweeper',
      assetPath: 'lib/assets/game screen/Frame 1984078794 (2).png',
      gradientColors: [Color(0xFFFF8177), Color(0xFFFF5677)],
      description:
          'Buka seluruh petak aman tanpa menginjak ranjau darat dengan membaca petunjuk angka!',
    ),
    _GameItem(
      title: 'Ludo',
      assetPath: 'lib/assets/game screen/image 1.png',
      gradientColors: [Color(0xFF52CF7A), Color(0xFFA3CF52)],
      description:
          'Permainan papan klasik seru untuk dimainkan bersama pasangan hingga garis akhir!',
    ),
    _GameItem(
      title: 'Ular Tangga',
      assetPath: 'lib/assets/game screen/image 1 (1).png',
      gradientColors: [Color(0xFF96E0F3), Color(0xFF6F82FF)],
      description:
          'Lempar dadu, naiki tangga kemenangan, dan hati-hati dengan jebakan ular licin!',
    ),
  ];

  void _showDevelopmentDialog(BuildContext context, _GameItem game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Game Icon Squircle
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFFF1F5F9), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: game.gradientColors.last.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      game.assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.sports_esports_rounded,
                        size: 38,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Game Title
                Text(
                  game.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFEDD5),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.construction_rounded,
                        size: 14,
                        color: Color(0xFFFF8A00),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Sedang Dikembangkan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF8A00),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Game Description
                Text(
                  game.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),

                // Action Button
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: game.gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: game.gradientColors.last.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(ctx).pop(),
                      borderRadius: BorderRadius.circular(14),
                      child: const Center(
                        child: Text(
                          'Mengerti',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Background
          Positioned.fill(
            child: Image.asset(
              'lib/assets/game screen/Game.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFFFC0D3),
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                  child: Row(
                    children: [
                      // Back Button (Rounded translucent square)
                      InkWell(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      // Title: "Game" (Centered)
                      const Expanded(
                        child: Text(
                          'Game',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),

                      // Symmetrical balancing spacer
                      const SizedBox(width: 42),
                    ],
                  ),
                ),

                // Games Scrollable List
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    itemCount: _games.length,
                    itemBuilder: (context, index) {
                      final game = _games[index];
                      return _GameCard(
                        item: game,
                        onTap: () {
                          if (game.title == 'Sudoku') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SudokuStartScreen(),
                              ),
                            );
                          } else if (game.title == '2048') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const Game2048StartScreen(),
                              ),
                            );
                          } else {
                            _showDevelopmentDialog(context, game);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatefulWidget {
  final _GameItem item;
  final VoidCallback onTap;

  const _GameCard({
    required this.item,
    required this.onTap,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          height: 94,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Gradient Pill Container
              Positioned(
                left: 0,
                right: 0,
                top: 12,
                bottom: 0,
                child: Container(
                  height: 82,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: item.gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: item.gradientColors.last.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(left: 118, right: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 32,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.keyboard_double_arrow_right_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Overlapping Icon on Left
              Positioned(
                left: 18,
                top: 0,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white,
                      width: 3.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Image.asset(
                      item.assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white,
                        child: const Icon(
                          Icons.sports_esports_rounded,
                          color: Color(0xFF64748B),
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

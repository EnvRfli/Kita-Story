import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kita_story/core/network/supabase_client.dart';
import 'package:kita_story/features/games/sudoku/providers/sudoku_provider.dart';
import 'package:kita_story/features/games/sudoku/ui/sudoku_game_screen.dart';
import 'package:kita_story/features/games/sudoku/utils/sudoku_formatters.dart';
import 'package:kita_story/features/games/sudoku/widgets/sudoku_history_bottom_sheet.dart';
import 'package:kita_story/features/games/sudoku/widgets/sudoku_mode_bottom_sheet.dart';

class SudokuStartScreen extends StatefulWidget {
  const SudokuStartScreen({super.key});

  @override
  State<SudokuStartScreen> createState() => _SudokuStartScreenState();
}

class _SudokuStartScreenState extends State<SudokuStartScreen> {
  bool _isLoading = true;
  Map<String, int?> _bestTimes = {
    'mudah': null,
    'normal': null,
    'susah': null,
    'sangat susah': null,
  };
  String? _currentUserId;
  Map<String, List<SudokuHistoryEntry>> _historyByDifficulty = {
    'mudah': [],
    'normal': [],
    'susah': [],
    'sangat susah': [],
  };

  @override
  void initState() {
    super.initState();
    _fetchBestTimes();
  }

  Future<void> _fetchBestTimes() async {
    try {
      final client = SupabaseNetwork.client;
      final user = client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final currentProfile = await client
          .from('app_users')
          .select('id, name, photo_url, partner_id')
          .eq('id', user.id)
          .maybeSingle();
      final partnerId = currentProfile?['partner_id'] as String?;
      final userIds = [
        user.id,
        if (partnerId != null && partnerId.isNotEmpty) partnerId,
      ];

      final profileRows = await client
          .from('app_users')
          .select('id, name, photo_url')
          .inFilter('id', userIds);
      final profiles = <String, Map<String, dynamic>>{
        for (final row in profileRows)
          row['id'] as String: Map<String, dynamic>.from(row),
      };

      final response = await client
          .from('game_history')
          .select('user_id, difficulty, duration_seconds, created_at')
          .eq('game_type', 'sudoku')
          .eq('status', 'completed')
          .inFilter('user_id', userIds)
          .order('created_at', ascending: false);

      Map<String, int?> best = {
        'mudah': null,
        'normal': null,
        'susah': null,
        'sangat susah': null,
      };
      final histories = <String, List<SudokuHistoryEntry>>{
        'mudah': [],
        'normal': [],
        'susah': [],
        'sangat susah': [],
      };

      for (var row in response) {
        final diff = (row['difficulty'] as String)
            .trim()
            .toLowerCase()
            .replaceAll('_', ' ');
        int duration = row['duration_seconds'] as int;
        if (best.containsKey(diff)) {
          final rowUserId = row['user_id'] as String;
          final profile = profiles[rowUserId];
          histories[diff]!.add(
            SudokuHistoryEntry(
              userId: rowUserId,
              userName: profile?['name'] as String? ?? 'Pengguna',
              photoUrl: profile?['photo_url'] as String?,
              durationSeconds: duration,
              completedAt: DateTime.parse(row['created_at'] as String),
            ),
          );
          int? currentBest = best[diff];
          if (currentBest == null || duration < currentBest) {
            best[diff] = duration;
          }
        }
      }

      if (mounted) {
        setState(() {
          _bestTimes = best;
          _historyByDifficulty = histories;
          _currentUserId = user.id;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching best times: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(
            top: -28,
            left: -20,
            right: -20,
            height: 420,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: 0.62,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Image.asset(
                        'lib/assets/game screen/image 83.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFFD9EBFF),
                        ),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x1AFFFFFF),
                          Color(0x33FFFFFF),
                          Color(0xB3F8F9FE),
                          Color(0xFFF8F9FE),
                          Color(0xFFF8F9FE),
                        ],
                        stops: [0, 0.25, 0.62, 0.82, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 55, 16, 112),
                    child: Column(
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(23),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.24),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(23),
                            child: Image.asset(
                              'lib/assets/game screen/image 83.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.grid_on_rounded,
                                color: Color(0xFF2563EB),
                                size: 46,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Sudoku',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF334155),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7047F6), Color(0xFF0088FF)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '10–100 poin',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          )
                        else ...[
                          _buildHistoryTile(
                            'mudah',
                            'Mudah',
                            formatSudokuDuration(_bestTimes['mudah']),
                          ),
                          _buildHistoryTile(
                            'normal',
                            'Normal',
                            formatSudokuDuration(_bestTimes['normal']),
                          ),
                          _buildHistoryTile(
                            'susah',
                            'Susah',
                            formatSudokuDuration(_bestTimes['susah']),
                          ),
                          _buildHistoryTile(
                            'sangat susah',
                            'Sangat Susah',
                            formatSudokuDuration(_bestTimes['sangat susah']),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0795FF), Color(0xFF087CE5)],
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0088FF).withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _handleStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'Mulai',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStart() {
    _showModeSelector(context).then((_) {
      if (mounted) {
        setState(() => _isLoading = true);
        _fetchBestTimes();
      }
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF334155),
                size: 22,
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(
    String difficultyKey,
    String difficulty,
    String timeStr,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showHistory(difficultyKey, difficulty),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF475569).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wb_sunny_rounded,
                  color: Color(0xFFFFC928),
                  size: 21,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    difficulty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.alarm_rounded,
                      color: const Color(0xFF0088FF),
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: timeStr == '-'
                            ? const Color(0xFFFFA340)
                            : const Color(0xFFFF7A00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHistory(String difficultyKey, String difficultyLabel) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SudokuHistoryBottomSheet(
        difficulty: difficultyLabel,
        currentUserId: currentUserId,
        entries: _historyByDifficulty[difficultyKey] ?? const [],
      ),
    );
  }

  Future<void> _showModeSelector(BuildContext context) async {
    final selectedMode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const SudokuModeBottomSheet(),
    );

    if (selectedMode != null && context.mounted) {
      // Start the game by navigating and wrapping with provider
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) {
              final provider = SudokuProvider();
              provider.startGame(selectedMode);
              return provider;
            },
            child: const SudokuGameScreen(),
          ),
        ),
      );
    }
  }
}

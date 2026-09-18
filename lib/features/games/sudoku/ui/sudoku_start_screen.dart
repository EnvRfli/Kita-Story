import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kita_story/core/network/supabase_client.dart';
import 'package:kita_story/features/games/sudoku/providers/sudoku_provider.dart';
import 'package:kita_story/features/games/sudoku/ui/sudoku_game_screen.dart';
import 'package:kita_story/features/games/sudoku/widgets/sudoku_mode_bottom_sheet.dart';

class SudokuStartScreen extends StatefulWidget {
  const SudokuStartScreen({super.key});

  @override
  State<SudokuStartScreen> createState() => _SudokuStartScreenState();
}

class _SudokuStartScreenState extends State<SudokuStartScreen> {
  bool _isLoading = true;
  Map<String, int?> _bestTimes = {
    'Mudah': null,
    'Normal': null,
    'Susah': null,
    'Sangat Susah': null,
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

      final response = await client
          .from('game_history')
          .select('difficulty, duration_seconds')
          .eq('game_type', 'sudoku')
          .eq('user_id', user.id)
          .eq('status', 'completed');

      Map<String, int?> best = {
        'Mudah': null,
        'Normal': null,
        'Susah': null,
        'Sangat Susah': null,
      };

      for (var row in response) {
        String diff = row['difficulty'] as String;
        int duration = row['duration_seconds'] as int;
        if (best.containsKey(diff)) {
          int? currentBest = best[diff];
          if (currentBest == null || duration < currentBest) {
            best[diff] = duration;
          }
        }
      }

      if (mounted) {
        setState(() {
          _bestTimes = best;
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

  String _formatDuration(int? seconds) {
    if (seconds == null) return '-';
    if (seconds < 60) return '$seconds detik';
    final minutes = seconds ~/ 60;
    final hrs = minutes ~/ 60;
    final mins = minutes % 60;
    if (hrs > 0) {
      if (mins == 0) return '$hrs jam';
      return '$hrs jam $mins menit';
    }
    return '$minutes menit';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: Stack(
        children: [
          // Background Blur / Gradient Effect
          Positioned(
            top: -50,
            left: -50,
            right: -50,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0088FF).withValues(alpha: 0.15),
                    const Color(0xFFFCFCFD).withValues(alpha: 0.0),
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // Sudoku Icon Placeholder
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0088FF),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0088FF).withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '9',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sudoku',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4454), // Maroon/Purple accent
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '125 poin', // Example points
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          )
                        else ...[
                          _buildHistoryTile('Mudah', _formatDuration(_bestTimes['Mudah'])),
                          _buildHistoryTile('Normal', _formatDuration(_bestTimes['Normal'])),
                          _buildHistoryTile('Susah', _formatDuration(_bestTimes['Susah'])),
                          _buildHistoryTile('Sangat Susah', _formatDuration(_bestTimes['Sangat Susah'])),
                        ],
                        
                        const SizedBox(height: 100), // Space for button
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Start Button at bottom
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                   // Refresh data when returning from game
                   _showModeSelector(context).then((_) {
                      if (mounted) {
                        setState(() => _isLoading = true);
                        _fetchBestTimes();
                      }
                   });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0088FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Mulai',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 22),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(String difficulty, String timeStr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFB020), size: 20),
              const SizedBox(width: 12),
              Text(
                difficulty,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                Icons.alarm_rounded,
                color: timeStr == '-' ? const Color(0xFF94A3B8) : const Color(0xFF0088FF),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: timeStr == '-' ? const Color(0xFF94A3B8) : const Color(0xFFFF8A00),
                ),
              ),
            ],
          )
        ],
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

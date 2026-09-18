import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../engine/game_2048_engine.dart';
import '../models/game_2048_snapshot.dart';
import '../providers/game_2048_provider.dart';
import '../repositories/game_2048_repository.dart';
import '../services/game_2048_local_storage.dart';
import '../utils/game_2048_formatters.dart';
import '../widgets/game_2048_history_bottom_sheet.dart';
import 'game_2048_screen.dart';

class Game2048StartScreen extends StatefulWidget {
  const Game2048StartScreen({
    this.storage,
    this.repository,
    this.currentUserId,
    this.engineFactory = Game2048Engine.new,
    super.key,
  });

  final Game2048LocalStorage? storage;
  final Game2048Repository? repository;
  final String? currentUserId;
  final Game2048Engine Function() engineFactory;

  @override
  State<Game2048StartScreen> createState() => _Game2048StartScreenState();
}

class _Game2048StartScreenState extends State<Game2048StartScreen> {
  late final Game2048LocalStorage _storage;
  late final Game2048Repository _repository;
  Game2048Snapshot? _snapshot;
  List<Game2048LeaderboardEntry> _leaderboard = const [];
  int _localBestScore = 0;
  var _openingGame = false;

  @override
  void initState() {
    super.initState();
    _storage = widget.storage ?? Game2048LocalStorage();
    _repository = widget.repository ?? Game2048Repository();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    await Future.wait([_loadSnapshot(), _loadLeaderboard()]);
  }

  Future<void> _loadSnapshot() async {
    try {
      final snapshot = await _storage.load();
      final best = await _storage.loadBestScore();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _localBestScore = best;
      });
    } catch (_) {}
  }

  Future<void> _loadLeaderboard() async {
    try {
      final leaderboard = await _repository.fetchLeaderboard();
      if (!mounted) return;
      setState(() {
        _leaderboard = leaderboard;
      });
    } catch (_) {}
  }

  Future<void> _startNew() async {
    if (_snapshot?.pendingFinalization != null) return;
    if (_snapshot != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mulai permainan baru?'),
          content: const Text('Simpanannya akan diganti.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0088FF),
              ),
              child: const Text('Mulai Baru'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await _openGame(restore: false);
  }

  Future<void> _retryFinalization() async {
    if (_openingGame || _snapshot?.pendingFinalization == null) return;
    setState(() => _openingGame = true);
    final provider = Game2048Provider(
      engine: widget.engineFactory(),
      storage: _storage,
      repository: _repository,
    );
    await provider.restore();
    provider.dispose();
    if (!mounted) return;
    setState(() => _openingGame = false);
    await _refresh();
  }

  Future<void> _openGame({required bool restore}) async {
    if (_openingGame) return;
    setState(() => _openingGame = true);
    final provider = Game2048Provider(
      engine: widget.engineFactory(),
      storage: _storage,
      repository: _repository,
    );
    final restored = restore ? await provider.restore() : false;
    if (!restore || !restored) await provider.newGame();
    if (!mounted) {
      provider.dispose();
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<Game2048Provider>.value(
          value: provider,
          child: const Game2048Screen(),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _openingGame = false);
    await _refresh();
  }

  int get _highestDisplayScore {
    var best = _localBestScore;
    if (_snapshot != null && _snapshot!.bestScore > best) {
      best = _snapshot!.bestScore;
    }
    for (final entry in _leaderboard) {
      if (entry.score > best) {
        best = entry.score;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Blurred artwork hero backdrop
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
                        'lib/assets/game screen/Frame 1984078794 (1).png',
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
                    padding: const EdgeInsets.fromLTRB(16, 50, 16, 120),
                    child: Column(
                      children: [
                        // Centered Game Icon Squircle
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(23),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0088FF)
                                    .withValues(alpha: 0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(23),
                            child: Image.asset(
                              'lib/assets/game screen/Frame 1984078794 (1).png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.grid_view_rounded,
                                color: Color(0xFF0088FF),
                                size: 46,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          '2048',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF334155),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Pill badge with gradientBiru
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientBiru,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6155F5)
                                    .withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Hingga +120 poin',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Rekor Terbaik card (opens leaderboard)
                        if (_snapshot?.pendingFinalization != null)
                          _PendingFinalizationCard(
                            isSaving: _openingGame,
                            onRetry: _retryFinalization,
                          )
                        else
                          _buildBestRecordCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom CTA button (Mulai / Lanjutkan / Mulai Baru)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: _buildBottomButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF334155),
                size: 20,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildBestRecordCard() {
    final bestScore = _highestDisplayScore;
    final scoreText =
        bestScore > 0 ? '${format2048Score(bestScore)} poin' : '- poin';

    return GestureDetector(
      onTap: () => Game2048HistoryBottomSheet.show(
        context,
        entries: _leaderboard,
        currentUserId: widget.currentUserId,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wb_sunny_rounded,
                color: Color(0xFFFFB020),
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Rekor Terbaik',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFEF3C7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Color(0xFFF59E0B),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    scoreText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    final hasActiveSnapshot = _snapshot != null &&
        _snapshot!.pendingFinalization == null &&
        _snapshot!.tiles.isNotEmpty;

    if (_snapshot?.pendingFinalization != null) {
      return const SizedBox.shrink();
    }

    if (!hasActiveSnapshot) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.gradientBiru,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284F6).withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: _openingGame ? null : () => _startNew(),
            child: Center(
              child: _openingGame
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Mulai',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    // Has saved game: Lanjutkan & Mulai Baru
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.gradientBiru,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284F6).withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: _openingGame ? null : () => _openGame(restore: true),
              child: Center(
                child: _openingGame
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Lanjutkan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _openingGame ? null : () => _startNew(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Mulai Baru',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingFinalizationCard extends StatelessWidget {
  const _PendingFinalizationCard({
    required this.isSaving,
    required this.onRetry,
  });

  final bool isSaving;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8EB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFD89B)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_upload_rounded,
              color: Color(0xFFE58A00),
              size: 30,
            ),
            const SizedBox(height: 9),
            const Text(
              'Hasil permainan belum tersimpan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Simpan hasil ini lebih dulu sebelum memulai permainan baru.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onRetry,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(isSaving ? 'Menyimpan...' : 'Coba Simpan Lagi'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE58A00),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
}

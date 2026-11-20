import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/supabase_client.dart';
import '../engine/tetris_engine.dart';
import '../models/tetris_snapshot.dart';
import '../models/tetromino.dart';
import '../providers/tetris_provider.dart';
import '../repositories/tetris_repository.dart';
import '../services/tetris_local_storage.dart';
import '../utils/tetris_formatters.dart';
import '../widgets/tetris_artwork.dart';
import '../widgets/tetris_gamification_sheet.dart';
import '../widgets/tetris_history_bottom_sheet.dart';
import '../widgets/tetris_mino.dart';
import 'tetris_game_screen.dart';

class TetrisStartScreen extends StatefulWidget {
  const TetrisStartScreen({
    this.storage,
    this.repository,
    this.currentUserId,
    this.engineFactory = TetrisEngine.new,
    super.key,
  });

  final TetrisLocalStorage? storage;
  final TetrisRepository? repository;
  final String? currentUserId;
  final TetrisEngine Function() engineFactory;

  @override
  State<TetrisStartScreen> createState() => _TetrisStartScreenState();
}

class _TetrisStartScreenState extends State<TetrisStartScreen> {
  late final TetrisLocalStorage _storage;
  late final TetrisRepository _repository;
  TetrisSnapshot? _snapshot;
  List<TetrisLeaderboardEntry> _leaderboard = const [];
  Set<int> _claimedMilestones = const {};
  int _localBestScore = 0;
  var _openingGame = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _storage = widget.storage ?? TetrisLocalStorage();
    _repository = widget.repository ?? TetrisRepository();
    _currentUserId = widget.currentUserId ?? _signedInUserId();
    unawaited(_refresh());
  }

  String? _signedInUserId() {
    try {
      return SupabaseNetwork.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadSnapshot(),
      _loadLeaderboard(),
      _loadClaimedMilestones(),
    ]);
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

  Future<void> _loadClaimedMilestones() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;
    try {
      final claimed = await _repository.fetchClaimedMilestones(userId);
      if (!mounted) return;
      setState(() {
        _claimedMilestones = claimed;
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
                backgroundColor: const Color(0xFF7C3AED),
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
    final provider = TetrisProvider(
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
    final provider = TetrisProvider(
      engine: widget.engineFactory(),
      storage: _storage,
      repository: _repository,
    );
    provider.setClaimedMilestones(_claimedMilestones);
    final restored = restore ? await provider.restore() : false;
    if (!restore || !restored) await provider.newGame();
    if (!mounted) {
      provider.dispose();
      return;
    }
    if (provider.status == TetrisStatus.error ||
        (provider.status != TetrisStatus.playing &&
            provider.status != TetrisStatus.paused &&
            provider.status != TetrisStatus.clearing &&
            provider.status != TetrisStatus.gameOver)) {
      provider.dispose();
      setState(() => _openingGame = false);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<TetrisProvider>.value(
          value: provider,
          child: const TetrisGameScreen(),
        ),
      ),
    );
    provider.dispose();
    if (!mounted) return;
    setState(() => _openingGame = false);
    await _refresh();
  }

  int get _earnedAchievementPoints {
    var total = 0;
    for (final milestone in _claimedMilestones) {
      total += TetrisRepository.rewardPointsFor(milestone) ?? 0;
    }
    return total;
  }

  int get _highestDisplayScore {
    var best = _localBestScore;
    if (_snapshot != null && _snapshot!.bestScore > best) {
      best = _snapshot!.bestScore;
    }
    for (final entry in _leaderboard) {
      if (entry.score > best) best = entry.score;
    }
    return best;
  }

  int get _highestDisplayLines {
    var best = _snapshot?.lines ?? 0;
    for (final entry in _leaderboard) {
      if (entry.linesCleared > best) best = entry.linesCleared;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('tetris-start-screen'),
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          const Positioned(
            top: -20,
            left: -20,
            right: -20,
            height: 430,
            child: _TetrisHeroBackdrop(),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 42, 16, 126),
                    child: Column(
                      children: [
                        const TetrisArtwork(size: 96, showBackdrop: true),
                        const SizedBox(height: 18),
                        const Text(
                          'Tetris',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildRewardPill(),
                        const SizedBox(height: 24),
                        if (_snapshot?.pendingFinalization != null)
                          _PendingFinalizationCard(
                            isSaving: _openingGame,
                            onRetry: _retryFinalization,
                          )
                        else ...[
                          _buildBestRecordCard(),
                          const SizedBox(height: 14),
                          _buildHowToPlayCard(),
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
            child: _buildBottomButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Padding(
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

  Widget _buildRewardPill() {
    final complete = _claimedMilestones.length ==
        TetrisGamificationBottomSheet.allMilestones.length;
    final label = complete
        ? 'Achievement lengkap 🏆'
        : _claimedMilestones.isEmpty
            ? 'Hingga +50 poin'
            : '$_earnedAchievementPoints / 50 poin terkumpul';

    return GestureDetector(
      key: const ValueKey('tetris-reward-pill'),
      onTap: () => TetrisGamificationBottomSheet.show(
        context,
        claimedMilestones: _claimedMilestones,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white70,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestRecordCard() {
    final bestScore = _highestDisplayScore;
    final bestLines = _highestDisplayLines;
    final scoreText =
        bestScore > 0 ? '${formatTetrisNumber(bestScore)} poin' : '- poin';

    return GestureDetector(
      key: const ValueKey('tetris-best-record'),
      onTap: () => TetrisHistoryBottomSheet.show(
        context,
        entries: _leaderboard,
        currentUserId: _currentUserId,
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
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rekor Terbaik',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (bestLines > 0)
                    Text(
                      '$bestLines garis',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Color(0xFF7C3AED),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    scoreText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6D28D9),
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

  Widget _buildHowToPlayCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cara Bermain',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 10),
          _HintRow(
            icon: Icons.swipe_rounded,
            text: 'Geser kiri atau kanan untuk memindahkan balok',
          ),
          SizedBox(height: 7),
          _HintRow(
            icon: Icons.rotate_right_rounded,
            text: 'Ketuk papan untuk memutar balok',
          ),
          SizedBox(height: 7),
          _HintRow(
            icon: Icons.vertical_align_bottom_rounded,
            text: 'Drop untuk menjatuhkan balok dan mengunci posisi',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final hasActiveSnapshot = _snapshot != null &&
        _snapshot!.pendingFinalization == null &&
        (_snapshot!.activePiece != null || _snapshot!.clearingRows.isNotEmpty);

    if (_snapshot?.pendingFinalization != null) {
      return const SizedBox.shrink();
    }

    if (!hasActiveSnapshot) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('tetris-start'),
            borderRadius: BorderRadius.circular(13),
            onTap: _openingGame ? null : _startNew,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('tetris-continue'),
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
            key: const ValueKey('tetris-new-game'),
            onPressed: _openingGame ? null : _startNew,
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

class _HintRow extends StatelessWidget {
  const _HintRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ),
        ],
      );
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
                key: const ValueKey('tetris-retry-pending'),
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

class _TetrisHeroBackdrop extends StatelessWidget {
  const _TetrisHeroBackdrop();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEDE9FE),
                  Color(0xFFE0F2FE),
                  Color(0xFFFDF2F8),
                ],
              ),
            ),
          ),
          Positioned(
            top: 38,
            left: -26,
            child: Opacity(
              opacity: 0.32,
              child: Transform.rotate(
                angle: -0.35,
                child: _HeroTetromino(type: TetrominoType.t, cell: 30),
              ),
            ),
          ),
          Positioned(
            top: 96,
            right: -18,
            child: Opacity(
              opacity: 0.26,
              child: Transform.rotate(
                angle: 0.30,
                child: _HeroTetromino(type: TetrominoType.i, cell: 26),
              ),
            ),
          ),
          Positioned(
            top: 198,
            left: 22,
            child: Opacity(
              opacity: 0.20,
              child: Transform.rotate(
                angle: 0.15,
                child: _HeroTetromino(type: TetrominoType.l, cell: 24),
              ),
            ),
          ),
          Positioned(
            top: 250,
            right: 40,
            child: Opacity(
              opacity: 0.22,
              child: Transform.rotate(
                angle: -0.18,
                child: _HeroTetromino(type: TetrominoType.s, cell: 22),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00F8F9FE),
                  Color(0x66F8F9FE),
                  Color(0xCCF8F9FE),
                  Color(0xFFF8F9FE),
                ],
                stops: [0, 0.34, 0.64, 1],
              ),
            ),
          ),
          Positioned(
            top: 26,
            right: 70,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTetromino extends StatelessWidget {
  const _HeroTetromino({required this.type, required this.cell});

  final TetrominoType type;
  final double cell;

  @override
  Widget build(BuildContext context) {
    final width = type.widthForRotation(0) * cell;
    final height = type.heightForRotation(0) * cell;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          for (final shapeCell in type.cellsForRotation(0))
            Positioned(
              left: shapeCell.col * cell,
              top: shapeCell.row * cell,
              child: TetrisMino(type: type, size: cell * 0.9),
            ),
        ],
      ),
    );
  }
}

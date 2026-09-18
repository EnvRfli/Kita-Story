import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_2048_engine.dart';
import '../models/game_2048_snapshot.dart';
import '../providers/game_2048_provider.dart';
import '../repositories/game_2048_repository.dart';
import '../services/game_2048_local_storage.dart';
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
  var _snapshotLoading = true;
  var _leaderboardLoading = true;
  var _snapshotFailed = false;
  var _leaderboardFailed = false;
  var _openingGame = false;

  @override
  void initState() {
    super.initState();
    _storage = widget.storage ?? Game2048LocalStorage();
    _repository = widget.repository ?? Game2048Repository();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _snapshotLoading = true;
        _leaderboardLoading = true;
        _snapshotFailed = false;
        _leaderboardFailed = false;
      });
    }
    await Future.wait([_loadSnapshot(), _loadLeaderboard()]);
  }

  Future<void> _loadSnapshot() async {
    try {
      final snapshot = await _storage.load();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _snapshotFailed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _snapshotFailed = true);
    } finally {
      if (mounted) setState(() => _snapshotLoading = false);
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      final leaderboard = await _repository.fetchLeaderboard();
      if (!mounted) return;
      setState(() {
        _leaderboard = leaderboard;
        _leaderboardFailed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _leaderboardFailed = true);
    } finally {
      if (mounted) setState(() => _leaderboardLoading = false);
    }
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

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFFCFCFD),
        body: Stack(children: [
          const _ArtworkBackdrop(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(children: [
                  _Header(onBack: () => Navigator.of(context).maybePop()),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                      child: Column(children: [
                        const _Hero(),
                        const SizedBox(height: 24),
                        _ResumeSection(
                          isLoading: _snapshotLoading,
                          snapshot: _snapshot,
                          failed: _snapshotFailed,
                          isOpening: _openingGame,
                          onContinue: () => unawaited(_openGame(restore: true)),
                          onNewGame: () => unawaited(_startNew()),
                          onRetryFinalization: () =>
                              unawaited(_retryFinalization()),
                        ),
                        const SizedBox(height: 18),
                        _LeaderboardPreview(
                          entries: _leaderboard,
                          isLoading: _leaderboardLoading,
                          failed: _leaderboardFailed,
                          onRetry: () => unawaited(_loadLeaderboard()),
                          onOpen: () =>
                              unawaited(Game2048HistoryBottomSheet.show(
                            context,
                            entries: _leaderboard,
                            currentUserId: widget.currentUserId,
                          )),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      );
}

class _ArtworkBackdrop extends StatelessWidget {
  const _ArtworkBackdrop();

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: Stack(fit: StackFit.expand, children: [
            Opacity(
              opacity: .13,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Image.asset(
                  'lib/assets/game screen/Frame 1984078794 (1).png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xD9F8F3FF), Color(0xFFFCFCFD)],
                ),
              ),
            ),
          ]),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Expanded(
            child: Text('2048',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 21,
                    fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 48),
        ]),
      );
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset(
            'lib/assets/game screen/Frame 1984078794 (1).png',
            width: 126,
            height: 126,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 15),
        const Text('2048',
            style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w900,
                fontSize: 28)),
        const SizedBox(height: 5),
        const Text('Gabungkan ubin, raih angka tertinggi!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xFF6B4454),
              borderRadius: BorderRadius.circular(20)),
          child: const Text('Hingga +120 poin',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
        ),
      ]);
}

class _ResumeSection extends StatelessWidget {
  const _ResumeSection({
    required this.isLoading,
    required this.snapshot,
    required this.failed,
    required this.isOpening,
    required this.onContinue,
    required this.onNewGame,
    required this.onRetryFinalization,
  });
  final bool isLoading;
  final Game2048Snapshot? snapshot;
  final bool failed;
  final bool isOpening;
  final VoidCallback onContinue;
  final VoidCallback onNewGame;
  final VoidCallback onRetryFinalization;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
          padding: EdgeInsets.all(20), child: CircularProgressIndicator());
    }
    if (failed) {
      return const _InlineState(
        icon: Icons.cloud_off_rounded,
        title: 'Permainan tersimpan belum bisa dimuat',
        subtitle: 'Kamu tetap bisa memulai permainan baru.',
      );
    }
    if (snapshot?.pendingFinalization != null) {
      return _PendingFinalizationState(
        isSaving: isOpening,
        onRetry: onRetryFinalization,
      );
    }
    final hasSnapshot = snapshot != null;
    return Column(children: [
      if (hasSnapshot) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6DBF9)),
          ),
          child: Text('Permainan tersimpan • Skor ${snapshot!.score}',
              style: const TextStyle(
                  color: Color(0xFF6B4454), fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 11),
      ],
      SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: isOpening
                ? null
                : hasSnapshot
                    ? onContinue
                    : onNewGame,
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            child: Text(hasSnapshot ? 'Lanjutkan' : 'Mulai',
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          )),
      if (hasSnapshot) ...[
        const SizedBox(height: 9),
        SizedBox(
            width: double.infinity,
            height: 49,
            child: OutlinedButton(
              onPressed: isOpening ? null : onNewGame,
              child: const Text('Mulai Baru',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            )),
      ],
    ]);
  }
}

class _PendingFinalizationState extends StatelessWidget {
  const _PendingFinalizationState({
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
        child: Column(children: [
          const Icon(Icons.cloud_upload_rounded,
              color: Color(0xFFE58A00), size: 30),
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
        ]),
      );
}

class _LeaderboardPreview extends StatelessWidget {
  const _LeaderboardPreview({
    required this.entries,
    required this.isLoading,
    required this.failed,
    required this.onRetry,
    required this.onOpen,
  });
  final List<Game2048LeaderboardEntry> entries;
  final bool isLoading;
  final bool failed;
  final VoidCallback onRetry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _InlineState(
        icon: Icons.leaderboard_rounded,
        title: 'Memuat papan skor...',
        subtitle: '',
      );
    }
    if (failed) {
      return _InlineState(
        icon: Icons.error_outline_rounded,
        title: 'Papan skor belum tersedia',
        subtitle: 'Coba muat lagi saat koneksi siap.',
        action: TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
      );
    }
    if (entries.isEmpty) {
      return const _InlineState(
        icon: Icons.emoji_events_outlined,
        title: 'Belum ada rekor permainan',
        subtitle: 'Jadilah yang pertama menorehkan skor!',
      );
    }
    return OutlinedButton.icon(
      onPressed: onOpen,
      icon: const Icon(Icons.leaderboard_rounded),
      label: const Text('Lihat papan skor & riwayat'),
    );
  }
}

class _InlineState extends StatelessWidget {
  const _InlineState(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.action});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(children: [
          Icon(icon, color: const Color(0xFFA07BFE)),
          const SizedBox(height: 7),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF1E293B), fontWeight: FontWeight.w800)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
          if (action != null) action!,
        ]),
      );
}

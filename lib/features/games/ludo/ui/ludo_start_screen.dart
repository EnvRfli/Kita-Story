import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../models/ludo_game_state.dart';
import '../providers/ludo_game_provider.dart';
import '../repositories/ludo_repository.dart';
import '../services/ludo_local_storage.dart';
import 'ludo_game_screen.dart';

class LudoStartScreen extends StatefulWidget {
  final String? currentUserId;
  final String? partnerName;
  final bool? hasPartner;
  final int? initialPoints;

  const LudoStartScreen({
    super.key,
    this.currentUserId,
    this.partnerName,
    this.hasPartner,
    this.initialPoints,
  });

  @override
  State<LudoStartScreen> createState() => _LudoStartScreenState();
}

class _LudoStartScreenState extends State<LudoStartScreen> {
  final LudoLocalStorage _storage = LudoLocalStorage();
  final LudoRepository _repository = LudoRepository();

  int _winCount = 0;
  bool _isLoading = false;
  LudoGameState? _savedGame;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final localWins = await _storage.loadWinCount();
    final saved = await _storage.loadActiveGame();
    if (!mounted) return;
    setState(() {
      _winCount = localWins;
      _savedGame = saved != null && !saved.isGameOver ? saved : null;
    });

    try {
      final userId = widget.currentUserId ??
          SupabaseNetwork.client.auth.currentUser?.id;
      if (userId != null && userId.isNotEmpty) {
        final remoteWins = await _repository.fetchTotalWins(userId);
        if (!mounted) return;
        setState(() {
          _winCount = remoteWins > localWins ? remoteWins : localWins;
        });
      }
    } catch (_) {}
  }

  void _pushGame() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      context.push('/ludo/game');
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LudoGameScreen()),
      );
    }
  }

  Future<void> _startOnlineInvitation() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUserProfile;
    final partner = auth.partnerProfile;
    if (user == null || partner == null) {
      AppSnackBar.warning(
        context,
        'Hubungkan akun dengan pemain lain dulu di menu Profil ya.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final gameProvider = context.read<LudoGameProvider>();
      await gameProvider.createOnlineInvitation(
        hostId: user.id,
        hostName: user.name,
        hostAvatar: user.photoUrl,
        guestId: partner.id,
        guestName: partner.name,
        guestAvatar: partner.photoUrl,
      );

      if (!mounted) return;
      _pushGame();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        title: 'Gagal mengirim ajakan',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startOfflineGame() async {
    final auth = context.read<AuthProvider>();
    final p1Name = auth.currentUserProfile?.name ?? 'Pemain 1';
    final p1Avatar = auth.currentUserProfile?.photoUrl;
    final partner = auth.partnerProfile;

    setState(() => _isLoading = true);
    try {
      final gameProvider = context.read<LudoGameProvider>();
      await gameProvider.startOfflineGame(
        mode: LudoGameMode.offline2,
        player1Name: p1Name,
        player1Avatar: p1Avatar,
        player2Name: partner?.name ?? 'Pemain 2',
        player2Avatar: partner?.photoUrl,
      );

      if (!mounted) return;
      _pushGame();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resumeOfflineGame() async {
    final game = _savedGame;
    if (game == null) return;

    setState(() => _isLoading = true);
    try {
      await context.read<LudoGameProvider>().resumeOfflineGame(game);
      if (!mounted) return;
      _pushGame();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUserProfile;
    final partner = auth.partnerProfile;

    final userPoints =
        widget.initialPoints ?? user?.points ?? 125;
    final partnerName =
        partner?.name ?? widget.partnerName ?? 'Pemain 2';
    final hasPartner = (partner != null) || (widget.hasPartner ?? false);
    final userName = user?.name ?? 'Kamu';

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'lib/assets/game screen/image 1.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE0F2FE),
                  ),
                ),
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFFFCFCFD).withValues(alpha: 0.8),
                        const Color(0xFFFCFCFD),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () {
                          final router = GoRouter.maybeOf(context);
                          if (router != null && router.canPop()) {
                            context.pop();
                          } else if (router != null) {
                            context.go('/games');
                          } else {
                            Navigator.of(context).maybePop();
                          }
                        },
                      ),
                      const Spacer(),
                      if (hasPartner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                color: Color(0xFF0088FF),
                                size: 14,
                              ),
                              SizedBox(width: 5),
                              Text(
                                '2 Pemain',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Ludo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasPartner
                              ? 'Tantang $partnerName, antar 4 pion ke rumah lebih dulu!'
                              : 'Hubungkan pemain untuk membuka mode berdua.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildPlayersHero(
                          userName: userName,
                          partnerName: partnerName,
                          userAvatar: user?.photoUrl,
                          partnerAvatar: partner?.photoUrl,
                          hasPartner: hasPartner,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _StatPill(
                                icon: '🌟',
                                label: 'Menang',
                                value: '$_winCount kali',
                                color: const Color(0xFFFF7A00),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatPill(
                                icon: '🪙',
                                label: 'Poin',
                                value: '$userPoints',
                                color: const Color(0xFF0088FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildInviteCard(
                          hasPartner: hasPartner,
                          partnerName: partnerName,
                        ),
                        if (_savedGame != null) ...[
                          const SizedBox(height: 14),
                          _buildResumeCard(),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed:
                                hasPartner && !_isLoading
                                    ? _startOnlineInvitation
                                    : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0088FF),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFE2E8F0),
                              disabledForegroundColor: const Color(0xFF94A3B8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 19),
                            label: Text(
                              hasPartner
                                  ? 'Ajak $partnerName Bermain'
                                  : 'Hubungkan Pemain Dulu',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _isLoading ? null : _startOfflineGame,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                          ),
                          icon: const Icon(Icons.phonelink_ring_rounded,
                              size: 18),
                          label: const Text(
                            'Main Berdua di HP Ini',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersHero({
    required String userName,
    required String partnerName,
    String? userAvatar,
    String? partnerAvatar,
    required bool hasPartner,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F2FE), Color(0xFFDCFCE7)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0088FF).withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _PlayerAvatar(
              name: userName,
              avatarUrl: userAvatar,
              color: const Color(0xFF0088FF),
            ),
          ),
          Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0088FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text('🎲', style: TextStyle(fontSize: 18)),
            ],
          ),
          Expanded(
            child: _PlayerAvatar(
              name: hasPartner ? partnerName : 'Pemain 2',
              avatarUrl: partnerAvatar,
              color: hasPartner
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF94A3B8),
              dimmed: !hasPartner,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard({
    required bool hasPartner,
    required String partnerName,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🎲', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPartner
                      ? 'Main realtime dengan $partnerName'
                      : 'Mode dua pemain belum aktif',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPartner
                      ? 'Kirim undangan ke $partnerName. Begitu diterima, papan langsung siap dipakai.'
                      : 'Hubungkan dua akun supaya bisa bermain dari HP masing-masing.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _resumeOfflineGame,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFDE68A),
              width: 1.2,
            ),
          ),
          child: const Row(
            children: [
              Text('⏳', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lanjutkan permainan offline',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Papan terakhir masih tersimpan di HP ini.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_fill_rounded,
                color: Color(0xFFFF7A00),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: const Color(0xFF1E293B), size: 20),
        ),
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final Color color;
  final bool dimmed;

  const _PlayerAvatar({
    required this.name,
    required this.color,
    this.avatarUrl,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: color.withValues(alpha: dimmed ? 0.3 : 0.8),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: dimmed ? 0.06 : 0.2),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: hasAvatar
              ? Image.network(
                  avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initial(),
                )
              : _initial(),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: dimmed
                ? const Color(0xFF94A3B8)
                : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _initial() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color,
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

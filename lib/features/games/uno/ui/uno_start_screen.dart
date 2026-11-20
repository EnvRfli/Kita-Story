import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../models/uno_card.dart';
import '../models/uno_match_model.dart';
import '../providers/uno_game_provider.dart';
import '../repositories/uno_repository.dart';
import '../widgets/uno_card_widget.dart';
import '../widgets/uno_rules_sheet.dart';

class UnoStartScreen extends StatefulWidget {
  const UnoStartScreen({super.key});

  @override
  State<UnoStartScreen> createState() => _UnoStartScreenState();
}

class _UnoStartScreenState extends State<UnoStartScreen> {
  final UnoRepository _repository = UnoRepository();

  bool _isLoading = false;
  int _winCount = 0;
  UnoMatchModel? _activeMatch;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUserProfile?.id;
    if (userId == null) return;

    final results = await Future.wait([
      _repository.fetchTotalWins(userId),
      _repository.fetchActiveMatch(userId),
    ]);
    if (!mounted) return;
    setState(() {
      _winCount = results[0] as int;
      _activeMatch = results[1] as UnoMatchModel?;
    });
  }

  void _pushGame() {
    context.push('/uno/game');
  }

  Future<void> _startInvitation() async {
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
      final gameProvider = context.read<UnoGameProvider>();
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

  Future<void> _resume() async {
    final match = _activeMatch;
    final auth = context.read<AuthProvider>();
    final user = auth.currentUserProfile;
    final partner = auth.partnerProfile;
    if (match == null || user == null) return;

    setState(() => _isLoading = true);
    try {
      await context.read<UnoGameProvider>().resumeMatch(
            matchId: match.id,
            currentUserId: user.id,
            partnerId: partner?.id,
            partnerName: partner?.name,
          );
      if (!mounted) return;
      _pushGame();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Gagal melanjutkan UNO: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUserProfile;
    final partner = auth.partnerProfile;
    final hasPartner = partner != null || (user?.partnerId != null);
    final partnerName = partner?.name ?? 'Pasangan';
    final gameProvider = context.watch<UnoGameProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF111827),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -70,
            right: -50,
            child: _Glow(color: const Color(0xFFE53935), size: 260),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: _Glow(color: const Color(0xFF1E88E5), size: 300),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(gameProvider),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                    child: Column(
                      children: [
                        _buildCardFan(),
                        const SizedBox(height: 18),
                        const Text(
                          'UNO',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 5,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 18),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasPartner
                              ? 'Tantang $partnerName. Tumpuk, balas, dan habiskan kartu duluan!'
                              : 'Hubungkan akun dengan pasangan dulu untuk membuka mode online.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildPlayersHero(
                          userName: user?.name ?? 'Kamu',
                          partnerName: partnerName,
                          userAvatar: user?.photoUrl,
                          partnerAvatar: partner?.photoUrl,
                          hasPartner: hasPartner,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _StatPill(
                                icon: '🏆',
                                label: 'Menang',
                                value: '$_winCount kali',
                                accent: const Color(0xFFF9A825),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatPill(
                                icon: '🪙',
                                label: 'Poin',
                                value: '${user?.points ?? 0}',
                                accent: const Color(0xFF4ADE80),
                              ),
                            ),
                          ],
                        ),
                        if (_activeMatch != null) ...[
                          const SizedBox(height: 14),
                          _buildResumeCard(),
                        ],
                        const SizedBox(height: 16),
                        _buildInviteCard(hasPartner, partnerName),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: hasPartner && !_isLoading
                                ? _startInvitation
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF334155),
                              disabledForegroundColor:
                                  const Color(0xFF94A3B8),
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
                                  : 'Hubungkan Pasangan Dulu',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => showUnoRulesSheet(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.menu_book_rounded, size: 18),
                            label: const Text(
                              'Cara Main UNO',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Online only • 7 kartu • 116 deck • tanpa serobot',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
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

  Widget _buildTopBar(UnoGameProvider gameProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          InkWell(
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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: gameProvider.toggleSound,
            tooltip: 'Suara',
            icon: Icon(
              gameProvider.soundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFan() {
    final cardWidth = MediaQuery.of(context).size.width * 0.2;
    return SizedBox(
      height: cardWidth * 1.7,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(-cardWidth * 0.72, 6),
            child: Transform.rotate(
              angle: -0.22,
              child: Opacity(
                opacity: 0.9,
                child: UnoCardWidget(
                  card: const UnoCard(
                    id: 'deco-1',
                    color: UnoColor.blue,
                    type: UnoCardType.number,
                    number: 7,
                  ),
                  width: cardWidth,
                  playable: false,
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(cardWidth * 0.72, 6),
            child: Transform.rotate(
              angle: 0.22,
              child: Opacity(
                opacity: 0.9,
                child: UnoCardWidget(
                  card: const UnoCard(
                    id: 'deco-2',
                    color: UnoColor.yellow,
                    type: UnoCardType.drawOne,
                  ),
                  width: cardWidth,
                  playable: false,
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -4),
            child: Transform.rotate(
              angle: -0.02,
              child: UnoCardWidget(
                card: const UnoCard(
                  id: 'deco-3',
                  type: UnoCardType.drawTwo,
                ),
                width: cardWidth,
                playable: false,
              ),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PlayerAvatar(
              name: userName,
              avatarUrl: userAvatar,
              accent: const Color(0xFF4ADE80),
            ),
          ),
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text('🃏', style: TextStyle(fontSize: 18)),
            ],
          ),
          Expanded(
            child: _PlayerAvatar(
              name: hasPartner ? partnerName : 'Pasangan',
              avatarUrl: partnerAvatar,
              accent: hasPartner
                  ? const Color(0xFFF9A825)
                  : const Color(0xFF64748B),
              dimmed: !hasPartner,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(bool hasPartner, String partnerName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🃏', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPartner
                      ? 'Meja UNO realtime dengan $partnerName'
                      : 'Mode online belum aktif',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPartner
                      ? 'Kirim undangan ke $partnerName. Begitu diterima, kartu langsung dibagikan server dan permainan dimulai.'
                      : 'Hubungkan dua akun supaya bisa bermain dari HP masing-masing.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Color(0xFFCBD5E1),
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
    final match = _activeMatch!;
    final isPaused = match.status == UnoMatchStatus.paused;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _resume,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9A825).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF9A825).withValues(alpha: 0.38),
            ),
          ),
          child: Row(
            children: [
              Text(
                isPaused ? '⏸️' : '⏳',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPaused
                          ? 'Lanjutkan UNO yang sedang pause'
                          : 'Lanjutkan permainan UNO',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFF8E1),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'State kartu terakhir tersimpan. Lawan tinggal menunggu.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFFDE68A),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.play_circle_fill_rounded,
                color: Color(0xFFF9A825),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final Color accent;
  final bool dimmed;

  const _PlayerAvatar({
    required this.name,
    required this.accent,
    this.avatarUrl,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: accent.withValues(alpha: dimmed ? 0.3 : 0.85),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: dimmed ? 0.05 : 0.28),
                blurRadius: 16,
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
            color: dimmed ? const Color(0xFF94A3B8) : Colors.white,
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
          color: accent,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color accent;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
                    color: accent,
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

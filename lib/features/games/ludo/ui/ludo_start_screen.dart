import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../auth/providers/auth_provider.dart';
import '../engine/ludo_engine.dart';
import '../models/ludo_game_state.dart';
import '../models/ludo_player.dart';
import '../providers/ludo_game_provider.dart';
import '../repositories/ludo_repository.dart';
import '../services/ludo_local_storage.dart';
import '../widgets/ludo_mode_sheet.dart';
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
  final LudoEngine _engine = LudoEngine();

  int _winCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final localWins = await _storage.loadWinCount();
    if (!mounted) return;
    setState(() => _winCount = localWins);

    try {
      final userId = widget.currentUserId ??
          SupabaseNetwork.client.auth.currentUser?.id;
      if (userId != null && userId.isNotEmpty) {
        final remoteWins = await _repository.fetchTotalWins(userId);
        if (!mounted) return;
        setState(() => _winCount = remoteWins > localWins ? remoteWins : localWins);
      }
    } catch (_) {}
  }

  void _onStartTap() {
    String? partnerName = widget.partnerName;
    bool hasPartner = widget.hasPartner ?? false;

    try {
      final auth = context.read<AuthProvider>();
      final partner = auth.partnerProfile;
      if (partner != null && partner.id.isNotEmpty) {
        partnerName = partner.name;
        hasPartner = true;
      }
    } catch (_) {}

    LudoModeSelectionBottomSheet.show(
      context,
      partnerName: partnerName,
      hasPartner: hasPartner,
      onSelectOfflineMode: (mode) => _startOfflineGame(mode),
      onSelectOnlineMode: () => _startOnlineInvitation(),
    );
  }

  Future<void> _startOfflineGame(LudoGameMode mode) async {
    final auth = context.read<AuthProvider>();
    final p1Name = auth.currentUserProfile?.name ?? 'Pemain 1';
    final p1Avatar = auth.currentUserProfile?.photoUrl;
    final partnerName = auth.partnerProfile?.name;
    final partnerAvatar = auth.partnerProfile?.photoUrl;

    final gameProvider = context.read<LudoGameProvider>();
    await gameProvider.startOfflineGame(
      mode: mode,
      player1Name: p1Name,
      player1Avatar: p1Avatar,
      player2Name: partnerName ?? 'Pemain 2',
      player2Avatar: partnerAvatar,
      player3Name: 'Pemain 3',
      player4Name: 'Pemain 4',
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LudoGameScreen()),
    ).then((_) => _loadStats());
  }

  Future<void> _startOnlineInvitation() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUserProfile;
    final partner = auth.partnerProfile;
    if (user == null || partner == null) return;

    setState(() => _isLoading = true);

    try {
      final initialGameState = _engine.createInitialState(
        mode: LudoGameMode.onlineCouple,
        player1Name: user.name,
        player1Avatar: user.photoUrl,
        player2Name: partner.name,
        player2Avatar: partner.photoUrl,
      );

      final match = await _repository.createMatchInvitation(
        hostId: user.id,
        guestId: partner.id,
        hostColor: LudoColor.green,
        guestColor: LudoColor.blue,
        initialState: initialGameState,
      );

      if (!mounted) return;
      final gameProvider = context.read<LudoGameProvider>();
      await gameProvider.startOnlineGame(
        matchId: match.id,
        currentUserId: user.id,
        partnerId: partner.id,
        myColor: LudoColor.green,
        initialState: initialGameState,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LudoGameScreen()),
      ).then((_) => _loadStats());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim ajakan: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int userPoints = widget.initialPoints ?? 125;
    try {
      final auth = context.watch<AuthProvider>();
      userPoints = widget.initialPoints ?? auth.currentUserProfile?.points ?? 125;
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: Stack(
        children: [
          // 1. Blurred Background Header
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
                // Gradient overlay to fade smoothly into background
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

          // 2. Safe Area Content
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Circular Back Button
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
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
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF1E293B),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Center Icon (Ludo 3D Squircle Logo matching Mockup 1)
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'lib/assets/game screen/image 1.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                const Text(
                  'Ludo',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Points Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0088FF),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0088FF).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '$userPoints poin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Win Count Card (Matching Mockup 1: "Menang" -> "11 kali")
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text('🌟', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 10),
                            Text(
                              'Menang',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              '$_winCount kali',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFF7A00),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Bottom Primary Button: "Mulai"
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _onStartTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0088FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Mulai',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
}

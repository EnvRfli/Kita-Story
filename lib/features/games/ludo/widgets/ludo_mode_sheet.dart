import 'package:flutter/material.dart';
import '../models/ludo_game_state.dart';

class LudoModeSelectionBottomSheet extends StatefulWidget {
  final String? partnerName;
  final bool hasPartner;
  final ValueChanged<LudoGameMode> onSelectOfflineMode;
  final VoidCallback onSelectOnlineMode;

  const LudoModeSelectionBottomSheet({
    super.key,
    this.partnerName,
    required this.hasPartner,
    required this.onSelectOfflineMode,
    required this.onSelectOnlineMode,
  });

  static Future<void> show(
    BuildContext context, {
    String? partnerName,
    required bool hasPartner,
    required ValueChanged<LudoGameMode> onSelectOfflineMode,
    required VoidCallback onSelectOnlineMode,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LudoModeSelectionBottomSheet(
        partnerName: partnerName,
        hasPartner: hasPartner,
        onSelectOfflineMode: onSelectOfflineMode,
        onSelectOnlineMode: onSelectOnlineMode,
      ),
    );
  }

  @override
  State<LudoModeSelectionBottomSheet> createState() =>
      _LudoModeSelectionBottomSheetState();
}

class _LudoModeSelectionBottomSheetState
    extends State<LudoModeSelectionBottomSheet> {
  int _offlinePlayerCount = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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

            // Header
            const Row(
              children: [
                Icon(
                  Icons.sports_esports_rounded,
                  color: Color(0xFF0088FF),
                  size: 26,
                ),
                SizedBox(width: 10),
                Text(
                  'Pilih Mode Permainan Ludo',
                  style: TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Option 1: Offline Pass & Play Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.phonelink_ring_rounded,
                        color: Color(0xFF22C55E),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Mode Offline (Pass & Play)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Main bergantian pada 1 HP bersama teman atau pasangan.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Player count chips (2, 3, 4 Pemain)
                  Row(
                    children: [2, 3, 4].map((count) {
                      final isSelected = _offlinePlayerCount == count;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _offlinePlayerCount = count),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '$count Pemain',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Start Offline Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        final mode = _offlinePlayerCount == 2
                            ? LudoGameMode.offline2
                            : (_offlinePlayerCount == 3
                                ? LudoGameMode.offline3
                                : LudoGameMode.offline4);
                        widget.onSelectOfflineMode(mode);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Mulai Mode Offline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Option 2: Online with Partner Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.hasPartner
                      ? const Color(0xFFBFDBFE)
                      : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mode Online (Bersama Pasangan)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: widget.hasPartner
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.hasPartner
                        ? 'Kirim ajakan realtime ke HP ${widget.partnerName ?? 'Pasangan'}.'
                        : 'Hubungkan akun dengan pasangan terlebih dahulu di menu Profil.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Start Online Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: widget.hasPartner
                          ? () {
                              Navigator.of(context).pop();
                              widget.onSelectOnlineMode();
                            }
                          : null,
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: Text(
                        widget.hasPartner
                            ? 'Ajak ${widget.partnerName ?? 'Pasangan'} Bermain'
                            : 'Belum Terhubung Pasangan',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0088FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        disabledForegroundColor: const Color(0xFF94A3B8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';

class PartnerHomeScreen extends StatelessWidget {
  const PartnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUserProfile;
    final partnerUser = authProvider.partnerProfile;

    final partnerName = partnerUser?.name.isNotEmpty == true
        ? partnerUser!.name
        : 'Nazilla Andiz A';
    final userPoints = currentUser?.points ?? 100;
    final partnerPoints = partnerUser?.points ?? 0;
    final isPartnerLeading = partnerPoints >= userPoints;
    final partnerPhotoUrl = partnerUser?.photoUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Image
          Image.asset(
            'lib/assets/background/Home.png',
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFEFF3),
                    Color(0xFFFFF9E6),
                    Color(0xFFE8F5E9),
                    Color(0xFFE3F2FD),
                  ],
                ),
              ),
            ),
          ),

          // 2. 3D Decorative Noodles (Same as HomeScreen)
          // 2a. Atas kiri (9785753 3.png)
          Positioned(
            top: -size.height * 0.032,
            right: size.width * 0.12,
            child: Transform.rotate(
              angle: -30 * math.pi / 180,
              child: Image.asset(
                'lib/assets/tai/9785753 3.png',
                width: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 2b. Atas kanan (9785753 8.png)
          Positioned(
            top: size.height * 0.02,
            right: -size.width * 0.05,
            child: Transform.rotate(
              angle: -10 * math.pi / 180,
              child: Image.asset(
                'lib/assets/tai/9785753 8.png',
                width: 60,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 2c. Bawah kanan (9785753 9.png)
          Positioned(
            top: size.height * 0.19,
            right: 1,
            child: Image.asset(
              'lib/assets/tai/9785753 9.png',
              width: 42,
              fit: BoxFit.contain,
            ),
          ),

          // 3. Main Scrollable Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Back Button ("← Kembali")
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0088FF),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0088FF).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Kembali',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Partner Profile Info Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: Name & Points
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              partnerName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Points Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6B55F5),
                                        Color(0xFF4C8DF5),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6155F5)
                                            .withValues(alpha: 0.32),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'lib/assets/homescreen assets/7068473 3.png',
                                        width: 17,
                                        height: 17,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.stars_rounded,
                                          color: Colors.yellowAccent,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$partnerPoints Poin',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Leader/Rank Shield Badge with AppColors.gradientOrange
                                Container(
                                  width: 32,
                                  height: 32,
                                  padding: const EdgeInsets.all(4.5),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.gradientOrange,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF96E0D)
                                            .withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    isPartnerLeading
                                        ? 'lib/assets/homescreen assets/7068473 3 (1).png'
                                        : 'lib/assets/homescreen assets/7068473 3 (2).png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.shield,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Right: Avatar with Glowing Ring
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0088FF),
                              Color(0xFF8B5CF6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0088FF)
                                  .withValues(alpha: 0.40),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(
                          child: partnerPhotoUrl != null &&
                                  partnerPhotoUrl.isNotEmpty
                              ? Image.network(
                                  partnerPhotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _defaultPartnerAvatar(),
                                )
                              : _defaultPartnerAvatar(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Section Title: "Jelajahi ✨"
                  const Text(
                    'Jelajahi ✨',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2-Column Menu Grid for Partner
                  _buildPartnerMenuGrid(
                    context,
                    partnerId: partnerUser?.id,
                    partnerName: partnerName,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultPartnerAvatar() {
    return Container(
      color: const Color(0xFF0B192C),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: Color(0xFFFFCC00),
          size: 36,
        ),
      ),
    );
  }

  Widget _buildPartnerMenuGrid(
    BuildContext context, {
    String? partnerId,
    required String partnerName,
  }) {
    return Column(
      children: [
        // Row 1: Bacaan & Catatan
        Row(
          children: [
            Expanded(
              child: _buildMenuCard(
                title: 'Bacaan',
                imagePath:
                    'lib/assets/homescreen assets/05june22_phonebook_icon_04 2.png',
                imageRight: -36,
                imageTop: null,
                imageBottom: -34,
                imageWidth: 135,
                onTap: () {
                  context.push(
                    '/partner-books',
                    extra: {
                      'partnerId': partnerId,
                      'partnerName': partnerName,
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMenuCard(
                title: 'Catatan',
                imagePath:
                    'lib/assets/homescreen assets/clipboard-with-checklist-paper-note-icon-symbol-purple-background-3d-rendering 2.png',
                imageRight: -10,
                imageTop: 10,
                imageBottom: null,
                imageWidth: 90,
                onTap: () => AppSnackBar.info(
                  context,
                  'Modul Catatan Pasangan segera hadir! ✨',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Row 2: Keuangan & Resep
        Row(
          children: [
            Expanded(
              child: _buildMenuCard(
                title: 'Keuangan',
                imagePath: 'lib/assets/homescreen assets/7068473 2.png',
                imageRight: -21,
                imageTop: 8,
                imageBottom: null,
                imageWidth: 100,
                onTap: () => AppSnackBar.info(
                  context,
                  'Modul Keuangan Pasangan segera hadir! 💰',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMenuCard(
                title: 'Resep',
                imagePath: 'lib/assets/homescreen assets/6024348 2.png',
                imageRight: -25,
                imageTop: null,
                imageBottom: -35,
                imageWidth: 130,
                onTap: () => AppSnackBar.info(
                  context,
                  'Modul Resep Pasangan segera hadir! 🥧',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Row 3: Pengingat (Half width aligned left)
        Row(
          children: [
            Expanded(
              child: _buildMenuCard(
                title: 'Pengingat',
                imagePath:
                    'lib/assets/homescreen assets/a888be4e-bdd0-45c0-8696-821a322cfebc 2.png',
                imageRight: -30,
                imageTop: -5,
                imageBottom: null,
                imageWidth: 120,
                onTap: () => AppSnackBar.info(
                  context,
                  'Modul Pengingat Pasangan segera hadir! ⏰',
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String imagePath,
    required double? imageRight,
    required double? imageTop,
    required double? imageBottom,
    required double imageWidth,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 14,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: imageRight,
                  top: imageTop,
                  bottom: imageBottom,
                  child: Image.asset(
                    imagePath,
                    width: imageWidth,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

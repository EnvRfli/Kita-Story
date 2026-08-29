import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUserProfile;
    final partnerUser = authProvider.partnerProfile;

    final userName = currentUser?.name.isNotEmpty == true
        ? currentUser!.name
        : 'M. Rafli Agusta R';
    final partnerName = partnerUser?.name.isNotEmpty == true
        ? partnerUser!.name
        : 'Nazilla Andiz A';

    final userPoints = currentUser?.points ?? 100;
    final partnerPoints = partnerUser?.points ?? 0;
    final isUserLeading = userPoints >= partnerPoints;

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

          // 2. 3D Decorative Noodles Anchored at Top-Right Corner (Fixed at Top)
          // 2a. Atas sedikit kiri user (9785753 3.png, rotate -30 deg)
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

          // 2b. Atas kanan user (9785753 8.png, rotate -10 deg)
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

          // 2c. Bawah kanan user (9785753 9.png)
          Positioned(
            top: size.height * 0.19,
            right: 1,
            child: Image.asset(
              'lib/assets/tai/9785753 9.png',
              width: 42,
              fit: BoxFit.contain,
            ),
          ),

          // 3. Main Scrollable Content (Moved Down for Comfortable Spacing)
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20.0, 64.0, 20.0, 115.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TOP HEADER (Greeting, Name, Badges, Avatar) ---
                  _buildHeader(
                    context: context,
                    userName: userName,
                    userPoints: userPoints,
                    userPhotoUrl: currentUser?.photoUrl,
                    isUserLeading: isUserLeading,
                  ),
                  const SizedBox(height: 40),

                  // --- PARTNER CARD (Nazilla Andiz A) ---
                  _buildPartnerCard(
                    context: context,
                    partnerName: partnerName,
                    partnerPhotoUrl: partnerUser?.photoUrl,
                    partnerPoints: partnerPoints,
                  ),
                  const SizedBox(height: 28),

                  // --- SECTION TITLE: "Jelajahi ✨" ---
                  const Text(
                    'Jelajahi ✨',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF222222),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- 2-COLUMN MENU GRID ---
                  _buildMenuGrid(context),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // ==========================================
  // WIDGET: TOP HEADER (User info & Avatar)
  // ==========================================
  Widget _buildHeader({
    required BuildContext context,
    required String userName,
    required int userPoints,
    required String? userPhotoUrl,
    required bool isUserLeading,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: Greeting, User Name, Badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat Datang, 👋',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF222222),
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Badges Row (Points Pill + Rank Shield)
              Row(
                children: [
                  // 100 Poin Pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B55F5), Color(0xFF4C8DF5)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF6155F5).withValues(alpha: 0.32),
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
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.stars_rounded,
                            color: Colors.yellowAccent,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$userPoints Poin',
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
                          color:
                              const Color(0xFFF96E0D).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      isUserLeading
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
        const SizedBox(width: 12),

        // Right Column: User Avatar with Neon Blue Glow Ring
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6B55F5),
                Color(0xFF007DFE),
                Color(0xFF00C6FF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF007DFE).withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3.0),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(2.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                  ? Image.network(
                      userPhotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultUserAvatar(),
                    )
                  : _defaultUserAvatar(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _defaultUserAvatar() {
    return Container(
      color: const Color(0xFF0A192F),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: Color(0xFF4C8DF5),
          size: 50,
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET: PARTNER CARD (NAZILLA ANDIZ A) WITH BLURRED FLARE
  // ==========================================
  Widget _buildPartnerCard({
    required BuildContext context,
    required String partnerName,
    required String? partnerPhotoUrl,
    required int partnerPoints,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppColors.gradientPartnerBlue,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0088FF).withValues(alpha: 0.38),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background blur kanan agak keatas menggunakan lib/assets/tai/9785753 3.png
            Positioned(
              top: -50,
              right: -50,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Image.asset(
                  'lib/assets/tai/9785753 3.png',
                  width: 125,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Card Content
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
              child: Row(
                children: [
                  // Partner Avatar with Golden Yellow Ring
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFCC00),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFFFCC00).withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child:
                          partnerPhotoUrl != null && partnerPhotoUrl.isNotEmpty
                              ? Image.network(
                                  partnerPhotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _defaultPartnerAvatar(),
                                )
                              : _defaultPartnerAvatar(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Partner Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partnerName,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pasangan • $partnerPoints Poin 💕',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Button "Kunjungi →"
                  InkWell(
                    onTap: () => context.push('/partner-home'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.90),
                          width: 1.3,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Kunjungi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '→',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
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
          size: 28,
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET: 2-COLUMN MENU GRID
  // ==========================================
  Widget _buildMenuGrid(BuildContext context) {
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
                onTap: () => context.push('/books'),
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
                  'Modul Catatan Harian & Quotes segera hadir! ✨',
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
                  'Modul Tabungan & Keuangan Bersama segera hadir! 💰',
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
                  'Modul Resep Masakan Favorit segera hadir! 🥧',
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
                  'Modul Pengingat Hari Spesial & Jadwal segera hadir! ⏰',
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(child: SizedBox()), // Empty slot for clean alignment
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
    double? imageTop,
    double? imageBottom,
    double? imageRight = 0,
    double? imageLeft,
    double? imageWidth = 70,
    double? imageHeight,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2C5FF6).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Title on left
                Positioned(
                  left: 18,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF222222),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),

                // 3D Illustration on right with custom top, bottom, right, left, width, height
                Positioned(
                  top: imageTop,
                  bottom: imageBottom ?? (imageTop == null ? 0 : null),
                  right: imageRight,
                  left: imageLeft,
                  child: (imageTop == null && imageBottom == null)
                      ? Center(
                          child: Image.asset(
                            imagePath,
                            width: imageWidth,
                            height: imageHeight,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.widgets_rounded,
                              color: Color(0xFF6155F5),
                              size: 34,
                            ),
                          ),
                        )
                      : Image.asset(
                          imagePath,
                          width: imageWidth,
                          height: imageHeight,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.widgets_rounded,
                            color: Color(0xFF6155F5),
                            size: 34,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET: CONVEX BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomNavigationBar(BuildContext context) {
    return ConvexAppBar.builder(
      count: 2,
      backgroundColor: Colors.white,
      curveSize: 85,
      top: -30,
      height: 60,
      elevation: 6,
      shadowColor: const Color(0xFF6B4454).withValues(alpha: 0.12),
      initialActiveIndex: _currentNavIndex,
      itemBuilder: _CustomConvexTabBuilder(
        titles: const ['Beranda', 'Profil'],
      ),
      onTap: (int index) {
        setState(() => _currentNavIndex = index);
        if (index == 1) {
          _showProfileModal(context);
        }
      },
    );
  }

  // ==========================================
  // MODAL: USER PROFILE & LOGOUT
  // ==========================================
  void _showProfileModal(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUserProfile;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(26),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                user?.name ?? 'Pengguna',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Total Poin: ${user?.points ?? 0} Poin 🌟',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6155F5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFECEF),
                  foregroundColor: const Color(0xFFD32F2F),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Keluar (Sign Out)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await authProvider.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// CUSTOM CONVEX TAB BUILDER
// ==========================================
class _CustomConvexTabBuilder extends DelegateBuilder {
  final List<String> titles;

  _CustomConvexTabBuilder({
    required this.titles,
  });

  @override
  Widget build(BuildContext context, int index, bool active) {
    final title = titles[index];

    if (active) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF007DFE),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF007DFE).withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: index == 0
                  ? const CuteHomeIcon(
                      size: 25,
                      color: Colors.white,
                    )
                  : const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF007DFE),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (index == 0)
          const CuteHomeIcon(
            size: 24,
            color: Color(0xFF8E8E93),
          )
        else
          const Icon(
            Icons.person_outline_rounded,
            color: Color(0xFF8E8E93),
            size: 25,
          ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  @override
  bool fixed() => false;
}

// ==========================================
// CUSTOM WIDGET: CUTE HOME OUTLINE ICON
// ==========================================
class CuteHomeIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CuteHomeIcon({
    super.key,
    this.size = 25,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CuteHomeIconPainter(color: color),
    );
  }
}

class _CuteHomeIconPainter extends CustomPainter {
  final Color color;

  _CuteHomeIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Pentagonal outer house with rounded apex & joints
    path.moveTo(w * 0.15, h * 0.44);
    path.lineTo(w * 0.50, h * 0.12);
    path.lineTo(w * 0.85, h * 0.44);
    path.lineTo(w * 0.85, h * 0.88);

    // Bottom right to door
    path.lineTo(w * 0.63, h * 0.88);

    // Arched door
    path.lineTo(w * 0.63, h * 0.56);
    path.arcToPoint(
      Offset(w * 0.37, h * 0.56),
      radius: Radius.circular(w * 0.13),
      clockwise: false,
    );
    path.lineTo(w * 0.37, h * 0.88);

    // Door to bottom left
    path.lineTo(w * 0.15, h * 0.88);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CuteHomeIconPainter oldDelegate) =>
      oldDelegate.color != color;
}


import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_storage_service.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/gradient_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reminders/providers/reminder_provider.dart';
import '../../reminders/widgets/widgets.dart';
import '../widgets/cute_home_icon.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentNavIndex;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshProfile();
      if (!mounted) return;
      final reminderProvider =
          Provider.of<ReminderProvider>(context, listen: false);
      await reminderProvider.fetchReminders(
        partnerId: authProvider.partnerProfile?.id,
      );
      if (!mounted) return;
      final shouldShow = await reminderProvider.shouldShowDailyPopup();
      if (shouldShow &&
          reminderProvider.upcomingReminders.isNotEmpty &&
          mounted) {
        ReminderDetailBottomSheet.show(
          context,
          reminders: reminderProvider.upcomingReminders,
          isDailyPopup: true,
        );
      }
    });
  }

  Future<void> _showImageSourcePicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Ubah Foto Profil',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih sumber gambar profil Anda',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0088FF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFF0088FF),
                  size: 22,
                ),
              ),
              title: const Text(
                'Kamera',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: Color(0xFF1E293B),
                ),
              ),
              subtitle: const Text(
                'Ambil foto langsung dengan kamera',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPhoto(ImageSource.camera);
              },
            ),
            const Divider(height: 8, color: Color(0xFFF1F5F9)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 22,
                ),
              ),
              title: const Text(
                'Galeri',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: Color(0xFF1E293B),
                ),
              ),
              subtitle: const Text(
                'Pilih foto dari galeri HP Anda',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (file == null) return;

      setState(() => _isUploadingPhoto = true);

      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();

      final publicUrl = await SupabaseStorageService.uploadUserProfilePicture(
        bytes,
        fileExtension: ext.isNotEmpty ? ext : 'jpg',
      );

      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateProfilePhoto(publicUrl);

      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);

      if (success) {
        AppSnackBar.success(context, 'Foto profil berhasil diperbarui!');
      } else {
        AppSnackBar.error(
          context,
          authProvider.errorMessage ?? 'Gagal memperbarui foto profil',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        AppSnackBar.error(context, 'Gagal mengunggah foto: $e');
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar Aplikasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Kita Story?',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Keluar',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      if (mounted) {
        context.go('/login');
      }
    }
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

          // 2. Tab Content (0: Beranda, 1: Profil)
          if (_currentNavIndex == 0)
            _buildHomeContent(
              context: context,
              size: size,
              userName: userName,
              partnerName: partnerName,
              userPoints: userPoints,
              partnerPoints: partnerPoints,
              userPhotoUrl: currentUser?.photoUrl,
              partnerPhotoUrl: partnerUser?.photoUrl,
              isUserLeading: isUserLeading,
            )
          else
            _buildProfileContent(
              context: context,
              size: size,
              userName: userName,
              userPoints: userPoints,
              userPhotoUrl: currentUser?.photoUrl,
              isUserLeading: isUserLeading,
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // ==========================================
  // TAB 1: BERANDA CONTENT
  // ==========================================
  Widget _buildHomeContent({
    required BuildContext context,
    required Size size,
    required String userName,
    required String partnerName,
    required int userPoints,
    required int partnerPoints,
    required String? userPhotoUrl,
    required String? partnerPhotoUrl,
    required bool isUserLeading,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 3D Decorative Noodles Anchored at Top-Right Corner
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
        Positioned(
          top: size.height * 0.19,
          right: 1,
          child: Image.asset(
            'lib/assets/tai/9785753 9.png',
            width: 42,
            fit: BoxFit.contain,
          ),
        ),

        // Scrollable Body
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20.0, 64.0, 20.0, 115.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                _buildHeader(
                  context: context,
                  userName: userName,
                  userPoints: userPoints,
                  userPhotoUrl: userPhotoUrl,
                  isUserLeading: isUserLeading,
                ),
                const SizedBox(height: 40),

                // Partner Card
                _buildPartnerCard(
                  context: context,
                  partnerName: partnerName,
                  partnerPhotoUrl: partnerPhotoUrl,
                  partnerPoints: partnerPoints,
                ),
                const SizedBox(height: 28),

                // Section Title
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

                // 2-Column Menu Grid
                _buildMenuGrid(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: PROFIL CONTENT
  // ==========================================
  Widget _buildProfileContent({
    required BuildContext context,
    required Size size,
    required String userName,
    required int userPoints,
    required String? userPhotoUrl,
    required bool isUserLeading,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Pojok Kanan Atas: 9785753 3.png (Rotate -30 deg, Blurred)
        Positioned(
          top: -size.height * 0.04,
          right: -size.width * 0.05,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Transform.rotate(
              angle: -30 * math.pi / 180,
              child: Image.asset(
                'lib/assets/tai/9785753 3.png',
                width: 145,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // Pojok Kiri Bawah: 9785753 6.png (Rotate 10 deg, Blurred)
        Positioned(
          bottom: size.height * 0.06,
          left: -size.width * 0.06,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Transform.rotate(
              angle: 10 * math.pi / 180,
              child: Image.asset(
                'lib/assets/tai/9785753 6.png',
                width: 165,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // Scrollable Profile Content
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 115),
            child: Column(
              children: [
                // Avatar with Glowing Ring & Edit Pencil Button
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        onTap:
                            _isUploadingPhoto ? null : _showImageSourcePicker,
                        borderRadius: BorderRadius.circular(54),
                        child: GradientAvatar(
                          photoUrl: userPhotoUrl,
                          size: 106,
                          strokeWidth: 3.2,
                          gap: 4.0,
                          fallback: _defaultUserAvatar(),
                          child: _isUploadingPhoto
                              ? Container(
                                  color: const Color(0xFF0B192C),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),

                      // Yellow Edit Pencil Badge
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap:
                              _isUploadingPhoto ? null : _showImageSourcePicker,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB800),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFB800)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // User Name
                Text(
                  userName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Badges Row (Points Pill + Rank Shield)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
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
                const SizedBox(height: 36),

                // Button 1: Pengaturan Akun
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF0088FF),
                        Color(0xFF0775D5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0088FF).withValues(alpha: 0.38),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/edit-account'),
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Pengaturan Akun',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Button 2: Keluar Aplikasi
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFFFF3B30),
                        Color(0xFFE02424),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showLogoutDialog,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Keluar Aplikasi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat Datang 👋,',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF222222),
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
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
        GradientAvatar(
          photoUrl: userPhotoUrl,
          size: 85,
          strokeWidth: 2.8,
          gap: 3.5,
          previewTitle: userName,
          fallback: _defaultUserAvatar(),
        ),
      ],
    );
  }

  Widget _defaultUserAvatar() {
    return Container(
      color: const Color(0xFF0B192C),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: Color(0xFFFFCC00),
          size: 40,
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET: PARTNER CARD
  // ==========================================
  Widget _buildPartnerCard({
    required BuildContext context,
    required String partnerName,
    required String? partnerPhotoUrl,
    required int partnerPoints,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0088FF),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0088FF).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Top-right glowing blurred 3D tube decoration
            Positioned(
              top: -40,
              right: -14,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Image.asset(
                  'lib/assets/tai/9785753 3.png',
                  width: 110,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),

            // Main Row Content
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  // Partner Avatar with Yellow Ring (Long press to preview with Bouncy Animation)
                  BouncyPressable(
                    onTap: () => context.push('/partner-home'),
                    onLongPress: () {
                      showProfilePhotoPreview(
                        context,
                        photoUrl: partnerPhotoUrl,
                        title: partnerName,
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFCC00),
                          width: 2.2,
                        ),
                      ),
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
                  ),
                  const SizedBox(width: 12),

                  // Partner Name and Points
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          partnerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'lib/assets/homescreen assets/7068473 3.png',
                              width: 15,
                              height: 15,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.stars_rounded,
                                color: Color(0xFFFFCC00),
                                size: 15,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$partnerPoints Poin',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Button "Kunjungi →"
                  InkWell(
                    onTap: () => context.push('/partner-home'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Kunjungi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '→',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
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
          size: 26,
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
                onTap: () => context.push('/notes'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
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
                  'Modul Keuangan segera hadir! 💰',
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
                onTap: () => context.push('/recipes'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
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
                onTap: () => context.push('/reminders'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMenuCard(
                title: 'Liburan',
                imagePath:
                    'lib/assets/homescreen assets/Adobe Express - file 1.png',
                imageRight: -18,
                imageTop: null,
                imageBottom: -15,
                imageWidth: 110,
                onTap: () => AppSnackBar.info(
                  context,
                  'Modul Liburan & Travel segera hadir! ✈️🏖️',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildMenuCard(
                title: 'Riwayat',
                imagePath:
                    'lib/assets/homescreen assets/386ff72a-ca85-47aa-9eeb-f38d9ab4c154 2.png',
                imageRight: -20,
                imageTop: null,
                imageBottom: -15,
                imageWidth: 110,
                onTap: () => context.push('/history'),
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

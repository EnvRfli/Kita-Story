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
import '../../home/widgets/cute_home_icon.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

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
                _pickAndUpload(ImageSource.camera);
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
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
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
    final user = authProvider.currentUserProfile;
    final partner = authProvider.partnerProfile;

    final userName = user?.name.isNotEmpty == true
        ? user!.name
        : 'M. Rafli Agusta R';
    final userPoints = user?.points ?? 100;
    final partnerPoints = partner?.points ?? 0;
    final isUserLeading = userPoints >= partnerPoints;
    final userPhotoUrl = user?.photoUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Image (Same as Home)
          Image.asset(
            'lib/assets/background/Home.png',
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
            errorBuilder: (_, __, ___) => Container(
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

          // 2. Blurred 3D Tube Decorations
          // 2a. Pojok Kanan Atas: 9785753 3.png (Rotate -30 deg, Blurred)
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

          // 2b. Pojok Kiri Bawah: 9785753 6.png (Rotate 10 deg, Blurred)
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

          // 3. Scrollable Profile Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
              child: Column(
                children: [
                  // --- Avatar with Glowing Ring & Edit Pencil Button ---
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Avatar Ring
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
                            onTap: _isUploadingPhoto
                                ? null
                                : _showImageSourcePicker,
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

                  // --- User Name ---
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

                  // --- Badges Row (Points Pill + Rank Shield) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Points Pill
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

                      // Rank Shield Badge
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

                  // --- Action Button 1: Pengaturan Akun ---
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
                          color:
                              const Color(0xFF0088FF).withValues(alpha: 0.38),
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

                  // --- Action Button 2: Keluar Aplikasi ---
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
                          color:
                              const Color(0xFFFF3B30).withValues(alpha: 0.35),
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
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _defaultUserAvatar() {
    return Container(
      color: const Color(0xFF0B192C),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: Color(0xFFFFCC00),
          size: 50,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return ConvexAppBar.builder(
      count: 2,
      backgroundColor: Colors.white,
      curveSize: 85,
      top: -30,
      height: 60,
      elevation: 6,
      shadowColor: const Color(0xFF6B4454).withValues(alpha: 0.12),
      initialActiveIndex: 1,
      itemBuilder: _CustomProfileTabBuilder(
        titles: const ['Beranda', 'Profil'],
      ),
      onTap: (int index) {
        if (index == 0) {
          context.go('/home');
        }
      },
    );
  }
}

class _CustomProfileTabBuilder extends DelegateBuilder {
  final List<String> titles;

  _CustomProfileTabBuilder({required this.titles});

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
                  ? const CuteHomeIcon(size: 25, color: Colors.white)
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
        index == 0
            ? const CuteHomeIcon(
                size: 25,
                color: Color(0xFF9E9E9E),
              )
            : const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF9E9E9E),
                size: 26,
              ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }

  @override
  bool fixed() => true;
}

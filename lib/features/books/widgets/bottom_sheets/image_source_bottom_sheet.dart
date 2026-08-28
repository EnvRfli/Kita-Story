import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';

class ImageSourceBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;

  const ImageSourceBottomSheet({
    super.key,
    this.title = 'Pilih Sumber Gambar',
    this.subtitle = 'Ambil foto langsung dengan kamera atau pilih dari galeri.',
  });

  static Future<ImageSource?> show(
    BuildContext context, {
    String title = 'Pilih Sumber Gambar',
    String subtitle =
        'Ambil foto langsung dengan kamera atau pilih dari galeri.',
  }) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ImageSourceBottomSheet(
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B4454),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOption(
                  context,
                  icon: Icons.camera_alt_rounded,
                  title: 'Kamera',
                  subtitle: 'Ambil Foto',
                  color: const Color(0xFF3B6B8A),
                  source: ImageSource.camera,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildOption(
                  context,
                  icon: Icons.photo_library_rounded,
                  title: 'Galeri',
                  subtitle: 'Pilih Gambar',
                  color: const Color(0xFF6B4454),
                  source: ImageSource.gallery,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required ImageSource source,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(source),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEADBDF), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4454),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

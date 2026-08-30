import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Universal Bottom Sheet for Image Source Selection (Camera & Gallery)
class ImageSourcePickerBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String cameraLabel;
  final String cameraSubtitle;
  final String galleryLabel;
  final String gallerySubtitle;

  const ImageSourcePickerBottomSheet({
    super.key,
    this.title = 'Pilih Sumber Foto',
    this.subtitle = 'Pilih sumber gambar yang ingin Anda gunakan',
    this.cameraLabel = 'Kamera',
    this.cameraSubtitle = 'Ambil foto langsung dengan kamera',
    this.galleryLabel = 'Galeri',
    this.gallerySubtitle = 'Pilih foto dari galeri HP Anda',
  });

  /// Static helper to display the bottom sheet and return the selected [ImageSource]
  static Future<ImageSource?> show(
    BuildContext context, {
    String title = 'Pilih Sumber Foto',
    String? subtitle = 'Pilih sumber gambar yang ingin Anda gunakan',
    String cameraLabel = 'Kamera',
    String cameraSubtitle = 'Ambil foto langsung dengan kamera',
    String galleryLabel = 'Galeri',
    String gallerySubtitle = 'Pilih foto dari galeri HP Anda',
  }) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ImageSourcePickerBottomSheet(
        title: title,
        subtitle: subtitle,
        cameraLabel: cameraLabel,
        cameraSubtitle: cameraSubtitle,
        galleryLabel: galleryLabel,
        gallerySubtitle: gallerySubtitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
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

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),

            // Subtitle
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
            const SizedBox(height: 18),

            // 1. Camera Option
            ListTile(
              contentPadding: EdgeInsets.zero,
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
              title: Text(
                cameraLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: Color(0xFF1E293B),
                ),
              ),
              subtitle: Text(
                cameraSubtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const Divider(height: 8, color: Color(0xFFF1F5F9)),

            // 2. Gallery Option
            ListTile(
              contentPadding: EdgeInsets.zero,
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
              title: Text(
                galleryLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: Color(0xFF1E293B),
                ),
              ),
              subtitle: Text(
                gallerySubtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

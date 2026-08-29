import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CharacterAvatarPickerResult {
  final String? assetPath;
  final ImageSource? imageSource;

  CharacterAvatarPickerResult({this.assetPath, this.imageSource});
}

class CharacterAvatarPickerBottomSheet extends StatelessWidget {
  final String? currentPhotoUrl;

  const CharacterAvatarPickerBottomSheet({
    super.key,
    this.currentPhotoUrl,
  });

  static const List<String> systemAvatars = [
    'lib/assets/characters profile/Frame 1984078724.png',
    'lib/assets/characters profile/Frame 1984078725.png',
    'lib/assets/characters profile/Frame 1984078726.png',
    'lib/assets/characters profile/Frame 1984078727.png',
    'lib/assets/characters profile/Frame 1984078728.png',
    'lib/assets/characters profile/Frame 1984078729.png',
    'lib/assets/characters profile/Frame 1984078730.png',
    'lib/assets/characters profile/Frame 1984078731.png',
    'lib/assets/characters profile/Frame 1984078732.png',
    'lib/assets/characters profile/Frame 1984078733.png',
    'lib/assets/characters profile/Frame 1984078734.png',
    'lib/assets/characters profile/Frame 1984078735.png',
    'lib/assets/characters profile/Frame 1984078736.png',
    'lib/assets/characters profile/Frame 1984078737.png',
    'lib/assets/characters profile/Frame 1984078738.png',
    'lib/assets/characters profile/Frame 1984078739.png',
  ];

  static Future<CharacterAvatarPickerResult?> show(
    BuildContext context, {
    String? currentPhotoUrl,
  }) {
    return showModalBottomSheet<CharacterAvatarPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CharacterAvatarPickerBottomSheet(
        currentPhotoUrl: currentPhotoUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Subtitle
              const Text(
                'Pilih Avatar Karakter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih dari koleksi karakter sistem atau gunakan foto sendiri.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),

              // Preset Avatars Grid (4 columns)
              const Text(
                'Avatar Pilihan Sistem',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: systemAvatars.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final assetPath = systemAvatars[index];
                  final isSelected = currentPhotoUrl != null &&
                      (currentPhotoUrl == assetPath ||
                          currentPhotoUrl == 'asset:$assetPath');

                  return InkWell(
                    onTap: () {
                      Navigator.pop(
                        context,
                        CharacterAvatarPickerResult(assetPath: assetPath),
                      );
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF7A00)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 2.5 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xFFFF7A00).withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.person_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),

              // Custom Photo Options
              const Text(
                'Unggah Foto Sendiri',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Camera Option
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(
                          context,
                          CharacterAvatarPickerResult(
                            imageSource: ImageSource.camera,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: Color(0xFF0088FF),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Kamera',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Gallery Option
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(
                          context,
                          CharacterAvatarPickerResult(
                            imageSource: ImageSource.gallery,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.photo_library_rounded,
                              size: 18,
                              color: Color(0xFFFF7A00),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Galeri',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

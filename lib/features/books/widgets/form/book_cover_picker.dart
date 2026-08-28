import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BookCoverPicker extends StatelessWidget {
  final String? coverUrl;
  final Uint8List? coverBytes;
  final bool isUploading;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const BookCoverPicker({
    super.key,
    this.coverUrl,
    this.coverBytes,
    this.isUploading = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = (coverBytes != null && coverBytes!.isNotEmpty) ||
        (coverUrl != null && coverUrl!.isNotEmpty);

    return Stack(
      alignment: Alignment.topRight,
      children: [
        InkWell(
          onTap: isUploading ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFD6B9C3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isUploading
                ? _buildUploadingState()
                : hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: coverBytes != null
                            ? Image.memory(
                                coverBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : Image.network(
                                coverUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(),
                              ),
                      )
                    : _buildPlaceholder(),
          ),
        ),
        if (hasImage && !isUploading && onRemove != null)
          Padding(
            padding: const EdgeInsets.all(10),
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUploadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B6B8A)),
          ),
          SizedBox(height: 12),
          Text(
            'Mengunggah cover buku...',
            style: TextStyle(
              color: Color(0xFF6B4454),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, size: 42, color: Color(0xFF8D8D8D)),
        SizedBox(height: 8),
        Text(
          'Ketuk untuk memilih cover buku',
          style: TextStyle(
            color: Color(0xFF4A4A4A),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Mendukung kamera & galeri',
          style: TextStyle(
            color: Colors.black38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

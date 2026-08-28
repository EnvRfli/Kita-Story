import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';

class BookSnippetsSection extends StatelessWidget {
  final List<Map<String, dynamic>> snippets;
  final VoidCallback onAddSnippet;
  final Future<void> Function(String snippetId)? onDeleteSnippet;

  const BookSnippetsSection({
    super.key,
    required this.snippets,
    required this.onAddSnippet,
    this.onDeleteSnippet,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Book Snippets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4454),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B6B8A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${snippets.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B6B8A),
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onAddSnippet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B6B8A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_a_photo_rounded,
                          size: 14, color: Color(0xFF3B6B8A)),
                      SizedBox(width: 4),
                      Text(
                        'Tambah',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B6B8A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Snippets List / Empty View
          if (snippets.isEmpty)
            _buildEmptySnippets(context)
          else
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: snippets.length,
                itemBuilder: (context, index) {
                  final item = snippets[index];
                  return _buildSnippetCard(context, item);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySnippets(BuildContext context) {
    return InkWell(
      onTap: onAddSnippet,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFEADBDF),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 32,
              color: Color(0xFF9E7787),
            ),
            SizedBox(height: 8),
            Text(
              'Belum ada cuplikan foto / quotes',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4454),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Foto kutipan kata menarik, dialog lucu, atau ilustrasi buku.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnippetCard(BuildContext context, Map<String, dynamic> item) {
    final imageUrl = item['image_url'] as String? ?? '';
    final caption = item['caption'] as String?;
    final pageNumber = item['page_number'] as int?;

    return Container(
      width: 135,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADBDF), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4454).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSnippetDetailModal(context, item),
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFFAFAFA),
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.black26),
                    ),
                  ),
                ),
              ),

              // Bottom Gradient Overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(17),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
              ),

              // Page Number Badge (Top Left)
              if (pageNumber != null)
                Positioned(
                  top: 7,
                  left: 7,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bookmark_rounded,
                            size: 9, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          'Hal $pageNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Caption Preview (Bottom)
              if (caption != null && caption.isNotEmpty)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 7,
                  child: Text(
                    caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnippetDetailModal(
      BuildContext context, Map<String, dynamic> item) {
    final imageUrl = item['image_url'] as String? ?? '';
    final caption = item['caption'] as String?;
    final pageNumber = item['page_number'] as int?;
    final snippetId = item['id'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (pageNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B6B8A)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Halaman $pageNumber',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B6B8A),
                            ),
                          ),
                        )
                      else
                        const Text(
                          'Cuplikan Foto',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B4454),
                          ),
                        ),
                    ],
                  ),
                  if (snippetId != null && onDeleteSnippet != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFD9534F),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: ctx,
                          builder: (c) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text('Hapus Cuplikan?'),
                            content: const Text(
                              'Apakah Anda yakin ingin menghapus cuplikan foto ini?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(c).pop(false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD9534F),
                                ),
                                onPressed: () => Navigator.of(c).pop(true),
                                child: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          if (!context.mounted) return;
                          Navigator.of(ctx).pop();
                          await onDeleteSnippet!(snippetId);
                          if (!context.mounted) return;
                          AppSnackBar.success(
                            context,
                            'Cuplikan foto berhasil dihapus',
                          );
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Image Preview (Interactive Viewer / Zoomable)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  color: Colors.black,
                  child: InteractiveViewer(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Caption Bubble
              if (caption != null && caption.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEADBDF),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        size: 20,
                        color: Color(0xFF3B6B8A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          caption,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF6B4454),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

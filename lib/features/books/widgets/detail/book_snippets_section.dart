import 'package:flutter/material.dart';

class BookSnippetsSection extends StatelessWidget {
  final List<Map<String, dynamic>> snippets;
  final VoidCallback? onAddSnippet;
  final ValueChanged<Map<String, dynamic>> onSnippetTap;

  const BookSnippetsSection({
    super.key,
    required this.snippets,
    this.onAddSnippet,
    required this.onSnippetTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.image_outlined,
                    color: Color(0xFFFF7A00),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Galeri',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              if (onAddSnippet != null)
                InkWell(
                  onTap: onAddSnippet,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.add_rounded,
                      color: Color(0xFF64748B),
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Snippets List / Empty View (Fit-to-Content 2-Column Wrap)
          if (snippets.isEmpty)
            _buildEmptySnippets(context)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final spacing = 12.0;
                final runSpacing = 12.0;
                final itemWidth = (constraints.maxWidth - spacing) / 2;

                return Wrap(
                  spacing: spacing,
                  runSpacing: runSpacing,
                  children: List.generate(snippets.length, (index) {
                    final item = snippets[index];
                    return SizedBox(
                      width: itemWidth,
                      height: itemWidth * 1.05,
                      child: _buildSnippetCard(context, item),
                    );
                  }),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySnippets(BuildContext context) {
    return InkWell(
      onTap: onAddSnippet,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 8),
            Text(
              'Belum ada foto cuplikan buku',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Ketuk ikon + untuk menambah foto quotes atau momen berkesan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF94A3B8),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSnippetTap(item),
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.isNotEmpty
                    ? (imageUrl.startsWith('http')
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.black26,
                                ),
                              ),
                            ),
                          )
                        : Image.asset(
                            imageUrl.replaceFirst('asset:', ''),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.black26,
                                ),
                              ),
                            ),
                          ))
                    : Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.black26,
                          ),
                        ),
                      ),
              ),

              // Bottom Gradient Overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),

              // Page Number Badge (Top Left)
              if (pageNumber != null)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bookmark_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$pageNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Caption Preview (Bottom)
              if (caption != null && caption.trim().isNotEmpty)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 7,
                  child: Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

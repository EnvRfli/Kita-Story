import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/book_model.dart';

class BookDetailHeaderDelegate extends SliverPersistentHeaderDelegate {
  final BookModel book;
  final List<String> genres;
  final VoidCallback? onEditBook;
  final VoidCallback? onDeleteBook;
  final VoidCallback onBack;
  final double topPadding;
  final double screenWidth;

  // --- Content-Derived Component Dimensions ---
  static const double kCollapsedCoverHeight = 62.0;
  static const double kCollapsedCoverWidth = 44.0;
  static const double kCollapsedVerticalPadding = 12.0;
  static const double kButtonDiameter = 40.0;
  static const double kExpandedTopMargin = 52.0;
  static const double kCoverToTextGap = 14.0;
  static const double kExpandedTextSectionHeight = 125.0;

  BookDetailHeaderDelegate({
    required this.book,
    required this.genres,
    this.onEditBook,
    this.onDeleteBook,
    required this.onBack,
    required this.topPadding,
    required this.screenWidth,
  });

  /// Dynamic collapsed toolbar height derived directly from tallest collapsed element + padding
  double get collapsedToolbarHeight =>
      kCollapsedCoverHeight + (kCollapsedVerticalPadding * 2); // 62 + 24 = 86.0

  @override
  double get minExtent => topPadding + collapsedToolbarHeight;

  @override
  double get maxExtent {
    final coverStartWidth = (screenWidth * 0.42).clamp(150.0, 175.0);
    final coverStartHeight = coverStartWidth * 1.38;
    return topPadding +
        kExpandedTopMargin +
        coverStartHeight +
        kCoverToTextGap +
        kExpandedTextSectionHeight;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (onEditBook != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Edit Buku',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                subtitle: const Text(
                  'Ubah judul, penulis, cover, dan informasi buku',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onEditBook!();
                },
              ),
            if (onDeleteBook != null) ...[
              const Divider(height: 8, color: Color(0xFFF1F5F9)),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Hapus Buku',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFFEF4444),
                  ),
                ),
                subtitle: const Text(
                  'Hapus buku beserta seluruh data karakternya',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onDeleteBook!();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxScroll = maxExtent - minExtent;
    final progress =
        (shrinkOffset / (maxScroll > 0 ? maxScroll : 1.0)).clamp(0.0, 1.0);

    final hasCover = book.coverUrl != null && book.coverUrl!.trim().isNotEmpty;

    // --- Dynamic Interpolations for Morphing Layout ---
    final morphProgress = Curves.easeInOutCubic.transform(progress);
    final appBarAlpha = Curves.easeIn.transform(
      ((progress - 0.25) / 0.75).clamp(0.0, 1.0),
    );

    // Dynamic measurements based on device width & toolbar metrics
    final toolbarContentHeight = collapsedToolbarHeight;
    final buttonTop = topPadding + (toolbarContentHeight - kButtonDiameter) / 2;

    // 1. Cover Dimensions & Coordinates
    final coverStartWidth = (screenWidth * 0.42).clamp(150.0, 175.0);
    final coverStartHeight =
        coverStartWidth * 1.38; // Proportional 1:1.38 aspect ratio
    const coverEndWidth = kCollapsedCoverWidth;
    const coverEndHeight = kCollapsedCoverHeight;

    final coverStartX = (screenWidth - coverStartWidth) / 2;
    const coverEndX = 64.0;

    final coverStartY = topPadding + kExpandedTopMargin;
    final coverEndY = topPadding + (toolbarContentHeight - coverEndHeight) / 2;

    final currentCoverW =
        lerpDouble(coverStartWidth, coverEndWidth, morphProgress)!;
    final currentCoverH =
        lerpDouble(coverStartHeight, coverEndHeight, morphProgress)!;
    final currentCoverX = lerpDouble(coverStartX, coverEndX, morphProgress)!;
    final currentCoverY = lerpDouble(coverStartY, coverEndY, morphProgress)!;
    final currentCoverRadius = lerpDouble(16.0, 6.0, morphProgress)!;
    final currentCoverShadowAlpha = lerpDouble(0.20, 0.06, morphProgress)!;

    // 2. Text Section Coordinates
    const textStartX = 16.0;
    const textEndX = 118.0;
    final textStartY = coverStartY + coverStartHeight + kCoverToTextGap;
    final textEndY = topPadding + (toolbarContentHeight - 58.0) / 2;

    final currentTextX = lerpDouble(textStartX, textEndX, morphProgress)!;
    final currentTextY = lerpDouble(textStartY, textEndY, morphProgress)!;
    final currentTextW =
        screenWidth - currentTextX - (progress > 0.5 ? 64.0 : 16.0);

    final titleSize = lerpDouble(19.0, 13.5, morphProgress)!;
    final authorSize = lerpDouble(13.0, 11.0, morphProgress)!;

    return Container(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // 1. Rich Blurred Cover Artwork Background
          if (hasCover && progress < 0.98)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: maxExtent,
              child: Opacity(
                opacity: (1.0 - progress * 1.15).clamp(0.0, 1.0),
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred Cover Image
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),

                      // Multi-stop Gradient Melting Seamlessly into Page Background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x33000000),
                              Color(0x00F8F9FE),
                              Color(0x4DF8F9FE),
                              Color(0xCCF8F9FE),
                              Color(0xFFF8F9FE),
                              Color(0xFFF8F9FE),
                            ],
                            stops: [0.0, 0.20, 0.40, 0.58, 0.68, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 2. Sticky Background Header Surface (Smoothly fades from transparent to solid)
          if (appBarAlpha > 0.01)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: minExtent,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FE).withValues(alpha: appBarAlpha),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: appBarAlpha * 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Top Action Buttons: Back (Left) & 3-Dots Menu (Right)
          Positioned(
            top: buttonTop,
            left: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF1E293B),
                  size: 20,
                ),
                onPressed: onBack,
              ),
            ),
          ),

          // 3-Dots Action Button (Right)
          if (onEditBook != null || onDeleteBook != null)
            Positioned(
              top: buttonTop,
              right: 16,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF1E293B),
                    size: 20,
                  ),
                  onPressed: () => _showActionMenu(context),
                ),
              ),
            ),

          // 4. Animating Book Cover (Transitions from center to top-left appbar)
          Positioned(
            top: currentCoverY,
            left: currentCoverX,
            width: currentCoverW,
            height: currentCoverH,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(currentCoverRadius),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E293B)
                        .withValues(alpha: currentCoverShadowAlpha),
                    blurRadius: lerpDouble(20.0, 4.0, morphProgress)!,
                    offset: Offset(0, lerpDouble(8.0, 2.0, morphProgress)!),
                  ),
                  if (progress < 0.5)
                    BoxShadow(
                      color: const Color(0xFF5D5FEF)
                          .withValues(alpha: 0.10 * (1.0 - progress * 2)),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),
              child: hasCover
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(currentCoverRadius),
                      child: Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildCoverPlaceholder(currentCoverRadius),
                      ),
                    )
                  : _buildCoverPlaceholder(currentCoverRadius),
            ),
          ),

          // 5. Animating Title, Author, & Genre Section (Transitions cleanly to right of cover)
          Positioned(
            top: currentTextY,
            left: currentTextX,
            width: currentTextW > 0 ? currentTextW : 100,
            child: Column(
              crossAxisAlignment: progress > 0.5
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  book.title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: progress > 0.5 ? TextAlign.left : TextAlign.center,
                ),
                const SizedBox(height: 2),

                // Author
                if (book.author != null && book.author!.isNotEmpty)
                  Text(
                    book.author!,
                    style: TextStyle(
                      fontSize: authorSize,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign:
                        progress > 0.5 ? TextAlign.left : TextAlign.center,
                  ),

                // Genre Pills
                if (genres.isNotEmpty) ...[
                  SizedBox(height: lerpDouble(10.0, 4.0, progress)!),
                  if (progress < 0.6)
                    // Expanded Genre Pills (Centered Wrap)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: genres.map((genre) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientBiru,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gradientBlueStart
                                    .withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _capitalize(genre),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    // Collapsed Compact Genre Row (Right next to author in appbar)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: genres.map((genre) {
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientBiru,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _capitalize(genre),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPlaceholder(double radius) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 30,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant BookDetailHeaderDelegate oldDelegate) {
    return oldDelegate.book != book ||
        oldDelegate.genres != genres ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.screenWidth != screenWidth ||
        oldDelegate.onEditBook != onEditBook ||
        oldDelegate.onDeleteBook != onDeleteBook;
  }
}

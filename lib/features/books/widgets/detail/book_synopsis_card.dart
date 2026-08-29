import 'package:flutter/material.dart';

class BookSynopsisCard extends StatefulWidget {
  final String? synopsis;

  const BookSynopsisCard({
    super.key,
    this.synopsis,
  });

  @override
  State<BookSynopsisCard> createState() => _BookSynopsisCardState();
}

class _BookSynopsisCardState extends State<BookSynopsisCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasSynopsis =
        widget.synopsis != null && widget.synopsis!.trim().isNotEmpty;
    final text =
        hasSynopsis ? widget.synopsis! : 'Belum ada sinopsis untuk buku ini.';

    final isAccordion = hasSynopsis && text.length > 150;

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
          // Header (Tappable when text > 150 chars)
          InkWell(
            onTap: isAccordion
                ? () {
                    setState(() => _isExpanded = !_isExpanded);
                  }
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.menu_book_outlined,
                      color: Color(0xFFFF7A00),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Sinopsis',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                if (isAccordion)
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),

          // Animated Preview (5 Lines) & Full Content
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                text,
                maxLines: (!isAccordion || _isExpanded) ? null : 5,
                overflow: (!isAccordion || _isExpanded)
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

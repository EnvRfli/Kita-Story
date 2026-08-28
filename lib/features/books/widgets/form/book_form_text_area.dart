import 'package:flutter/material.dart';

class BookFormTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? label;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onScanPressed;
  final bool isScanning;

  const BookFormTextArea({
    super.key,
    required this.controller,
    required this.hintText,
    this.label,
    this.maxLines = 4,
    this.onChanged,
    this.onScanPressed,
    this.isScanning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || onScanPressed != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B4454),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (onScanPressed != null)
                InkWell(
                  onTap: isScanning ? null : onScanPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isScanning
                          ? const Color(0xFFFAFAFA)
                          : const Color(0xFF3B6B8A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF3B6B8A).withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isScanning) ...[
                          const SizedBox(
                            height: 12,
                            width: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF3B6B8A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Memindai AI...',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B6B8A),
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.document_scanner_rounded,
                              color: Color(0xFF3B6B8A), size: 14),
                          const SizedBox(width: 6),
                          const Text(
                            'Scan via AI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B6B8A),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B4454),
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFEADBDF), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFEADBDF), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide:
                    const BorderSide(color: Color(0xFF3B6B8A), width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

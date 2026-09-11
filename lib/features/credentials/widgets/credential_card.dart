import 'package:flutter/material.dart';
import '../models/credential_model.dart';

class CredentialCard extends StatelessWidget {
  final CredentialModel credential;
  final VoidCallback onTap;

  const CredentialCard({
    super.key,
    required this.credential,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getCategoryColors(credential.categoryName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Category & Subcategory Badges
                Row(
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.categoryBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        credential.categoryName,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: colors.categoryText,
                        ),
                      ),
                    ),
                    if (credential.subcategoryName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      // Subcategory Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.subcategoryBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          credential.subcategoryName,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: colors.subcategoryText,
                          ),
                        ),
                      ),
                    ],
                    if (credential.isSharedWithPartner) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 12,
                              color: Color(0xFF0088FF),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Bersama',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0088FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // 2. Title
                Text(
                  credential.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // 3. Dynamic Field Preview (if available)
                Builder(
                  builder: (context) {
                    final subtitle = _getSubtitle(credential);
                    if (subtitle == null || subtitle.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _CategoryColorPair _getCategoryColors(String category) {
    switch (category.toLowerCase()) {
      case 'aplikasi':
        return _CategoryColorPair(
          categoryBg: const Color(0xFFFCE7F3),
          categoryText: const Color(0xFFDB2777),
          subcategoryBg: const Color(0xFFFDF2F8),
          subcategoryText: const Color(0xFFEC4899),
        );
      case 'sosial media':
        return _CategoryColorPair(
          categoryBg: const Color(0xFFDBEAFE),
          categoryText: const Color(0xFF2563EB),
          subcategoryBg: const Color(0xFFEFF6FF),
          subcategoryText: const Color(0xFF3B82F6),
        );
      case 'keuangan':
        return _CategoryColorPair(
          categoryBg: const Color(0xFFCCFBF1),
          categoryText: const Color(0xFF0D9488),
          subcategoryBg: const Color(0xFFE6FFFA),
          subcategoryText: const Color(0xFF14B8A6),
        );
      case 'game':
        return _CategoryColorPair(
          categoryBg: const Color(0xFFEDE9FE),
          categoryText: const Color(0xFF7C3AED),
          subcategoryBg: const Color(0xFFF5F3FF),
          subcategoryText: const Color(0xFF8B5CF6),
        );
      default:
        return _CategoryColorPair(
          categoryBg: const Color(0xFFFFEDD5),
          categoryText: const Color(0xFFEA580C),
          subcategoryBg: const Color(0xFFFFF7ED),
          subcategoryText: const Color(0xFFF97316),
        );
    }
  }

  String? _getSubtitle(CredentialModel cred) {
    if (cred.fields.isNotEmpty) {
      final preferred = cred.fields.firstWhere(
        (f) =>
            !f.label.toLowerCase().contains('sandi') &&
            !f.label.toLowerCase().contains('pass') &&
            !f.label.toLowerCase().contains('pin'),
        orElse: () => cred.fields.first,
      );

      final isSecret = preferred.label.toLowerCase().contains('sandi') ||
          preferred.label.toLowerCase().contains('pass') ||
          preferred.label.toLowerCase().contains('pin');

      if (isSecret) {
        return '${preferred.label}: ••••••••';
      }
      return '${preferred.label}: ${preferred.value}';
    }

    if (cred.usernameId != null && cred.usernameId!.isNotEmpty) {
      return cred.usernameId;
    }
    if (cred.email != null && cred.email!.isNotEmpty) {
      return cred.email;
    }
    return null;
  }
}

class _CategoryColorPair {
  final Color categoryBg;
  final Color categoryText;
  final Color subcategoryBg;
  final Color subcategoryText;

  _CategoryColorPair({
    required this.categoryBg,
    required this.categoryText,
    required this.subcategoryBg,
    required this.subcategoryText,
  });
}

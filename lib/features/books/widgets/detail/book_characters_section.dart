import 'package:flutter/material.dart';

class BookCharactersSection extends StatelessWidget {
  final List<Map<String, dynamic>> characters;
  final ValueChanged<Map<String, dynamic>> onCharacterTap;
  final VoidCallback? onAddCharacter;

  const BookCharactersSection({
    super.key,
    required this.characters,
    required this.onCharacterTap,
    this.onAddCharacter,
  });

  static const List<Color> _avatarBgColors = [
    Color(0xFFFFEDD5), // Soft Orange
    Color(0xFFFCE7F3), // Soft Pink
    Color(0xFFEDE9FE), // Soft Purple
    Color(0xFFE0F2FE), // Soft Blue
    Color(0xFFDCFCE7), // Soft Green
    Color(0xFFFEF3C7), // Soft Amber
  ];

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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFFFF7A00),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Karakter',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              if (onAddCharacter != null)
                InkWell(
                  onTap: onAddCharacter,
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

          // 3-Column Fit-to-Content Grid / Wrap View
          if (characters.isEmpty)
            _buildEmptyCharacters()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final spacing = 10.0;
                final runSpacing = 14.0;
                final itemWidth = (constraints.maxWidth - (spacing * 2)) / 3;

                return Wrap(
                  spacing: spacing,
                  runSpacing: runSpacing,
                  children: List.generate(characters.length, (index) {
                    final char = characters[index];
                    final name = (char['name'] as String?) ?? 'Unnamed';
                    final role = (char['role'] as String?) ?? '';
                    final photoUrl = (char['photo_url'] as String?) ?? '';
                    final bgColor =
                        _avatarBgColors[index % _avatarBgColors.length];

                    return SizedBox(
                      width: itemWidth,
                      child: InkWell(
                        onTap: () => onCharacterTap(char),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Avatar Container
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: photoUrl.isNotEmpty
                                    ? ClipOval(
                                        child: photoUrl.startsWith('http')
                                            ? Image.network(
                                                photoUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    _buildFallbackAvatar(
                                                        name, index),
                                              )
                                            : Image.asset(
                                                photoUrl.replaceFirst(
                                                    'asset:', ''),
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    _buildFallbackAvatar(
                                                        name, index),
                                              ),
                                      )
                                    : _buildFallbackAvatar(name, index),
                              ),
                              const SizedBox(height: 8),

                              // Character Name
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),

                              // Character Role
                              if (role.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  role,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(String name, int index) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildEmptyCharacters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: const [
          Icon(
            Icons.people_outline_rounded,
            size: 36,
            color: Color(0xFFCBD5E1),
          ),
          SizedBox(height: 8),
          Text(
            'Belum ada karakter yang ditambahkan',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

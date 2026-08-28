import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BookCharactersSection extends StatelessWidget {
  final List<Map<String, dynamic>> characters;
  final ValueChanged<Map<String, dynamic>> onCharacterTap;
  final VoidCallback onAddCharacter;

  const BookCharactersSection({
    super.key,
    required this.characters,
    required this.onCharacterTap,
    required this.onAddCharacter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.people_outline_rounded, color: Color(0xFF6B4454), size: 20),
              SizedBox(width: 8),
              Text(
                'Characters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4454),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: characters.length + 1,
              itemBuilder: (context, index) {
                // Add character button
                if (index == characters.length) {
                  return InkWell(
                    onTap: onAddCharacter,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 76,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: AppColors.lavender.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: Color(0xFF6B4454)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tambah',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B4454),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final char = characters[index];
                final name = (char['name'] as String?) ?? 'Unnamed';
                final role = (char['role'] as String?) ?? '';
                final photoUrl = (char['photo_url'] as String?) ?? '';

                return InkWell(
                  onTap: () => onCharacterTap(char),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 76,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFADD8E6),
                              width: 2,
                            ),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: photoUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildInitial(name),
                                  ),
                                )
                              : _buildInitial(name),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B4454),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        if (role.isNotEmpty)
                          Text(
                            role,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3B6B8A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitial(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B4454),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookCharactersSection extends StatefulWidget {
  final List<Map<String, dynamic>> characters;
  final ValueChanged<Map<String, dynamic>> onCharacterTap;
  final VoidCallback? onAddCharacter;

  const BookCharactersSection({
    super.key,
    required this.characters,
    required this.onCharacterTap,
    this.onAddCharacter,
  });

  @override
  State<BookCharactersSection> createState() => _BookCharactersSectionState();
}

class _BookCharactersSectionState extends State<BookCharactersSection> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'all';
  bool _showSearch = false;

  static const List<Color> _avatarBgColors = [
    Color(0xFFFFEDD5), // Soft Orange
    Color(0xFFFCE7F3), // Soft Pink
    Color(0xFFEDE9FE), // Soft Purple
    Color(0xFFE0F2FE), // Soft Blue
    Color(0xFFDCFCE7), // Soft Green
    Color(0xFFFEF3C7), // Soft Amber
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _getRolePriority(String role) {
    final lower = role.toLowerCase().trim();
    if (lower.contains('main') ||
        lower.contains('utama') ||
        lower.contains('protagonis') ||
        lower.contains('lead')) {
      return 1;
    }
    if (lower.contains('side') ||
        lower.contains('sampingan') ||
        lower.contains('pendukung') ||
        lower.contains('figuran') ||
        lower.isEmpty) {
      return 99;
    }
    return 10;
  }

  (IconData icon, Color color, String label) _getRoleMeta(String role) {
    final lower = role.toLowerCase().trim();
    if (lower.contains('main') ||
        lower.contains('utama') ||
        lower.contains('protagonis') ||
        lower.contains('lead')) {
      return (
        Icons.stars_rounded,
        const Color(0xFFFF7A00),
        role.isEmpty ? 'Tokoh Utama' : role
      );
    } else if (lower.contains('detektif') ||
        lower.contains('detective') ||
        lower.contains('penyelidik')) {
      return (Icons.search_rounded, const Color(0xFF0088FF), role);
    } else if (lower.contains('inspektur') ||
        lower.contains('polisi') ||
        lower.contains('officer')) {
      return (Icons.shield_rounded, const Color(0xFF6366F1), role);
    } else if (lower.contains('korban') || lower.contains('victim')) {
      return (Icons.heart_broken_rounded, const Color(0xFFEC4899), role);
    } else if (lower.contains('pelaku') ||
        lower.contains('suspect') ||
        lower.contains('antagonis') ||
        lower.contains('villain')) {
      return (Icons.warning_amber_rounded, const Color(0xFFEF4444), role);
    } else if (lower.contains('fisikawan') ||
        lower.contains('profesor') ||
        lower.contains('ilmuwan') ||
        lower.contains('scientist') ||
        lower.contains('doktor')) {
      return (Icons.science_rounded, const Color(0xFF10B981), role);
    } else if (lower.contains('side') ||
        lower.contains('sampingan') ||
        lower.contains('pendukung') ||
        lower.contains('figuran')) {
      return (
        Icons.people_alt_rounded,
        const Color(0xFF64748B),
        role.isEmpty ? 'Karakter Pendukung' : role
      );
    }
    return (
      Icons.person_rounded,
      const Color(0xFF8B5CF6),
      role.isEmpty ? 'Lainnya' : role
    );
  }

  int _getAppearancePage(Map<String, dynamic> char) {
    final val = char['first_appearance_page'];
    if (val == null) return 999999;
    if (val is int) return val <= 0 ? 999999 : val;
    if (val is num) return val <= 0 ? 999999 : val.toInt();
    if (val is String) {
      final parsed = int.tryParse(val);
      return (parsed == null || parsed <= 0) ? 999999 : parsed;
    }
    return 999999;
  }

  int _compareCharacters(Map<String, dynamic> a, Map<String, dynamic> b) {
    final pageA = _getAppearancePage(a);
    final pageB = _getAppearancePage(b);
    if (pageA != pageB) {
      return pageA.compareTo(pageB); // Smallest page first (left to right)
    }
    final nameA = (a['name'] as String? ?? '').toLowerCase();
    final nameB = (b['name'] as String? ?? '').toLowerCase();
    return nameA.compareTo(nameB);
  }

  /// Groups and orders characters by narrative role priority, then by appearance page ascending
  Map<String, List<Map<String, dynamic>>> _getGroupedCharacters(
      List<Map<String, dynamic>> chars) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final char in chars) {
      final role = ((char['role'] as String?) ?? '').trim();
      final key = role.isNotEmpty ? role : 'Lainnya';
      grouped.putIfAbsent(key, () => []).add(char);
    }

    // Sort characters by appearance page ascending (then alphabetically) within each group
    for (final key in grouped.keys) {
      grouped[key]!.sort(_compareCharacters);
    }

    // Sort grouped keys by priority
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final prioA = _getRolePriority(a);
        final prioB = _getRolePriority(b);
        if (prioA != prioB) return prioA.compareTo(prioB);
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    return {for (final k in sortedKeys) k: grouped[k]!};
  }

  @override
  Widget build(BuildContext context) {
    final allCharacters = List<Map<String, dynamic>>.from(widget.characters)
      ..sort(_compareCharacters);
    final groupedAll = _getGroupedCharacters(allCharacters);
    final distinctRoles = groupedAll.keys.toList();

    final query = _searchController.text.trim().toLowerCase();
    final isSearching = query.isNotEmpty;

    // Filtered by Search Query
    final searchFilteredChars = isSearching
        ? (allCharacters.where((c) {
            final name = (c['name'] as String? ?? '').toLowerCase();
            final role = (c['role'] as String? ?? '').toLowerCase();
            return name.contains(query) || role.contains(query);
          }).toList()
          ..sort(_compareCharacters))
        : allCharacters;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
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
          // 1. Header Row (Title, Counter, Search Toggle, Add Button)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFFFF7A00),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Karakter',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (allCharacters.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${allCharacters.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (allCharacters.length > 3)
                      IconButton(
                        icon: Icon(
                          _showSearch
                              ? Icons.search_off_rounded
                              : Icons.search_rounded,
                          color: const Color(0xFF64748B),
                          size: 20,
                        ),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        onPressed: () {
                          setState(() {
                            _showSearch = !_showSearch;
                            if (!_showSearch) {
                              _searchController.clear();
                            }
                          });
                        },
                      ),
                    if (widget.onAddCharacter != null)
                      InkWell(
                        onTap: widget.onAddCharacter,
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
              ],
            ),
          ),

          // 2. Expandable Search Input
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  autofocus: true,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau peran karakter...',
                    hintStyle: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF94A3B8),
                              size: 16,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),

          // 3. Role Filter Chips (Edge-to-Edge Scrollable inside Card)
          if (!isSearching && distinctRoles.length > 1) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildRoleFilterChip(
                    label: 'Semua (${allCharacters.length})',
                    isSelected: _selectedRole == 'all',
                    onTap: () => setState(() => _selectedRole = 'all'),
                  ),
                  ...distinctRoles.map((role) {
                    final count = groupedAll[role]?.length ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _buildRoleFilterChip(
                        label: '$role ($count)',
                        isSelected: _selectedRole == role,
                        onTap: () => setState(() => _selectedRole = role),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // 4. Characters Content (Empty, Search Results, Filtered Role, or Grouped)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: _buildBodyContent(
              allCharacters: allCharacters,
              isSearching: isSearching,
              searchFilteredChars: searchFilteredChars,
              groupedAll: groupedAll,
              distinctRoles: distinctRoles,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent({
    required List<Map<String, dynamic>> allCharacters,
    required bool isSearching,
    required List<Map<String, dynamic>> searchFilteredChars,
    required Map<String, List<Map<String, dynamic>>> groupedAll,
    required List<String> distinctRoles,
  }) {
    if (allCharacters.isEmpty) {
      return _buildEmptyCharacters();
    } else if (isSearching) {
      return searchFilteredChars.isEmpty
          ? _buildNoSearchMatch()
          : _buildCharactersWrap(searchFilteredChars);
    } else if (_selectedRole != 'all') {
      return _buildCharactersWrap(groupedAll[_selectedRole] ?? []);
    } else if (distinctRoles.length <= 1) {
      return _buildCharactersWrap(allCharacters);
    } else {
      // Grouped By Role View (Main Characters at top, followed by other narrative roles)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: distinctRoles.map((role) {
          final roleChars = groupedAll[role] ?? [];
          if (roleChars.isEmpty) return const SizedBox.shrink();
          final meta = _getRoleMeta(role);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role Subheader Badge Pill
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: meta.$2.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(meta.$1, size: 14, color: meta.$2),
                      const SizedBox(width: 5),
                      Text(
                        '${meta.$3} (${roleChars.length})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: meta.$2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Characters Grid of this group
                _buildCharactersWrap(roleChars),
              ],
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildRoleFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0088FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0088FF).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCharactersWrap(List<Map<String, dynamic>> charList) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 10.0;
        final runSpacing = 14.0;
        final itemWidth = (constraints.maxWidth - (spacing * 2)) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: List.generate(charList.length, (index) {
            final char = charList[index];
            final name = (char['name'] as String?) ?? 'Unnamed';
            final role = (char['role'] as String?) ?? '';
            final photoUrl = (char['photo_url'] as String?) ?? '';
            final bgColor = _avatarBgColors[index % _avatarBgColors.length];

            return SizedBox(
              width: itemWidth,
              child: InkWell(
                onTap: () => widget.onCharacterTap(char),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar Container with #Page Badge at Top-Right
                      Builder(
                        builder: (_) {
                          final page = _getAppearancePage(char);
                          final hasPage = page > 0 && page < 999999;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Circular Avatar
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
                                                    _buildFallbackAvatar(name),
                                              )
                                            : Image.asset(
                                                photoUrl.replaceFirst(
                                                    'asset:', ''),
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    _buildFallbackAvatar(name),
                                              ),
                                      )
                                    : _buildFallbackAvatar(name),
                              ),

                              // Page Number Badge (#16, #72)
                              if (hasPage)
                                Positioned(
                                  top: -3,
                                  right: -5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF8A00),
                                          Color(0xFFFF6A00),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF8A00)
                                              .withValues(alpha: 0.40),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '#$page',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
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

                      // Character Role Subtitle
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
    );
  }

  Widget _buildFallbackAvatar(String name) {
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
      child: const Column(
        children: [
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

  Widget _buildNoSearchMatch() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 32,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 6),
          Text(
            'Tidak ada karakter yang cocok dengan "${_searchController.text.trim()}"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

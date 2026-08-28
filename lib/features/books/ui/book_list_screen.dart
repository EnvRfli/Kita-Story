import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/book_model.dart';
import '../providers/book_provider.dart';
import '../widgets/widgets.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'reading', 'completed', 'favorites'
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookProvider>(context, listen: false).fetchBooks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BookModel> _filterBooks(List<BookModel> books) {
    final query = _searchController.text.trim().toLowerCase();

    return books.where((book) {
      // 1. Search Query Filter
      if (query.isNotEmpty) {
        final title = book.title.toLowerCase();
        final author = (book.author ?? '').toLowerCase();
        if (!title.contains(query) && !author.contains(query)) {
          return false;
        }
      }

      // 2. Category Filter
      final isCompleted =
          book.totalPages > 0 && book.currentPage >= book.totalPages;
      final isReading = book.currentPage > 0 && !isCompleted;

      switch (_selectedFilter) {
        case 'reading':
          return isReading;
        case 'completed':
          return isCompleted;
        case 'favorites':
          return (book.personalRating ?? 0) >= 4;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar Akun',
          style: TextStyle(
            color: Color(0xFF6B4454),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Kita Story?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9534F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      body: Consumer<BookProvider>(
        builder: (context, provider, child) {
          final allBooks = provider.books;
          final filteredBooks = _filterBooks(allBooks);

          // Calculate statistics
          final completedCount = allBooks
              .where((b) => b.totalPages > 0 && b.currentPage >= b.totalPages)
              .length;
          final readingCount = allBooks
              .where((b) =>
                  b.currentPage > 0 &&
                  (b.totalPages == 0 || b.currentPage < b.totalPages))
              .length;

          return RefreshIndicator(
            onRefresh: provider.fetchBooks,
            color: const Color(0xFF3B6B8A),
            backgroundColor: Colors.white,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // 1. Pinned Pastel App Bar (No overlap on scroll)
                SliverAppBar(
                  pinned: true,
                  backgroundColor: const Color(0xFFFFF6F8),
                  elevation: 0,
                  scrolledUnderElevation: 1,
                  shadowColor: Colors.black.withValues(alpha: 0.05),
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF6B4454),
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      }
                    },
                  ),
                  centerTitle: true,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'My Bookshelf',
                        style: TextStyle(
                          color: Color(0xFF6B4454),
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B4454)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${allBooks.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B4454),
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _showSearchBar
                            ? Icons.search_off_rounded
                            : Icons.search_rounded,
                        color: const Color(0xFF6B4454),
                      ),
                      onPressed: () {
                        setState(() {
                          _showSearchBar = !_showSearchBar;
                          if (!_showSearchBar) {
                            _searchController.clear();
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFF6B4454),
                      ),
                      onPressed: _handleLogout,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),

                // 2. Interactive Stats Ribbon
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildStatsRow(
                          total: allBooks.length,
                          reading: readingCount,
                          completed: completedCount,
                        ),
                        const SizedBox(height: 16),

                        // Search Bar (Expandable)
                        if (_showSearchBar) ...[
                          _buildSearchField(),
                          const SizedBox(height: 14),
                        ],

                        // Filter Chips Row
                        _buildFilterChips(
                          total: allBooks.length,
                          reading: readingCount,
                          completed: completedCount,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // 3. Grid View / Empty State
                if (provider.isLoading && allBooks.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF3B6B8A)),
                      ),
                    ),
                  )
                else if (allBooks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyBooksView(
                      onAddPressed: () async {
                        await context.push('/add-book');
                        provider.fetchBooks();
                      },
                    ),
                  )
                else if (filteredBooks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildNoSearchResultsState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.58,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final book = filteredBooks[index];
                          return BookGridCard(
                            book: book,
                            onTap: () async {
                              await context.push('/book-detail', extra: book);
                              provider.fetchBooks();
                            },
                          );
                        },
                        childCount: filteredBooks.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3B6B8A),
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: const Text(
          'Tambah Buku',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        onPressed: () async {
          await context.push('/add-book');
          if (!context.mounted) return;
          Provider.of<BookProvider>(context, listen: false).fetchBooks();
        },
      ),
    );
  }

  Widget _buildStatsRow({
    required int total,
    required int reading,
    required int completed,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            label: 'Total Koleksi',
            value: '$total',
            icon: Icons.library_books_rounded,
            color: const Color(0xFF6B4454),
            isSelected: _selectedFilter == 'all',
            onTap: () => setState(() => _selectedFilter = 'all'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            label: 'Sedang Dibaca',
            value: '$reading',
            icon: Icons.auto_stories_rounded,
            color: const Color(0xFF3B6B8A),
            isSelected: _selectedFilter == 'reading',
            onTap: () => setState(() => _selectedFilter = 'reading'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            label: 'Tamat',
            value: '$completed',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF2E7D32),
            isSelected: _selectedFilter == 'completed',
            onTap: () => setState(() => _selectedFilter = 'completed'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFF3E4EA),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.12 : 0.03),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBDF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 13, color: Color(0xFF6B4454)),
        decoration: InputDecoration(
          hintText: 'Cari judul buku atau penulis...',
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF6B4454),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.black45,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips({
    required int total,
    required int reading,
    required int completed,
  }) {
    final filters = [
      {'id': 'all', 'label': 'Semua ($total)'},
      {'id': 'reading', 'label': 'Sedang Baca ($reading)'},
      {'id': 'completed', 'label': 'Selesai ($completed)'},
      {'id': 'favorites', 'label': 'Favorit ★'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF6B4454),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF6B4454),
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF6B4454)
                      : const Color(0xFFEADBDF),
                ),
              ),
              onSelected: (val) {
                if (val) setState(() => _selectedFilter = f['id']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4454).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Color(0xFF6B4454),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Buku Tidak Ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4454),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba ubah kata kunci pencarian atau filter status membaca Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedFilter = 'all';
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset Filter'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3B6B8A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

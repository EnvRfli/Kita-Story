import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/book_model.dart';
import '../repositories/book_repository.dart';
import '../providers/book_provider.dart';
import '../widgets/widgets.dart';

class BookListScreen extends StatefulWidget {
  final String? partnerId;
  final String? partnerName;
  final bool isReadOnly;

  const BookListScreen({
    super.key,
    this.partnerId,
    this.partnerName,
    this.isReadOnly = false,
  });

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final BookRepository _repository = BookRepository();

  String _selectedFilter = 'all'; // 'all', 'reading', 'completed'
  bool _showSearchBar = false;

  List<BookModel> _partnerBooks = [];
  bool _isLoadingPartner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isReadOnly) {
        _fetchPartnerBooks();
      } else {
        Provider.of<BookProvider>(context, listen: false).fetchBooks();
      }
    });
  }

  Future<void> _fetchPartnerBooks() async {
    setState(() => _isLoadingPartner = true);
    try {
      final books = await _repository.getBooks(targetUserId: widget.partnerId);
      if (mounted) {
        setState(() {
          _partnerBooks = books;
          _isLoadingPartner = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPartner = false);
      }
    }
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
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: widget.isReadOnly ? _buildPartnerBody() : _buildMyBooksBody(),
      floatingActionButton: widget.isReadOnly
          ? null
          : Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.fabGold,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.fabGold.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await context.push('/add-book');
                    if (!context.mounted) return;
                    Provider.of<BookProvider>(context, listen: false)
                        .fetchBooks();
                  },
                  customBorder: const CircleBorder(),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPartnerBody() {
    final allBooks = _partnerBooks;
    final filteredBooks = _filterBooks(allBooks);

    final completedCount = allBooks
        .where((b) => b.totalPages > 0 && b.currentPage >= b.totalPages)
        .length;
    final readingCount = allBooks
        .where((b) =>
            b.currentPage > 0 &&
            (b.totalPages == 0 || b.currentPage < b.totalPages))
        .length;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Sticky Top Header
          _buildStickyHeader(
            title: widget.partnerName != null &&
                    widget.partnerName!.trim().isNotEmpty
                ? 'Bacaan ${widget.partnerName}'
                : 'Bacaan Pasangan',
            allBooks: allBooks,
            readingCount: readingCount,
            completedCount: completedCount,
          ),

          // Scrollable Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchPartnerBooks,
              color: AppColors.primaryPurple,
              backgroundColor: Colors.white,
              child: _isLoadingPartner && allBooks.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryPurple,
                        ),
                      ),
                    )
                  : allBooks.isEmpty
                      ? const EmptyBooksView(
                          onAddPressed: null,
                        )
                      : filteredBooks.isEmpty
                          ? _buildNoSearchResultsState()
                          : GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                6,
                                16,
                                95,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.58,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: filteredBooks.length,
                              itemBuilder: (context, index) {
                                final book = filteredBooks[index];
                                return BookGridCard(
                                  book: book,
                                  onTap: () {
                                    context.push(
                                      '/book-detail',
                                      extra: {
                                        'book': book,
                                        'isReadOnly': true,
                                      },
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyBooksBody() {
    return Consumer<BookProvider>(
      builder: (context, provider, child) {
        final allBooks = provider.books;
        final filteredBooks = _filterBooks(allBooks);

        final completedCount = allBooks
            .where((b) => b.totalPages > 0 && b.currentPage >= b.totalPages)
            .length;
        final readingCount = allBooks
            .where((b) =>
                b.currentPage > 0 &&
                (b.totalPages == 0 || b.currentPage < b.totalPages))
            .length;

        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Sticky Top Header
              _buildStickyHeader(
                title: 'Bacaan',
                allBooks: allBooks,
                readingCount: readingCount,
                completedCount: completedCount,
              ),

              // Scrollable Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.fetchBooks,
                  color: AppColors.primaryPurple,
                  backgroundColor: Colors.white,
                  child: provider.isLoading && allBooks.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryPurple,
                            ),
                          ),
                        )
                      : allBooks.isEmpty
                          ? EmptyBooksView(
                              onAddPressed: () async {
                                await context.push('/add-book');
                                provider.fetchBooks();
                              },
                            )
                          : filteredBooks.isEmpty
                              ? _buildNoSearchResultsState()
                              : GridView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    6,
                                    16,
                                    95,
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.58,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: filteredBooks.length,
                                  itemBuilder: (context, index) {
                                    final book = filteredBooks[index];
                                    return BookGridCard(
                                      book: book,
                                      onTap: () async {
                                        await context.push(
                                          '/book-detail',
                                          extra: {
                                            'book': book,
                                            'isReadOnly': false,
                                          },
                                        );
                                        provider.fetchBooks();
                                      },
                                    );
                                  },
                                ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStickyHeader({
    required String title,
    required List<BookModel> allBooks,
    required int readingCount,
    required int completedCount,
  }) {
    return Container(
      color: const Color(0xFFFCFCFD),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top App Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF1E293B),
                      size: 22,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      }
                    },
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: -0.3,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      _showSearchBar
                          ? Icons.search_off_rounded
                          : Icons.search_rounded,
                      color: const Color(0xFF1E293B),
                      size: 22,
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
                ),
              ],
            ),
          ),

          // Expandable Search Bar
          if (_showSearchBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _buildSearchField(),
            ),

          // Sticky Filter Pills
          _buildFilterChips(
            total: allBooks.length,
            reading: readingCount,
            completed: completedCount,
          ),
        ],
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
      {'id': 'reading', 'label': 'Sedang Dibaca ($reading)'},
      {'id': 'completed', 'label': 'Selesai ($completed)'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _BouncyFilterChip(
              label: f['label'] as String,
              isSelected: isSelected,
              onTap: () {
                setState(() => _selectedFilter = f['id'] as String);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        autofocus: true,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: 'Cari judul buku atau penulis...',
          hintStyle: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    final query = _searchController.text.trim();
    final isSearching = query.isNotEmpty;

    IconData icon;
    String title;
    String message;

    if (isSearching) {
      icon = Icons.search_off_rounded;
      title = 'Tidak Ditemukan';
      message = 'Tidak ada buku yang cocok dengan "$query".';
    } else if (_selectedFilter == 'completed') {
      icon = Icons.check_circle_outline_rounded;
      title = 'Belum Ada Buku Selesai';
      message = 'Buku yang sudah selesai dibaca akan muncul di sini.';
    } else if (_selectedFilter == 'reading') {
      icon = Icons.menu_book_rounded;
      title = 'Belum Ada yang Sedang Dibaca';
      message = 'Buku yang sedang dalam proses membaca akan muncul di sini.';
    } else {
      icon = Icons.auto_stories_rounded;
      title = 'Belum Ada Buku';
      message = 'Belum ada buku pada kategori ini.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BouncyFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BouncyFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_BouncyFilterChip> createState() => _BouncyFilterChipState();
}

class _BouncyFilterChipState extends State<_BouncyFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF0088FF),
                      Color(0xFF0775D5),
                    ],
                  )
                : null,
            color: widget.isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: widget.isSelected
                ? null
                : Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? const Color(0xFF0088FF).withValues(alpha: 0.28)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: widget.isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: widget.isSelected ? Colors.white : const Color(0xFF64748B),
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

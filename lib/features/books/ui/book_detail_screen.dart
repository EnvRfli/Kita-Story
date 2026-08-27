import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/book_model.dart';
import '../repositories/book_repository.dart';

class BookDetailScreen extends StatefulWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final BookRepository _repository = BookRepository();
  bool _isLoading = true;

  List<String> _genres = [];
  List<Map<String, dynamic>> _characters = [];
  List<Map<String, dynamic>> _notes = [];

  // For bottom sheets
  final _progressController = TextEditingController();
  final _reviewController = TextEditingController();
  final _charNameController = TextEditingController();
  String _charRole = 'Main';
  final _notePageController = TextEditingController();
  final _noteTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      _repository.getBookGenres(widget.book.id),
      _repository.getBookCharacters(widget.book.id),
      _repository.getBookNotes(widget.book.id),
    ]);

    if (mounted) {
      setState(() {
        _genres = results[0] as List<String>;
        _characters = results[1] as List<Map<String, dynamic>>;
        _notes = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _reviewController.dispose();
    _charNameController.dispose();
    _notePageController.dispose();
    _noteTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B4454)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Library',
          style: TextStyle(color: Color(0xFF6B4454), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF6B4454)),
            onPressed: () {},
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildProgressSection(),
                  const SizedBox(height: 16),
                  _buildSynopsisSection(),
                  const SizedBox(height: 16),
                  _buildReviewSection(),
                  const SizedBox(height: 24),
                  _buildCharactersSection(),
                  const SizedBox(height: 24),
                  _buildNotesSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              height: 220,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: widget.book.coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(widget.book.coverUrl!, fit: BoxFit.cover),
                    )
                  : const Center(child: Icon(Icons.book, size: 60, color: Color(0xFFD6B9C3))),
            ),
            Positioned(
              right: -10,
              bottom: -10,
              child: InkWell(
                onTap: () {
                  context.push('/add-book', extra: widget.book).then((_) {
                    // Optional: refresh data on return
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
                  ),
                  child: const Icon(Icons.edit_outlined, color: Color(0xFF6B4454), size: 20),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 24),
        Text(
          widget.book.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        if (widget.book.author != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.book.author!,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8EC),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              int rating = widget.book.personalRating ?? 0;
              return Icon(
                index < rating ? Icons.favorite : Icons.favorite_border,
                color: const Color(0xFFFFD1DC),
                size: 24,
              );
            }),
          ),
        ),
        if (_genres.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _genres.map((g) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE6E6FA).withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(g, style: const TextStyle(fontSize: 12, color: Color(0xFF6B4454))),
            )).toList(),
          ),
        ]
      ],
    );
  }

  Widget _buildProgressSection() {
    double progress = widget.book.totalPages > 0 ? widget.book.currentPage / widget.book.totalPages : 0.0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('READING PROGRESS', style: TextStyle(fontSize: 10, color: Colors.black54, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Page ${widget.book.currentPage}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(' / ${widget.book.totalPages}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: _showProgressBottomSheet,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFF3E8EC), shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Color(0xFF6B4454), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFF3E8EC),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF98FB98)),
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(progress * 100).toInt()}% Read', style: const TextStyle(fontSize: 10, color: Color(0xFF98FB98))),
          ),
        ],
      ),
    );
  }

  Widget _buildSynopsisSection() {
    if (widget.book.synopsis == null || widget.book.synopsis!.isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.menu_book, color: Color(0xFF6B4454), size: 20),
              SizedBox(width: 8),
              Text('Synopsis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6B4454))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.book.synopsis!,
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.chat_bubble_outline, color: Color(0xFF3B6B8A), size: 20),
                  SizedBox(width: 8),
                  Text('Our Thoughts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6B4454))),
                ],
              ),
              InkWell(
                onTap: _showReviewBottomSheet,
                child: const Icon(Icons.edit_outlined, color: Color(0xFF3B6B8A), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF3B6B8A), width: 3))),
            child: Text(
              widget.book.personalReview?.isNotEmpty == true ? '"${widget.book.personalReview}"' : 'No review yet.',
              style: const TextStyle(fontSize: 14, color: Colors.black87, fontStyle: FontStyle.italic, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharactersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.people_outline, color: Color(0xFF6B4454), size: 20),
              SizedBox(width: 8),
              Text('Characters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6B4454))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _characters.length + 1,
              itemBuilder: (context, index) {
                if (index == _characters.length) {
                  return InkWell(
                    onTap: () => _showCharacterBottomSheet(null),
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Container(
                            height: 60, width: 60,
                            decoration: BoxDecoration(color: const Color(0xFFE6E6FA).withOpacity(0.5), shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: Color(0xFF6B4454)),
                          ),
                          const SizedBox(height: 8),
                          const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B4454))),
                        ],
                      ),
                    ),
                  );
                }
                final char = _characters[index];
                return InkWell(
                  onTap: () => _showCharacterBottomSheet(char),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Container(
                          height: 60, width: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF81D4FA), width: 2),
                            color: Colors.white,
                          ),
                          child: Center(child: Text(char['name'][0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                        ),
                        const SizedBox(height: 8),
                        Text(char['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        Text(char['role'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.black54)),
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

  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.sticky_note_2_outlined, color: Color(0xFF6B4454), size: 20),
              SizedBox(width: 8),
              Text('Shared Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6B4454))),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ...List.generate(_notes.length, (index) {
                final note = _notes[index];
                final color = index % 2 == 0 ? const Color(0xFF98FB98).withOpacity(0.3) : const Color(0xFFE6E6FA).withOpacity(0.5);
                return Container(
                  width: (MediaQuery.of(context).size.width - 48 - 16) / 2, // 2 columns
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('NOTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                          const Icon(Icons.push_pin_outlined, size: 14, color: Colors.black54),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('"${note['note_text']}" - pg ${note['page_number']}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                );
              }),
              InkWell(
                onTap: _showNoteBottomSheet,
                child: Container(
                  width: (MediaQuery.of(context).size.width - 48 - 16) / 2,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD1DC), width: 1.5, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFFFFD1DC), shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Color(0xFF6B4454)),
                      ),
                      const SizedBox(height: 8),
                      const Text('New Note', style: TextStyle(fontSize: 12, color: Color(0xFF6B4454))),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- Bottom Sheets Methods ---
  void _showProgressBottomSheet() {
    _progressController.text = widget.book.currentPage.toString();
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Update Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _progressController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current Page')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // To do: call BookProvider.updateBookProgress
                context.pop();
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }

  void _showReviewBottomSheet() {
    _reviewController.text = widget.book.personalReview ?? '';
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Our Thoughts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _reviewController, maxLines: 3, decoration: const InputDecoration(labelText: 'Review')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.pop();
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }

  void _showCharacterBottomSheet(Map<String, dynamic>? char) {
    _charNameController.text = char != null ? char['name'] : '';
    _charRole = char != null ? (char['role'] ?? 'Main') : 'Main';
    
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(char == null ? 'New Character' : 'Edit Character', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: _charNameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['Main', 'Side', 'Cameo'].map((role) {
                    bool sel = _charRole == role;
                    return ChoiceChip(
                      label: Text(role),
                      selected: sel,
                      onSelected: (v) => setModalState(() => _charRole = role),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Logic to save character via repository
                    context.pop();
                  },
                  child: const Text('Save'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      );
    });
  }

  void _showNoteBottomSheet() {
    _notePageController.clear();
    _noteTextController.clear();
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('New Note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _notePageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Page Number')),
            const SizedBox(height: 16),
            TextField(controller: _noteTextController, maxLines: 2, decoration: const InputDecoration(labelText: 'Note text')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Logic to save note
                context.pop();
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }
}

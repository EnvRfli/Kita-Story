import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/book_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookProvider>(context, listen: false).fetchBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookshelf'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Consumer<BookProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.books.isEmpty) {
            return const Center(
              child: Text(
                'No books yet. Add one!',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchBooks,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.books.length,
              itemBuilder: (context, index) {
                final book = provider.books[index];
                final progress = book.totalPages > 0 
                    ? book.currentPage / book.totalPages 
                    : 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.softPink.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: book.coverUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(book.coverUrl!, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.book, color: AppColors.softBlue),
                    ),
                    title: Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (book.author != null)
                          Text(book.author!, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.lavender,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mintGreen),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${book.currentPage} / ${book.totalPages} pages',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    onTap: () {
                      context.push('/book-detail', extra: book);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.softPink,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
        onPressed: () {
          context.push('/add-book');
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../widgets/widgets.dart';

class RecipeListScreen extends StatefulWidget {
  final String? partnerId;
  final String? partnerName;
  final bool isReadOnly;

  const RecipeListScreen({
    super.key,
    this.partnerId,
    this.partnerName,
    this.isReadOnly = false,
  });

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecipeProvider>(context, listen: false).fetchRecipes(
        targetUserId: widget.isReadOnly ? widget.partnerId : null,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RecipeModel> _filterRecipes(List<RecipeModel> recipes) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return recipes;

    return recipes.where((r) {
      final title = r.title.toLowerCase();
      final desc = (r.description ?? '').toLowerCase();
      final ingredientMatch =
          r.ingredients.any((i) => i.name.toLowerCase().contains(query));
      return title.contains(query) || desc.contains(query) || ingredientMatch;
    }).toList();
  }

  Future<void> _openAddRecipe() async {
    await context.push('/add-recipe');
    if (!mounted) return;
    context.read<RecipeProvider>().fetchRecipes();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isReadOnly
        ? (widget.partnerName != null && widget.partnerName!.trim().isNotEmpty
            ? 'Resep ${widget.partnerName}'
            : 'Resep Pasangan')
        : 'Resep';

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: Consumer<RecipeProvider>(
        builder: (_, provider, __) {
          final filteredList = _filterRecipes(provider.recipes);

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Header Bar
                Container(
                  color: const Color(0xFFFCFCFD),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      IconButton(
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
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balances leading back button
                    ],
                  ),
                ),

                // 2. Permanent Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: _buildSearchField(),
                ),

                // 3. 2-Column Grid / Empty State / No Search Results
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await provider.fetchRecipes(
                        targetUserId:
                            widget.isReadOnly ? widget.partnerId : null,
                      );
                    },
                    color: const Color(0xFFFF7A00),
                    backgroundColor: Colors.white,
                    child: provider.isLoading && provider.recipes.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF7A00),
                              ),
                            ),
                          )
                        : provider.recipes.isEmpty
                            ? _buildEmptyState()
                            : filteredList.isEmpty
                                ? _buildNoSearchResultsState()
                                : GridView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      95,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 14,
                                      crossAxisSpacing: 14,
                                      childAspectRatio: 0.70,
                                    ),
                                    itemCount: filteredList.length,
                                    itemBuilder: (ctx, index) {
                                      final recipe = filteredList[index];
                                      return RecipeCard(
                                        recipe: recipe,
                                        onTap: () async {
                                          await context.push(
                                            '/recipe-detail',
                                            extra: {
                                              'recipe': recipe,
                                              'isReadOnly': widget.isReadOnly,
                                            },
                                          );
                                          if (mounted) {
                                            provider.fetchRecipes(
                                              targetUserId: widget.isReadOnly
                                                  ? widget.partnerId
                                                  : null,
                                            );
                                          }
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
      ),
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
                  onTap: _openAddRecipe,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 58,
                color: Color(0xFFFF7A00),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum Ada Resep',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Simpan resep masakan favorit Anda bersama pasangan lengkap dengan bahan dan foto langkah memasaknya!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            if (!widget.isReadOnly) ...[
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _openAddRecipe,
                icon: const Icon(Icons.add_rounded,
                    size: 18, color: Colors.white),
                label: const Text(
                  'Buat Resep Pertama',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Cari resep atau bahan...',
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
            vertical: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
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
              child: const Icon(
                Icons.search_off_rounded,
                size: 38,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Resep Tidak Ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ada resep yang cocok dengan "${_searchController.text.trim()}".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

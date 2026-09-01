import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';

class RecipeDetailScreen extends StatelessWidget {
  final RecipeModel recipe;
  final bool isReadOnly;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.isReadOnly = false,
  });

  void _openImageViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Interactive Pinch & Zoom Viewer
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.5,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),

            // Top Close Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Resep',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontSize: 17,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus resep "${recipe.title}"?',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await Provider.of<RecipeProvider>(context, listen: false)
          .deleteRecipe(recipe.id);
      if (context.mounted) {
        if (success) {
          AppSnackBar.success(
            context,
            'Resep "${recipe.title}" berhasil dihapus!',
          );
          context.pop();
        } else {
          AppSnackBar.error(context, 'Gagal menghapus resep.');
        }
      }
    }
  }

  void _showOptionsBottomSheet(BuildContext context) {
    if (isReadOnly) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              title: const Text(
                'Edit Resep',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              subtitle: const Text(
                'Ubah judul, bahan, cara membuat, dan foto resep',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await context.push(
                  '/add-recipe',
                  extra: recipe,
                );
                if (context.mounted) {
                  context.pop();
                }
              },
            ),
            const Divider(height: 8, color: Color(0xFFF1F5F9)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              title: const Text(
                'Hapus Resep',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFFEF4444),
                ),
              ),
              subtitle: const Text(
                'Hapus resep beserta seluruh bahan dan langkahnya',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _handleDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        recipe.imageUrl != null && recipe.imageUrl!.trim().isNotEmpty;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Top Image (Tappable with Zoom Viewer)
                InkWell(
                  onTap: hasImage
                      ? () => _openImageViewer(context, recipe.imageUrl!)
                      : null,
                  child: SizedBox(
                    height: 320,
                    width: double.infinity,
                    child: hasImage
                        ? Image.network(
                            recipe.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                ),

                // Overlapping Sheet Body
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title (Direct on sheet)
                        Text(
                          recipe.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Description (Direct on sheet)
                        if (recipe.description?.isNotEmpty == true) ...[
                          Text(
                            recipe.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ] else
                          const SizedBox(height: 10),

                        // Badges Row (Pills with gradientBiru)
                        Row(
                          children: [
                            // Duration Pill (gradientBiru)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientBiru,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6155F5)
                                        .withValues(alpha: 0.28),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    recipe.cookingDuration,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Portion Pill (gradientBiru)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientBiru,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284F6)
                                        .withValues(alpha: 0.28),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people_alt_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    recipe.portionSize,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Card 1: Bahan-Bahan Card
                        _buildIngredientsCard(),
                        const SizedBox(height: 16),

                        // Card 2: Cara Membuat Card
                        _buildInstructionsCard(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Floating Top Action Bar
          Positioned(
            top: topPadding + 6,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                _buildCircleActionButton(
                  icon: Icons.arrow_back_rounded,
                  iconColor: const Color(0xFF1E293B),
                  onTap: () => context.pop(),
                ),

                // 3-Dots Action Button (Single Menu)
                if (!isReadOnly)
                  _buildCircleActionButton(
                    icon: Icons.more_vert_rounded,
                    iconColor: const Color(0xFF1E293B),
                    onTap: () => _showOptionsBottomSheet(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 1: Bahan-Bahan
  Widget _buildIngredientsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4454).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.format_list_bulleted_rounded,
            title: 'Bahan-Bahan',
          ),
          const SizedBox(height: 14),
          if (recipe.ingredients.isEmpty)
            const Text(
              'Tidak ada daftar bahan.',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            )
          else
            ...recipe.ingredients.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final ingredient = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Text(
                      '$idx. ',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        ingredient.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      ingredient.quantity,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFFFF7A00),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // Card 2: Cara Membuat
  Widget _buildInstructionsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4454).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.soup_kitchen_rounded,
            title: 'Cara Membuat',
          ),
          const SizedBox(height: 14),
          if (recipe.instructions.isEmpty)
            const Text(
              'Tidak ada langkah memasak.',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            )
          else
            ...recipe.instructions.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final step = entry.value;
              final hasStepImage =
                  step.imageUrl != null && step.imageUrl!.trim().isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$idx. ',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            step.text,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasStepImage) ...[
                      const SizedBox(height: 9),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: InkWell(
                          onTap: () => _openImageViewer(
                            context,
                            step.imageUrl!,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              children: [
                                Image.network(
                                  step.imageUrl!,
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox(),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.fullscreen_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF7A00), size: 19),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFFFF0F5),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          color: const Color(0xFF6B4454).withValues(alpha: 0.3),
          size: 64,
        ),
      ),
    );
  }
}

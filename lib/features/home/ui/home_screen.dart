import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kita Story Apps'),
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Text(
                'Discovery',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 28,
                    ),
              ),
            ),
            Expanded(
              child: GridView.count(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildFeatureCard(
                    context,
                    title: 'Book Tracker',
                    subtitle: 'Library & Notes',
                    icon: Icons.menu_book_rounded,
                    iconColor: AppColors.softPink,
                    onTap: () {
                      context.push('/books');
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    title: 'Travel Planning',
                    subtitle: 'Coming Soon',
                    icon: Icons.flight_takeoff_rounded,
                    iconColor: AppColors.softBlue,
                  ),
                  _buildFeatureCard(
                    context,
                    title: 'Savings',
                    subtitle: 'Coming Soon',
                    icon: Icons.savings_rounded,
                    iconColor: AppColors.mintGreen,
                  ),
                  _buildFeatureCard(
                    context,
                    title: 'Recipes',
                    subtitle: 'Coming Soon',
                    icon: Icons.restaurant_menu_rounded,
                    iconColor: AppColors.softYellow,
                    isHighlighted:
                        true, // Mimic the highlighted card from the reference image
                  ),
                  _buildFeatureCard(
                    context,
                    title: 'Movie List',
                    subtitle: 'Coming Soon',
                    icon: Icons.movie_creation_rounded,
                    iconColor: AppColors.lavender,
                  ),
                  _buildFeatureCard(
                    context,
                    title: 'Memories',
                    subtitle: 'Coming Soon',
                    icon: Icons.photo_library_rounded,
                    iconColor: AppColors.softPink,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
    bool isHighlighted = false,
  }) {
    final bgColor = isHighlighted ? AppColors.softYellow : Colors.white;
    final textColor =
        isHighlighted ? AppColors.textPrimary : AppColors.textPrimary;
    final subTextColor = isHighlighted
        ? AppColors.textPrimary.withValues(alpha: 0.7)
        : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.white.withValues(alpha: 0.3)
                      : iconColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: isHighlighted ? AppColors.textPrimary : iconColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      color: textColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: subTextColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

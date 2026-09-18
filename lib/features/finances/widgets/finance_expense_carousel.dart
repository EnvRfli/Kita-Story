import 'package:flutter/material.dart';
import '../models/finance_budget_model.dart';
import '../providers/finance_provider.dart';
import 'finance_category_donut_chart.dart';
import 'finance_budget_overview_slide.dart';

class FinanceExpenseCarousel extends StatefulWidget {
  final List<CategoryBreakdownItem> breakdown;
  final List<FinanceBudgetProgress> budgetProgressList;
  final String? targetUserId;
  final String? partnerName;
  final bool isPartnerMode;

  const FinanceExpenseCarousel({
    super.key,
    required this.breakdown,
    required this.budgetProgressList,
    this.targetUserId,
    this.partnerName,
    this.isPartnerMode = false,
  });

  @override
  State<FinanceExpenseCarousel> createState() => _FinanceExpenseCarouselState();
}

class _FinanceExpenseCarouselState extends State<FinanceExpenseCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Swipeable Carousel PageView
          SizedBox(
            // Sized appropriately to contain donut chart or budget list
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: IndexedStack(
                index: _currentPage,
                children: [
                  // Slide 0: Category Donut Chart
                  GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! < -100) {
                        setState(() => _currentPage = 1);
                      }
                    },
                    child: FinanceCategoryDonutChart(
                      breakdown: widget.breakdown,
                      showContainer: false,
                    ),
                  ),

                  // Slide 1: Budget Overview
                  GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! > 100) {
                        setState(() => _currentPage = 0);
                      }
                    },
                    child: FinanceBudgetOverviewSlide(
                      progressList: widget.budgetProgressList,
                      targetUserId: widget.targetUserId,
                      partnerName: widget.partnerName,
                      isPartnerMode: widget.isPartnerMode,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pagination Dots & Tab Indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(0, 'Kategori'),
                const SizedBox(width: 8),
                _buildDot(1, 'Budget'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, String label) {
    final isActive = _currentPage == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentPage = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0284F6).withValues(alpha: 0.12)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0xFF0284F6).withValues(alpha: 0.35)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 6 : 5,
              height: isActive ? 6 : 5,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF0284F6)
                    : const Color(0xFF94A3B8),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? const Color(0xFF0284F6)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/finances/providers/finance_provider.dart';
import 'package:kita_story/features/finances/widgets/finance_category_donut_chart.dart';

void main() {
  group('FinanceCategoryDonutChart Tests', () {
    testWidgets('renders empty state when breakdown is empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FinanceCategoryDonutChart(
              breakdown: [],
              periodLabel: 'Tgl 25 (25 Agu – 24 Sep)',
            ),
          ),
        ),
      );

      expect(find.text('Kategori Pengeluaran'), findsOneWidget);
      expect(find.text('Tgl 25 (25 Agu – 24 Sep)'), findsOneWidget);
      expect(find.text('Belum ada pengeluaran di periode ini'), findsOneWidget);
    });

    testWidgets('renders category list and percentages when breakdown is present',
        (tester) async {
      final breakdown = [
        const CategoryBreakdownItem(
          name: 'Makan dan Minum',
          amount: 300000,
          percentage: 60.0,
          color: Colors.orange,
        ),
        const CategoryBreakdownItem(
          name: 'Belanja',
          amount: 200000,
          percentage: 40.0,
          color: Colors.blue,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinanceCategoryDonutChart(
              breakdown: breakdown,
              periodLabel: 'Tgl 25 (25 Agu – 24 Sep)',
            ),
          ),
        ),
      );

      expect(find.text('Kategori Pengeluaran'), findsOneWidget);
      expect(find.text('Tgl 25 (25 Agu – 24 Sep)'), findsOneWidget);
      expect(find.text('Makan dan Minum'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('Belanja'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
    });
  });
}

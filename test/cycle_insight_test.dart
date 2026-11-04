import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/cycle/data/cycle_insight_content.dart';
import 'package:kita_story/features/cycle/models/cycle_summary.dart';
import 'package:kita_story/features/cycle/utils/cycle_calculator.dart';
import 'package:kita_story/features/cycle/utils/cycle_insight_builder.dart';
import 'package:kita_story/features/cycle/utils/cycle_role.dart';

final DateTime _today = DateTime(2026, 11, 4);

CycleSummary _summaryAt(int daysAfterStart, {bool allowRollover = true}) {
  return CycleCalculator.compute(
    lastPeriodStart: _today,
    cycleLength: 28,
    periodLength: 5,
    today: _today.add(Duration(days: daysAfterStart)),
    allowRollover: allowRollover,
  );
}

void main() {
  group('CycleInsightContent', () {
    test('every phase has exactly three owner and partner insights', () {
      for (final phase in CyclePhase.values) {
        final owner = CycleInsightContent.owner[phase];
        final partner = CycleInsightContent.partner[phase];

        expect(owner, isNotNull);
        expect(partner, isNotNull);
        expect(owner!.length, 3);
        expect(partner!.length, 3);
        expect(owner.every((text) => text.trim().isNotEmpty), isTrue);
        expect(partner.every((text) => text.trim().isNotEmpty), isTrue);
      }
    });

    test('late insights have three entries for each role', () {
      expect(CycleInsightContent.lateOwner.length, 3);
      expect(CycleInsightContent.latePartner.length, 3);
    });
  });

  group('CycleInsightBuilder', () {
    test('owner messages stay unique across three consecutive days', () {
      final messages = List.generate(
        3,
        (offset) => CycleInsightBuilder.build(
          summary: _summaryAt(offset),
          role: CycleRole.owner,
        ),
      );

      expect(messages.map((message) => message.body).toSet().length, 3);
      expect(messages[0].title, contains('Hari 1'));
      expect(messages[2].title, contains('Hari 3'));
    });

    test('owner late message mentions the delay', () {
      final summary = _summaryAt(29, allowRollover: false);
      final message = CycleInsightBuilder.build(
        summary: summary,
        role: CycleRole.owner,
      );

      expect(summary.isLate, isTrue);
      expect(message.title.toLowerCase(), contains('terlambat'));
      expect(message.body, contains('Terlambat 1 hari'));
    });

    test('monitor message uses partner insight and name', () {
      final message = CycleInsightBuilder.build(
        summary: _summaryAt(1),
        role: CycleRole.monitor,
        partnerName: 'Sari',
      );

      expect(message.title, contains('Siklus Sari'));
      expect(message.body, contains('Hari ke-2'));
      expect(
        CycleInsightContent.partner.values
            .expand((list) => list)
            .any((insight) => message.body.startsWith(insight)),
        isTrue,
      );
    });

    test('monitor message falls back to Pasangan without a name', () {
      final message = CycleInsightBuilder.build(
        summary: _summaryAt(0),
        role: CycleRole.monitor,
      );

      expect(message.title, contains('Pasangan'));
    });

    test('monitor late message uses late partner copy', () {
      final message = CycleInsightBuilder.build(
        summary: _summaryAt(29, allowRollover: false),
        role: CycleRole.monitor,
        partnerName: 'Sari',
      );

      expect(message.title, contains('Terlambat 1 hari'));
      expect(
        CycleInsightContent.latePartner.any(
          (insight) => message.body.startsWith(insight),
        ),
        isTrue,
      );
    });
  });
}

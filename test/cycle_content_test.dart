import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/cycle/data/cycle_content.dart';
import 'package:kita_story/features/cycle/models/cycle_summary.dart';

void main() {
  group('CycleContent', () {
    test('every phase has complete curated content', () {
      for (final phase in CyclePhase.values) {
        final content = CycleContent.forPhase(phase);
        expect(content.tagline, isNotEmpty, reason: '${phase.name} tagline');
        expect(content.hormoneSummary, isNotEmpty,
            reason: '${phase.name} hormone summary');
        expect(content.predictedMoods, isNotEmpty);
        expect(content.commonSymptoms, isNotEmpty);
        expect(content.energyLevel, inInclusiveRange(1, 5));
        expect(content.bodyTips, isNotEmpty);
        expect(content.foodTips, isNotEmpty);
        expect(content.activityTips, isNotEmpty);
        expect(content.avoidTips, isNotEmpty);
        expect(content.partnerTips, isNotEmpty);
        expect(content.partnerAvoidTips, isNotEmpty);
      }
    });

    test('phases map covers every enum value', () {
      expect(CycleContent.phases.keys.toSet(), CyclePhase.values.toSet());
    });
  });

  group('CycleContent.rotatingTips', () {
    test('changes the starting tip for consecutive days', () {
      final source = ['a', 'b', 'c', 'd', 'e', 'f'];

      final dayOne = CycleContent.rotatingTips(source, 1, count: 3);
      final dayTwo = CycleContent.rotatingTips(source, 2, count: 3);
      final dayThree = CycleContent.rotatingTips(source, 3, count: 3);

      expect(dayOne.first, isNot(dayTwo.first));
      expect(dayTwo.first, isNot(dayThree.first));
      expect(dayOne, ['a', 'b', 'c']);
      expect(dayTwo, ['b', 'c', 'd']);
    });

    test('wraps around the end of the list', () {
      final source = ['a', 'b', 'c'];
      expect(
        CycleContent.rotatingTips(source, 3, count: 3),
        ['c', 'a', 'b'],
      );
    });

    test('never returns more tips than the source has', () {
      final source = ['a', 'b'];
      expect(CycleContent.rotatingTips(source, 1, count: 5), hasLength(2));
    });

    test('handles empty sources', () {
      expect(CycleContent.rotatingTips(const [], 1), isEmpty);
    });
  });
}

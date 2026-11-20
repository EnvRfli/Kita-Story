import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/tetris/repositories/tetris_repository.dart';

void main() {
  group('TetrisRepository', () {
    test('builds the completed game-history payload with Tetris fields', () {
      final repository = TetrisRepository();

      expect(
        repository.buildResultPayload(
          runId: '11111111-1111-4111-8111-111111111111',
          userId: 'me',
          partnerId: 'partner',
          score: 12300,
          linesCleared: 42,
          levelReached: 5,
          piecesPlaced: 87,
          durationSeconds: 321,
        ),
        {
          'id': '11111111-1111-4111-8111-111111111111',
          'game_type': 'tetris',
          'difficulty': 'classic',
          'user_id': 'me',
          'partner_id': 'partner',
          'duration_seconds': 321,
          'score': 12300,
          'lines_cleared': 42,
          'level_reached': 5,
          'moves_count': 87,
          'status': 'completed',
        },
      );
    });

    test('ranks tied scores by lines, level, duration, then completion time',
        () {
      final entries = [
        TetrisLeaderboardEntry(
          userId: 'later',
          userName: 'Later',
          score: 5000,
          linesCleared: 40,
          levelReached: 5,
          piecesPlaced: 100,
          durationSeconds: 600,
          completedAt: DateTime.utc(2026, 11, 19, 12, 4),
        ),
        TetrisLeaderboardEntry(
          userId: 'shorter',
          userName: 'Shorter',
          score: 5000,
          linesCleared: 40,
          levelReached: 5,
          piecesPlaced: 100,
          durationSeconds: 580,
          completedAt: DateTime.utc(2026, 11, 19, 12, 5),
        ),
        TetrisLeaderboardEntry(
          userId: 'higher-level',
          userName: 'Higher level',
          score: 5000,
          linesCleared: 40,
          levelReached: 6,
          piecesPlaced: 100,
          durationSeconds: 700,
          completedAt: DateTime.utc(2026, 11, 19, 12, 6),
        ),
        TetrisLeaderboardEntry(
          userId: 'more-lines',
          userName: 'More lines',
          score: 5000,
          linesCleared: 45,
          levelReached: 4,
          piecesPlaced: 110,
          durationSeconds: 700,
          completedAt: DateTime.utc(2026, 11, 19, 12, 7),
        ),
        TetrisLeaderboardEntry(
          userId: 'earlier',
          userName: 'Earlier',
          score: 5000,
          linesCleared: 40,
          levelReached: 5,
          piecesPlaced: 100,
          durationSeconds: 600,
          completedAt: DateTime.utc(2026, 11, 19, 12, 3),
        ),
      ];

      final ranked = TetrisRepository.sortLeaderboard(entries);

      expect(
        ranked.map((entry) => entry.userId),
        ['more-lines', 'higher-level', 'shorter', 'earlier', 'later'],
      );
    });

    test('maps achievement milestones to one-time rewards', () {
      expect(
        TetrisRepository.milestonePoints,
        const {
          10: 2,
          25: 3,
          50: 5,
          100: 10,
          150: 15,
          200: 15,
        },
      );
      expect(TetrisRepository.rewardPointsFor(10), 2);
      expect(TetrisRepository.rewardPointsFor(200), 15);
      expect(TetrisRepository.rewardPointsFor(11), isNull);
      expect(TetrisRepository.maxAchievementPoints, 50);
    });

    test('derives every eligible achievement from cleared lines', () {
      expect(TetrisRepository.milestoneCandidatesFor(0), isEmpty);
      expect(TetrisRepository.milestoneCandidatesFor(9), isEmpty);
      expect(TetrisRepository.milestoneCandidatesFor(10), {10});
      expect(TetrisRepository.milestoneCandidatesFor(60), {10, 25, 50});
      expect(
        TetrisRepository.milestoneCandidatesFor(200),
        {10, 25, 50, 100, 150, 200},
      );
    });

    test('calculates points from claimed milestones', () {
      expect(TetrisRepository.calculatePointsForMilestones([]), 0);
      expect(TetrisRepository.calculatePointsForMilestones([10, 25]), 5);
      expect(
        TetrisRepository.calculatePointsForMilestones(
          TetrisRepository.milestoneCandidatesFor(200),
        ),
        50,
      );
    });

    test('filters out non-positive scores from the leaderboard', () {
      final entries = [
        TetrisLeaderboardEntry(
          userId: 'valid',
          userName: 'Valid',
          score: 100,
          linesCleared: 10,
          levelReached: 2,
          piecesPlaced: 20,
          durationSeconds: 60,
          completedAt: DateTime.utc(2026, 11, 19),
        ),
        TetrisLeaderboardEntry(
          userId: 'zero',
          userName: 'Zero',
          score: 0,
          linesCleared: 0,
          levelReached: 1,
          piecesPlaced: 0,
          durationSeconds: 5,
          completedAt: DateTime.utc(2026, 11, 19),
        ),
      ];

      final sorted = TetrisRepository.sortLeaderboard(entries);
      expect(sorted, hasLength(1));
      expect(sorted.first.userId, 'valid');
    });

    test('fetchClaimedMilestones returns empty set for an empty user id',
        () async {
      final repository = TetrisRepository();
      expect(await repository.fetchClaimedMilestones(''), isEmpty);
    });
  });
}

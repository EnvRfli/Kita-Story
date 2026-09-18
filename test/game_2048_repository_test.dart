import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/2048/repositories/game_2048_repository.dart';

void main() {
  group('Game2048Repository', () {
    test('builds the completed game-history payload with all 2048 fields', () {
      final repository = Game2048Repository();

      expect(
        repository.buildResultPayload(
          runId: '11111111-1111-4111-8111-111111111111',
          userId: 'me',
          partnerId: 'partner',
          score: 11248,
          highestTile: 2048,
          movesCount: 420,
          durationSeconds: 900,
        ),
        {
          'id': '11111111-1111-4111-8111-111111111111',
          'game_type': '2048',
          'difficulty': null,
          'user_id': 'me',
          'partner_id': 'partner',
          'duration_seconds': 900,
          'score': 11248,
          'highest_tile': 2048,
          'moves_count': 420,
          'status': 'completed',
        },
      );
    });

    test('ranks tied scores by tile, moves, duration, then completion time',
        () {
      final entries = [
        Game2048LeaderboardEntry(
          userId: 'later',
          userName: 'Later',
          score: 5000,
          highestTile: 2048,
          movesCount: 300,
          durationSeconds: 600,
          completedAt: DateTime.utc(2026, 9, 17, 12, 4),
        ),
        Game2048LeaderboardEntry(
          userId: 'shorter',
          userName: 'Shorter',
          score: 5000,
          highestTile: 2048,
          movesCount: 300,
          durationSeconds: 580,
          completedAt: DateTime.utc(2026, 9, 17, 12, 5),
        ),
        Game2048LeaderboardEntry(
          userId: 'fewer-moves',
          userName: 'Fewer moves',
          score: 5000,
          highestTile: 2048,
          movesCount: 280,
          durationSeconds: 700,
          completedAt: DateTime.utc(2026, 9, 17, 12, 6),
        ),
        Game2048LeaderboardEntry(
          userId: 'higher-tile',
          userName: 'Higher tile',
          score: 5000,
          highestTile: 4096,
          movesCount: 900,
          durationSeconds: 1200,
          completedAt: DateTime.utc(2026, 9, 17, 12, 7),
        ),
        Game2048LeaderboardEntry(
          userId: 'earlier',
          userName: 'Earlier',
          score: 5000,
          highestTile: 2048,
          movesCount: 300,
          durationSeconds: 600,
          completedAt: DateTime.utc(2026, 9, 17, 12, 3),
        ),
      ];

      final ranked = Game2048Repository.sortLeaderboard(entries);

      expect(
        ranked.map((entry) => entry.userId),
        ['higher-tile', 'fewer-moves', 'shorter', 'earlier', 'later'],
      );
    });

    test('derives each eligible milestone reward from the highest tile', () {
      expect(
        Game2048Repository.milestonePoints,
        const {
          128: 2,
          256: 3,
          512: 5,
          1024: 10,
          2048: 20,
          4096: 30,
          8192: 50,
          16384: 50,
        },
      );
      expect(
        Game2048Repository.milestoneCandidatesFor(2048),
        {128, 256, 512, 1024, 2048},
      );
    });

    test('sends no caller-controlled reward and supports later doublings', () {
      final repository = Game2048Repository();

      expect(
        repository.buildMilestoneClaimParams(32768),
        {'p_milestone': 32768},
      );
      expect(
        Game2048Repository.milestoneCandidatesFor(32768),
        {128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768},
      );
      expect(Game2048Repository.rewardPointsFor(32768), 50);
      expect(Game2048Repository.rewardPointsFor(300), isNull);
    });

    test('filters out non-positive scores from leaderboard', () {
      final entries = [
        Game2048LeaderboardEntry(
          userId: 'valid',
          userName: 'Valid',
          score: 100,
          highestTile: 16,
          movesCount: 20,
          durationSeconds: 60,
          completedAt: DateTime.utc(2026, 9, 17),
        ),
        Game2048LeaderboardEntry(
          userId: 'zero',
          userName: 'Zero',
          score: 0,
          highestTile: 2,
          movesCount: 0,
          durationSeconds: 5,
          completedAt: DateTime.utc(2026, 9, 17),
        ),
      ];

      final sorted = Game2048Repository.sortLeaderboard(entries);
      expect(sorted, hasLength(1));
      expect(sorted.first.userId, 'valid');
    });

    test('verifies milestone rewards sum up to 120 points for standard 7 milestones', () {
      const standardMilestones = [128, 256, 512, 1024, 2048, 4096, 8192];
      var total = 0;
      for (final m in standardMilestones) {
        total += Game2048Repository.rewardPointsFor(m) ?? 0;
      }
      expect(total, 120);
    });

    test('fetchClaimedMilestones returns empty set safely on empty userId', () async {
      final repository = Game2048Repository();
      expect(await repository.fetchClaimedMilestones(''), isEmpty);
    });

    test('calculatePointsForMilestones calculates accumulated points correctly', () {
      expect(Game2048Repository.calculatePointsForMilestones([]), 0);
      // 128 (2) + 256 (3) = 5
      expect(Game2048Repository.calculatePointsForMilestones([128, 256]), 5);
      // Candidates up to 2048: 128(2) + 256(3) + 512(5) + 1024(10) + 2048(20) = 40
      final candidates2048 = Game2048Repository.milestoneCandidatesFor(2048);
      expect(Game2048Repository.calculatePointsForMilestones(candidates2048), 40);
      // All 7 standard milestones = 120
      final all7 = [128, 256, 512, 1024, 2048, 4096, 8192];
      expect(Game2048Repository.calculatePointsForMilestones(all7), 120);
    });

    test('claimMilestones filters candidate milestones to only valid milestone tiles', () async {
      final repository = Game2048Repository();
      final claimed = await repository.claimMilestones({64, 128, 300, 2048});
      expect(claimed, {128, 2048});
    });
  });
}

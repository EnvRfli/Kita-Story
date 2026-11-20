import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';

@immutable
class TetrisResult {
  const TetrisResult({
    required this.id,
    required this.userId,
    required this.partnerId,
    required this.score,
    required this.linesCleared,
    required this.levelReached,
    required this.piecesPlaced,
    required this.durationSeconds,
    required this.completedAt,
  });

  final String id;
  final String userId;
  final String? partnerId;
  final int score;
  final int linesCleared;
  final int levelReached;
  final int piecesPlaced;
  final int durationSeconds;
  final DateTime completedAt;

  factory TetrisResult.fromJson(Map<String, dynamic> json) => TetrisResult(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        partnerId: json['partner_id'] as String?,
        score: (json['score'] as num?)?.toInt() ?? 0,
        linesCleared: (json['lines_cleared'] as num?)?.toInt() ?? 0,
        levelReached: (json['level_reached'] as num?)?.toInt() ?? 0,
        piecesPlaced: (json['moves_count'] as num?)?.toInt() ?? 0,
        durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
        completedAt: _completedAtFromJson(json),
      );

  static DateTime _completedAtFromJson(Map<String, dynamic> json) {
    final value = json['created_at'];
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.now();
  }
}

@immutable
class TetrisLeaderboardEntry {
  const TetrisLeaderboardEntry({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.score,
    required this.linesCleared,
    required this.levelReached,
    required this.piecesPlaced,
    required this.durationSeconds,
    required this.completedAt,
  });

  final String userId;
  final String? userName;
  final String? userPhotoUrl;
  final int score;
  final int linesCleared;
  final int levelReached;
  final int piecesPlaced;
  final int durationSeconds;
  final DateTime completedAt;
}

class TetrisRepository {
  TetrisRepository({SupabaseClient? client}) : _providedClient = client;

  static const Map<int, int> milestonePoints = {
    10: 2,
    25: 3,
    50: 5,
    100: 10,
    150: 15,
    200: 15,
  };

  static const int maxAchievementPoints = 50;

  final SupabaseClient? _providedClient;

  SupabaseClient get _client => _providedClient ?? SupabaseNetwork.client;

  Map<String, Object?> buildResultPayload({
    required String runId,
    required String userId,
    required String? partnerId,
    required int score,
    required int linesCleared,
    required int levelReached,
    required int piecesPlaced,
    required int durationSeconds,
  }) =>
      {
        'id': runId,
        'game_type': 'tetris',
        'difficulty': 'classic',
        'user_id': userId,
        'partner_id': partnerId,
        'duration_seconds': durationSeconds,
        'score': score,
        'lines_cleared': linesCleared,
        'level_reached': levelReached,
        'moves_count': piecesPlaced,
        'status': 'completed',
      };

  Future<TetrisResult> saveResult({
    required String runId,
    required int score,
    required int linesCleared,
    required int levelReached,
    required int piecesPlaced,
    required int durationSeconds,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('A signed-in user is required.');

    if (score <= 0) {
      return TetrisResult(
        id: runId,
        userId: userId,
        partnerId: null,
        score: score,
        linesCleared: linesCleared,
        levelReached: levelReached,
        piecesPlaced: piecesPlaced,
        durationSeconds: durationSeconds,
        completedAt: DateTime.now(),
      );
    }

    final partnerId = await _partnerIdFor(userId);
    final payload = buildResultPayload(
      runId: runId,
      userId: userId,
      partnerId: partnerId,
      score: score,
      linesCleared: linesCleared,
      levelReached: levelReached,
      piecesPlaced: piecesPlaced,
      durationSeconds: durationSeconds,
    );

    late final Map<String, dynamic> response;
    try {
      response =
          await _client.from('game_history').insert(payload).select().single();
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
      response =
          await _client.from('game_history').select().eq('id', runId).single();
    }
    return TetrisResult.fromJson(response);
  }

  Future<List<TetrisLeaderboardEntry>> fetchLeaderboard() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final partnerId = await _partnerIdFor(userId);
    var query = _client.from('game_history').select('''
          id,
          user_id,
          duration_seconds,
          score,
          lines_cleared,
          level_reached,
          moves_count,
          created_at
        ''').eq('game_type', 'tetris').gt('score', 0);
    query = partnerId == null || partnerId.isEmpty
        ? query.eq('user_id', userId)
        : query.or('user_id.eq.$userId,user_id.eq.$partnerId');

    final records = List<Map<String, dynamic>>.from(await query);
    if (records.isEmpty) return const [];

    final userIds = records
        .map((record) => record['user_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    final profileResponse = await _client
        .from('app_users')
        .select('id, name, photo_url')
        .inFilter('id', userIds);
    final profiles = <String, Map<String, dynamic>>{
      for (final profile in profileResponse as List)
        if (profile['id'] is String)
          profile['id'] as String: Map<String, dynamic>.from(profile),
    };

    return sortLeaderboard(
      records.map((record) {
        final profile = profiles[record['user_id'] as String?];
        final result = TetrisResult.fromJson(record);
        return TetrisLeaderboardEntry(
          userId: result.userId,
          userName: profile?['name'] as String?,
          userPhotoUrl: profile?['photo_url'] as String?,
          score: result.score,
          linesCleared: result.linesCleared,
          levelReached: result.levelReached,
          piecesPlaced: result.piecesPlaced,
          durationSeconds: result.durationSeconds,
          completedAt: result.completedAt,
        );
      }),
    );
  }

  Future<Set<int>> fetchClaimedMilestones(String userId) async {
    if (userId.isEmpty) return const {};
    try {
      final rows = await _client
          .from('game_achievements')
          .select('milestone')
          .eq('user_id', userId)
          .eq('game_type', 'tetris');
      return {
        for (final row in rows as List)
          if ((row['milestone'] as num?)?.toInt() case final int milestone)
            milestone,
      };
    } catch (error) {
      debugPrint('Tetris achievements are not available yet: $error');
      return const {};
    }
  }

  Future<Set<int>> claimMilestones(Set<int> candidates) async {
    final claimed = <int>{};
    final valid = candidates
        .where((value) => rewardPointsFor(value) != null)
        .toList()
      ..sort();

    for (final milestone in valid) {
      try {
        final response = await _client.rpc(
          'claim_tetris_milestone',
          params: {'p_milestone': milestone},
        );
        if (response == true) claimed.add(milestone);
      } catch (error) {
        debugPrint('Failed to claim Tetris milestone $milestone: $error');
        break;
      }
    }
    return claimed;
  }

  static int? rewardPointsFor(int milestone) => milestonePoints[milestone];

  static Set<int> milestoneCandidatesFor(int lines) => {
        for (final milestone in milestonePoints.keys)
          if (milestone <= lines) milestone,
      };

  static int calculatePointsForMilestones(Iterable<int> milestones) {
    var total = 0;
    for (final milestone in milestones) {
      total += rewardPointsFor(milestone) ?? 0;
    }
    return total;
  }

  static List<TetrisLeaderboardEntry> sortLeaderboard(
    Iterable<TetrisLeaderboardEntry> entries,
  ) {
    final validEntries = entries.where((entry) => entry.score > 0);
    final sorted = List<TetrisLeaderboardEntry>.from(validEntries)
      ..sort((left, right) {
        var comparison = right.score.compareTo(left.score);
        if (comparison != 0) return comparison;
        comparison = right.linesCleared.compareTo(left.linesCleared);
        if (comparison != 0) return comparison;
        comparison = right.levelReached.compareTo(left.levelReached);
        if (comparison != 0) return comparison;
        comparison = left.durationSeconds.compareTo(right.durationSeconds);
        if (comparison != 0) return comparison;
        comparison = left.completedAt.compareTo(right.completedAt);
        if (comparison != 0) return comparison;
        return left.userId.compareTo(right.userId);
      });
    return List.unmodifiable(sorted);
  }

  Future<String?> _partnerIdFor(String userId) async {
    final record = await _client
        .from('app_users')
        .select('partner_id')
        .eq('id', userId)
        .maybeSingle();
    return record?['partner_id'] as String?;
  }
}

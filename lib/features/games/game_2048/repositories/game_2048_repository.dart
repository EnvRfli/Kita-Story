import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';

class Game2048Result {
  const Game2048Result({
    required this.id,
    required this.userId,
    required this.partnerId,
    required this.score,
    required this.highestTile,
    required this.movesCount,
    required this.durationSeconds,
    required this.completedAt,
  });

  final String id;
  final String userId;
  final String? partnerId;
  final int score;
  final int highestTile;
  final int movesCount;
  final int durationSeconds;
  final DateTime completedAt;

  factory Game2048Result.fromJson(Map<String, dynamic> json) => Game2048Result(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        partnerId: json['partner_id'] as String?,
        score: (json['score'] as num?)?.toInt() ?? 0,
        highestTile: (json['highest_tile'] as num?)?.toInt() ?? 0,
        movesCount: (json['moves_count'] as num?)?.toInt() ?? 0,
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

class Game2048LeaderboardEntry {
  const Game2048LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.score,
    required this.highestTile,
    required this.movesCount,
    required this.durationSeconds,
    required this.completedAt,
  });

  final String userId;
  final String? userName;
  final String? userPhotoUrl;
  final int score;
  final int highestTile;
  final int movesCount;
  final int durationSeconds;
  final DateTime completedAt;
}

class Game2048Repository {
  Game2048Repository({SupabaseClient? client}) : _providedClient = client;

  static const Map<int, int> milestonePoints = {
    128: 2,
    256: 3,
    512: 5,
    1024: 10,
    2048: 20,
    4096: 30,
    8192: 50,
    16384: 50,
  };

  final SupabaseClient? _providedClient;

  SupabaseClient get _client => _providedClient ?? SupabaseNetwork.client;

  Map<String, Object?> buildResultPayload({
    required String userId,
    required String? partnerId,
    required int score,
    required int highestTile,
    required int movesCount,
    required int durationSeconds,
  }) =>
      {
        'game_type': '2048',
        'difficulty': null,
        'user_id': userId,
        'partner_id': partnerId,
        'duration_seconds': durationSeconds,
        'score': score,
        'highest_tile': highestTile,
        'moves_count': movesCount,
        'status': 'completed',
      };

  Future<Game2048Result> saveResult({
    required int score,
    required int highestTile,
    required int movesCount,
    required int durationSeconds,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('A signed-in user is required.');

    final partnerId = await _partnerIdFor(userId);
    final response = await _client
        .from('game_history')
        .insert(
          buildResultPayload(
            userId: userId,
            partnerId: partnerId,
            score: score,
            highestTile: highestTile,
            movesCount: movesCount,
            durationSeconds: durationSeconds,
          ),
        )
        .select()
        .single();

    await claimMilestones(milestoneCandidatesFor(highestTile));
    return Game2048Result.fromJson(response);
  }

  Future<List<Game2048LeaderboardEntry>> fetchLeaderboard() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final partnerId = await _partnerIdFor(userId);
    var query = _client.from('game_history').select('''
          id,
          user_id,
          duration_seconds,
          score,
          highest_tile,
          moves_count,
          created_at
        ''').eq('game_type', '2048');
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
        final result = Game2048Result.fromJson(record);
        return Game2048LeaderboardEntry(
          userId: result.userId,
          userName: profile?['name'] as String?,
          userPhotoUrl: profile?['photo_url'] as String?,
          score: result.score,
          highestTile: result.highestTile,
          movesCount: result.movesCount,
          durationSeconds: result.durationSeconds,
          completedAt: result.completedAt,
        );
      }),
    );
  }

  Future<Set<int>> claimMilestones(Set<int> candidates) async {
    final claimed = <int>{};
    for (final milestone in candidates.toList()..sort()) {
      if (rewardPointsFor(milestone) == null) continue;
      final response = await _client.rpc(
        'claim_2048_milestone',
        params: buildMilestoneClaimParams(milestone),
      );
      if (response == true) claimed.add(milestone);
    }
    return claimed;
  }

  Map<String, Object> buildMilestoneClaimParams(int milestone) {
    if (rewardPointsFor(milestone) == null) {
      throw ArgumentError.value(milestone, 'milestone', 'is not claimable');
    }
    return {'p_milestone': milestone};
  }

  static int? rewardPointsFor(int milestone) {
    final configuredReward = milestonePoints[milestone];
    if (configuredReward != null) return configuredReward;
    if (milestone >= 8192 && (milestone & (milestone - 1)) == 0) return 50;
    return null;
  }

  static Set<int> milestoneCandidatesFor(int highestTile) {
    final candidates = <int>{};
    for (var milestone = 128; milestone <= highestTile;) {
      if (rewardPointsFor(milestone) != null) candidates.add(milestone);
      if (milestone > highestTile ~/ 2) break;
      milestone *= 2;
    }
    return candidates;
  }

  static List<Game2048LeaderboardEntry> sortLeaderboard(
    Iterable<Game2048LeaderboardEntry> entries,
  ) {
    final sorted = List<Game2048LeaderboardEntry>.from(entries)
      ..sort((left, right) {
        var comparison = right.score.compareTo(left.score);
        if (comparison != 0) return comparison;
        comparison = right.highestTile.compareTo(left.highestTile);
        if (comparison != 0) return comparison;
        comparison = left.movesCount.compareTo(right.movesCount);
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

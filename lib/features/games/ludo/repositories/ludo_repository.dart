import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/services/activity_log_service.dart';
import '../models/ludo_game_state.dart';
import '../models/ludo_match_model.dart';
import '../models/ludo_player.dart';

class LudoRepository {
  final SupabaseClient? _providedClient;

  LudoRepository({SupabaseClient? client}) : _providedClient = client;

  SupabaseClient get _client => _providedClient ?? SupabaseNetwork.client;

  /// Create a new match invitation to partner
  Future<LudoMatchModel> createMatchInvitation({
    required String hostId,
    required String guestId,
    LudoColor hostColor = LudoColor.green,
    LudoColor guestColor = LudoColor.blue,
    required LudoGameState initialState,
  }) async {
    final payload = {
      'host_id': hostId,
      'guest_id': guestId,
      'host_color': hostColor.name,
      'guest_color': guestColor.name,
      'current_turn_color': hostColor.name,
      'status': 'invited',
      'game_state': initialState.toJson(),
    };

    final response = await _client
        .from('ludo_matches')
        .insert(payload)
        .select()
        .single();

    return LudoMatchModel.fromJson(response);
  }

  /// Accept an invitation
  Future<LudoMatchModel> acceptMatch(String matchId) async {
    final response = await _client
        .from('ludo_matches')
        .update({
          'status': 'accepted',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', matchId)
        .select()
        .single();

    return LudoMatchModel.fromJson(response);
  }

  /// Reject an invitation
  Future<void> rejectMatch(String matchId) async {
    await _client
        .from('ludo_matches')
        .update({
          'status': 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', matchId);
  }

  /// Update match state in database
  Future<void> updateMatchState({
    required String matchId,
    required LudoGameState state,
    required LudoColor currentTurnColor,
  }) async {
    try {
      await _client.from('ludo_matches').update({
        'game_state': state.toJson(),
        'current_turn_color': currentTurnColor.name,
        'status': state.isGameOver ? 'completed' : 'in_progress',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', matchId);
    } catch (e) {
      debugPrint('Warning: Failed to update ludo match state: $e');
    }
  }

  /// Fetch a match by id
  Future<LudoMatchModel?> fetchMatch(String matchId) async {
    try {
      final response = await _client
          .from('ludo_matches')
          .select()
          .eq('id', matchId)
          .maybeSingle();

      if (response == null) return null;
      return LudoMatchModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching ludo match: $e');
      return null;
    }
  }

  /// Record completed match to game_history and award points
  Future<void> recordGameHistory({
    required String matchId,
    required String userId,
    required String? partnerId,
    required bool isWinner,
    required int durationSeconds,
    required int totalMoves,
  }) async {
    try {
      final payload = {
        'id': matchId,
        'game_type': 'ludo',
        'difficulty': null,
        'user_id': userId,
        'partner_id': partnerId,
        'duration_seconds': durationSeconds,
        'score': isWinner ? 100 : 50,
        'moves_count': totalMoves,
        'status': 'completed',
      };

      try {
        await _client.from('game_history').insert(payload);
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow; // ignore duplicate key
      }

      // Gamification: Award points & record to activity ledger
      final points = isWinner ? 15 : 5;
      await ActivityLogService.recordActivityAndAddPoints(
        userId: userId,
        points: points,
        activityType: 'play_ludo',
        title: isWinner ? 'Menang Ludo' : 'Bermain Ludo',
        description: isWinner
            ? 'Memenangkan pertandingan Ludo bersama pasangan (+15 poin)'
            : 'Menyelesaikan permainan Ludo (+5 poin)',
        referenceId: matchId,
      );
    } catch (e) {
      debugPrint('Warning: Failed to record ludo history: $e');
    }
  }

  /// Fetch total Ludo wins for user
  Future<int> fetchTotalWins(String userId) async {
    try {
      final rows = await _client
          .from('game_history')
          .select('id, score')
          .eq('user_id', userId)
          .eq('game_type', 'ludo')
          .gte('score', 100);

      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }
}

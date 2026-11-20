import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/services/activity_log_service.dart';
import '../models/ludo_action.dart';
import '../models/ludo_game_state.dart';
import '../models/ludo_match_model.dart';
import '../models/ludo_player.dart';

class LudoActiveMatchException implements Exception {
  final String message;
  const LudoActiveMatchException([
    this.message = 'Masih ada permainan Ludo yang sedang berjalan.',
  ]);

  @override
  String toString() => message;
}

class LudoRepository {
  final SupabaseClient? _providedClient;

  LudoRepository({SupabaseClient? client}) : _providedClient = client;

  SupabaseClient get _client => _providedClient ?? SupabaseNetwork.client;

  static const _activeStatuses = ['accepted', 'in_progress'];

  /// Create a new match invitation to partner. Previous pending invites
  /// between the same couple are cancelled so only one snackbar is active.
  Future<LudoMatchModel> createMatchInvitation({
    required String hostId,
    required String guestId,
    LudoColor hostColor = LudoColor.green,
    LudoColor guestColor = LudoColor.blue,
    required LudoGameState initialState,
  }) async {
    final existing = await _client
        .from('ludo_matches')
        .select('id, host_id, guest_id, status')
        .or('host_id.eq.$hostId,guest_id.eq.$hostId');

    for (final row in (existing as List)) {
      final rowHost = row['host_id'] as String?;
      final rowGuest = row['guest_id'] as String?;
      final isSamePair = (rowHost == hostId && rowGuest == guestId) ||
          (rowHost == guestId && rowGuest == hostId);
      if (!isSamePair) continue;

      final status = row['status'] as String? ?? '';
      if (_activeStatuses.contains(status)) {
        throw const LudoActiveMatchException();
      }
      if (status == 'invited') {
        await _client.from('ludo_matches').update({
          'status': 'cancelled',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', row['id']);
      }
    }

    // A newer Ludo invitation supersedes older pending invites across games.
    try {
      await _client.rpc('game_supersede_pending_invites', params: {
        'p_user_a': hostId,
        'p_user_b': guestId,
      });
    } catch (e) {
      debugPrint('Warning: failed to supersede pending invites: $e');
    }

    final now = DateTime.now().toUtc();
    final payload = {
      'host_id': hostId,
      'guest_id': guestId,
      'host_color': hostColor.name,
      'guest_color': guestColor.name,
      'current_turn_color': hostColor.name,
      'status': 'invited',
      'game_state': initialState.toJson(),
      'game_version': 0,
      'expires_at': now.add(const Duration(minutes: 5)).toIso8601String(),
    };

    final response = await _client
        .from('ludo_matches')
        .insert(payload)
        .select()
        .single();

    return LudoMatchModel.fromJson(response);
  }

  /// Latest valid invitation for this guest, used when the app opens/reconnects.
  Future<LudoMatchModel?> fetchIncomingInvite(String guestId) async {
    try {
      final response = await _client
          .from('ludo_matches')
          .select()
          .eq('guest_id', guestId)
          .eq('status', 'invited')
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return LudoMatchModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching incoming ludo invite: $e');
      return null;
    }
  }

  /// Latest pending invite created by this host, used to restore waiting state.
  Future<LudoMatchModel?> fetchOutgoingInvite(String hostId) async {
    try {
      final response = await _client
          .from('ludo_matches')
          .select()
          .eq('host_id', hostId)
          .eq('status', 'invited')
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return LudoMatchModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching outgoing ludo invite: $e');
      return null;
    }
  }

  /// Accept an invitation. Returns null when it has already expired/handled.
  Future<LudoMatchModel?> acceptMatch(String matchId, String guestId) async {
    try {
      final response = await _client
          .from('ludo_matches')
          .update({
            'status': 'accepted',
            'accepted_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', matchId)
          .eq('guest_id', guestId)
          .eq('status', 'invited')
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .select()
          .maybeSingle();

      if (response == null) return null;
      return LudoMatchModel.fromJson(response);
    } catch (e) {
      debugPrint('Error accepting ludo invite: $e');
      return null;
    }
  }

  Future<void> rejectMatch(
    String matchId,
    String guestId, {
    String reason = 'rejected',
  }) async {
    await _client
        .from('ludo_matches')
        .update({
          'status': 'rejected',
          'abandon_reason': reason,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', matchId)
        .eq('guest_id', guestId)
        .eq('status', 'invited');
  }

  Future<void> cancelMatch(String matchId, String hostId) async {
    await _client
        .from('ludo_matches')
        .update({
          'status': 'cancelled',
          'abandon_reason': 'cancelled_by_host',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', matchId)
        .eq('host_id', hostId)
        .eq('status', 'invited');
  }

  Future<void> markExpired(String matchId) async {
    try {
      await _client
          .from('ludo_matches')
          .update({
            'status': 'expired',
            'abandon_reason': 'invite_expired',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', matchId)
          .eq('status', 'invited');
    } catch (e) {
      debugPrint('Error marking ludo invite expired: $e');
    }
  }

  /// Live stream of a match row. This is the authoritative game state.
  Stream<LudoMatchModel> watchMatch(String matchId) {
    return _client
        .from('ludo_matches')
        .stream(primaryKey: ['id'])
        .eq('id', matchId)
        .map((rows) => LudoMatchModel.fromJson(
              Map<String, dynamic>.from(rows.first),
            ));
  }

  /// Optimistic-concurrency write. Only the client holding the latest
  /// [expectedVersion] can advance the match.
  Future<LudoMatchModel?> applyMatchAction({
    required String matchId,
    required int expectedVersion,
    required LudoGameState state,
    required LudoColor currentTurnColor,
    required LudoAction action,
    required String? winnerId,
    required bool isCompleted,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final payload = {
        'game_state': state.toJson(),
        'current_turn_color': currentTurnColor.name,
        'status': isCompleted ? 'completed' : 'in_progress',
        'game_version': expectedVersion + 1,
        'last_action': action.toJson(),
        'winner_id': winnerId,
        'finished_at': isCompleted ? now.toIso8601String() : null,
        'updated_at': now.toIso8601String(),
      };

      final response = await _client
          .from('ludo_matches')
          .update(payload)
          .eq('id', matchId)
          .eq('game_version', expectedVersion)
          .select()
          .maybeSingle();

      if (response == null) return null;
      return LudoMatchModel.fromJson(response);
    } catch (e) {
      debugPrint('Warning: failed to apply ludo action: $e');
      return null;
    }
  }

  Future<void> abandonMatch({
    required String matchId,
    required String winnerId,
    required String reason,
  }) async {
    try {
      await _client.from('ludo_matches').update({
        'status': 'abandoned',
        'winner_id': winnerId,
        'finished_at': DateTime.now().toUtc().toIso8601String(),
        'abandon_reason': reason,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', matchId).inFilter('status', _activeStatuses);
    } catch (e) {
      debugPrint('Warning: failed to abandon ludo match: $e');
    }
  }

  /// Fetch a match by id.
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

  /// Record completed match to game_history and award points. This is
  /// idempotent per (user_id, match_id).
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
        'match_id': matchId,
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
        if (e.code == '23505') return;
        rethrow;
      }

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

  /// Fetch total Ludo wins for user.
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

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/services/activity_log_service.dart';
import '../models/uno_card.dart';
import '../models/uno_match_model.dart';

class UnoRepositoryException implements Exception {
  final String message;
  const UnoRepositoryException(this.message);

  @override
  String toString() => message;
}

class UnoActiveMatchException extends UnoRepositoryException {
  const UnoActiveMatchException([
    super.message = 'Masih ada permainan UNO yang sedang berjalan.',
  ]);
}

class UnoVersionConflictException extends UnoRepositoryException {
  const UnoVersionConflictException([
    super.message = 'State permainan sudah berubah. Menyinkronkan ulang...',
  ]);
}

class UnoStateSnapshot {
  final UnoMatchModel match;
  final List<UnoCard> myHand;

  const UnoStateSnapshot({required this.match, required this.myHand});

  factory UnoStateSnapshot.fromRpc(dynamic data) {
    final map = Map<String, dynamic>.from(data as Map);
    final publicState =
        Map<String, dynamic>.from(map['public_state'] as Map);
    final handJson = map['my_hand'];
    final hand = handJson is List
        ? handJson
            .whereType<Map>()
            .map((e) => UnoCard.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <UnoCard>[];
    return UnoStateSnapshot(
      match: UnoMatchModel.fromJson(publicState),
      myHand: hand,
    );
  }
}

class UnoDrawResult {
  final UnoStateSnapshot snapshot;
  final List<UnoCard> drawnCards;

  const UnoDrawResult({required this.snapshot, required this.drawnCards});
}

class UnoRepository {
  final SupabaseClient? _providedClient;

  UnoRepository({SupabaseClient? client}) : _providedClient = client;

  SupabaseClient get _client => _providedClient ?? SupabaseNetwork.client;

  static const _activeStatuses = ['in_progress', 'paused'];

  Future<dynamic> _rpc(String name, [Map<String, dynamic>? params]) async {
    try {
      return await _client.rpc(name, params: params);
    } on PostgrestException catch (e) {
      final message = e.message;
      if (message.contains('version_conflict')) {
        throw const UnoVersionConflictException();
      }
      if (message.contains('active_match')) {
        throw const UnoActiveMatchException();
      }
      throw UnoRepositoryException(_friendly(message));
    } catch (e) {
      if (e is UnoRepositoryException) rethrow;
      throw UnoRepositoryException('Gagal menghubungi server UNO: $e');
    }
  }

  String _friendly(String raw) {
    if (raw.contains('invite_expired')) {
      return 'Undangan sudah kedaluwarsa. Minta pasangan mengirim ulang ya.';
    }
    if (raw.contains('invite_not_found') || raw.contains('invite_not_pending')) {
      return 'Undangan sudah tidak tersedia.';
    }
    if (raw.contains('not_your_turn')) {
      return 'Sekarang bukan giliranmu.';
    }
    if (raw.contains('not_your_response')) {
      return 'Sekarang bukan giliranmu untuk merespons.';
    }
    if (raw.contains('card_not_in_hand')) {
      return 'Kartu itu sudah tidak ada di tanganmu.';
    }
    if (raw.contains('invalid_draw_response')) {
      return 'Balasan harus +1 sesuai warna atau +2.';
    }
    if (raw.contains('invalid_penalty_count')) {
      return 'Jumlah kartu penalti tidak cocok.';
    }
    if (raw.contains('catch_not_allowed')) {
      return 'Tidak ada UNO yang bisa ditangkap sekarang.';
    }
    if (raw.contains('uno_already_called')) {
      return 'Lawan sudah menekan UNO.';
    }
    if (raw.contains('uno_call_not_allowed')) {
      return 'Tombol UNO hanya bisa dipakai saat sisa 1 kartu.';
    }
    if (raw.contains('opponent_still_active')) {
      return 'Lawan masih terlihat aktif.';
    }
    if (raw.contains('not_paused')) {
      return 'Game belum dalam keadaan pause.';
    }
    if (raw.contains('match_not_found')) {
      return 'Pertandingan tidak ditemukan.';
    }
    return raw.replaceFirst('Exception: ', '');
  }

  // --- Invite lifecycle ----------------------------------------------------

  Future<UnoMatchModel> createMatchInvitation({
    required String hostId,
    required String guestId,
  }) async {
    final data = await _rpc('uno_create_invite', {
      'p_guest_id': guestId,
    });
    return UnoMatchModel.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  Future<UnoStateSnapshot> acceptMatch(String matchId) async {
    final data = await _rpc('uno_accept_invite', {
      'p_match_id': matchId,
    });
    return UnoStateSnapshot.fromRpc(data);
  }

  Future<UnoStateSnapshot> fetchState(String matchId) async {
    final data = await _rpc('uno_get_state', {
      'p_match_id': matchId,
    });
    return UnoStateSnapshot.fromRpc(data);
  }

  Future<UnoMatchModel?> fetchIncomingInvite(String guestId) async {
    try {
      final response = await _client
          .from('uno_matches')
          .select()
          .eq('guest_id', guestId)
          .eq('status', 'invited')
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return UnoMatchModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching incoming uno invite: $e');
      return null;
    }
  }

  Future<UnoMatchModel?> fetchOutgoingInvite(String hostId) async {
    try {
      final response = await _client
          .from('uno_matches')
          .select()
          .eq('host_id', hostId)
          .eq('status', 'invited')
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return UnoMatchModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching outgoing uno invite: $e');
      return null;
    }
  }

  Future<UnoMatchModel?> fetchActiveMatch(String userId) async {
    try {
      final response = await _client
          .from('uno_matches')
          .select()
          .or('host_id.eq.$userId,guest_id.eq.$userId')
          .inFilter('status', _activeStatuses)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return UnoMatchModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching active uno match: $e');
      return null;
    }
  }

  Future<UnoMatchModel?> fetchMatch(String matchId) async {
    try {
      final response = await _client
          .from('uno_matches')
          .select()
          .eq('id', matchId)
          .maybeSingle();
      if (response == null) return null;
      return UnoMatchModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching uno match: $e');
      return null;
    }
  }

  Future<void> rejectMatch(
    String matchId,
    String guestId, {
    String reason = 'rejected',
  }) async {
    await _client
        .from('uno_matches')
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
        .from('uno_matches')
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
          .from('uno_matches')
          .update({
            'status': 'expired',
            'abandon_reason': 'invite_expired',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', matchId)
          .eq('status', 'invited');
    } catch (e) {
      debugPrint('Error marking uno invite expired: $e');
    }
  }

  /// Live stream of the public match row.
  Stream<UnoMatchModel> watchMatch(String matchId) {
    return _client
        .from('uno_matches')
        .stream(primaryKey: ['id'])
        .eq('id', matchId)
        .map((rows) => UnoMatchModel.fromJson(
              Map<String, dynamic>.from(rows.first),
            ));
  }

  // --- Game actions --------------------------------------------------------

  Future<UnoStateSnapshot> playCard({
    required String matchId,
    required int expectedVersion,
    required String cardId,
    required Map<String, dynamic> publicState,
  }) async {
    final data = await _rpc('uno_play_card', {
      'p_match_id': matchId,
      'p_expected_version': expectedVersion,
      'p_card_id': cardId,
      'p_public_state': publicState,
    });
    return UnoStateSnapshot.fromRpc(data);
  }

  Future<UnoDrawResult> drawCards({
    required String matchId,
    required int expectedVersion,
    required int count,
    required Map<String, dynamic> publicState,
  }) async {
    final data = await _rpc('uno_draw_cards', {
      'p_match_id': matchId,
      'p_expected_version': expectedVersion,
      'p_count': count,
      'p_public_state': publicState,
    });
    final map = Map<String, dynamic>.from(data as Map);
    final snapshot = UnoStateSnapshot.fromRpc(map);
    final drawnJson = map['drawn_cards'];
    final drawn = drawnJson is List
        ? drawnJson
            .whereType<Map>()
            .map((e) => UnoCard.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <UnoCard>[];
    return UnoDrawResult(snapshot: snapshot, drawnCards: drawn);
  }

  Future<UnoMatchModel> endTurn({
    required String matchId,
    required int expectedVersion,
    required Map<String, dynamic> publicState,
  }) async {
    final data = await _rpc('uno_end_turn', {
      'p_match_id': matchId,
      'p_expected_version': expectedVersion,
      'p_public_state': publicState,
    });
    return UnoMatchModel.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  Future<UnoMatchModel> pause({
    required String matchId,
    required String action,
  }) async {
    final data = await _rpc('uno_pause', {
      'p_match_id': matchId,
      'p_action': action,
    });
    return UnoMatchModel.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  Future<UnoMatchModel> abandon({
    required String matchId,
    required String reason,
  }) async {
    final data = await _rpc('uno_abandon', {
      'p_match_id': matchId,
      'p_reason': reason,
    });
    return UnoMatchModel.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  Future<UnoStateSnapshot> rematch(String matchId) async {
    final data = await _rpc('uno_rematch', {
      'p_match_id': matchId,
    });
    return UnoStateSnapshot.fromRpc(data);
  }

  Future<void> heartbeat(String matchId) async {
    try {
      await _client.rpc('uno_heartbeat', params: {'p_match_id': matchId});
    } catch (e) {
      debugPrint('UNO heartbeat failed: $e');
    }
  }

  static Future<void> supersedePendingInvites({
    required String userA,
    required String userB,
    SupabaseClient? client,
  }) async {
    try {
      final c = client ?? SupabaseNetwork.client;
      await c.rpc('game_supersede_pending_invites', params: {
        'p_user_a': userA,
        'p_user_b': userB,
      });
    } catch (e) {
      debugPrint('Failed to supersede pending invites: $e');
    }
  }

  // --- History -------------------------------------------------------------

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
        'game_type': 'uno',
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
        activityType: 'play_uno',
        title: isWinner ? 'Menang UNO' : 'Bermain UNO',
        description: isWinner
            ? 'Memenangkan pertandingan UNO bersama pasangan (+15 poin)'
            : 'Menyelesaikan permainan UNO (+5 poin)',
        referenceId: matchId,
      );
    } catch (e) {
      debugPrint('Warning: Failed to record uno history: $e');
    }
  }

  Future<int> fetchTotalWins(String userId) async {
    try {
      final rows = await _client
          .from('game_history')
          .select('id, score')
          .eq('user_id', userId)
          .eq('game_type', 'uno')
          .gte('score', 100);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }
}

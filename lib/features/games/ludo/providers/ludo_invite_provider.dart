import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../models/ludo_match_model.dart';
import '../repositories/ludo_repository.dart';

class LudoInviteProvider extends ChangeNotifier {
  final SupabaseClient? _providedClient;
  final LudoRepository _repository;

  RealtimeChannel? _subscription;
  LudoMatchModel? _pendingInvite;
  String? _partnerName;
  String? _currentUserId;

  LudoInviteProvider({
    SupabaseClient? client,
    LudoRepository? repository,
  })  : _providedClient = client,
        _repository = repository ?? LudoRepository();

  SupabaseClient get _client => _providedClient ?? SupabaseNetwork.client;

  LudoMatchModel? get pendingInvite => _pendingInvite;
  String? get partnerName => _partnerName;
  String? get currentUserId => _currentUserId;
  bool get hasInvite => _pendingInvite != null;

  /// Start listening for partner invitations
  void initialize({
    required String currentUserId,
    required String? partnerId,
    String? partnerName,
  }) {
    _currentUserId = currentUserId;
    _partnerName = partnerName;

    _subscription?.unsubscribe();

    try {
      final channel = _client.channel('public:ludo_invites:$currentUserId');

      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'ludo_matches',
        callback: (payload) {
          final newRecord = payload.newRecord;
          if (newRecord.isEmpty) return;

          final guestId = newRecord['guest_id'] as String?;
          final status = newRecord['status'] as String?;

          if (guestId == currentUserId && status == 'invited') {
            _pendingInvite = LudoMatchModel.fromJson(newRecord);
            notifyListeners();
          } else if (_pendingInvite != null &&
              _pendingInvite!.id == newRecord['id'] &&
              status != 'invited') {
            _pendingInvite = null;
            notifyListeners();
          }
        },
      ).subscribe();

      _subscription = channel;
    } catch (e) {
      debugPrint('Warning: Failed to subscribe to ludo invites: $e');
    }
  }

  /// Accept the pending match invitation
  Future<LudoMatchModel?> acceptInvite() async {
    final invite = _pendingInvite;
    if (invite == null) return null;

    try {
      final accepted = await _repository.acceptMatch(invite.id);
      _pendingInvite = null;
      notifyListeners();
      return accepted;
    } catch (e) {
      debugPrint('Error accepting ludo invite: $e');
      return null;
    }
  }

  /// Reject the pending match invitation
  Future<void> rejectInvite() async {
    final invite = _pendingInvite;
    if (invite == null) return;

    try {
      await _repository.rejectMatch(invite.id);
      _pendingInvite = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error rejecting ludo invite: $e');
    }
  }

  /// Dismiss locally without rejecting
  void dismissInvite() {
    _pendingInvite = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

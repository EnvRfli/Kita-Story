import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../models/ludo_match_model.dart';
import '../repositories/ludo_repository.dart';

enum LudoInviteOutcomeType { accepted, rejected, expired, cancelled }

class LudoInviteOutcome {
  final LudoInviteOutcomeType type;
  final String partnerName;

  const LudoInviteOutcome({
    required this.type,
    required this.partnerName,
  });
}

class LudoInviteProvider extends ChangeNotifier {
  final SupabaseClient? _providedClient;
  final LudoRepository _repository;

  RealtimeChannel? _subscription;
  LudoMatchModel? _pendingInvite;
  LudoMatchModel? _outgoingInvite;
  LudoInviteOutcome? _outcome;
  String? _partnerName;
  String? _currentUserId;
  String? _initializedKey;
  Timer? _expiryTimer;

  LudoInviteProvider({
    SupabaseClient? client,
    LudoRepository? repository,
  })  : _providedClient = client,
        _repository = repository ?? LudoRepository();

  SupabaseClient get _client => _providedClient ?? SupabaseNetwork.client;

  LudoMatchModel? get pendingInvite => _pendingInvite;
  LudoMatchModel? get outgoingInvite => _outgoingInvite;
  LudoInviteOutcome? get outcome => _outcome;
  String? get partnerName => _partnerName;
  String? get currentUserId => _currentUserId;
  bool get hasInvite => _pendingInvite != null;

  /// Start listening for partner invitations and outgoing status changes.
  Future<void> initialize({
    required String currentUserId,
    required String? partnerId,
    String? partnerName,
  }) async {
    final key = '$currentUserId:${partnerId ?? ''}:${partnerName ?? ''}';
    if (_initializedKey == key) {
      _partnerName = partnerName;
      return;
    }
    _initializedKey = key;
    _currentUserId = currentUserId;
    _partnerName = partnerName;

    final oldSubscription = _subscription;
    _subscription = null;
    if (oldSubscription != null) {
      try {
        await _client.removeChannel(oldSubscription);
      } catch (_) {}
    }
    _expiryTimer?.cancel();

    await _loadExistingInvites();

    try {
      final channel = _client.channel('public:ludo_updates:$currentUserId');

      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'ludo_matches',
        callback: (payload) {
          final newRecord = payload.newRecord;
          if (newRecord.isEmpty) return;
          _handleMatchRecord(Map<String, dynamic>.from(newRecord));
        },
      ).subscribe();

      _subscription = channel;
    } catch (e) {
      debugPrint('Warning: failed to subscribe to ludo invites: $e');
    }
  }

  Future<void> _loadExistingInvites() async {
    final userId = _currentUserId;
    if (userId == null) return;

    final incoming = await _repository.fetchIncomingInvite(userId);
    final outgoing = await _repository.fetchOutgoingInvite(userId);

    _pendingInvite = incoming;
    _outgoingInvite = outgoing;
    _scheduleExpiry();
    notifyListeners();
  }

  void _handleMatchRecord(Map<String, dynamic> record) {
    final userId = _currentUserId;
    if (userId == null) return;

    final match = LudoMatchModel.fromJson(record);
    final guestId = record['guest_id'] as String?;
    final hostId = record['host_id'] as String?;
    final status = match.status;

    if (guestId == userId) {
      if (status == LudoMatchStatus.invited && !match.isExpired) {
        _pendingInvite = match;
        _scheduleExpiry();
        notifyListeners();
        return;
      }
      if (_pendingInvite?.id == match.id) {
        _pendingInvite = null;
        notifyListeners();
      }
    }

    if (hostId == userId) {
      if (status == LudoMatchStatus.invited && !match.isExpired) {
        _outgoingInvite = match;
        _scheduleExpiry();
        notifyListeners();
        return;
      }

      if (_outgoingInvite?.id == match.id) {
        _outgoingInvite = null;
        switch (status) {
          case LudoMatchStatus.accepted:
          case LudoMatchStatus.inProgress:
            _outcome = LudoInviteOutcome(
              type: LudoInviteOutcomeType.accepted,
              partnerName: _partnerName ?? 'Pasangan',
            );
            break;
          case LudoMatchStatus.rejected:
            _outcome = LudoInviteOutcome(
              type: LudoInviteOutcomeType.rejected,
              partnerName: _partnerName ?? 'Pasangan',
            );
            break;
          case LudoMatchStatus.cancelled:
            _outcome = LudoInviteOutcome(
              type: LudoInviteOutcomeType.cancelled,
              partnerName: _partnerName ?? 'Pasangan',
            );
            break;
          case LudoMatchStatus.expired:
            _outcome = LudoInviteOutcome(
              type: LudoInviteOutcomeType.expired,
              partnerName: _partnerName ?? 'Pasangan',
            );
            break;
          default:
            break;
        }
        notifyListeners();
      }
    }
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();

    DateTime? next;
    for (final match in [_pendingInvite, _outgoingInvite]) {
      if (match?.expiresAt == null) continue;
      final expiresAt = match!.expiresAt!;
      if (next == null || expiresAt.isBefore(next)) {
        next = expiresAt;
      }
    }
    if (next == null) return;

    final delay = next.difference(DateTime.now());
    if (delay.isNegative) {
      _handleExpired();
      return;
    }

    _expiryTimer = Timer(delay + const Duration(milliseconds: 250), () {
      _handleExpired();
    });
  }

  Future<void> _handleExpired() async {
    final now = DateTime.now();
    final pending = _pendingInvite;
    final outgoing = _outgoingInvite;

    if (pending != null &&
        pending.expiresAt != null &&
        now.isAfter(pending.expiresAt!)) {
      _pendingInvite = null;
      unawaited(_repository.markExpired(pending.id));
    }

    if (outgoing != null &&
        outgoing.expiresAt != null &&
        now.isAfter(outgoing.expiresAt!)) {
      _outgoingInvite = null;
      _outcome = LudoInviteOutcome(
        type: LudoInviteOutcomeType.expired,
        partnerName: _partnerName ?? 'Pasangan',
      );
      unawaited(_repository.markExpired(outgoing.id));
    }

    _scheduleExpiry();
    notifyListeners();
  }

  /// Accept the pending match invitation.
  Future<LudoMatchModel?> acceptInvite() async {
    final invite = _pendingInvite;
    final userId = _currentUserId;
    if (invite == null || userId == null) return null;

    final accepted = await _repository.acceptMatch(invite.id, userId);
    _pendingInvite = null;
    if (accepted == null) {
      unawaited(_repository.markExpired(invite.id));
    }
    notifyListeners();
    return accepted;
  }

  /// Reject the pending match invitation.
  Future<void> rejectInvite() async {
    final invite = _pendingInvite;
    final userId = _currentUserId;
    if (invite == null || userId == null) return;

    try {
      await _repository.rejectMatch(invite.id, userId);
      _pendingInvite = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error rejecting ludo invite: $e');
    }
  }

  /// Dismiss locally without rejecting.
  void dismissInvite() {
    _pendingInvite = null;
    notifyListeners();
  }

  LudoInviteOutcome? takeOutcome() {
    final outcome = _outcome;
    _outcome = null;
    return outcome;
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      unawaited(_client.removeChannel(subscription));
    }
    super.dispose();
  }
}

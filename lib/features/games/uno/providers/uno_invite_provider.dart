import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../models/uno_match_model.dart';
import '../repositories/uno_repository.dart';

enum UnoInviteOutcomeType { accepted, rejected, expired, cancelled }

class UnoInviteOutcome {
  final UnoInviteOutcomeType type;
  final String partnerName;

  const UnoInviteOutcome({required this.type, required this.partnerName});
}

class UnoInviteProvider extends ChangeNotifier {
  final SupabaseClient? _providedClient;
  final UnoRepository _repository;

  RealtimeChannel? _subscription;
  UnoMatchModel? _pendingInvite;
  UnoMatchModel? _outgoingInvite;
  UnoInviteOutcome? _outcome;
  String? _partnerName;
  String? _currentUserId;
  String? _initializedKey;
  Timer? _expiryTimer;

  UnoInviteProvider({SupabaseClient? client, UnoRepository? repository})
      : _providedClient = client,
        _repository = repository ?? UnoRepository();

  SupabaseClient get _client => _providedClient ?? SupabaseNetwork.client;

  UnoMatchModel? get pendingInvite => _pendingInvite;
  UnoMatchModel? get outgoingInvite => _outgoingInvite;
  UnoInviteOutcome? get outcome => _outcome;
  String? get partnerName => _partnerName;
  String? get currentUserId => _currentUserId;
  bool get hasInvite => _pendingInvite != null;

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
      final channel = _client.channel('public:uno_updates:$currentUserId');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'uno_matches',
        callback: (payload) {
          final newRecord = payload.newRecord;
          if (newRecord.isEmpty) return;
          _handleMatchRecord(Map<String, dynamic>.from(newRecord));
        },
      ).subscribe();
      _subscription = channel;
    } catch (e) {
      debugPrint('Warning: failed to subscribe to uno invites: $e');
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

    final match = UnoMatchModel.fromJson(record);
    final guestId = record['guest_id'] as String?;
    final hostId = record['host_id'] as String?;
    final status = match.status;

    if (guestId == userId) {
      if (status == UnoMatchStatus.invited && !match.isExpired) {
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
      if (status == UnoMatchStatus.invited && !match.isExpired) {
        _outgoingInvite = match;
        _scheduleExpiry();
        notifyListeners();
        return;
      }

      if (_outgoingInvite?.id == match.id) {
        _outgoingInvite = null;
        final superseded = match.abandonReason == 'superseded';
        if (!superseded) {
          switch (status) {
            case UnoMatchStatus.inProgress:
            case UnoMatchStatus.paused:
              _outcome = UnoInviteOutcome(
                type: UnoInviteOutcomeType.accepted,
                partnerName: _partnerName ?? 'Pasangan',
              );
              break;
            case UnoMatchStatus.rejected:
              _outcome = UnoInviteOutcome(
                type: UnoInviteOutcomeType.rejected,
                partnerName: _partnerName ?? 'Pasangan',
              );
              break;
            case UnoMatchStatus.cancelled:
              _outcome = UnoInviteOutcome(
                type: UnoInviteOutcomeType.cancelled,
                partnerName: _partnerName ?? 'Pasangan',
              );
              break;
            case UnoMatchStatus.expired:
              _outcome = UnoInviteOutcome(
                type: UnoInviteOutcomeType.expired,
                partnerName: _partnerName ?? 'Pasangan',
              );
              break;
            default:
              break;
          }
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
      _outcome = UnoInviteOutcome(
        type: UnoInviteOutcomeType.expired,
        partnerName: _partnerName ?? 'Pasangan',
      );
      unawaited(_repository.markExpired(outgoing.id));
    }

    _scheduleExpiry();
    notifyListeners();
  }

  Future<UnoStateSnapshot?> acceptInvite() async {
    final invite = _pendingInvite;
    final userId = _currentUserId;
    if (invite == null || userId == null) return null;

    try {
      final accepted = await _repository.acceptMatch(invite.id);
      _pendingInvite = null;
      notifyListeners();
      return accepted;
    } on UnoRepositoryException catch (e) {
      debugPrint('Error accepting uno invite: $e');
      final gone = e.message.toLowerCase().contains('kedaluwarsa') ||
          e.message.toLowerCase().contains('tidak tersedia');
      if (gone) {
        _pendingInvite = null;
        unawaited(_repository.markExpired(invite.id));
        notifyListeners();
      }
      return null;
    } catch (e) {
      debugPrint('Error accepting uno invite: $e');
      return null;
    }
  }

  Future<void> rejectInvite() async {
    final invite = _pendingInvite;
    final userId = _currentUserId;
    if (invite == null || userId == null) return;

    try {
      await _repository.rejectMatch(invite.id, userId);
      _pendingInvite = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error rejecting uno invite: $e');
    }
  }

  void dismissInvite() {
    _pendingInvite = null;
    notifyListeners();
  }

  UnoInviteOutcome? takeOutcome() {
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

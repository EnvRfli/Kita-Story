import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';

class LudoRealtimeEvent {
  final String event;
  final Map<String, dynamic> payload;

  const LudoRealtimeEvent({required this.event, required this.payload});
}

class LudoRealtimeService {
  final SupabaseClient? _client;
  RealtimeChannel? _channel;
  String? _myUserId;

  final _eventController = StreamController<LudoRealtimeEvent>.broadcast();
  final _presenceController = StreamController<Set<String>>.broadcast();

  LudoRealtimeService({SupabaseClient? client}) : _client = client;

  SupabaseClient get client => _client ?? SupabaseNetwork.client;

  Stream<LudoRealtimeEvent> get onEvent => _eventController.stream;
  Stream<Set<String>> get onPresence => _presenceController.stream;

  /// Connect to a specific match channel.
  Future<void> connect(String matchId, {String? currentUserId}) async {
    await disconnect();

    _myUserId = currentUserId;

    try {
      final channel = client.channel('ludo:match:$matchId');

      channel.onBroadcast(
        event: 'reaction',
        callback: (payload) {
          if (_eventController.isClosed) return;
          _eventController.add(LudoRealtimeEvent(
            event: 'reaction',
            payload: payload,
          ));
        },
      );

      channel.onBroadcast(
        event: 'surrender',
        callback: (payload) {
          if (_eventController.isClosed) return;
          _eventController.add(LudoRealtimeEvent(
            event: 'surrender',
            payload: payload,
          ));
        },
      );

      channel.onPresenceSync((_) {
        _emitPresence(channel);
      });

      channel.subscribe((status, error) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          if (_myUserId != null && _myUserId!.isNotEmpty) {
            try {
              await channel.track({'user_id': _myUserId});
            } catch (e) {
              debugPrint('Ludo presence track failed: $e');
            }
          }
          _emitPresence(channel);
        } else if (status == RealtimeSubscribeStatus.closed ||
            status == RealtimeSubscribeStatus.channelError ||
            status == RealtimeSubscribeStatus.timedOut) {
          if (!_presenceController.isClosed) {
            _presenceController.add(const {});
          }
          if (error != null) {
            debugPrint('Ludo realtime status $status: $error');
          }
        }
      });

      _channel = channel;
    } catch (e) {
      debugPrint('LudoRealtimeService connect error: $e');
    }
  }

  void _emitPresence(RealtimeChannel channel) {
    try {
      final ids = <String>{};
      for (final state in channel.presenceState()) {
        for (final presence in state.presences) {
          final id = presence.payload['user_id'];
          if (id is String && id.isNotEmpty) {
            ids.add(id);
          }
        }
      }
      if (!_presenceController.isClosed) {
        _presenceController.add(ids);
      }
    } catch (e) {
      debugPrint('Ludo presence read failed: $e');
    }
  }

  /// Broadcast a playful reaction emoji.
  Future<void> broadcastReaction({
    required String emoji,
    required String senderId,
  }) async {
    final channel = _channel;
    if (channel == null) return;
    try {
      await channel.sendBroadcastMessage(
        event: 'reaction',
        payload: {
          'emoji': emoji,
          'senderId': senderId,
        },
      );
    } catch (e) {
      debugPrint('Error broadcasting reaction: $e');
    }
  }

  /// Broadcast surrender for instant feedback. The database row remains the
  /// authoritative source for the final result.
  Future<void> broadcastSurrender({required String playerId}) async {
    final channel = _channel;
    if (channel == null) return;
    try {
      await channel.sendBroadcastMessage(
        event: 'surrender',
        payload: {'playerId': playerId},
      );
    } catch (e) {
      debugPrint('Error broadcasting surrender: $e');
    }
  }

  /// Disconnect and cleanup channel.
  Future<void> disconnect() async {
    final channel = _channel;
    if (channel != null) {
      try {
        await channel.untrack();
      } catch (_) {}
      try {
        await client.removeChannel(channel);
      } catch (_) {}
      _channel = null;
    }
    _myUserId = null;
    if (!_presenceController.isClosed) {
      _presenceController.add(const {});
    }
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _presenceController.close();
  }
}

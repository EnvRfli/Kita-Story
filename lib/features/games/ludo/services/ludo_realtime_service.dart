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
  final _eventController = StreamController<LudoRealtimeEvent>.broadcast();

  LudoRealtimeService({SupabaseClient? client}) : _client = client;

  SupabaseClient get client => _client ?? SupabaseNetwork.client;

  Stream<LudoRealtimeEvent> get onEvent => _eventController.stream;

  /// Connect to a specific match channel
  Future<void> connect(String matchId) async {
    await disconnect();

    try {
      final channelName = 'ludo:match:$matchId';
      final channel = client.channel(channelName);

      channel.onBroadcast(
        event: 'dice_rolled',
        callback: (payload) {
          _eventController.add(LudoRealtimeEvent(
            event: 'dice_rolled',
            payload: payload,
          ));
        },
      );

      channel.onBroadcast(
        event: 'token_moved',
        callback: (payload) {
          _eventController.add(LudoRealtimeEvent(
            event: 'token_moved',
            payload: payload,
          ));
        },
      );

      channel.onBroadcast(
        event: 'sync_state',
        callback: (payload) {
          _eventController.add(LudoRealtimeEvent(
            event: 'sync_state',
            payload: payload,
          ));
        },
      );

      channel.onBroadcast(
        event: 'reaction',
        callback: (payload) {
          _eventController.add(LudoRealtimeEvent(
            event: 'reaction',
            payload: payload,
          ));
        },
      );

      channel.onBroadcast(
        event: 'surrender',
        callback: (payload) {
          _eventController.add(LudoRealtimeEvent(
            event: 'surrender',
            payload: payload,
          ));
        },
      );

      channel.subscribe();
      _channel = channel;
    } catch (e) {
      debugPrint('LudoRealtimeService connect error: $e');
    }
  }

  /// Broadcast dice roll
  Future<void> broadcastDiceRoll({
    required int diceValue,
    required String playerId,
  }) async {
    final channel = _channel;
    if (channel == null) return;
    try {
      await channel.sendBroadcastMessage(
        event: 'dice_rolled',
        payload: {
          'diceValue': diceValue,
          'playerId': playerId,
        },
      );
    } catch (e) {
      debugPrint('Error broadcasting dice roll: $e');
    }
  }

  /// Broadcast token move
  Future<void> broadcastTokenMove({
    required int tokenId,
    required String playerId,
  }) async {
    final channel = _channel;
    if (channel == null) return;
    try {
      await channel.sendBroadcastMessage(
        event: 'token_moved',
        payload: {
          'tokenId': tokenId,
          'playerId': playerId,
        },
      );
    } catch (e) {
      debugPrint('Error broadcasting token move: $e');
    }
  }

  /// Broadcast full state synchronization (authoritative from host)
  Future<void> broadcastStateSync(Map<String, dynamic> stateJson) async {
    final channel = _channel;
    if (channel == null) return;
    try {
      await channel.sendBroadcastMessage(
        event: 'sync_state',
        payload: {'state': stateJson},
      );
    } catch (e) {
      debugPrint('Error broadcasting state sync: $e');
    }
  }

  /// Broadcast reaction emoji
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

  /// Disconnect and cleanup channel
  Future<void> disconnect() async {
    final channel = _channel;
    if (channel != null) {
      try {
        await client.removeChannel(channel);
      } catch (_) {}
      _channel = null;
    }
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}

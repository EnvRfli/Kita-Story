import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/supabase_client.dart';

/// Centralized Gamification & Activity Ledger Service
class ActivityLogService {
  static final SupabaseClient _client = SupabaseNetwork.client;

  /// Records an activity log entry and awards points to the user in Supabase
  static Future<void> recordActivityAndAddPoints({
    required String userId,
    required int points,
    required String activityType,
    required String title,
    required String description,
    String? referenceId,
  }) async {
    if (userId.isEmpty) return;

    // 1. Try invoking atomic RPC stored procedure in Supabase if exists
    try {
      await _client.rpc('record_activity_and_add_points', params: {
        'p_user_id': userId,
        'p_points': points,
        'p_activity_type': activityType,
        'p_title': title,
        'p_description': description,
        'p_reference_id': referenceId,
      });
      return;
    } catch (rpcError) {
      debugPrint(
        'Info: RPC record_activity_and_add_points unavailable, using direct DB fallback: $rpcError',
      );
    }

    // 2. Direct Fallback: Insert into user_point_logs + Increment app_users.points
    try {
      // A. Insert Log Entry
      await _client.from('user_point_logs').insert({
        'user_id': userId,
        'activity_type': activityType,
        'title': title,
        'description': description,
        'points_earned': points,
        if (referenceId != null) 'reference_id': referenceId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // B. Increment points in app_users
      if (points != 0) {
        final userRecord = await _client
            .from('app_users')
            .select('points')
            .eq('id', userId)
            .maybeSingle();

        if (userRecord != null) {
          final currentPoints = (userRecord['points'] as num?)?.toInt() ?? 0;
          await _client.from('app_users').update({
            'points': currentPoints + points,
          }).eq('id', userId);
        }
      }
    } catch (fallbackError) {
      debugPrint(
        'Warning: Failed to record activity log and points: $fallbackError',
      );
    }
  }

  /// Fetch activity & points history for the current user or partner
  static Future<List<Map<String, dynamic>>> getActivityLogs({
    int limit = 50,
    String? userId,
  }) async {
    try {
      var query = _client
          .from('user_point_logs')
          .select('*, app_users(display_name, photo_url)');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final data =
          await query.order('created_at', ascending: false).limit(limit);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching activity logs: $e');
      return [];
    }
  }
}

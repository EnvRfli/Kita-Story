import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../../../core/services/activity_log_service.dart';
import '../models/cycle_day_log_model.dart';
import '../models/cycle_settings_model.dart';
import '../utils/cycle_date_utils.dart';

class CycleRepository {
  final SupabaseClient _client = SupabaseNetwork.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<CycleSettingsModel?> getSettings(String userId) async {
    try {
      final response = await _client
          .from('cycle_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return null;
      return CycleSettingsModel.fromJson(response);
    } catch (e) {
      debugPrint('Gagal memuat pengaturan siklus: $e');
      return null;
    }
  }

  Future<CycleSettingsModel> upsertSettings({
    required String userId,
    required int cycleLength,
    required int periodLength,
    DateTime? lastPeriodStart,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'cycle_length': cycleLength,
      'period_length': periodLength,
      'last_period_start':
          lastPeriodStart == null ? null : cycleIsoDate(lastPeriodStart),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _client
        .from('cycle_settings')
        .upsert(payload, onConflict: 'user_id')
        .select()
        .single();

    return CycleSettingsModel.fromJson(response);
  }

  Future<List<CycleDayLogModel>> getLogs(String userId) async {
    try {
      final response = await _client
          .from('cycle_day_logs')
          .select()
          .eq('user_id', userId)
          .order('log_date', ascending: false)
          .limit(400);

      return (response as List<dynamic>)
          .map((json) =>
              CycleDayLogModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Gagal memuat log siklus: $e');
      return [];
    }
  }

  Future<({CycleDayLogModel log, bool wasCreated})> upsertLog({
    required String userId,
    required DateTime logDate,
    required String flow,
    String? mood,
    List<String> symptoms = const [],
    String? notes,
  }) async {
    final existing = await _findLog(userId, logDate);

    final payload = <String, dynamic>{
      'user_id': userId,
      'log_date': cycleIsoDate(logDate),
      'flow': flow,
      'mood': mood,
      'symptoms': symptoms,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _client
        .from('cycle_day_logs')
        .upsert(payload, onConflict: 'user_id,log_date')
        .select()
        .single();

    final log = CycleDayLogModel.fromJson(response);

    if (flow == 'medium' || flow == 'heavy') {
      await _syncLastPeriodStart(userId, logDate);
    }

    if (existing == null) {
      await ActivityLogService.recordActivityAndAddPoints(
        userId: userId,
        points: 3,
        activityType: 'cycle_log',
        title: 'Mencatat Siklus 🌸',
        description: 'Mencatat kondisi siklus pada ${log.formattedDate}',
        referenceId: log.id,
      );
    }

    return (log: log, wasCreated: existing == null);
  }

  Future<void> deleteLog(String logId) async {
    await _client.from('cycle_day_logs').delete().eq('id', logId);
  }

  Future<Map<String, dynamic>?> _findLog(
    String userId,
    DateTime logDate,
  ) async {
    try {
      return await _client
          .from('cycle_day_logs')
          .select('id')
          .eq('user_id', userId)
          .eq('log_date', cycleIsoDate(logDate))
          .maybeSingle();
    } catch (e) {
      debugPrint('Gagal memeriksa log siklus sebelumnya: $e');
      return null;
    }
  }

  /// Moves the configured period start forward when a newer period is logged.
  Future<void> _syncLastPeriodStart(String userId, DateTime logDate) async {
    try {
      final settings = await _client
          .from('cycle_settings')
          .select('last_period_start')
          .eq('user_id', userId)
          .maybeSingle();
      if (settings == null) return;

      final current = cycleParseDate(settings['last_period_start']);
      final nextDate = cycleDateOnly(logDate);
      if (current != null && !nextDate.isAfter(current)) return;

      await _client.from('cycle_settings').update({
        'last_period_start': cycleIsoDate(nextDate),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', userId);
    } catch (e) {
      debugPrint('Gagal menyinkronkan awal haid terakhir: $e');
    }
  }

  static const Map<int, int> streakMilestones = {3: 5, 7: 10, 14: 20};

  Future<Set<String>> fetchEarnedStreakMilestones(String userId) async {
    final rows = await _client
        .from('user_point_logs')
        .select('activity_type')
        .eq('user_id', userId)
        .like('activity_type', 'cycle_streak_%');
    return rows.map((row) => row['activity_type'].toString()).toSet();
  }

  Future<int> awardStreakMilestones({
    required String userId,
    required int streak,
  }) async {
    var total = 0;
    try {
      final earned = await fetchEarnedStreakMilestones(userId);
      for (final entry in streakMilestones.entries) {
        if (streak < entry.key) continue;
        final type = 'cycle_streak_${entry.key}';
        if (earned.contains(type)) continue;

        await ActivityLogService.recordActivityAndAddPoints(
          userId: userId,
          points: entry.value,
          activityType: type,
          title: 'Streak ${entry.key} Hari 🔥',
          description: 'Mencatat siklus ${entry.key} hari berturut-turut',
        );
        total += entry.value;
      }
    } catch (e) {
      debugPrint('Gagal memberi bonus streak siklus: $e');
    }
    return total;
  }
}

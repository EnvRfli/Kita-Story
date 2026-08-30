import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/activity_log_service.dart';
import '../models/reminder_model.dart';

class ReminderRepository {
  final SupabaseClient _client = SupabaseNetwork.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Fetch reminders for the logged in user + any shared reminders from partner
  Future<List<ReminderModel>> getReminders({
    String? targetUserId,
    String? partnerId,
  }) async {
    final userId = targetUserId ?? currentUserId;
    if (userId == null) return [];

    // Query both personal reminders and shared reminders
    final response = await _client
        .from('reminders')
        .select('*')
        .or('added_by.eq.$userId,and(is_shared.eq.true,partner_id.eq.$userId)')
        .order('target_date', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data
        .map((json) => ReminderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new reminder (Awards +5/+10 Points and records to user_point_logs)
  Future<ReminderModel> createReminder({
    required String title,
    String? description,
    required DateTime targetDate,
    bool hasCustomTime = false,
    String reminderLeadTime = 'on_time',
    bool isShared = false,
    String? partnerId,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User tidak terautentikasi.');
    }

    final response = await _client
        .from('reminders')
        .insert({
          'title': title.trim(),
          'description': description?.trim(),
          'target_date': targetDate.toUtc().toIso8601String(),
          'has_custom_time': hasCustomTime,
          'reminder_lead_time': reminderLeadTime,
          'is_shared': isShared,
          'partner_id': partnerId,
          'is_completed': false,
          'added_by': userId,
          'last_updated_by': userId,
        })
        .select()
        .single();

    // Award Points and record activity log (Shared: +10 pts, Personal: +5 pts)
    final points = isShared ? 10 : 5;
    await ActivityLogService.recordActivityAndAddPoints(
      userId: userId,
      points: points,
      activityType: isShared ? 'add_shared_reminder' : 'add_reminder',
      title: isShared
          ? 'Membuat Pengingat Bersama 💕'
          : 'Membuat Pengingat ⏰',
      description: isShared
          ? 'Berbagi pengingat "${title.trim()}" dengan pasangan'
          : 'Membuat pengingat "${title.trim()}"',
      referenceId: response['id'] as String?,
    );

    return ReminderModel.fromJson(response);
  }

  /// Update existing reminder
  Future<void> updateReminder(
    String reminderId, {
    required String title,
    String? description,
    required DateTime targetDate,
    bool hasCustomTime = false,
    String reminderLeadTime = 'on_time',
    bool isShared = false,
    String? partnerId,
  }) async {
    final userId = currentUserId;

    await _client.from('reminders').update({
      'title': title.trim(),
      'description': description?.trim(),
      'target_date': targetDate.toUtc().toIso8601String(),
      'has_custom_time': hasCustomTime,
      'reminder_lead_time': reminderLeadTime,
      'is_shared': isShared,
      'partner_id': partnerId,
      'last_updated_by': userId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', reminderId);
  }

  /// Toggle reminder completed status (Awards +10 Points when completed)
  Future<void> toggleReminderCompleted(
    String reminderId,
    bool isCompleted, {
    String? reminderTitle,
  }) async {
    final userId = currentUserId;
    await _client.from('reminders').update({
      'is_completed': isCompleted,
      'last_updated_by': userId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', reminderId);

    if (isCompleted && userId != null) {
      String resolvedTitle = reminderTitle ?? '';
      if (resolvedTitle.isEmpty) {
        try {
          final rec = await _client
              .from('reminders')
              .select('title')
              .eq('id', reminderId)
              .maybeSingle();
          resolvedTitle = rec?['title'] as String? ?? '';
        } catch (_) {}
      }

      final desc = resolvedTitle.isNotEmpty
          ? 'Menyelesaikan pengingat "$resolvedTitle"'
          : 'Menyelesaikan pengingat';

      await ActivityLogService.recordActivityAndAddPoints(
        userId: userId,
        points: 10,
        activityType: 'complete_reminder',
        title: 'Menyelesaikan Pengingat ✅',
        description: desc,
        referenceId: reminderId,
      );
    }
  }

  /// Delete reminder
  Future<void> deleteReminder(String reminderId) async {
    await _client.from('reminders').delete().eq('id', reminderId);
  }
}

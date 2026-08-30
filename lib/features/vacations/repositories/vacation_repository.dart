import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/activity_log_service.dart';
import '../models/vacation_model.dart';
import '../models/vacation_activity_model.dart';

class VacationRepository {
  final SupabaseClient _client = SupabaseNetwork.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Fetch all vacations for user and partner, with activities
  Future<List<VacationModel>> getVacations({String? targetUserId}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      // 1. Get partner ID if available
      final userRecord = await _client
          .from('app_users')
          .select('partner_id')
          .eq('id', userId)
          .maybeSingle();

      final partnerId = userRecord?['partner_id'] as String?;

      var query = _client.from('vacations').select('''
        *,
        vacation_activities (*)
      ''');

      if (targetUserId != null) {
        query = query.eq('added_by', targetUserId);
      } else if (partnerId != null && partnerId.isNotEmpty) {
        query = query.or(
            'added_by.eq.$userId,added_by.eq.$partnerId,and(is_shared.eq.true,partner_id.eq.$userId)');
      } else {
        query = query.eq('added_by', userId);
      }

      final response = await query.order('start_date', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final vacations = data.map((json) {
        final vMap = json as Map<String, dynamic>;
        return VacationModel.fromJson(vMap);
      }).toList();

      return _sortVacations(vacations);
    } catch (e) {
      debugPrint('Error fetching vacations: $e');
      return [];
    }
  }

  /// Sort vacations logic:
  /// 1. In-Progress (Active today) -> Top priority
  /// 2. Upcoming (Closest to today -> Further in the future)
  /// 3. Completed / Past -> Bottom of the list
  List<VacationModel> _sortVacations(List<VacationModel> list) {
    final inProgress = <VacationModel>[];
    final upcoming = <VacationModel>[];
    final completed = <VacationModel>[];

    for (var v in list) {
      if (v.isInProgress) {
        inProgress.add(v);
      } else if (v.isUpcoming) {
        upcoming.add(v);
      } else {
        completed.add(v);
      }
    }

    // In-progress sorted by start_date ASC
    inProgress.sort((a, b) => a.startDate.compareTo(b.startDate));
    // Upcoming sorted by start_date ASC (closest to today first)
    upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
    // Completed sorted by end_date DESC (most recent completion first)
    completed.sort((a, b) => b.endDate.compareTo(a.endDate));

    return [...inProgress, ...upcoming, ...completed];
  }

  /// Get single vacation with sorted activities
  Future<VacationModel> getVacationById(String id) async {
    final data = await _client.from('vacations').select('''
      *,
      vacation_activities (*)
    ''').eq('id', id).single();

    final model = VacationModel.fromJson(data);
    // Sort activities by activity_date ASC, then start_time ASC
    final sortedActivities = [...model.activities]..sort((a, b) {
        final dateComp = a.activityDate.compareTo(b.activityDate);
        if (dateComp != 0) return dateComp;
        return a.startTime.compareTo(b.startTime);
      });

    return model.copyWith(activities: sortedActivities);
  }

  /// Create a new vacation (Awards +10 Points)
  Future<VacationModel> createVacation({
    required String title,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    bool isShared = true,
    String? partnerId,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Pengguna tidak terautentikasi.');
    }

    // Fetch partner ID if shared and partnerId not passed
    String? pId = partnerId;
    if (isShared && pId == null) {
      try {
        final userRec = await _client
            .from('app_users')
            .select('partner_id')
            .eq('id', userId)
            .maybeSingle();
        pId = userRec?['partner_id'] as String?;
      } catch (_) {}
    }

    final vacationData = {
      'title': title.trim(),
      'description': description?.trim(),
      'start_date':
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'end_date':
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      'is_shared': isShared,
      'partner_id': pId,
      'added_by': userId,
      'last_updated_by': userId,
    };

    final response =
        await _client.from('vacations').insert(vacationData).select().single();

    final model = VacationModel.fromJson(response);

    // Award +10 Points & Log
    await ActivityLogService.recordActivityAndAddPoints(
      userId: userId,
      points: 10,
      activityType: 'add_vacation',
      title: 'Menambah Liburan Baru ✈️',
      description:
          'Menjadwalkan liburan "${title.trim()}" (${model.formattedDateRange})',
      referenceId: model.id,
    );

    return model;
  }

  /// Update existing vacation
  Future<void> updateVacation(
    String id, {
    required String title,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    bool isShared = true,
  }) async {
    final userId = currentUserId;
    await _client.from('vacations').update({
      'title': title.trim(),
      'description': description?.trim(),
      'start_date':
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'end_date':
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      'is_shared': isShared,
      'last_updated_by': userId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    if (userId != null) {
      await ActivityLogService.recordActivityAndAddPoints(
        userId: userId,
        points: 3,
        activityType: 'update_vacation',
        title: 'Memperbarui Liburan ✈️',
        description: 'Memperbarui jadwal liburan "${title.trim()}"',
        referenceId: id,
      );
    }
  }

  /// Delete vacation
  Future<void> deleteVacation(String id) async {
    await _client.from('vacations').delete().eq('id', id);
  }

  /// Add activity to a vacation (Awards +3 Points)
  Future<VacationActivityModel> addVacationActivity({
    required String vacationId,
    required String title,
    String? description,
    required DateTime activityDate,
    required String startTime,
    required String endTime,
    String? vacationTitle,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Pengguna tidak terautentikasi.');
    }

    final activityData = {
      'vacation_id': vacationId,
      'title': title.trim(),
      'description': description?.trim(),
      'activity_date':
          '${activityDate.year}-${activityDate.month.toString().padLeft(2, '0')}-${activityDate.day.toString().padLeft(2, '0')}',
      'start_time': startTime,
      'end_time': endTime,
      'is_completed': false,
      'added_by': userId,
      'last_updated_by': userId,
    };

    final response = await _client
        .from('vacation_activities')
        .insert(activityData)
        .select()
        .single();

    final model = VacationActivityModel.fromJson(response);

    // Resolve vacation title if not provided
    String resolvedVacTitle = vacationTitle ?? '';
    if (resolvedVacTitle.isEmpty) {
      try {
        final vRec = await _client
            .from('vacations')
            .select('title')
            .eq('id', vacationId)
            .maybeSingle();
        resolvedVacTitle = vRec?['title'] as String? ?? '';
      } catch (_) {}
    }

    final desc = resolvedVacTitle.isNotEmpty
        ? 'Menambahkan agenda "${title.trim()}" pada liburan "$resolvedVacTitle"'
        : 'Menambahkan agenda "${title.trim()}"';

    // Award +3 Points & Log
    await ActivityLogService.recordActivityAndAddPoints(
      userId: userId,
      points: 3,
      activityType: 'add_vacation_activity',
      title: 'Menambah Agenda Liburan 🏖️',
      description: desc,
      referenceId: vacationId,
    );

    return model;
  }

  /// Update activity
  Future<void> updateVacationActivity(
    String activityId, {
    required String title,
    String? description,
    required DateTime activityDate,
    required String startTime,
    required String endTime,
  }) async {
    final userId = currentUserId;
    await _client.from('vacation_activities').update({
      'title': title.trim(),
      'description': description?.trim(),
      'activity_date':
          '${activityDate.year}-${activityDate.month.toString().padLeft(2, '0')}-${activityDate.day.toString().padLeft(2, '0')}',
      'start_time': startTime,
      'end_time': endTime,
      'last_updated_by': userId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', activityId);
  }

  /// Delete activity
  Future<void> deleteVacationActivity(String activityId) async {
    await _client.from('vacation_activities').delete().eq('id', activityId);
  }

  /// Toggle activity completion status (Awards +2 Points when completed)
  Future<void> toggleActivityCompleted(
    String activityId,
    bool isCompleted, {
    String? vacationId,
    String? activityTitle,
    String? vacationTitle,
  }) async {
    final userId = currentUserId;
    await _client.from('vacation_activities').update({
      'is_completed': isCompleted,
      'last_updated_by': userId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', activityId);

    if (isCompleted && userId != null) {
      String resolvedActTitle = activityTitle ?? '';
      String resolvedVacTitle = vacationTitle ?? '';

      if (resolvedActTitle.isEmpty || resolvedVacTitle.isEmpty) {
        try {
          final actRec = await _client
              .from('vacation_activities')
              .select('title, vacation_id, vacations(title)')
              .eq('id', activityId)
              .maybeSingle();

          if (actRec != null) {
            resolvedActTitle = actRec['title'] as String? ?? '';
            if (actRec['vacations'] is Map) {
              resolvedVacTitle = actRec['vacations']['title'] as String? ?? '';
            }
          }
        } catch (_) {}
      }

      final desc = (resolvedActTitle.isNotEmpty && resolvedVacTitle.isNotEmpty)
          ? 'Menyelesaikan agenda "$resolvedActTitle" pada liburan "$resolvedVacTitle"'
          : resolvedActTitle.isNotEmpty
              ? 'Menyelesaikan agenda "$resolvedActTitle"'
              : 'Menyelesaikan agenda liburan';

      await ActivityLogService.recordActivityAndAddPoints(
        userId: userId,
        points: 2,
        activityType: 'complete_vacation_activity',
        title: 'Agenda Selesai ✅',
        description: desc,
        referenceId: vacationId ?? activityId,
      );
    }
  }
}

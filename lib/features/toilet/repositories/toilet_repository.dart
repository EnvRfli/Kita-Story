import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/activity_log_service.dart';
import '../models/poop_log_model.dart';

class ToiletRepository {
  final SupabaseClient _client = SupabaseNetwork.client;

  /// Fetch poop logs for the current user and (optionally) their partner
  Future<List<PoopLogModel>> getPoopLogs({
    String? targetUserId,
    String? partnerId,
  }) async {
    final currentUserId = targetUserId ?? _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    // Build filter condition: own logs OR partner's shared logs
    String orFilter = 'user_id.eq.$currentUserId';
    if (partnerId != null && partnerId.isNotEmpty) {
      orFilter =
          'user_id.eq.$currentUserId,and(user_id.eq.$partnerId,is_shared.eq.true)';
    }

    List<Map<String, dynamic>> rawList = [];
    try {
      final response = await _client
          .from('poop_logs')
          .select('*, app_users!poop_logs_user_id_fkey(name, photo_url, gender)')
          .or(orFilter)
          .order('pooped_at', ascending: false);
      rawList = List<Map<String, dynamic>>.from(response);
    } catch (joinError) {
      debugPrint(
        'Info: Direct FK join on poop_logs fallback to manual profile lookup: $joinError',
      );
      final response = await _client
          .from('poop_logs')
          .select()
          .or(orFilter)
          .order('pooped_at', ascending: false);
      rawList = List<Map<String, dynamic>>.from(response);

      // Enrich user profiles from app_users
      final userIds = rawList
          .map((e) => e['user_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      if (userIds.isNotEmpty) {
        try {
          final profiles = await _client
              .from('app_users')
              .select('id, name, photo_url, gender')
              .inFilter('id', userIds);
          final profileMap = <String, Map<String, dynamic>>{};
          for (final p in profiles) {
            profileMap[p['id'].toString()] = Map<String, dynamic>.from(p);
          }
          for (final row in rawList) {
            final uid = row['user_id']?.toString();
            if (uid != null && profileMap.containsKey(uid)) {
              row['app_users'] = profileMap[uid];
            }
          }
        } catch (_) {}
      }
    }

    return rawList.map((json) => PoopLogModel.fromJson(json)).toList();
  }

  /// Create a new poop log entry and award gamification points
  Future<PoopLogModel> createPoopLog({
    required DateTime poopedAt,
    required bool isBackdated,
    required String locationName,
    String? locationAddress,
    double? latitude,
    double? longitude,
    required bool isManualLocation,
    required String stoolType,
    required String feeling,
    required int durationMinutes,
    String? note,
    bool isShared = true,
    String? partnerId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Pengguna belum terautentikasi');
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'user_id': user.id,
      if (partnerId != null && partnerId.isNotEmpty) 'partner_id': partnerId,
      'is_shared': isShared,
      'pooped_at': poopedAt.toUtc().toIso8601String(),
      'is_backdated': isBackdated,
      'location_name': locationName.trim(),
      'location_address':
          locationAddress?.trim().isNotEmpty == true ? locationAddress!.trim() : null,
      'latitude': latitude,
      'longitude': longitude,
      'is_manual_location': isManualLocation,
      'stool_type': stoolType,
      'feeling': feeling,
      'duration_minutes': durationMinutes,
      'note': note?.trim().isNotEmpty == true ? note!.trim() : null,
      'added_by': user.id,
      'last_updated_by': user.id,
      'created_at': nowIso,
      'updated_at': nowIso,
    };

    Map<String, dynamic> inserted;
    try {
      inserted = await _client
          .from('poop_logs')
          .insert(payload)
          .select('*, app_users!poop_logs_user_id_fkey(name, photo_url, gender)')
          .single();
    } catch (_) {
      inserted =
          await _client.from('poop_logs').insert(payload).select().single();
    }

    final model = PoopLogModel.fromJson(inserted);

    // Record Activity & Gamification Points (+5 Shared / +3 Personal)
    final points = isShared ? 5 : 3;
    final activityType = isShared ? 'add_shared_poop' : 'add_poop';
    final title = isShared
        ? 'Mencatat Laporan Toilet 🚽💕'
        : 'Mencatat Laporan Toilet 🚽';
    final description =
        'Mencatat aktivitas toilet di "${model.locationName}" (${model.stoolTypeShort}, ${model.feelingShort})';

    await ActivityLogService.recordActivityAndAddPoints(
      userId: user.id,
      points: points,
      activityType: activityType,
      title: title,
      description: description,
      referenceId: model.id,
    );

    return model;
  }

  /// Update an existing poop log entry
  Future<PoopLogModel> updatePoopLog(
    String logId, {
    required DateTime poopedAt,
    required bool isBackdated,
    required String locationName,
    String? locationAddress,
    double? latitude,
    double? longitude,
    required bool isManualLocation,
    required String stoolType,
    required String feeling,
    required int durationMinutes,
    String? note,
    bool isShared = true,
    String? partnerId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Pengguna belum terautentikasi');
    }

    final payload = <String, dynamic>{
      'partner_id':
          (partnerId != null && partnerId.isNotEmpty) ? partnerId : null,
      'is_shared': isShared,
      'pooped_at': poopedAt.toUtc().toIso8601String(),
      'is_backdated': isBackdated,
      'location_name': locationName.trim(),
      'location_address':
          locationAddress?.trim().isNotEmpty == true ? locationAddress!.trim() : null,
      'latitude': latitude,
      'longitude': longitude,
      'is_manual_location': isManualLocation,
      'stool_type': stoolType,
      'feeling': feeling,
      'duration_minutes': durationMinutes,
      'note': note?.trim().isNotEmpty == true ? note!.trim() : null,
      'last_updated_by': user.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    Map<String, dynamic> updated;
    try {
      updated = await _client
          .from('poop_logs')
          .update(payload)
          .eq('id', logId)
          .select('*, app_users!poop_logs_user_id_fkey(name, photo_url, gender)')
          .single();
    } catch (_) {
      updated = await _client
          .from('poop_logs')
          .update(payload)
          .eq('id', logId)
          .select()
          .single();
    }

    return PoopLogModel.fromJson(updated);
  }

  /// Delete a poop log entry
  Future<void> deletePoopLog(String logId) async {
    await _client.from('poop_logs').delete().eq('id', logId);
  }
}

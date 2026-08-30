import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../models/activity_log_model.dart';

class HistoryRepository {
  final SupabaseClient _client = SupabaseNetwork.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Fetch activity logs for the current user & connected partner
  Future<List<ActivityLogModel>> getActivityLogs({
    int limit = 100,
    String? searchQuery,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      // 1. Get current user's partner ID to fetch both activities
      final userRecord = await _client
          .from('app_users')
          .select('partner_id')
          .eq('id', userId)
          .maybeSingle();

      final partnerId = userRecord?['partner_id'] as String?;

      // 2. Build Query
      var query = _client.from('user_point_logs').select('''
        id,
        user_id,
        activity_type,
        title,
        description,
        points_earned,
        reference_id,
        created_at,
        app_users (
          id,
          name,
          photo_url
        )
      ''');

      if (partnerId != null && partnerId.isNotEmpty) {
        query = query.or('user_id.eq.$userId,user_id.eq.$partnerId');
      } else {
        query = query.eq('user_id', userId);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      var logs = data
          .map((json) =>
              ActivityLogModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // 3. Dynamic Multi-Feature Title Resolver for legacy / existing logs
      // A. Books resolver
      final bookRefIds = logs
          .where((l) =>
              l.referenceId != null &&
              l.referenceId!.isNotEmpty &&
              (l.description.endsWith('pada buku') ||
                  l.description.endsWith('pada buku ') ||
                  (!l.description.contains('pada buku "') &&
                      (l.activityType.contains('character') ||
                          l.activityType.contains('snippet') ||
                          l.activityType.contains('book') ||
                          l.activityType == 'add_note'))))
          .map((l) => l.referenceId!)
          .toSet()
          .toList();

      if (bookRefIds.isNotEmpty) {
        try {
          final booksData = await _client
              .from('books')
              .select('id, title, author')
              .inFilter('id', bookRefIds);

          final bookMap = <String, Map<String, dynamic>>{};
          for (var b in booksData as List) {
            bookMap[b['id'] as String] = b as Map<String, dynamic>;
          }

          logs = logs.map((log) {
            if (log.referenceId != null &&
                bookMap.containsKey(log.referenceId)) {
              final b = bookMap[log.referenceId]!;
              final bTitle = b['title'] as String? ?? '';
              if (bTitle.isNotEmpty) {
                var desc = log.description.trim();
                if (desc.endsWith('pada buku')) {
                  desc = '$desc "$bTitle"';
                } else if (!desc.contains('pada buku')) {
                  desc = '$desc pada buku "$bTitle"';
                }

                return ActivityLogModel(
                  id: log.id,
                  userId: log.userId,
                  userName: log.userName,
                  userPhotoUrl: log.userPhotoUrl,
                  activityType: log.activityType,
                  title: log.title,
                  description: desc,
                  pointsEarned: log.pointsEarned,
                  referenceId: log.referenceId,
                  createdAt: log.createdAt,
                );
              }
            }
            return log;
          }).toList();
        } catch (e) {
          debugPrint('Error enriching book titles in history: $e');
        }
      }

      // B. Notes & Checklist Items Resolver
      final noteRefIds = logs
          .where((l) =>
              l.referenceId != null &&
              l.referenceId!.isNotEmpty &&
              l.activityType == 'complete_note' &&
              !l.description.contains('"'))
          .map((l) => l.referenceId!)
          .toSet()
          .toList();

      if (noteRefIds.isNotEmpty) {
        try {
          final notesData = await _client
              .from('notes')
              .select('id, title')
              .inFilter('id', noteRefIds);

          final noteMap = <String, String>{};
          for (var n in notesData as List) {
            noteMap[n['id'] as String] = n['title'] as String? ?? '';
          }

          logs = logs.map((log) {
            if (log.referenceId != null &&
                noteMap.containsKey(log.referenceId)) {
              final nTitle = noteMap[log.referenceId]!;
              if (nTitle.isNotEmpty) {
                return ActivityLogModel(
                  id: log.id,
                  userId: log.userId,
                  userName: log.userName,
                  userPhotoUrl: log.userPhotoUrl,
                  activityType: log.activityType,
                  title: log.title,
                  description: 'Menyelesaikan seluruh isi catatan "$nTitle"',
                  pointsEarned: log.pointsEarned,
                  referenceId: log.referenceId,
                  createdAt: log.createdAt,
                );
              }
            }
            return log;
          }).toList();
        } catch (_) {}
      }

      // C. Reminders Resolver
      final reminderRefIds = logs
          .where((l) =>
              l.referenceId != null &&
              l.referenceId!.isNotEmpty &&
              l.activityType == 'complete_reminder' &&
              (l.description.contains('"Pengingat"') ||
                  !l.description.contains('"')))
          .map((l) => l.referenceId!)
          .toSet()
          .toList();

      if (reminderRefIds.isNotEmpty) {
        try {
          final remindersData = await _client
              .from('reminders')
              .select('id, title')
              .inFilter('id', reminderRefIds);

          final reminderMap = <String, String>{};
          for (var r in remindersData as List) {
            reminderMap[r['id'] as String] = r['title'] as String? ?? '';
          }

          logs = logs.map((log) {
            if (log.referenceId != null &&
                reminderMap.containsKey(log.referenceId)) {
              final rTitle = reminderMap[log.referenceId]!;
              if (rTitle.isNotEmpty) {
                return ActivityLogModel(
                  id: log.id,
                  userId: log.userId,
                  userName: log.userName,
                  userPhotoUrl: log.userPhotoUrl,
                  activityType: log.activityType,
                  title: log.title,
                  description: 'Menyelesaikan pengingat "$rTitle"',
                  pointsEarned: log.pointsEarned,
                  referenceId: log.referenceId,
                  createdAt: log.createdAt,
                );
              }
            }
            return log;
          }).toList();
        } catch (_) {}
      }

      // Client-side search filtering if provided
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final queryLower = searchQuery.trim().toLowerCase();
        logs = logs.where((log) {
          final titleMatch = log.title.toLowerCase().contains(queryLower);
          final descMatch =
              log.description.toLowerCase().contains(queryLower);
          final userMatch =
              log.userName?.toLowerCase().contains(queryLower) ?? false;
          return titleMatch || descMatch || userMatch;
        }).toList();
      }

      return logs;
    } catch (e) {
      debugPrint('Error fetching history logs: $e');
      return [];
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/notification_service.dart';
import '../models/poop_log_model.dart';
import '../repositories/toilet_repository.dart';

class ToiletProvider extends ChangeNotifier {
  final ToiletRepository _repository = ToiletRepository();

  List<PoopLogModel> _logs = [];
  List<PoopLogModel> get logs => _logs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Fetch poop logs and synchronize progressive digestive reminder notifications
  Future<void> fetchPoopLogs({
    String? targetUserId,
    String? partnerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logs = await _repository.getPoopLogs(
        targetUserId: targetUserId,
        partnerId: partnerId,
      );
      _logs.sort((a, b) => b.poopedAt.compareTo(a.poopedAt));

      final authUid = SupabaseNetwork.client.auth.currentUser?.id;
      if (authUid != null && (targetUserId == null || targetUserId == authUid)) {
        await syncPoopReminderNotifications(currentUserId: authUid);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Synchronizes or hard-resets the Day 1, 2, 3, >=4 poop notifications
  /// based on the latest poop log or the app first-install timestamp.
  Future<void> syncPoopReminderNotifications({
    required String currentUserId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final installKey = 'poop_install_anchor_$currentUserId';

      final ownLogs = _logs.where((l) => l.userId == currentUserId).toList()
        ..sort((a, b) => b.poopedAt.compareTo(a.poopedAt));

      DateTime anchorTime;
      if (ownLogs.isNotEmpty) {
        anchorTime = ownLogs.first.poopedAt;
        await prefs.setString(installKey, anchorTime.toIso8601String());
      } else {
        final savedStr = prefs.getString(installKey);
        if (savedStr != null) {
          anchorTime = DateTime.tryParse(savedStr) ?? DateTime.now();
        } else {
          anchorTime = DateTime.now();
          await prefs.setString(installKey, anchorTime.toIso8601String());
        }
      }

      // Hard-reset all existing poop notifications and rewrite schedule from anchorTime
      await NotificationService.resetAndSchedulePoopReminders(
        anchorTime: anchorTime,
      );
    } catch (e) {
      debugPrint('Error syncing poop reminder notifications: $e');
    }
  }

  /// Create a new poop log, award points, and hard-reset poop reminder notifications
  Future<bool> createPoopLog({
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
    String? currentUserName,
    String? currentUserPhotoUrl,
    String? currentUserGender,
  }) async {
    _errorMessage = null;
    try {
      final created = await _repository.createPoopLog(
        poopedAt: poopedAt,
        isBackdated: isBackdated,
        locationName: locationName,
        locationAddress: locationAddress,
        latitude: latitude,
        longitude: longitude,
        isManualLocation: isManualLocation,
        stoolType: stoolType,
        feeling: feeling,
        durationMinutes: durationMinutes,
        note: note,
        isShared: isShared,
        partnerId: partnerId,
      );

      final enriched = created.copyWith(
        userName: created.userName ?? currentUserName,
        userPhotoUrl: created.userPhotoUrl ?? currentUserPhotoUrl,
        userGender: created.userGender ?? currentUserGender,
      );

      _logs.insert(0, enriched);
      _logs.sort((a, b) => b.poopedAt.compareTo(a.poopedAt));
      notifyListeners();

      // Hard-reset & rewrite poop notifications from the new latest poop timestamp
      await syncPoopReminderNotifications(currentUserId: enriched.userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update an existing poop log and rewrite poop reminder notifications
  Future<bool> updatePoopLog(
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
    _errorMessage = null;
    try {
      final updated = await _repository.updatePoopLog(
        logId,
        poopedAt: poopedAt,
        isBackdated: isBackdated,
        locationName: locationName,
        locationAddress: locationAddress,
        latitude: latitude,
        longitude: longitude,
        isManualLocation: isManualLocation,
        stoolType: stoolType,
        feeling: feeling,
        durationMinutes: durationMinutes,
        note: note,
        isShared: isShared,
        partnerId: partnerId,
      );

      final idx = _logs.indexWhere((l) => l.id == logId);
      if (idx != -1) {
        final prev = _logs[idx];
        _logs[idx] = updated.copyWith(
          userName: updated.userName ?? prev.userName,
          userPhotoUrl: updated.userPhotoUrl ?? prev.userPhotoUrl,
          userGender: updated.userGender ?? prev.userGender,
        );
        _logs.sort((a, b) => b.poopedAt.compareTo(a.poopedAt));
        notifyListeners();
      }

      await syncPoopReminderNotifications(currentUserId: updated.userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a poop log and recalculate poop reminder notifications
  Future<bool> deletePoopLog(String logId) async {
    _errorMessage = null;
    try {
      final existing = _logs.where((l) => l.id == logId).firstOrNull;
      await _repository.deletePoopLog(logId);
      _logs.removeWhere((l) => l.id == logId);
      notifyListeners();

      final authUid =
          existing?.userId ?? SupabaseNetwork.client.auth.currentUser?.id;
      if (authUid != null) {
        await syncPoopReminderNotifications(currentUserId: authUid);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // ANALYTICS & COUPLE STATUS HELPERS
  // ===========================================================================

  /// Returns the most recent poop log for [userId]
  PoopLogModel? latestLogForUser(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    for (final l in _logs) {
      if (l.userId == userId) return l;
    }
    return null;
  }

  /// Returns the Playful DigestiveStatusInfo for [userId]
  DigestiveStatusInfo digestiveStatusForUser(String? userId) {
    final latest = latestLogForUser(userId);
    return DigestiveStatusInfo.fromLastPoop(latest?.poopedAt);
  }

  /// Count of poops recorded today for [userId]
  int todayCountForUser(String? userId) {
    if (userId == null || userId.isEmpty) return 0;
    final now = DateTime.now();
    return _logs.where((l) {
      return l.userId == userId &&
          l.poopedAt.year == now.year &&
          l.poopedAt.month == now.month &&
          l.poopedAt.day == now.day;
    }).length;
  }

  /// Count of poops recorded in the last 7 days for [userId]
  int thisWeekCountForUser(String? userId) {
    if (userId == null || userId.isEmpty) return 0;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _logs
        .where((l) => l.userId == userId && l.poopedAt.isAfter(cutoff))
        .length;
  }

  /// Count of poops recorded in the current calendar month for [userId]
  int thisMonthCountForUser(String? userId) {
    if (userId == null || userId.isEmpty) return 0;
    final now = DateTime.now();
    return _logs.where((l) {
      return l.userId == userId &&
          l.poopedAt.year == now.year &&
          l.poopedAt.month == now.month;
    }).length;
  }

  /// Monthly stool texture breakdown for Digestive Health Insight Banner
  ({int total, int normal, int hard, int soft, int liquid})
      monthlyDigestiveBreakdown({String? userId}) {
    final now = DateTime.now();
    final monthLogs = _logs.where((l) {
      final matchesUser =
          userId == null || userId.isEmpty || l.userId == userId;
      return matchesUser &&
          l.poopedAt.year == now.year &&
          l.poopedAt.month == now.month;
    }).toList();

    int normal = 0;
    int hard = 0;
    int soft = 0;
    int liquid = 0;

    for (final l in monthLogs) {
      switch (l.stoolType) {
        case 'hard':
          hard++;
          break;
        case 'soft':
          soft++;
          break;
        case 'liquid':
          liquid++;
          break;
        case 'normal':
        default:
          normal++;
          break;
      }
    }

    return (
      total: monthLogs.length,
      normal: normal,
      hard: hard,
      soft: soft,
      liquid: liquid,
    );
  }
}

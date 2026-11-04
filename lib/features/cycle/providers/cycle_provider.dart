import 'package:flutter/foundation.dart';

import '../models/cycle_data.dart';
import '../repositories/cycle_repository.dart';
import '../services/cycle_notification_service.dart';
import '../utils/cycle_role.dart';

class CycleLogSaveResult {
  final bool success;
  final bool isNew;
  final int pointsAwarded;
  final String? errorMessage;

  const CycleLogSaveResult({
    required this.success,
    this.isNew = false,
    this.pointsAwarded = 0,
    this.errorMessage,
  });
}

class CycleProvider extends ChangeNotifier {
  final CycleRepository _repository = CycleRepository();

  final Map<String, CycleData> _data = {};
  final Map<String, CycleRole> _roles = {};
  final Map<String, String?> _partnerNames = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _loadingUserId;
  String? get loadingUserId => _loadingUserId;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CycleData? dataFor(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    return _data[userId];
  }

  bool isLoadingFor(String? userId) =>
      _isLoading && (userId == null || _loadingUserId == userId);

  Future<void> fetchCycleData({
    required String userId,
    CycleRole? role,
    String? partnerName,
  }) async {
    if (role != null) _roles[userId] = role;
    if (partnerName != null) _partnerNames[userId] = partnerName;

    _isLoading = true;
    _loadingUserId = userId;
    _errorMessage = null;
    notifyListeners();

    try {
      final settings = await _repository.getSettings(userId);
      final logs = await _repository.getLogs(userId);
      _data[userId] = CycleData(userId: userId, settings: settings, logs: logs);
      await _syncInsightNotifications(userId);
    } catch (e) {
      _errorMessage = 'Gagal memuat data siklus: $e';
    } finally {
      _isLoading = false;
      _loadingUserId = null;
      notifyListeners();
    }
  }

  Future<bool> saveSettings({
    required String userId,
    required int cycleLength,
    required int periodLength,
    required DateTime lastPeriodStart,
  }) async {
    _errorMessage = null;
    try {
      final settings = await _repository.upsertSettings(
        userId: userId,
        cycleLength: cycleLength,
        periodLength: periodLength,
        lastPeriodStart: lastPeriodStart,
      );

      final current = _data[userId] ?? CycleData(userId: userId);
      _data[userId] = CycleData(
        userId: userId,
        settings: settings,
        logs: current.logs,
      );
      notifyListeners();
      await _syncInsightNotifications(userId);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan pengaturan siklus: $e';
      notifyListeners();
      return false;
    }
  }

  Future<CycleLogSaveResult> saveDayLog({
    required String userId,
    DateTime? date,
    required String flow,
    String? mood,
    List<String> symptoms = const [],
    String? notes,
  }) async {
    _errorMessage = null;
    try {
      final saved = await _repository.upsertLog(
        userId: userId,
        logDate: date ?? DateTime.now(),
        flow: flow,
        mood: mood,
        symptoms: symptoms,
        notes: notes,
      );

      final current = _data[userId] ?? CycleData(userId: userId);
      final updatedLogs = [
        ...current.logs.where((log) => log.dateKey != saved.log.dateKey),
        saved.log,
      ];

      final refreshedSettings = await _repository.getSettings(userId);
      final updated = CycleData(
        userId: userId,
        settings: refreshedSettings ?? current.settings,
        logs: updatedLogs,
      );
      _data[userId] = updated;

      final bonus = await _repository.awardStreakMilestones(
        userId: userId,
        streak: updated.logStreak,
      );

      notifyListeners();
      await _syncInsightNotifications(userId);

      return CycleLogSaveResult(
        success: true,
        isNew: saved.wasCreated,
        pointsAwarded: (saved.wasCreated ? 3 : 0) + bonus,
      );
    } catch (e) {
      _errorMessage = 'Gagal menyimpan catatan siklus: $e';
      notifyListeners();
      return CycleLogSaveResult(success: false, errorMessage: _errorMessage);
    }
  }

  Future<bool> deleteDayLog({
    required String userId,
    required String logId,
  }) async {
    _errorMessage = null;
    try {
      await _repository.deleteLog(logId);

      final current = _data[userId];
      if (current != null) {
        _data[userId] = CycleData(
          userId: userId,
          settings: current.settings,
          logs: current.logs.where((log) => log.id != logId).toList(),
        );
      }
      notifyListeners();
      await _syncInsightNotifications(userId);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus catatan siklus: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> _syncInsightNotifications(String userId) async {
    final role = _roles[userId];
    final data = _data[userId];
    if (role == null || data == null) return;

    try {
      await CycleNotificationService.sync(
        userId: userId,
        role: role,
        data: data,
        partnerName: _partnerNames[userId],
      );
    } catch (e) {
      debugPrint('Gagal menyinkronkan notifikasi siklus: $e');
    }
  }

  void clearUser(String userId) {
    _data.remove(userId);
    _roles.remove(userId);
    _partnerNames.remove(userId);
    CycleNotificationService.cancelAll();
    notifyListeners();
  }

  void clear() {
    _data.clear();
    _roles.clear();
    _partnerNames.clear();
    _errorMessage = null;
    CycleNotificationService.cancelAll();
    notifyListeners();
  }
}

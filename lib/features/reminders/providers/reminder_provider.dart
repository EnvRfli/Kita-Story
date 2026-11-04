import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';
import '../models/reminder_model.dart';
import '../repositories/reminder_repository.dart';

class ReminderProvider extends ChangeNotifier {
  final ReminderRepository _repository = ReminderRepository();

  List<ReminderModel> _reminders = [];
  List<ReminderModel> get reminders => _reminders;

  List<ReminderModel> get activeReminders =>
      _reminders.where((r) => !r.isExpired).toList();

  List<ReminderModel> get expiredReminders =>
      _reminders.where((r) => r.isExpired).toList();

  /// Reminders happening today or within 7 days
  List<ReminderModel> get upcomingReminders => _reminders.where((r) {
        if (r.isExpired) return false;
        final diff = r.targetDate.difference(DateTime.now());
        return diff.inDays <= 7;
      }).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReminders({
    String? targetUserId,
    String? partnerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reminders = await _repository.getReminders(
        targetUserId: targetUserId,
        partnerId: partnerId,
      );
      // Sync local notifications only when fetching own reminders (not partner read-only view)
      if (targetUserId == null) {
        await _syncLocalNotifications();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createReminder({
    required String title,
    String? description,
    required DateTime targetDate,
    bool hasCustomTime = false,
    String reminderLeadTime = 'on_time',
    bool isShared = false,
    String? partnerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newReminder = await _repository.createReminder(
        title: title,
        description: description,
        targetDate: targetDate,
        hasCustomTime: hasCustomTime,
        reminderLeadTime: reminderLeadTime,
        isShared: isShared,
        partnerId: partnerId,
      );

      _reminders.add(newReminder);
      _reminders.sort((a, b) => a.targetDate.compareTo(b.targetDate));
      _isLoading = false;
      notifyListeners();

      // Schedule notification
      await _scheduleReminderAlarm(newReminder);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReminder(
    String reminderId, {
    required String title,
    String? description,
    required DateTime targetDate,
    bool hasCustomTime = false,
    String reminderLeadTime = 'on_time',
    bool isShared = false,
    String? partnerId,
  }) async {
    try {
      await _repository.updateReminder(
        reminderId,
        title: title,
        description: description,
        targetDate: targetDate,
        hasCustomTime: hasCustomTime,
        reminderLeadTime: reminderLeadTime,
        isShared: isShared,
        partnerId: partnerId,
      );

      final index = _reminders.indexWhere((r) => r.id == reminderId);
      if (index != -1) {
        final updated = _reminders[index].copyWith(
          title: title,
          description: description,
          targetDate: targetDate,
          hasCustomTime: hasCustomTime,
          reminderLeadTime: reminderLeadTime,
          isShared: isShared,
          partnerId: partnerId,
        );
        _reminders[index] = updated;
        _reminders.sort((a, b) => a.targetDate.compareTo(b.targetDate));
        notifyListeners();

        // Cancel all previous milestone alarms first before rescheduling
        await NotificationService.cancelReminderNotifications(reminderId);
        if (!updated.isCompleted) {
          await _scheduleReminderAlarm(updated);
        }
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteReminder(String reminderId) async {
    try {
      await _repository.deleteReminder(reminderId);
      // Cancel all scheduled milestone alarms (0 to 5) deterministically
      await NotificationService.cancelReminderNotifications(reminderId);

      _reminders.removeWhere((r) => r.id == reminderId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Toggle reminder completed status (Awards +10 Points when completed)
  Future<bool> toggleReminderCompleted(
    String reminderId,
    bool isCompleted, {
    String? reminderTitle,
  }) async {
    try {
      await _repository.toggleReminderCompleted(
        reminderId,
        isCompleted,
        reminderTitle: reminderTitle,
      );
      final index = _reminders.indexWhere((r) => r.id == reminderId);
      if (index != -1) {
        final updated = _reminders[index].copyWith(
          isCompleted: isCompleted,
        );
        _reminders[index] = updated;
        notifyListeners();

        if (isCompleted) {
          await NotificationService.cancelReminderNotifications(reminderId);
        } else if (!updated.isExpired) {
          await _scheduleReminderAlarm(updated);
        }
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Sync and schedule local notifications for all active, uncompleted reminders,
  /// while sweeping any orphaned/deleted reminder notifications from OS AlarmManager.
  Future<void> _syncLocalNotifications() async {
    final validIds = <int>{};

    for (final reminder in activeReminders) {
      if (reminder.isCompleted) {
        await NotificationService.cancelReminderNotifications(reminder.id);
        continue;
      }
      for (int slot = 0; slot <= 5; slot++) {
        validIds.add(
          NotificationService.stableIdFromKey(reminder.id, slot: slot),
        );
      }
      await _scheduleReminderAlarm(reminder);
    }

    // Also cancel notifications for any expired reminders still in list
    for (final expired in expiredReminders) {
      await NotificationService.cancelReminderNotifications(expired.id);
    }

    // Sweep any leftover/orphaned reminder notifications (e.g. deleted from another session/partner)
    await NotificationService.sweepOrphanedReminderNotifications(validIds);
  }

  /// Schedule exact alarms progressively for all relevant milestones:
  /// (1 Bulan -> 1 Minggu -> 3 Hari -> 1 Hari -> 1 Jam -> Saat Tiba)
  Future<void> _scheduleReminderAlarm(ReminderModel reminder) async {
    if (reminder.isCompleted) return;

    final target = reminder.targetDate;
    final now = DateTime.now();

    // 0. Saat Waktu Tiba (Hari H)
    final id0 = NotificationService.stableIdFromKey(reminder.id, slot: 0);
    if (target.isAfter(now)) {
      await NotificationService.scheduleNotification(
        id: id0,
        title: '🎉 Hari Ini: ${reminder.title}',
        body: reminder.description?.isNotEmpty == true
            ? reminder.description!
            : 'Waktunya untuk "${reminder.title}" telah tiba!',
        scheduledDate: target,
        payload: 'reminder:${reminder.id}',
      );
    } else {
      await NotificationService.cancelNotification(id0);
    }

    // 1. 1 Jam Sebelumnya
    final id1 = NotificationService.stableIdFromKey(reminder.id, slot: 1);
    final oneHourBefore = target.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(now)) {
      await NotificationService.scheduleNotification(
        id: id1,
        title: '⏰ 1 Jam Lagi: ${reminder.title}',
        body: 'Agenda "${reminder.title}" akan berlangsung 1 jam lagi.',
        scheduledDate: oneHourBefore,
        payload: 'reminder:${reminder.id}',
      );
    } else {
      await NotificationService.cancelNotification(id1);
    }

    // 2. 1 Hari Sebelumnya (H-1 / Besok)
    final id2 = NotificationService.stableIdFromKey(reminder.id, slot: 2);
    final oneDayBefore = target.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(now)) {
      await NotificationService.scheduleNotification(
        id: id2,
        title: '📅 Besok: ${reminder.title}',
        body: 'Pengingat untuk "${reminder.title}" akan tiba besok!',
        scheduledDate: oneDayBefore,
        payload: 'reminder:${reminder.id}',
      );
    } else {
      await NotificationService.cancelNotification(id2);
    }

    // 3. 3 Hari Sebelumnya
    final id3 = NotificationService.stableIdFromKey(reminder.id, slot: 3);
    final threeDaysBefore = target.subtract(const Duration(days: 3));
    if (threeDaysBefore.isAfter(now)) {
      await NotificationService.scheduleNotification(
        id: id3,
        title: '🔔 3 Hari Lagi: ${reminder.title}',
        body: 'Agenda "${reminder.title}" tinggal 3 hari lagi.',
        scheduledDate: threeDaysBefore,
        payload: 'reminder:${reminder.id}',
      );
    } else {
      await NotificationService.cancelNotification(id3);
    }

    // 4. 1 Minggu Sebelumnya
    final id4 = NotificationService.stableIdFromKey(reminder.id, slot: 4);
    final oneWeekBefore = target.subtract(const Duration(days: 7));
    if (oneWeekBefore.isAfter(now)) {
      await NotificationService.scheduleNotification(
        id: id4,
        title: '📆 1 Minggu Lagi: ${reminder.title}',
        body: 'Agenda "${reminder.title}" akan tiba dalam 1 minggu.',
        scheduledDate: oneWeekBefore,
        payload: 'reminder:${reminder.id}',
      );
    } else {
      await NotificationService.cancelNotification(id4);
    }

    // 5. 1 Bulan Sebelumnya
    final id5 = NotificationService.stableIdFromKey(reminder.id, slot: 5);
    final oneMonthBefore = target.subtract(const Duration(days: 30));
    if (oneMonthBefore.isAfter(now)) {
      await NotificationService.scheduleNotification(
        id: id5,
        title: '✨ 1 Bulan Lagi: ${reminder.title}',
        body:
            'Pengingat: "${reminder.title}" akan berlangsung dalam 1 bulan.',
        scheduledDate: oneMonthBefore,
        payload: 'reminder:${reminder.id}',
      );
    } else {
      await NotificationService.cancelNotification(id5);
    }
  }

  /// Check if daily bottomsheet popup should be shown
  Future<bool> shouldShowDailyPopup() async {
    if (upcomingReminders.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastDismissedDate = prefs.getString('dont_show_reminder_popup_date');
    final today = _formatDateKey(DateTime.now());

    return lastDismissedDate != today;
  }

  /// Mark "Jangan ingatkan lagi hari ini"
  Future<void> setDontShowAgainToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _formatDateKey(DateTime.now());
    await prefs.setString('dont_show_reminder_popup_date', today);
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

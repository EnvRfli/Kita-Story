import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint(
      'Background notification tapped: id=${notificationResponse.id}, payload=${notificationResponse.payload}');
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'kita_story_reminders';
  static const String channelName = 'Pengingat & Agenda Kita Story';
  static const String channelDescription =
      'Notifikasi alarm jadwal pengingat, kesehatan pencernaan, dan hari penting bersama pasangan.';

  /// Reserved Fixed Notification IDs for Toilet / Poop Tracker (Day 1 to Day 6)
  static const List<int> poopReminderIds = [
    900101, // Day 1 (24h)
    900102, // Day 2 (48h)
    900103, // Day 3 (72h)
    900104, // Day 4 (96h)
    900105, // Day 5 (120h / >4 days)
    900106, // Day 6 (144h / >4 days)
  ];

  static const String poopReminderPayload = 'toilet_reminder';

  /// Reserved notification IDs for the daily Cycle insight (07:00).
  static const int cycleInsightBaseId = 910001;
  static const int cycleInsightSlotCount = 14;
  static const String cycleInsightPayload = 'cycle_insight';

  static Future<void> initialize() async {
    // 1. Initialize timezone database
    tz.initializeTimeZones();
    try {
      // Default to Jakarta (WIB / GMT+7) or local device timezone
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // Fallback if not available
    }

    // 2. Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. Darwin/iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // Create Android Notification Channel explicitly with MAX importance
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          enableLights: true,
        );

        await androidImplementation.createNotificationChannel(channel);
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('Notification initialization warning: $e');
    }
  }

  /// Generates a 100% deterministic 32-bit positive integer ID from a UUID/key and a slot (0..9).
  /// Unlike Dart's `String.hashCode`, this never changes across app restarts.
  static int stableIdFromKey(String key, {int slot = 0}) {
    int hash = 0x811c9dc5;
    for (int i = 0; i < key.length; i++) {
      hash ^= key.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    // Keep base within safe 32-bit signed integer range when multiplied by 10
    final safeBase = (hash % 180000000) + 10000;
    return (safeBase * 10) + (slot % 10);
  }

  /// Schedule exact notification at scheduledDate
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    bool isAlarm = true,
  }) async {
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) return;

    final AndroidNotificationDetails androidDetails = isAlarm
        ? const AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
            enableLights: true,
            autoCancel: true,
            showWhen: true,
          )
        : const AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
            autoCancel: true,
            showWhen: true,
          );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      final tzDateTime = tz.TZDateTime(
        tz.local,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute,
        scheduledDate.second,
      );

      if (tzDateTime.isBefore(tz.TZDateTime.now(tz.local))) return;

      if (!isAlarm) {
        try {
          await _notificationsPlugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: tzDateTime,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: payload,
          );
        } catch (e) {
          debugPrint(
              'exactAllowWhileIdle failed, falling back to inexact: $e');
          await _notificationsPlugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: tzDateTime,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
        }
      } else {
        try {
          // Prioritize alarmClock so OS wakes device up when app is terminated/closed
          await _notificationsPlugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: tzDateTime,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            payload: payload,
          );
        } catch (e) {
          debugPrint(
              'alarmClock failed, falling back to exactAllowWhileIdle: $e');
          await _notificationsPlugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: tzDateTime,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: payload,
          );
        }
      }

      debugPrint('Notification scheduled: id=$id, at=$tzDateTime ($title)');
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  /// Immediately show a notification
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  /// Get all pending notifications currently registered in the OS
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Failed to get pending notifications: $e');
      return [];
    }
  }

  /// Cancel notification by ID
  static Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('Failed to cancel notification $id: $e');
    }
  }

  /// Cancel all milestone notifications (0..5) for a specific reminder ID
  /// (Cancels both deterministic IDs and legacy hashCode IDs)
  static Future<void> cancelReminderNotifications(String reminderId) async {
    final legacyHash = reminderId.hashCode;
    for (int slot = 0; slot <= 5; slot++) {
      final stableId = stableIdFromKey(reminderId, slot: slot);
      await cancelNotification(stableId);
      await cancelNotification(legacyHash + slot);
    }
  }

  /// Sweep and remove any orphaned reminder notifications that are no longer in [validIds],
  /// while preserving Toilet / Poop Tracker reserved notification IDs.
  static Future<void> sweepOrphanedReminderNotifications(
    Set<int> validIds,
  ) async {
    try {
      final pending = await getPendingNotifications();
      for (final req in pending) {
        if (poopReminderIds.contains(req.id) ||
            req.payload == poopReminderPayload ||
            req.payload == cycleInsightPayload) {
          continue;
        }
        if (!validIds.contains(req.id)) {
          await cancelNotification(req.id);
          debugPrint('Swept orphaned notification id=${req.id} (${req.title})');
        }
      }
    } catch (e) {
      debugPrint('Error sweeping orphaned notifications: $e');
    }
  }

  // ===========================================================================
  // TOILET / POOP TRACKER PLAYFUL REMINDER SYSTEM (HARD-RESET & REWRITE)
  // ===========================================================================

  /// Completely cancels all scheduled Poop Tracker notifications from the OS
  static Future<void> cancelPoopReminders() async {
    for (final id in poopReminderIds) {
      await cancelNotification(id);
    }
    try {
      final pending = await getPendingNotifications();
      for (final req in pending) {
        if (req.payload == poopReminderPayload ||
            poopReminderIds.contains(req.id)) {
          await cancelNotification(req.id);
        }
      }
    } catch (e) {
      debugPrint('Error verifying poop reminder cancellation: $e');
    }
  }

  // ===========================================================================
  // CYCLE / MENSTRUAL DAILY INSIGHT NOTIFICATIONS
  // ===========================================================================

  /// Cancels every scheduled daily Cycle insight notification.
  static Future<void> cancelCycleInsightNotifications() async {
    for (var slot = 0; slot < cycleInsightSlotCount; slot++) {
      await cancelNotification(cycleInsightBaseId + slot);
    }
    try {
      final pending = await getPendingNotifications();
      for (final req in pending) {
        if (req.payload == cycleInsightPayload) {
          await cancelNotification(req.id);
        }
      }
    } catch (e) {
      debugPrint('Error verifying cycle insight cancellation: $e');
    }
  }

  /// Adjusts a target notification time so it doesn't wake the user in the middle of the night
  /// (00:00 - 06:29 is shifted to 07:30 on that same day, or +24h if 07:30 has already passed).
  static DateTime _normalizeWakeHour(DateTime target) {
    if (target.hour >= 0 && target.hour < 7) {
      return DateTime(
        target.year,
        target.month,
        target.day,
        7,
        30,
      );
    }
    return target;
  }

  /// Hard-resets all previous poop notifications and schedules a fresh progressive sequence
  /// (Day 1, Day 2, Day 3, Day 4, Day 5, Day 6) starting from [anchorTime].
  static Future<void> resetAndSchedulePoopReminders({
    required DateTime anchorTime,
  }) async {
    // 1. Hard-reset all existing poop notifications first
    await cancelPoopReminders();

    final now = DateTime.now();

    final milestones = <({
      int id,
      int days,
      String title,
      String body,
    })>[
      (
        id: 900101,
        days: 1,
        title: '🚽 Udah 1 Hari Belum Setor Nih! 🌱',
        body:
            'Perut gimana kabarnya? Jangan lupa minum air putih yang cukup & makan buah/sayur berserat hari ini ya! 🍎🥦',
      ),
      (
        id: 900102,
        days: 2,
        title: '⚠️ Hari ke-2 Belum Poop! Perut Mulai Penuh? 🎈',
        body:
            'Udah 2 hari sejak terakhir ke toilet! Yuk makan pepaya, buah naga, atau sayur hijau & jalan kaki sebentar biar lancar~ 🥗🚶',
      ),
      (
        id: 900103,
        days: 3,
        title: '🚨 Alarm Sembelit Hari ke-3! 🪨🚽',
        body:
            'Waduh, udah 3 hari belum poop! Wajib perbanyak makanan berserat tinggi, yogurt/probiotik, dan minum air hangat sekarang ya! 🐉💧',
      ),
      (
        id: 900104,
        days: 4,
        title: '🆘 DARURAT! Udah 4 Hari Belum Poop! 😭🔥',
        body:
            'Perut pasti begah banget! Ayo konsumsi serat ekstra & air putih, atau cek ke dokter kalau perut terasa melilit ya! 🏥💊',
      ),
      (
        id: 900105,
        days: 5,
        title: '🚨🙇‍♂️ Udah >4 Hari Belum Ke Toilet! Jangan Ditahan!',
        body:
            'Poop itu penting banget buat kesehatanmu! Yuk makan serat tinggi & jangan lupa catat di menu Toilet kalau sudah berhasil ya! 🚽✨',
      ),
      (
        id: 900106,
        days: 6,
        title: '🆘🥦 Pengingat Serat Harian (>4 Hari Belum Poop)!',
        body:
            'Kesehatan pencernaanmu penting buat kamu & pasanganmu 💕. Ayo minum air hangat, makan buah berserat, dan catat poop-mu! 🚽',
      ),
    ];

    for (final m in milestones) {
      final rawDate = anchorTime.add(Duration(days: m.days));
      final scheduledDate = _normalizeWakeHour(rawDate);
      if (scheduledDate.isAfter(now)) {
        await scheduleNotification(
          id: m.id,
          title: m.title,
          body: m.body,
          scheduledDate: scheduledDate,
          payload: poopReminderPayload,
        );
      }
    }
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}

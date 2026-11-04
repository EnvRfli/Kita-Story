import '../../../core/services/notification_service.dart';
import '../models/cycle_data.dart';
import '../utils/cycle_calculator.dart';
import '../utils/cycle_date_utils.dart';
import '../utils/cycle_insight_builder.dart';
import '../utils/cycle_role.dart';

class CycleNotificationService {
  static const int _hour = 7;

  static Future<void> sync({
    required String userId,
    required CycleRole role,
    required CycleData data,
    String? partnerName,
    DateTime? now,
  }) async {
    await _cancelAll();

    if (role == CycleRole.hidden) return;
    final current = data.summary;
    if (current == null) return;

    final reference = now ?? DateTime.now();
    final today = cycleDateOnly(reference);

    for (var offset = 0; offset < NotificationService.cycleInsightSlotCount;
        offset++) {
      final date = today.add(Duration(days: offset));
      final scheduled = DateTime(date.year, date.month, date.day, _hour);
      if (!scheduled.isAfter(reference)) continue;

      final summary = CycleCalculator.compute(
        lastPeriodStart: current.lastPeriodStart,
        cycleLength: data.cycleLength,
        periodLength: data.periodLength,
        today: date,
        // Never assume a new cycle before the user confirms a period start.
        allowRollover: false,
      );
      final message = CycleInsightBuilder.build(
        summary: summary,
        role: role,
        partnerName: partnerName,
      );

      await NotificationService.scheduleNotification(
        id: NotificationService.cycleInsightBaseId + offset,
        title: message.title,
        body: message.body,
        scheduledDate: scheduled,
        payload: NotificationService.cycleInsightPayload,
        isAlarm: false,
      );
    }
  }

  static Future<void> cancelAll() =>
      NotificationService.cancelCycleInsightNotifications();

  static Future<void> _cancelAll() => cancelAll();
}

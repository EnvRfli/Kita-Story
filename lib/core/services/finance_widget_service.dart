import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../features/finances/providers/finance_provider.dart';

class FinanceWidgetService {
  static const MethodChannel _channel =
      MethodChannel('com.example.kita_story/finance_widget');

  static final StreamController<String> _actionStreamController =
      StreamController<String>.broadcast();

  /// Stream to listen for widget action clicks when the app is in foreground or resumed
  static Stream<String> get onWidgetAction => _actionStreamController.stream;

  static bool _initialized = false;
  static String? _pendingAction;

  /// Initialize channel handler for receiving widget actions
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetAction') {
        final action = call.arguments?.toString();
        if (action != null && action.isNotEmpty) {
          _pendingAction = action;
          _actionStreamController.add(action);
        }
      }
    });
  }

  /// Get pending initial action if the app was launched directly from the widget
  static Future<String?> getInitialAction() async {
    try {
      final nativeAction =
          await _channel.invokeMethod<String>('getInitialWidgetAction');
      if (nativeAction != null && nativeAction.isNotEmpty) {
        _pendingAction = nativeAction;
      }
    } catch (e) {
      debugPrint('Error getting initial widget action: $e');
    }
    final result = _pendingAction;
    _pendingAction = null;
    return result;
  }

  /// Update the Android Home Screen Widget with latest finance figures
  static Future<void> updateWidget({
    required double totalBalance,
    required double totalRemaining,
    required bool isBalanceVisible,
  }) async {
    try {
      final now = DateTime.now();
      const shortMonths = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      final monthName = shortMonths[now.month - 1];
      final year = now.year;
      final dateBadge = '$monthName $year';

      final formattedBalance = FinanceProvider.formatRupiah(totalBalance);
      final rawRemaining = FinanceProvider.formatRupiah(totalRemaining);
      final remainingInfo = 'Sisa bulan ini: $rawRemaining';

      await _channel.invokeMethod('updateFinanceWidget', {
        'total_balance': formattedBalance,
        'remaining_info': remainingInfo,
        'remaining_amount': rawRemaining,
        'date_badge': dateBadge,
        'is_visible': isBalanceVisible,
      });
    } catch (e) {
      debugPrint('Error updating finance widget: $e');
    }
  }
}

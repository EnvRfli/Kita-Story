import 'package:flutter/foundation.dart';
import '../models/activity_log_model.dart';
import '../repositories/history_repository.dart';

class HistoryProvider extends ChangeNotifier {
  final HistoryRepository _repository = HistoryRepository();

  List<ActivityLogModel> _logs = [];
  List<ActivityLogModel> get logs => _filteredLogs();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Future<void> fetchLogs({bool isRefresh = false}) async {
    if (!isRefresh) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _logs = await _repository.getActivityLogs();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  List<ActivityLogModel> _filteredLogs() {
    if (_searchQuery.trim().isEmpty) {
      return _logs;
    }

    final queryLower = _searchQuery.trim().toLowerCase();
    return _logs.where((log) {
      final titleMatch = log.title.toLowerCase().contains(queryLower);
      final descMatch = log.description.toLowerCase().contains(queryLower);
      final userMatch =
          log.userName?.toLowerCase().contains(queryLower) ?? false;
      return titleMatch || descMatch || userMatch;
    }).toList();
  }
}

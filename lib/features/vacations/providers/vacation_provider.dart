import 'package:flutter/foundation.dart';
import '../models/vacation_model.dart';
import '../models/vacation_activity_model.dart';
import '../repositories/vacation_repository.dart';

enum VacationFilterTab { all, inProgress, completed }

class VacationProvider extends ChangeNotifier {
  final VacationRepository _repository = VacationRepository();

  List<VacationModel> _vacations = [];
  bool _isLoading = false;
  String? _errorMessage;

  VacationFilterTab _filterTab = VacationFilterTab.all;
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  VacationModel? _currentVacation;
  DateTime? _selectedDetailDay;
  bool _isLoadingDetail = false;

  // Getters
  List<VacationModel> get vacations => _vacations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  VacationFilterTab get filterTab => _filterTab;
  DateTime get focusedMonth => _focusedMonth;
  VacationModel? get currentVacation => _currentVacation;
  DateTime? get selectedDetailDay => _selectedDetailDay;
  bool get isLoadingDetail => _isLoadingDetail;

  int get allCount => _vacations.length;
  int get inProgressCount => _vacations.where((v) => v.isInProgress).length;
  int get completedCount => _vacations.where((v) => v.isCompleted).length;

  /// Filtered list based on active tab
  List<VacationModel> get filteredVacations {
    switch (_filterTab) {
      case VacationFilterTab.inProgress:
        return _vacations.where((v) => v.isInProgress).toList();
      case VacationFilterTab.completed:
        return _vacations.where((v) => v.isCompleted).toList();
      case VacationFilterTab.all:
        return _vacations;
    }
  }

  /// Get activities for the selected day in detail screen
  List<VacationActivityModel> get activitiesForSelectedDay {
    if (_currentVacation == null || _selectedDetailDay == null) return [];
    final sel = _selectedDetailDay!;
    return _currentVacation!.activities.where((a) {
      return a.activityDate.year == sel.year &&
          a.activityDate.month == sel.month &&
          a.activityDate.day == sel.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void setFilterTab(VacationFilterTab tab) {
    _filterTab = tab;
    notifyListeners();
  }

  void setFocusedMonth(DateTime month) {
    _focusedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  void nextMonth() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    notifyListeners();
  }

  void previousMonth() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    notifyListeners();
  }

  void resetCalendarAndFilters() {
    _filterTab = VacationFilterTab.all;
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _selectedDetailDay = null;
    notifyListeners();
  }

  void setSelectedDetailDay(DateTime day) {
    _selectedDetailDay = DateTime(day.year, day.month, day.day);
    notifyListeners();
  }

  // --- CRUD Operations ---

  Future<void> loadVacations({String? targetUserId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vacations = await _repository.getVacations(targetUserId: targetUserId);
    } catch (e) {
      _errorMessage = 'Gagal memuat jadwal liburan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVacationDetail(String id, {bool showLoading = true}) async {
    if (showLoading) {
      _isLoadingDetail = true;
      notifyListeners();
    }

    try {
      _currentVacation = await _repository.getVacationById(id);
      // Default to first day if none selected
      if (_currentVacation != null) {
        if (_selectedDetailDay == null ||
            !_currentVacation!.allDays.any((d) =>
                d.year == _selectedDetailDay!.year &&
                d.month == _selectedDetailDay!.month &&
                d.day == _selectedDetailDay!.day)) {
          _selectedDetailDay = _currentVacation!.startDate;
        }
      }
    } catch (e) {
      debugPrint('Error loading vacation detail: $e');
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<VacationModel> createVacation({
    required String title,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    bool isShared = true,
  }) async {
    final newVacation = await _repository.createVacation(
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      isShared: isShared,
    );

    await loadVacations();
    return newVacation;
  }

  Future<void> updateVacation(
    String id, {
    required String title,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    bool isShared = true,
  }) async {
    await _repository.updateVacation(
      id,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      isShared: isShared,
    );

    await loadVacations();
    if (_currentVacation?.id == id) {
      await loadVacationDetail(id, showLoading: false);
    }
  }

  Future<void> deleteVacation(String id) async {
    await _repository.deleteVacation(id);
    _vacations.removeWhere((v) => v.id == id);
    if (_currentVacation?.id == id) {
      _currentVacation = null;
    }
    notifyListeners();
  }

  Future<void> addActivity({
    required String vacationId,
    required String title,
    String? description,
    required DateTime activityDate,
    required String startTime,
    required String endTime,
  }) async {
    await _repository.addVacationActivity(
      vacationId: vacationId,
      title: title,
      description: description,
      activityDate: activityDate,
      startTime: startTime,
      endTime: endTime,
      vacationTitle: _currentVacation?.title,
    );

    await loadVacationDetail(vacationId, showLoading: false);
    // Also refresh list to reflect updated activity count / progress
    loadVacations();
  }

  Future<void> updateActivity(
    String activityId, {
    required String vacationId,
    required String title,
    String? description,
    required DateTime activityDate,
    required String startTime,
    required String endTime,
  }) async {
    await _repository.updateVacationActivity(
      activityId,
      title: title,
      description: description,
      activityDate: activityDate,
      startTime: startTime,
      endTime: endTime,
    );

    await loadVacationDetail(vacationId, showLoading: false);
  }

  Future<void> deleteActivity(String activityId, String vacationId) async {
    await _repository.deleteVacationActivity(activityId);
    await loadVacationDetail(vacationId, showLoading: false);
    loadVacations();
  }

  Future<void> toggleActivityCompleted(
    String activityId,
    bool isCompleted, {
    required String vacationId,
    String? activityTitle,
  }) async {
    await _repository.toggleActivityCompleted(
      activityId,
      isCompleted,
      vacationId: vacationId,
      activityTitle: activityTitle,
      vacationTitle: _currentVacation?.title,
    );

    await loadVacationDetail(vacationId, showLoading: false);
    loadVacations();
  }
}

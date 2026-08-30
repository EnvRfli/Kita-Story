import 'vacation_activity_model.dart';

enum VacationStatus { inProgress, upcoming, completed }

class VacationModel {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final bool isShared;
  final String? partnerId;
  final String? addedBy;
  final String? lastUpdatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<VacationActivityModel> activities;

  VacationModel({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    this.isShared = true,
    this.partnerId,
    this.addedBy,
    this.lastUpdatedBy,
    this.createdAt,
    this.updatedAt,
    this.activities = const [],
  });

  factory VacationModel.fromJson(
    Map<String, dynamic> json, {
    List<VacationActivityModel>? activities,
  }) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      return DateTime.tryParse(val.toString())?.toLocal() ?? DateTime.now();
    }

    final acts = activities ??
        (json['vacation_activities'] is List
            ? (json['vacation_activities'] as List)
                .map((a) =>
                    VacationActivityModel.fromJson(a as Map<String, dynamic>))
                .toList()
            : <VacationActivityModel>[]);

    return VacationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      isShared: json['is_shared'] as bool? ?? true,
      partnerId: json['partner_id'] as String?,
      addedBy: json['added_by'] as String?,
      lastUpdatedBy: json['last_updated_by'] as String?,
      createdAt: json['created_at'] != null
          ? parseDate(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? parseDate(json['updated_at'])
          : null,
      activities: acts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title.trim(),
      'description': description?.trim(),
      'start_date':
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'end_date':
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      'is_shared': isShared,
      if (partnerId != null) 'partner_id': partnerId,
      if (addedBy != null) 'added_by': addedBy,
      if (lastUpdatedBy != null) 'last_updated_by': lastUpdatedBy,
    };
  }

  static const List<String> _monthsLong = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  static String _formatDateLong(DateTime dt) {
    return '${dt.day} ${_monthsLong[dt.month - 1]} ${dt.year}';
  }

  /// Whether the vacation spans a single day
  bool get isSingleDay {
    return startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;
  }

  /// Formatted date range string (e.g. "11 April 2026 - 13 April 2026" or "11 April 2026")
  String get formattedDateRange {
    if (isSingleDay) {
      return _formatDateLong(startDate);
    }
    return '${_formatDateLong(startDate)} - ${_formatDateLong(endDate)}';
  }

  /// Total duration in days
  int get totalDays {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1;
  }

  /// Returns list of all dates in the vacation range
  List<DateTime> get allDays {
    final days = <DateTime>[];
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    while (!current.isAfter(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  /// Determines the status of the vacation
  VacationStatus get status {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (activities.isNotEmpty &&
        activities.every((activity) => activity.isCompleted)) {
      return VacationStatus.completed;
    }

    if (end.isBefore(today)) {
      return VacationStatus.completed;
    }

    if (today.isBefore(start)) {
      return VacationStatus.upcoming;
    }

    // In-progress: start <= today <= end
    return VacationStatus.inProgress;
  }

  bool get isInProgress => status == VacationStatus.inProgress;
  bool get isUpcoming => status == VacationStatus.upcoming;
  bool get isCompleted => status == VacationStatus.completed;

  /// Progress ratio (0.0 to 1.0)
  double get progressRatio {
    if (activities.isNotEmpty) {
      final completed = activities.where((a) => a.isCompleted).length;
      return completed / activities.length;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (today.isBefore(start)) return 0.0;
    if (today.isAfter(end)) return 1.0;

    final total = end.difference(start).inDays + 1;
    final passed = today.difference(start).inDays + 1;
    if (total <= 0) return 1.0;
    return (passed / total).clamp(0.0, 1.0);
  }

  VacationModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isShared,
    String? partnerId,
    String? addedBy,
    String? lastUpdatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<VacationActivityModel>? activities,
  }) {
    return VacationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isShared: isShared ?? this.isShared,
      partnerId: partnerId ?? this.partnerId,
      addedBy: addedBy ?? this.addedBy,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activities: activities ?? this.activities,
    );
  }
}

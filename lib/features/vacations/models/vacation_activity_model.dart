import '../../../core/utils/date_formatter.dart';

class VacationActivityModel {
  final String id;
  final String vacationId;
  final String title;
  final String? description;
  final DateTime activityDate;
  final String startTime;
  final String endTime;
  final bool isCompleted;
  final int sortOrder;
  final String? addedBy;
  final DateTime? createdAt;

  VacationActivityModel({
    required this.id,
    required this.vacationId,
    required this.title,
    this.description,
    required this.activityDate,
    required this.startTime,
    required this.endTime,
    this.isCompleted = false,
    this.sortOrder = 0,
    this.addedBy,
    this.createdAt,
  });

  factory VacationActivityModel.fromJson(Map<String, dynamic> json) {
    // Parse time strings (e.g. '09:00:00' -> '09:00')
    String parseTime(dynamic val) {
      if (val == null) return '00:00';
      final str = val.toString();
      final parts = str.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
      return str;
    }

    return VacationActivityModel(
      id: json['id'] as String? ?? '',
      vacationId: json['vacation_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      activityDate: json['activity_date'] != null
          ? DateTime.tryParse(json['activity_date'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
      startTime: parseTime(json['start_time']),
      endTime: parseTime(json['end_time']),
      isCompleted: json['is_completed'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      addedBy: json['added_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vacation_id': vacationId,
      'title': title.trim(),
      'description': description?.trim(),
      'activity_date':
          '${activityDate.year}-${activityDate.month.toString().padLeft(2, '0')}-${activityDate.day.toString().padLeft(2, '0')}',
      'start_time': startTime,
      'end_time': endTime,
      'is_completed': isCompleted,
      'sort_order': sortOrder,
      if (addedBy != null) 'added_by': addedBy,
    };
  }

  String get timeRange => '$startTime - $endTime';

  String get formattedDate => DateFormatter.formatActivityDate(activityDate);

  VacationActivityModel copyWith({
    String? id,
    String? vacationId,
    String? title,
    String? description,
    DateTime? activityDate,
    String? startTime,
    String? endTime,
    bool? isCompleted,
    int? sortOrder,
    String? addedBy,
    DateTime? createdAt,
  }) {
    return VacationActivityModel(
      id: id ?? this.id,
      vacationId: vacationId ?? this.vacationId,
      title: title ?? this.title,
      description: description ?? this.description,
      activityDate: activityDate ?? this.activityDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
      addedBy: addedBy ?? this.addedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

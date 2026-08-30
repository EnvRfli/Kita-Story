class ReminderModel {
  final String id;
  final String title;
  final String? description;
  final DateTime targetDate;
  final bool hasCustomTime;
  final String reminderLeadTime; // 'on_time', '1_hour_before', '1_day_before', '3_days_before', '1_week_before', '1_month_before'
  final bool isShared;
  final String? partnerId;
  final bool isCompleted;
  final String? addedBy;
  final String? lastUpdatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReminderModel({
    required this.id,
    required this.title,
    this.description,
    required this.targetDate,
    this.hasCustomTime = false,
    this.reminderLeadTime = 'on_time',
    this.isShared = false,
    this.partnerId,
    this.isCompleted = false,
    this.addedBy,
    this.lastUpdatedBy,
    this.createdAt,
    this.updatedAt,
  });

  bool get isExpired => targetDate.isBefore(DateTime.now());

  /// Short countdown label for badges (e.g., "3 hari", "1 bulan", "1 tahun", "Kadaluarsa")
  String get countdownText {
    final now = DateTime.now();
    final difference = targetDate.difference(now);

    if (difference.isNegative && difference.inDays != 0) {
      return 'Kadaluarsa';
    }

    final days = difference.inDays;
    final hours = difference.inHours;

    if (days <= 0 && hours <= 0 && difference.inMinutes < 0) {
      return 'Kadaluarsa';
    }

    if (days <= 0) {
      if (hours > 0) return '$hours jam';
      final minutes = difference.inMinutes;
      if (minutes > 0) return '$minutes mnt';
      return 'Hari ini';
    }

    if (days < 30) {
      return '$days hari';
    }

    final months = (days / 30).floor();
    if (days < 365) {
      return '$months bulan';
    }

    final years = (days / 365).floor();
    return '$years tahun';
  }

  /// Detailed countdown label (e.g. "3 hari lagi", "Hari ini", "Kadaluarsa")
  String get countdownDetailedText {
    final text = countdownText;
    if (text == 'Kadaluarsa' || text == 'Hari ini') return text;
    return '$text lagi';
  }

  /// Formatted date string in Indonesian (e.g., "11 April 2026" or "11 April 2026, 14:30")
  String get formattedDate {
    const months = [
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

    final day = targetDate.day;
    final month = months[targetDate.month - 1];
    final year = targetDate.year;

    if (hasCustomTime) {
      final hour = targetDate.hour.toString().padLeft(2, '0');
      final minute = targetDate.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute';
    }

    return '$day $month $year';
  }

  /// Label for lead time dropdown
  String get leadTimeLabel {
    switch (reminderLeadTime) {
      case '1_hour_before':
        return '1 jam sebelumnya';
      case '1_day_before':
        return '1 hari sebelumnya';
      case '3_days_before':
        return '3 hari sebelumnya';
      case '1_week_before':
        return '1 minggu sebelumnya';
      case '1_month_before':
        return '1 bulan sebelumnya';
      case 'on_time':
      default:
        return 'Saat waktu tiba';
    }
  }

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Tanpa Judul',
      description: json['description'] as String?,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String).toLocal()
          : DateTime.now(),
      hasCustomTime: json['has_custom_time'] as bool? ?? false,
      reminderLeadTime: json['reminder_lead_time'] as String? ?? 'on_time',
      isShared: json['is_shared'] as bool? ?? false,
      partnerId: json['partner_id'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      addedBy: json['added_by'] as String?,
      lastUpdatedBy: json['last_updated_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target_date': targetDate.toUtc().toIso8601String(),
      'has_custom_time': hasCustomTime,
      'reminder_lead_time': reminderLeadTime,
      'is_shared': isShared,
      if (partnerId != null) 'partner_id': partnerId,
      'is_completed': isCompleted,
      if (addedBy != null) 'added_by': addedBy,
      if (lastUpdatedBy != null) 'last_updated_by': lastUpdatedBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ReminderModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? targetDate,
    bool? hasCustomTime,
    String? reminderLeadTime,
    bool? isShared,
    String? partnerId,
    bool? isCompleted,
    String? addedBy,
    String? lastUpdatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      hasCustomTime: hasCustomTime ?? this.hasCustomTime,
      reminderLeadTime: reminderLeadTime ?? this.reminderLeadTime,
      isShared: isShared ?? this.isShared,
      partnerId: partnerId ?? this.partnerId,
      isCompleted: isCompleted ?? this.isCompleted,
      addedBy: addedBy ?? this.addedBy,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

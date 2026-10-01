class UserFinanceSettingsModel {
  final String userId;
  final int? summaryStartDay; // 1 to 31, or null for all-time default
  final DateTime? updatedAt;

  const UserFinanceSettingsModel({
    required this.userId,
    this.summaryStartDay,
    this.updatedAt,
  });

  bool get hasCustomStartDay => summaryStartDay != null && summaryStartDay! >= 1 && summaryStartDay! <= 31;

  UserFinanceSettingsModel copyWith({
    String? userId,
    int? summaryStartDay,
    bool clearStartDay = false,
    DateTime? updatedAt,
  }) {
    return UserFinanceSettingsModel(
      userId: userId ?? this.userId,
      summaryStartDay: clearStartDay ? null : (summaryStartDay ?? this.summaryStartDay),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserFinanceSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserFinanceSettingsModel(
      userId: json['user_id'] as String? ?? json['id'] as String? ?? '',
      summaryStartDay: json['summary_start_day'] as int?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'summary_start_day': summaryStartDay,
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}

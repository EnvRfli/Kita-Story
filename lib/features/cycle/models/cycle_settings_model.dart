import '../utils/cycle_date_utils.dart';

class CycleSettingsModel {
  final String userId;
  final int cycleLength;
  final int periodLength;
  final DateTime? lastPeriodStart;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CycleSettingsModel({
    required this.userId,
    this.cycleLength = 28,
    this.periodLength = 5,
    this.lastPeriodStart,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasPeriodStart => lastPeriodStart != null;

  factory CycleSettingsModel.fromJson(Map<String, dynamic> json) {
    return CycleSettingsModel(
      userId: (json['user_id'] ?? '').toString(),
      cycleLength: (json['cycle_length'] as num?)?.toInt() ?? 28,
      periodLength: (json['period_length'] as num?)?.toInt() ?? 5,
      lastPeriodStart: cycleParseDate(json['last_period_start']),
      createdAt: cycleParseDate(json['created_at']),
      updatedAt: cycleParseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'cycle_length': cycleLength,
      'period_length': periodLength,
      'last_period_start':
          lastPeriodStart == null ? null : cycleIsoDate(lastPeriodStart!),
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),
    };
  }

  CycleSettingsModel copyWith({
    String? userId,
    int? cycleLength,
    int? periodLength,
    DateTime? lastPeriodStart,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CycleSettingsModel(
      userId: userId ?? this.userId,
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

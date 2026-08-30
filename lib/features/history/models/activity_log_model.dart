import '../../../core/utils/date_formatter.dart';

class ActivityLogModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userPhotoUrl;
  final String activityType;
  final String title;
  final String description;
  final int pointsEarned;
  final String? referenceId;
  final DateTime createdAt;

  ActivityLogModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userPhotoUrl,
    required this.activityType,
    required this.title,
    required this.description,
    required this.pointsEarned,
    this.referenceId,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    String? name;
    String? photo;
    if (json['app_users'] is Map<String, dynamic>) {
      final userMap = json['app_users'] as Map<String, dynamic>;
      name = userMap['name'] as String? ?? userMap['display_name'] as String?;
      photo = userMap['photo_url'] as String?;
    }

    return ActivityLogModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userName: name,
      userPhotoUrl: photo,
      activityType: json['activity_type'] as String? ?? 'general',
      title: json['title'] as String? ?? 'Aktivitas Baru',
      description: json['description'] as String? ?? '',
      pointsEarned: (json['points_earned'] as num?)?.toInt() ??
          (json['points'] as num?)?.toInt() ??
          0,
      referenceId: json['reference_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  /// Clean display title (strips trailing emojis for elegant typography)
  String get displayTitle {
    return title
        .replaceAll(
          RegExp(
            r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]',
            unicode: true,
          ),
          '',
        )
        .trim();
  }

  /// Formatted date string (e.g., "11 Apr 2026, 11:00")
  String get formattedDate {
    return DateFormatter.formatActivityDate(createdAt);
  }
}

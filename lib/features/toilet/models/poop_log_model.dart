import 'package:flutter/material.dart';
import '../../../core/utils/date_formatter.dart';

class PoopLogModel {
  final String id;
  final String userId;
  final String? partnerId;
  final bool isShared;
  final DateTime poopedAt;
  final bool isBackdated;
  final String locationName;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final bool isManualLocation;
  final String stoolType; // 'normal', 'hard', 'soft', 'liquid'
  final String feeling; // 'relieved', 'quick', 'struggle', 'stomachache'
  final int durationMinutes;
  final String? note;
  final String addedBy;
  final String? lastUpdatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined profile fields from app_users
  final String? userName;
  final String? userPhotoUrl;
  final String? userGender;

  const PoopLogModel({
    required this.id,
    required this.userId,
    this.partnerId,
    this.isShared = true,
    required this.poopedAt,
    this.isBackdated = false,
    required this.locationName,
    this.locationAddress,
    this.latitude,
    this.longitude,
    this.isManualLocation = false,
    this.stoolType = 'normal',
    this.feeling = 'relieved',
    this.durationMinutes = 5,
    this.note,
    required this.addedBy,
    this.lastUpdatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userPhotoUrl,
    this.userGender,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  String get formattedCoordinates {
    if (!hasCoordinates) return '-';
    return '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}';
  }

  String get relativeTime => DateFormatter.formatRelativeTime(poopedAt);

  String get formattedDateTime => DateFormatter.formatActivityDate(poopedAt);

  String get stoolTypeLabel {
    switch (stoolType) {
      case 'hard':
        return 'Agak Keras / Sembelit 🪨';
      case 'soft':
        return 'Lembek / Mulas 🍦';
      case 'liquid':
        return 'Cair / Diare 🌊';
      case 'normal':
      default:
        return 'Normal & Lancar ✨';
    }
  }

  String get stoolTypeShort {
    switch (stoolType) {
      case 'hard':
        return 'Keras 🪨';
      case 'soft':
        return 'Lembek 🍦';
      case 'liquid':
        return 'Cair 🌊';
      case 'normal':
      default:
        return 'Normal ✨';
    }
  }

  String get stoolTypeEmoji {
    switch (stoolType) {
      case 'hard':
        return '🪨';
      case 'soft':
        return '🍦';
      case 'liquid':
        return '🌊';
      case 'normal':
      default:
        return '✨';
    }
  }

  Color get stoolTypeColor {
    switch (stoolType) {
      case 'hard':
        return const Color(0xFFD97706);
      case 'soft':
        return const Color(0xFF8B5CF6);
      case 'liquid':
        return const Color(0xFFEF4444);
      case 'normal':
      default:
        return const Color(0xFF10B981);
    }
  }

  Color get stoolTypeBgColor {
    switch (stoolType) {
      case 'hard':
        return const Color(0xFFFEF3C7);
      case 'soft':
        return const Color(0xFFF3E8FF);
      case 'liquid':
        return const Color(0xFFFEE2E2);
      case 'normal':
      default:
        return const Color(0xFFD1FAE5);
    }
  }

  String get feelingLabel {
    switch (feeling) {
      case 'quick':
        return 'Kilat & Cepat ⚡';
      case 'struggle':
        return 'Perjuangan Berat 🥵';
      case 'stomachache':
        return 'Mulas / Sakit Perut 🤕';
      case 'relieved':
      default:
        return 'Lega Banget! 😌';
    }
  }

  String get feelingShort {
    switch (feeling) {
      case 'quick':
        return 'Kilat ⚡';
      case 'struggle':
        return 'Perjuangan 🥵';
      case 'stomachache':
        return 'Mulas 🤕';
      case 'relieved':
      default:
        return 'Lega 😌';
    }
  }

  String get feelingEmoji {
    switch (feeling) {
      case 'quick':
        return '⚡';
      case 'struggle':
        return '🥵';
      case 'stomachache':
        return '🤕';
      case 'relieved':
      default:
        return '😌';
    }
  }

  factory PoopLogModel.fromJson(Map<String, dynamic> json) {
    final userObj = json['app_users'] as Map<String, dynamic>?;
    final rawPoopedAt = json['pooped_at'] != null
        ? DateTime.tryParse(json['pooped_at'].toString())
        : null;
    final rawCreatedAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null;
    final rawUpdatedAt = json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString())
        : null;

    return PoopLogModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      partnerId: json['partner_id']?.toString(),
      isShared: (json['is_shared'] as bool?) ?? true,
      poopedAt: DateFormatter.parseAndSanitize(rawPoopedAt),
      isBackdated: (json['is_backdated'] as bool?) ?? false,
      locationName: (json['location_name'] as String?)?.trim().isNotEmpty == true
          ? (json['location_name'] as String).trim()
          : 'Lokasi Toilet',
      locationAddress: (json['location_address'] as String?)?.trim(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isManualLocation: (json['is_manual_location'] as bool?) ?? false,
      stoolType: (json['stool_type'] as String?) ?? 'normal',
      feeling: (json['feeling'] as String?) ?? 'relieved',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 5,
      note: (json['note'] as String?)?.trim(),
      addedBy: (json['added_by'] ?? json['user_id'] ?? '').toString(),
      lastUpdatedBy: json['last_updated_by']?.toString(),
      createdAt: DateFormatter.parseAndSanitize(rawCreatedAt),
      updatedAt: DateFormatter.parseAndSanitize(rawUpdatedAt),
      userName: (userObj?['name'] as String?) ??
          (json['user_name'] as String?),
      userPhotoUrl: (userObj?['photo_url'] as String?) ??
          (json['user_photo_url'] as String?),
      userGender: (userObj?['gender'] as String?) ??
          (json['user_gender'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (partnerId != null) 'partner_id': partnerId,
      'is_shared': isShared,
      'pooped_at': poopedAt.toUtc().toIso8601String(),
      'is_backdated': isBackdated,
      'location_name': locationName,
      'location_address': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'is_manual_location': isManualLocation,
      'stool_type': stoolType,
      'feeling': feeling,
      'duration_minutes': durationMinutes,
      'note': note,
      'added_by': addedBy,
      if (lastUpdatedBy != null) 'last_updated_by': lastUpdatedBy,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  PoopLogModel copyWith({
    String? id,
    String? userId,
    String? partnerId,
    bool? isShared,
    DateTime? poopedAt,
    bool? isBackdated,
    String? locationName,
    String? locationAddress,
    double? latitude,
    double? longitude,
    bool? isManualLocation,
    String? stoolType,
    String? feeling,
    int? durationMinutes,
    String? note,
    String? addedBy,
    String? lastUpdatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userPhotoUrl,
    String? userGender,
  }) {
    return PoopLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      partnerId: partnerId ?? this.partnerId,
      isShared: isShared ?? this.isShared,
      poopedAt: poopedAt ?? this.poopedAt,
      isBackdated: isBackdated ?? this.isBackdated,
      locationName: locationName ?? this.locationName,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isManualLocation: isManualLocation ?? this.isManualLocation,
      stoolType: stoolType ?? this.stoolType,
      feeling: feeling ?? this.feeling,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      note: note ?? this.note,
      addedBy: addedBy ?? this.addedBy,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      userGender: userGender ?? this.userGender,
    );
  }
}

/// Playful Digestive Status based on hours/days elapsed since the last poop
class DigestiveStatusInfo {
  final int daysSince;
  final String iconEmoji;
  final String badgeLabel;
  final String tipText;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final Color accentColor;
  final bool isWarning;

  const DigestiveStatusInfo({
    required this.daysSince,
    required this.iconEmoji,
    required this.badgeLabel,
    required this.tipText,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.accentColor,
    this.isWarning = false,
  });

  static DigestiveStatusInfo fromLastPoop(DateTime? lastPoopTime) {
    if (lastPoopTime == null) {
      return const DigestiveStatusInfo(
        daysSince: -1,
        iconEmoji: '🚽',
        badgeLabel: 'Belum Catat',
        tipText: 'Yuk catat poop pertamamu & makan makanan berserat! 🥦🍎',
        badgeBgColor: Color(0xFFF1F5F9),
        badgeTextColor: Color(0xFF64748B),
        accentColor: Color(0xFF94A3B8),
        isWarning: false,
      );
    }

    final now = DateTime.now();
    final diffHours = now.difference(lastPoopTime).inHours;
    final days = (diffHours / 24).floor().clamp(0, 999);

    if (days <= 0) {
      // < 24 hours
      return const DigestiveStatusInfo(
        daysSince: 0,
        iconEmoji: '💩',
        badgeLabel: 'Lancar Jaya ✨',
        tipText: 'Pencernaan sehat & lega! Pertahankan minum air putih ya 💧',
        badgeBgColor: Color(0xFFD1FAE5),
        badgeTextColor: Color(0xFF047857),
        accentColor: Color(0xFF10B981),
        isWarning: false,
      );
    } else if (days == 1) {
      // 1 Day (24-47h)
      return const DigestiveStatusInfo(
        daysSince: 1,
        iconEmoji: '🌱',
        badgeLabel: '1 Hari Belum Poop',
        tipText: 'Waktunya makan buah & sayur berserat hari ini! 🍎🥦',
        badgeBgColor: Color(0xFFFEF3C7),
        badgeTextColor: Color(0xFFB45309),
        accentColor: Color(0xFFF59E0B),
        isWarning: false,
      );
    } else if (days == 2) {
      // 2 Days (48-71h)
      return const DigestiveStatusInfo(
        daysSince: 2,
        iconEmoji: '🎈',
        badgeLabel: '2 Hari Belum Poop!',
        tipText: 'Mulai penuh nih! Yuk makan pepaya, oatmeal, atau yogurt 🥭🥣',
        badgeBgColor: Color(0xFFFFEDD5),
        badgeTextColor: Color(0xFFC2410C),
        accentColor: Color(0xFFF97316),
        isWarning: true,
      );
    } else if (days == 3) {
      // 3 Days (72-95h)
      return const DigestiveStatusInfo(
        daysSince: 3,
        iconEmoji: '🪨',
        badgeLabel: '3 Hari! Awas Sembelit',
        tipText: 'Darurat serat! Perbanyak buah naga, sayur & air hangat 🐉🍵',
        badgeBgColor: Color(0xFFFEE2E2),
        badgeTextColor: Color(0xFFB91C1C),
        accentColor: Color(0xFFEF4444),
        isWarning: true,
      );
    } else {
      // >= 4 Days (96+h)
      return DigestiveStatusInfo(
        daysSince: days,
        iconEmoji: '🚨',
        badgeLabel: '$days Hari Belum Poop!',
        tipText:
            'Bahaya sembelit! Wajib asupan serat tinggi / probiotik sekarang! 🆘',
        badgeBgColor: const Color(0xFFFFE4E6),
        badgeTextColor: const Color(0xFFBE123C),
        accentColor: const Color(0xFFF43F5E),
        isWarning: true,
      );
    }
  }
}

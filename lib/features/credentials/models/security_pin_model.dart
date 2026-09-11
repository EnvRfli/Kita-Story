class SecurityPinModel {
  final String userId;
  final String pinHash;
  final String salt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SecurityPinModel({
    required this.userId,
    required this.pinHash,
    required this.salt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SecurityPinModel.fromJson(Map<String, dynamic> json) {
    return SecurityPinModel(
      userId: json['user_id'] as String,
      pinHash: json['pin_hash'] as String,
      salt: json['salt'] as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'pin_hash': pinHash,
      'salt': salt,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

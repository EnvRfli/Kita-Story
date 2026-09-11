class CredentialCategoryModel {
  final String id;
  final String name;
  final String? userId;
  final DateTime createdAt;

  CredentialCategoryModel({
    required this.id,
    required this.name,
    this.userId,
    required this.createdAt,
  });

  factory CredentialCategoryModel.fromJson(Map<String, dynamic> json) {
    return CredentialCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      userId: json['user_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (userId != null) 'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

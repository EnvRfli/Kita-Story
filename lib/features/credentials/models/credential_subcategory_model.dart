class CredentialSubcategoryModel {
  final String id;
  final String categoryId;
  final String name;
  final String? userId;
  final DateTime createdAt;

  CredentialSubcategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.userId,
    required this.createdAt,
  });

  factory CredentialSubcategoryModel.fromJson(Map<String, dynamic> json) {
    return CredentialSubcategoryModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      userId: json['user_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      if (userId != null) 'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

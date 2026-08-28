class UserModel {
  final String id;
  final String name;
  final DateTime? birthdate;
  final int points;
  final String? photoUrl;
  final String? partnerId;

  UserModel({
    required this.id,
    required this.name,
    this.birthdate,
    this.points = 0,
    this.photoUrl,
    this.partnerId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      birthdate: json['birthdate'] != null
          ? DateTime.tryParse(json['birthdate'] as String)
          : null,
      points: json['points'] as int? ?? 0,
      photoUrl: json['photo_url'] as String?,
      partnerId: json['partner_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (birthdate != null) 'birthdate': birthdate!.toIso8601String(),
      'points': points,
      'photo_url': photoUrl,
      'partner_id': partnerId,
    };
  }
}

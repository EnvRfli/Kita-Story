class UserModel {
  final String id;
  final String name;
  final DateTime? birthdate;
  final int points;

  UserModel({
    required this.id,
    required this.name,
    this.birthdate,
    this.points = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      birthdate: json['birthdate'] != null ? DateTime.parse(json['birthdate'] as String) : null,
      points: json['points'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (birthdate != null) 'birthdate': birthdate!.toIso8601String(),
      'points': points,
    };
  }
}

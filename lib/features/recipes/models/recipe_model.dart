class RecipeIngredientModel {
  final String name;
  final String quantity;

  const RecipeIngredientModel({
    required this.name,
    required this.quantity,
  });

  factory RecipeIngredientModel.fromJson(Map<String, dynamic> json) {
    return RecipeIngredientModel(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
    };
  }

  RecipeIngredientModel copyWith({
    String? name,
    String? quantity,
  }) {
    return RecipeIngredientModel(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
    );
  }
}

class RecipeStepModel {
  final int step;
  final String text;
  final String? imageUrl;

  const RecipeStepModel({
    required this.step,
    required this.text,
    this.imageUrl,
  });

  factory RecipeStepModel.fromJson(Map<String, dynamic> json) {
    return RecipeStepModel(
      step: json['step'] as int? ?? 1,
      text: json['text'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': step,
      'text': text,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }

  RecipeStepModel copyWith({
    int? step,
    String? text,
    String? imageUrl,
  }) {
    return RecipeStepModel(
      step: step ?? this.step,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class RecipeModel {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String cookingDuration; // e.g. "55 menit"
  final String portionSize;     // e.g. "2-3 porsi"
  final List<RecipeIngredientModel> ingredients;
  final List<RecipeStepModel> instructions;
  final String? addedBy;
  final String? lastUpdatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RecipeModel({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.cookingDuration = '30 menit',
    this.portionSize = '2-3 porsi',
    this.ingredients = const [],
    this.instructions = const [],
    this.addedBy,
    this.lastUpdatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    var rawIngredients = json['ingredients'];
    List<RecipeIngredientModel> parsedIngredients = [];
    if (rawIngredients is List) {
      parsedIngredients = rawIngredients
          .map((i) => RecipeIngredientModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    var rawInstructions = json['instructions'];
    List<RecipeStepModel> parsedInstructions = [];
    if (rawInstructions is List) {
      parsedInstructions = rawInstructions
          .map((s) => RecipeStepModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return RecipeModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Tanpa Judul Resep',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      cookingDuration: json['cooking_duration'] as String? ?? '30 menit',
      portionSize: json['portion_size'] as String? ?? '2-3 porsi',
      ingredients: parsedIngredients,
      instructions: parsedInstructions,
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
      if (imageUrl != null) 'image_url': imageUrl,
      'cooking_duration': cookingDuration,
      'portion_size': portionSize,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions.map((s) => s.toJson()).toList(),
      if (addedBy != null) 'added_by': addedBy,
      if (lastUpdatedBy != null) 'last_updated_by': lastUpdatedBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  RecipeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? cookingDuration,
    String? portionSize,
    List<RecipeIngredientModel>? ingredients,
    List<RecipeStepModel>? instructions,
    String? addedBy,
    String? lastUpdatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      cookingDuration: cookingDuration ?? this.cookingDuration,
      portionSize: portionSize ?? this.portionSize,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      addedBy: addedBy ?? this.addedBy,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

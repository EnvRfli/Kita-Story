import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/activity_log_service.dart';
import '../models/recipe_model.dart';

class RecipeRepository {
  final SupabaseClient _client = SupabaseNetwork.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Fetch recipes belonging to user or partner
  Future<List<RecipeModel>> getRecipes({String? targetUserId}) async {
    final userId = targetUserId ?? currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('recipes')
        .select('*')
        .eq('added_by', userId)
        .order('created_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data
        .map((json) => RecipeModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch single recipe by ID
  Future<RecipeModel?> getRecipeById(String recipeId) async {
    final response = await _client
        .from('recipes')
        .select('*')
        .eq('id', recipeId)
        .maybeSingle();

    if (response == null) return null;
    return RecipeModel.fromJson(response);
  }

  /// Create new recipe (Awards +10 Points and records to user_point_logs)
  Future<RecipeModel> createRecipe({
    required String title,
    String? description,
    String? imageUrl,
    required String cookingDuration,
    required String portionSize,
    required List<RecipeIngredientModel> ingredients,
    required List<RecipeStepModel> instructions,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User tidak terautentikasi.');
    }

    final response = await _client
        .from('recipes')
        .insert({
          'title': title.trim(),
          'description': description?.trim(),
          'image_url': imageUrl,
          'cooking_duration': cookingDuration.trim(),
          'portion_size': portionSize.trim(),
          'ingredients': ingredients.map((i) => i.toJson()).toList(),
          'instructions': instructions.map((s) => s.toJson()).toList(),
          'added_by': userId,
          'last_updated_by': userId,
        })
        .select()
        .single();

    // Award +10 Points and record activity log
    await ActivityLogService.recordActivityAndAddPoints(
      userId: userId,
      points: 10,
      activityType: 'add_recipe',
      title: 'Menambah Resep Baru 🍳',
      description:
          'Menulis resep "${title.trim()}" ($cookingDuration, $portionSize)',
      referenceId: response['id'] as String?,
    );

    return RecipeModel.fromJson(response);
  }

  /// Update existing recipe (Awards +3 Points)
  Future<void> updateRecipe(
    String recipeId, {
    required String title,
    String? description,
    String? imageUrl,
    required String cookingDuration,
    required String portionSize,
    required List<RecipeIngredientModel> ingredients,
    required List<RecipeStepModel> instructions,
  }) async {
    final userId = currentUserId;

    await _client.from('recipes').update({
      'title': title.trim(),
      'description': description?.trim(),
      'image_url': imageUrl,
      'cooking_duration': cookingDuration.trim(),
      'portion_size': portionSize.trim(),
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions.map((s) => s.toJson()).toList(),
      'last_updated_by': userId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', recipeId);

    // Award +3 Points and record activity log
    if (userId != null) {
      await ActivityLogService.recordActivityAndAddPoints(
        userId: userId,
        points: 3,
        activityType: 'update_recipe',
        title: 'Memperbarui Resep 📝',
        description: 'Memperbarui resep masakan "${title.trim()}"',
        referenceId: recipeId,
      );
    }
  }

  /// Delete recipe
  Future<void> deleteRecipe(String recipeId) async {
    await _client.from('recipes').delete().eq('id', recipeId);
  }
}

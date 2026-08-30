import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';
import '../repositories/recipe_repository.dart';

class RecipeProvider extends ChangeNotifier {
  final RecipeRepository _repository = RecipeRepository();

  List<RecipeModel> _recipes = [];
  List<RecipeModel> get recipes => _recipes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRecipes({String? targetUserId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recipes = await _repository.getRecipes(targetUserId: targetUserId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRecipe({
    required String title,
    String? description,
    String? imageUrl,
    required String cookingDuration,
    required String portionSize,
    required List<RecipeIngredientModel> ingredients,
    required List<RecipeStepModel> instructions,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newRecipe = await _repository.createRecipe(
        title: title,
        description: description,
        imageUrl: imageUrl,
        cookingDuration: cookingDuration,
        portionSize: portionSize,
        ingredients: ingredients,
        instructions: instructions,
      );

      _recipes.insert(0, newRecipe);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRecipe(
    String recipeId, {
    required String title,
    String? description,
    String? imageUrl,
    required String cookingDuration,
    required String portionSize,
    required List<RecipeIngredientModel> ingredients,
    required List<RecipeStepModel> instructions,
  }) async {
    try {
      await _repository.updateRecipe(
        recipeId,
        title: title,
        description: description,
        imageUrl: imageUrl,
        cookingDuration: cookingDuration,
        portionSize: portionSize,
        ingredients: ingredients,
        instructions: instructions,
      );

      final index = _recipes.indexWhere((r) => r.id == recipeId);
      if (index != -1) {
        _recipes[index] = _recipes[index].copyWith(
          title: title,
          description: description,
          imageUrl: imageUrl,
          cookingDuration: cookingDuration,
          portionSize: portionSize,
          ingredients: ingredients,
          instructions: instructions,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteRecipe(String recipeId) async {
    try {
      await _repository.deleteRecipe(recipeId);
      _recipes.removeWhere((r) => r.id == recipeId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}

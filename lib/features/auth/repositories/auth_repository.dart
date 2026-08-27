import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../../core/network/supabase_client.dart';

class AuthRepository {
  final _client = SupabaseNetwork.client;

  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmailPassword(String email, String password, String name) async {
    final response = await _client.auth.signUp(email: email, password: password);
    
    if (response.user != null) {
      // create user profile in app_users
      await _client.from('app_users').insert({
        'id': response.user!.id,
        'name': name,
        'password_hash': 'managed_by_supabase_auth', 
        // We use supabase auth, so password_hash is not strictly needed, 
        // but schema has it as NOT NULL, so we fill dummy or we should alter schema later.
      });
    }
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final data = await _client.from('app_users').select().eq('id', userId).single();
      return UserModel.fromJson(data);
    } catch (e) {
      return null; // Handle error appropriately in production
    }
  }
}

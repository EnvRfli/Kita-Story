import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/activity_log_service.dart';

class AuthRepository {
  final _client = SupabaseNetwork.client;

  Future<AuthResponse> signInWithEmailPassword(
      String email, String password) async {
    return await _client.auth
        .signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmailPassword(
      String email, String password, String name) async {
    final response =
        await _client.auth.signUp(email: email, password: password);

    if (response.user != null) {
      // create user profile in app_users
      await _client.from('app_users').insert({
        'id': response.user!.id,
        'name': name,
        'password_hash': 'managed_by_supabase_auth',
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
      final data =
          await _client.from('app_users').select().eq('id', userId).single();
      return UserModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfilePhoto(String userId, String photoUrl) async {
    await _client.from('app_users').update({
      'photo_url': photoUrl,
    }).eq('id', userId);

    // Award +5 Points and log
    await ActivityLogService.recordActivityAndAddPoints(
      userId: userId,
      points: 5,
      activityType: 'update_avatar',
      title: 'Ganti Foto Profil 🖼️',
      description: 'Memperbarui foto profil akun',
    );
  }

  Future<void> updateAccount({
    required String userId,
    required String name,
    String? newEmail,
    String? currentPassword,
    String? newPassword,
  }) async {
    final currentUser = _client.auth.currentUser;
    final currentEmail = currentUser?.email;

    // 1. If email or password is being changed, re-authenticate if currentPassword provided
    final isChangingEmail = newEmail != null &&
        newEmail.trim().isNotEmpty &&
        newEmail.trim().toLowerCase() != currentEmail?.toLowerCase();
    final isChangingPassword =
        newPassword != null && newPassword.trim().isNotEmpty;

    if (isChangingEmail || isChangingPassword) {
      if (currentPassword != null &&
          currentPassword.isNotEmpty &&
          currentEmail != null) {
        await _client.auth.signInWithPassword(
          email: currentEmail,
          password: currentPassword,
        );
      }

      if (isChangingEmail) {
        await _client.auth.updateUser(
          UserAttributes(email: newEmail.trim()),
        );
      }

      if (isChangingPassword) {
        await _client.auth.updateUser(
          UserAttributes(password: newPassword.trim()),
        );
      }
    }

    // 2. Update display name in app_users
    await _client.from('app_users').update({
      'name': name.trim(),
    }).eq('id', userId);
  }
}

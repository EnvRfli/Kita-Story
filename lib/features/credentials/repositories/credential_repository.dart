import '../../../core/network/supabase_client.dart';
import '../../../core/services/activity_log_service.dart';
import '../models/credential_model.dart';
import '../models/credential_category_model.dart';
import '../models/credential_subcategory_model.dart';

class CredentialRepository {
  final _client = SupabaseNetwork.client;

  /// Mengambil semua kategori (bawaan & kustom pengguna)
  Future<List<CredentialCategoryModel>> fetchCategories() async {
    final data = await _client
        .from('credential_categories')
        .select()
        .order('name', ascending: true);

    return (data as List)
        .map((json) => CredentialCategoryModel.fromJson(json))
        .toList();
  }

  /// Menambah kategori kustom baru
  Future<CredentialCategoryModel> addCategory({
    required String name,
    required String userId,
  }) async {
    final data = await _client
        .from('credential_categories')
        .insert({
          'name': name,
          'user_id': userId,
        })
        .select()
        .single();

    return CredentialCategoryModel.fromJson(data);
  }

  /// Mengambil semua subkategori berdasarkan categoryId
  Future<List<CredentialSubcategoryModel>> fetchSubcategories({
    String? categoryId,
  }) async {
    var query = _client.from('credential_subcategories').select();

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }

    final data = await query.order('name', ascending: true);
    return (data as List)
        .map((json) => CredentialSubcategoryModel.fromJson(json))
        .toList();
  }

  /// Menambah subkategori kustom baru
  Future<CredentialSubcategoryModel> addSubcategory({
    required String categoryId,
    required String name,
    required String userId,
  }) async {
    final data = await _client
        .from('credential_subcategories')
        .insert({
          'category_id': categoryId,
          'name': name,
          'user_id': userId,
        })
        .select()
        .single();

    return CredentialSubcategoryModel.fromJson(data);
  }

  /// Mengambil semua kredensial milik pengguna + kredensial bersama dari pasangan
  Future<List<CredentialModel>> fetchCredentials(
    String userId, {
    String? partnerId,
  }) async {
    var query = _client.from('user_credentials').select();

    if (partnerId != null && partnerId.trim().isNotEmpty) {
      query = query.or(
        'user_id.eq.$userId,and(is_shared_with_partner.eq.true,partner_id.eq.$userId),and(is_shared_with_partner.eq.true,user_id.eq.$partnerId)',
      );
    } else {
      query = query.eq('user_id', userId);
    }

    final data = await query.order('created_at', ascending: false);

    return (data as List)
        .map((json) => CredentialModel.fromJson(json))
        .toList();
  }

  /// Menambahkan kredensial baru (Mendapatkan +5 Poin atau +10 Poin jika dibagikan ke pasangan)
  Future<CredentialModel> addCredential(CredentialModel credential) async {
    final payload = credential.toJson(targetUserId: credential.userId)..remove('id');
    final data = await _client
        .from('user_credentials')
        .insert(payload)
        .select()
        .single();

    final isShared = credential.isSharedWithPartner;
    final points = isShared ? 10 : 5;

    // Gamifikasi: Catat aktivitas & berikan poin otomatis ke user
    await ActivityLogService.recordActivityAndAddPoints(
      userId: credential.userId,
      points: points,
      activityType: isShared ? 'add_shared_credential' : 'add_credential',
      title: isShared
          ? 'Menyimpan Kredensial Bersama 🔐💕'
          : 'Menyimpan Kredensial 🔐',
      description: isShared
          ? 'Menyimpan data "${credential.title.trim()}" ke brankas bersama pasangan'
          : 'Menyimpan data "${credential.title.trim()}" ke brankas pribadi',
      referenceId: data['id'] as String?,
    );

    return CredentialModel.fromJson(data, currentUserId: credential.userId);
  }

  /// Memperbarui kredensial yang ada
  Future<CredentialModel> updateCredential(CredentialModel credential) async {
    final payload = credential.toJson(targetUserId: credential.userId)..remove('id');
    final data = await _client
        .from('user_credentials')
        .update(payload)
        .eq('id', credential.id)
        .select()
        .single();

    return CredentialModel.fromJson(data, currentUserId: credential.userId);
  }

  /// Menghapus kredensial
  Future<void> deleteCredential(String id) async {
    await _client.from('user_credentials').delete().eq('id', id);
  }
}

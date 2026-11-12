import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../domain/user_profile.dart';

/// Provider Riverpod untuk dependency injection ProfileRepository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Repository layanan profil pengguna.
/// Menangani seluruh komunikasi data dan autentikasi dengan Supabase (Separation of Concerns).
class ProfileRepository {
  final SupabaseClient? _customClient;

  ProfileRepository({SupabaseClient? supabaseClient})
      : _customClient = supabaseClient;

  SupabaseClient? get _supabase {
    if (_customClient != null) return _customClient;
    if (SupabaseConstants.isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Mengambil profil pengguna saat ini
  UserProfile getCurrentProfile() {
    final sb = _supabase;
    if (sb == null) return UserProfile.guest();
    final user = sb.auth.currentUser;
    if (user == null) return UserProfile.guest();
    return UserProfile.fromSupabaseUser(user);
  }

  /// Memperbarui nama dan nomor telepon pada metadata akun Supabase
  Future<void> updateProfile({
    required String displayName,
    String? phone,
  }) async {
    final sb = _supabase;
    if (sb == null) return;
    final user = sb.auth.currentUser;
    if (user == null) return;

    final updatedData = Map<String, dynamic>.from(user.userMetadata ?? {});
    updatedData['full_name'] = displayName;
    if (phone != null && phone.isNotEmpty) {
      updatedData['phone'] = phone;
    }

    await sb.auth.updateUser(
      UserAttributes(data: updatedData),
    );
  }

  /// Memperbarui atau menghapus URL foto avatar profil pada metadata Supabase
  Future<void> updateAvatar(String? avatarPath) async {
    final sb = _supabase;
    if (sb == null) return;
    final user = sb.auth.currentUser;
    if (user == null) return;

    final updatedData = Map<String, dynamic>.from(user.userMetadata ?? {});
    if (avatarPath != null && avatarPath.isNotEmpty) {
      updatedData['avatar_url'] = avatarPath;
    } else {
      updatedData.remove('avatar_url');
    }

    await sb.auth.updateUser(
      UserAttributes(data: updatedData),
    );
  }

  /// Mengubah kata sandi pengguna
  Future<void> changePassword(String newPassword) async {
    final sb = _supabase;
    if (sb == null) return;

    await sb.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Keluar dari sesi akun saat ini
  Future<void> signOut() async {
    final sb = _supabase;
    if (sb != null) {
      await sb.auth.signOut();
    }
  }
}

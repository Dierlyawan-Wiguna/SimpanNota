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

  /// Mengambil profil pengguna secara asynchronous termasuk tabel profiles (jika ada)
  Future<UserProfile> fetchProfile() async {
    final sb = _supabase;
    if (sb == null) return getCurrentProfile();
    final user = sb.auth.currentUser;
    if (user == null) return UserProfile.guest();

    try {
      final data = await sb.from('profiles').select().eq('id', user.id).maybeSingle();
      if (data != null) {
        final profile = UserProfile.fromSupabaseUser(user);
        return profile.copyWith(
          displayName: data['name']?.toString() ?? profile.displayName,
          phone: data['phone']?.toString() ?? profile.phone,
          telegramChatId: data['telegram_chat_id']?.toString() ?? profile.telegramChatId,
          avatarUrl: data['avatar_url']?.toString() ?? profile.avatarUrl,
        );
      }
    } catch (_) {}

    return UserProfile.fromSupabaseUser(user);
  }

  /// Memperbarui nama, nomor telepon, dan Telegram Chat ID pada metadata akun Supabase & tabel profiles
  Future<void> updateProfile({
    required String displayName,
    String? phone,
    String? telegramChatId,
  }) async {
    final sb = _supabase;
    if (sb == null) return;
    final user = sb.auth.currentUser;
    if (user == null) return;

    final updatedData = Map<String, dynamic>.from(user.userMetadata ?? {});
    updatedData['full_name'] = displayName;
    if (phone != null && phone.isNotEmpty) {
      updatedData['phone'] = phone;
    } else {
      updatedData.remove('phone');
    }

    if (telegramChatId != null && telegramChatId.trim().isNotEmpty) {
      updatedData['telegram_chat_id'] = telegramChatId.trim();
    } else {
      updatedData.remove('telegram_chat_id');
    }

    await sb.auth.updateUser(
      UserAttributes(data: updatedData),
    );

    // Sinkronisasi ke tabel database profiles
    try {
      await sb.from('profiles').upsert({
        'id': user.id,
        'name': displayName,
        'phone': phone,
        'telegram_chat_id': (telegramChatId != null && telegramChatId.trim().isNotEmpty)
            ? telegramChatId.trim()
            : null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
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


import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Domain Entity model untuk data profil pengguna.
/// Menerapkan immutability dan Single Responsibility Principle.
class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final String phone;
  final String? telegramChatId;
  final String? telegramBotToken;
  final String? avatarUrl;
  final DateTime registrationDate;
  final String authProvider;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phone,
    this.telegramChatId,
    this.telegramBotToken,
    this.avatarUrl,
    required this.registrationDate,
    required this.authProvider,
  });

  /// Inisial untuk avatar default jika tidak ada gambar
  String get initials {
    final parts = displayName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  /// Mengecek apakah menggunakan autentikasi email (bukan Google)
  bool get isEmailProvider => !authProvider.toLowerCase().contains('google');

  /// Tanggal pendaftaran terformat rapi dalam Bahasa Indonesia
  String get formattedRegistrationDate {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(registrationDate);
  }

  /// Profil default untuk pengguna offline / tamu
  factory UserProfile.guest() {
    return UserProfile(
      id: 'guest',
      displayName: 'Pengguna Tamu',
      email: 'tamu@simpannota.local',
      phone: '-',
      telegramChatId: null,
      avatarUrl: null,
      registrationDate: DateTime.now(),
      authProvider: 'Offline',
    );
  }

  /// Membuat UserProfile dari Map/JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['registration_date'] != null) {
      parsedDate = DateTime.tryParse(json['registration_date'].toString()) ?? DateTime.now();
    } else if (json['registrationDate'] != null) {
      parsedDate = DateTime.tryParse(json['registrationDate'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return UserProfile(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ??
          json['display_name']?.toString() ??
          json['name']?.toString() ??
          'Pengguna SimpanNota',
      email: json['email']?.toString() ?? '-',
      phone: json['phone']?.toString() ?? '-',
      telegramChatId: json['telegram_chat_id']?.toString() ?? json['telegramChatId']?.toString(),
      telegramBotToken: json['telegram_bot_token']?.toString() ?? json['telegramBotToken']?.toString(),
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      registrationDate: parsedDate,
      authProvider: json['auth_provider']?.toString() ?? json['authProvider']?.toString() ?? 'Email & Kata Sandi',
    );
  }

  /// Serialisasi ke Map/JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'name': displayName,
      'email': email,
      'phone': phone,
      'telegram_chat_id': telegramChatId,
      'telegram_bot_token': telegramBotToken,
      'avatar_url': avatarUrl,
      'registration_date': registrationDate.toIso8601String(),
      'auth_provider': authProvider,
    };
  }

  /// Membuat UserProfile dari objek User Supabase
  factory UserProfile.fromSupabaseUser(User user) {
    final metadata = user.userMetadata;
    final fullName = metadata?['full_name'] ?? metadata?['name'] ?? metadata?['display_name'];

    String name;
    if (fullName != null && fullName.toString().trim().isNotEmpty) {
      name = fullName.toString().trim();
    } else if (user.email != null && user.email!.isNotEmpty) {
      name = user.email!.split('@').first;
    } else {
      name = 'Pengguna SimpanNota';
    }

    String phone = '-';
    if (user.phone != null && user.phone!.isNotEmpty) {
      phone = user.phone!;
    } else if (metadata?['phone'] != null && metadata!['phone'].toString().isNotEmpty) {
      phone = metadata['phone'].toString();
    }

    final rawTgId = metadata?['telegram_chat_id'] ?? metadata?['telegramChatId'];
    final String? tgId = (rawTgId != null && rawTgId.toString().trim().isNotEmpty)
        ? rawTgId.toString().trim()
        : null;

    final rawTgToken = metadata?['telegram_bot_token'] ?? metadata?['telegramBotToken'];
    final String? tgToken = (rawTgToken != null && rawTgToken.toString().trim().isNotEmpty)
        ? rawTgToken.toString().trim()
        : null;

    final avatar = metadata?['avatar_url'] ?? metadata?['picture'];
    final avatarUrl = (avatar != null && avatar.toString().trim().isNotEmpty)
        ? avatar.toString().trim()
        : null;

    DateTime regDate;
    try {
      regDate = DateTime.parse(user.createdAt).toLocal();
    } catch (_) {
      regDate = DateTime.now();
    }

    final appMeta = user.appMetadata;
    final rawProvider = appMeta['provider'] as String? ?? 'email';
    final provider = rawProvider.toLowerCase() == 'google' ? 'Google Account' : 'Email & Kata Sandi';

    return UserProfile(
      id: user.id,
      displayName: name,
      email: user.email ?? '-',
      phone: phone,
      telegramChatId: tgId,
      telegramBotToken: tgToken,
      avatarUrl: avatarUrl,
      registrationDate: regDate,
      authProvider: provider,
    );
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? phone,
    String? telegramChatId,
    String? telegramBotToken,
    String? avatarUrl,
    DateTime? registrationDate,
    String? authProvider,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      telegramBotToken: telegramBotToken ?? this.telegramBotToken,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      registrationDate: registrationDate ?? this.registrationDate,
      authProvider: authProvider ?? this.authProvider,
    );
  }
}

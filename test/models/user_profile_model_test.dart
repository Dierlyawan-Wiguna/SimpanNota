import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:simpan_nota/features/profile/domain/user_profile.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('UserProfile Default & Guest Factory Tests', () {
    test('guest factory returns stable fallback values', () {
      final guest = UserProfile.guest();
      expect(guest.id, 'guest');
      expect(guest.displayName, 'Pengguna Tamu');
      expect(guest.email, 'tamu@simpannota.local');
      expect(guest.phone, '-');
      expect(guest.telegramChatId, isNull);
      expect(guest.telegramBotToken, isNull);
      expect(guest.avatarUrl, isNull);
      expect(guest.authProvider, 'Offline');
      expect(guest.initials, 'PT');
      expect(guest.isEmailProvider, isTrue);
    });

    test('guest registration date defaults to today', () {
      final guest = UserProfile.guest();
      final now = DateTime.now();
      expect(guest.registrationDate.year, now.year);
      expect(guest.registrationDate.month, now.month);
    });
  });

  group('UserProfile Initials Extraction Tests', () {
    test('single word name returns first letter capitalized', () {
      final u = UserProfile.guest().copyWith(displayName: 'dierly');
      expect(u.initials, 'D');
    });

    test('two word name returns first letter of both words', () {
      final u = UserProfile.guest().copyWith(displayName: 'Dierly Awan');
      expect(u.initials, 'DA');
    });

    test('three word name returns first letter of first and last words', () {
      final u = UserProfile.guest().copyWith(displayName: 'Muhammad Rizky Pratama');
      expect(u.initials, 'MP');
    });

    test('four word name returns first and last letters', () {
      final u = UserProfile.guest().copyWith(displayName: 'Ahmad Dahlan bin Salim');
      expect(u.initials, 'AS');
    });

    test('whitespace padding is trimmed before calculating initials', () {
      final u = UserProfile.guest().copyWith(displayName: '   Budi   Santoso   ');
      expect(u.initials, 'BS');
    });

    test('empty or whitespace-only name falls back to U', () {
      final u1 = UserProfile.guest().copyWith(displayName: '');
      expect(u1.initials, 'U');

      final u2 = UserProfile.guest().copyWith(displayName: '     ');
      expect(u2.initials, 'U');
    });
  });

  group('UserProfile AuthProvider & Localization Tests', () {
    test('isEmailProvider returns true for Email & Kata Sandi', () {
      final u = UserProfile.guest().copyWith(authProvider: 'Email & Kata Sandi');
      expect(u.isEmailProvider, isTrue);
    });

    test('isEmailProvider returns false for Google Account', () {
      final u = UserProfile.guest().copyWith(authProvider: 'Google Account');
      expect(u.isEmailProvider, isFalse);
    });

    test('isEmailProvider returns false for google_oauth', () {
      final u = UserProfile.guest().copyWith(authProvider: 'google_oauth');
      expect(u.isEmailProvider, isFalse);
    });

    test('formattedRegistrationDate formats date in Indonesian language', () {
      final u = UserProfile.guest().copyWith(
        registrationDate: DateTime(2026, 8, 17),
      );
      expect(u.formattedRegistrationDate, '17 Agustus 2026');
    });

    test('formattedRegistrationDate formats December date correctly', () {
      final u = UserProfile.guest().copyWith(
        registrationDate: DateTime(2025, 12, 25),
      );
      expect(u.formattedRegistrationDate, '25 Desember 2025');
    });
  });

  group('UserProfile CopyWith Tests', () {
    final original = UserProfile(
      id: 'usr-001',
      displayName: 'Original Name',
      email: 'original@test.com',
      phone: '0811111111',
      telegramChatId: '12345',
      telegramBotToken: 'tok123',
      avatarUrl: 'https://img.com/avatar.png',
      registrationDate: DateTime(2025, 1, 1),
      authProvider: 'Email',
    );

    test('copyWith updates only provided fields', () {
      final updated = original.copyWith(
        displayName: 'Updated Name',
        phone: '0822222222',
      );

      expect(updated.displayName, 'Updated Name');
      expect(updated.phone, '0822222222');
      expect(updated.id, 'usr-001');
      expect(updated.email, 'original@test.com');
      expect(updated.telegramChatId, '12345');
      expect(updated.telegramBotToken, 'tok123');
      expect(updated.avatarUrl, 'https://img.com/avatar.png');
      expect(updated.authProvider, 'Email');
    });

    test('copyWith updates telegramChatId and avatarUrl', () {
      final updated = original.copyWith(
        telegramChatId: '-100987654321',
        avatarUrl: 'https://img.com/new.png',
      );

      expect(updated.telegramChatId, '-100987654321');
      expect(updated.avatarUrl, 'https://img.com/new.png');
      expect(updated.displayName, 'Original Name');
    });
  });

  group('UserProfile JSON Serialization Tests', () {
    test('toJson produces complete map with all properties', () {
      final user = UserProfile(
        id: 'usr-100',
        displayName: 'Siti Aminah',
        email: 'siti@example.com',
        phone: '0855555555',
        telegramChatId: '987654321',
        telegramBotToken: 'bot_secret',
        avatarUrl: 'https://example.com/siti.jpg',
        registrationDate: DateTime(2026, 3, 10, 10, 0),
        authProvider: 'Google',
      );

      final json = user.toJson();
      expect(json['id'], 'usr-100');
      expect(json['displayName'], 'Siti Aminah');
      expect(json['email'], 'siti@example.com');
      expect(json['phone'], '0855555555');
      expect(json['telegram_chat_id'], '987654321');
      expect(json['telegram_bot_token'], 'bot_secret');
      expect(json['avatar_url'], 'https://example.com/siti.jpg');
      expect(json['auth_provider'], 'Google');
    });

    test('fromJson handles snake_case keys correctly', () {
      final map = {
        'id': 'u-200',
        'display_name': 'Eko Prasetyo',
        'email': 'eko@example.com',
        'phone': '0877777777',
        'telegram_chat_id': '-100111222333',
        'avatar_url': 'https://eko.com/pic.png',
        'registration_date': '2026-04-01T08:00:00.000',
        'auth_provider': 'Email & Kata Sandi',
      };

      final user = UserProfile.fromJson(map);
      expect(user.id, 'u-200');
      expect(user.displayName, 'Eko Prasetyo');
      expect(user.telegramChatId, '-100111222333');
      expect(user.avatarUrl, 'https://eko.com/pic.png');
      expect(user.registrationDate.year, 2026);
      expect(user.registrationDate.month, 4);
    });

    test('fromJson handles camelCase keys correctly', () {
      final map = {
        'id': 'u-300',
        'displayName': 'Rina Sugiarto',
        'email': 'rina@test.com',
        'phone': '0899999999',
        'telegramChatId': '778899',
        'avatarUrl': 'https://rina.com/avatar.png',
        'registrationDate': '2025-11-15T12:00:00.000',
        'authProvider': 'Google Account',
      };

      final user = UserProfile.fromJson(map);
      expect(user.id, 'u-300');
      expect(user.displayName, 'Rina Sugiarto');
      expect(user.telegramChatId, '778899');
      expect(user.avatarUrl, 'https://rina.com/avatar.png');
      expect(user.authProvider, 'Google Account');
    });

    test('fromJson provides safe defaults when json keys are missing', () {
      final map = <String, dynamic>{};
      final user = UserProfile.fromJson(map);

      expect(user.id, '');
      expect(user.displayName, 'Pengguna SimpanNota');
      expect(user.email, '-');
      expect(user.phone, '-');
      expect(user.telegramChatId, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.authProvider, 'Email & Kata Sandi');
    });
  });
}

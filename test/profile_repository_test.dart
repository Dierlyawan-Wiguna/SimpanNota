import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:simpan_nota/features/profile/domain/user_profile.dart';
import 'package:simpan_nota/features/profile/services/profile_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('UserProfile Entity Tests', () {
    test('1. UserProfile.guest() menghasilkan nilai default aman', () {
      final guest = UserProfile.guest();
      expect(guest.id, 'guest');
      expect(guest.displayName, 'Pengguna Tamu');
      expect(guest.email, 'tamu@simpannota.local');
      expect(guest.phone, '-');
      expect(guest.avatarUrl, isNull);
      expect(guest.authProvider, 'Offline');
      expect(guest.initials, 'PT');
      expect(guest.isEmailProvider, isTrue);
    });

    test('2. Inisial profil dihitung dengan benar dari variasi nama', () {
      final p1 = UserProfile.guest().copyWith(displayName: 'Ahmad');
      expect(p1.initials, 'A');

      final p2 = UserProfile.guest().copyWith(displayName: 'Budi Santoso');
      expect(p2.initials, 'BS');

      final p3 = UserProfile.guest().copyWith(displayName: 'Citra Dewi Lestari');
      expect(p3.initials, 'CL');

      final p4 = UserProfile.guest().copyWith(displayName: '   ');
      expect(p4.initials, 'U');
    });

    test('3. isEmailProvider membedakan provider Google dan Email', () {
      final googleUser = UserProfile.guest().copyWith(authProvider: 'Google Account');
      expect(googleUser.isEmailProvider, isFalse);

      final emailUser = UserProfile.guest().copyWith(authProvider: 'Email & Kata Sandi');
      expect(emailUser.isEmailProvider, isTrue);
    });

    test('4. formattedRegistrationDate memformat tanggal ke Bahasa Indonesia', () {
      final profile = UserProfile.guest().copyWith(
        registrationDate: DateTime(2024, 5, 17),
      );
      expect(profile.formattedRegistrationDate, contains('17 Mei 2024'));
    });

    test('5. UserProfile serialisasi dan deserialisasi telegram_chat_id', () {
      final jsonMap = {
        'id': 'usr-123',
        'displayName': 'Rian Sastrawan',
        'email': 'rian@example.com',
        'phone': '081234567890',
        'telegram_chat_id': '987654321',
        'avatar_url': 'https://example.com/avatar.jpg',
        'registration_date': '2024-03-10T10:00:00.000Z',
        'auth_provider': 'Email & Kata Sandi',
      };

      final profile = UserProfile.fromJson(jsonMap);
      expect(profile.id, 'usr-123');
      expect(profile.displayName, 'Rian Sastrawan');
      expect(profile.telegramChatId, '987654321');

      final outputJson = profile.toJson();
      expect(outputJson['telegram_chat_id'], '987654321');
      expect(outputJson['name'], 'Rian Sastrawan');

      // Test copyWith untuk telegramChatId
      final updated = profile.copyWith(telegramChatId: '1122334455');
      expect(updated.telegramChatId, '1122334455');
      expect(updated.displayName, 'Rian Sastrawan');
    });
  });

  group('ProfileRepository Tests', () {
    test('6. ProfileRepository mengembalikan profile default saat offline/guest', () {
      final repo = ProfileRepository();
      final profile = repo.getCurrentProfile();
      expect(profile.displayName, isNotEmpty);
      expect(profile.email, isNotEmpty);
      expect(profile.telegramChatId, isNull);
    });

    test('7. ProfileRepository metode mutasi dan fetchProfile tidak crash saat tidak terhubung', () async {
      final repo = ProfileRepository();
      // Memastikan metode aman dipanggil tanpa exception ketika Supabase instance belum login
      await expectLater(
        repo.updateProfile(
          displayName: 'Budi',
          phone: '08123456789',
          telegramChatId: '12345678',
        ),
        completes,
      );
      final profile = await repo.fetchProfile();
      expect(profile.displayName, isNotEmpty);
      await expectLater(repo.updateAvatar('/path/avatar.jpg'), completes);
      await expectLater(repo.changePassword('newpass123'), completes);
      await expectLater(repo.signOut(), completes);
    });
  });
}


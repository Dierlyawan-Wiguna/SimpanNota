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
  });

  group('ProfileRepository Tests', () {
    test('5. ProfileRepository mengembalikan profile default saat offline/guest', () {
      final repo = ProfileRepository();
      final profile = repo.getCurrentProfile();
      expect(profile.displayName, isNotEmpty);
      expect(profile.email, isNotEmpty);
    });

    test('6. ProfileRepository metode mutasi tidak crash saat tidak terhubung', () async {
      final repo = ProfileRepository();
      // Memastikan metode aman dipanggil tanpa exception ketika Supabase instance belum login
      await expectLater(repo.updateProfile(displayName: 'Budi'), completes);
      await expectLater(repo.updateAvatar('/path/avatar.jpg'), completes);
      await expectLater(repo.changePassword('newpass123'), completes);
      await expectLater(repo.signOut(), completes);
    });
  });
}


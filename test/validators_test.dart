import 'package:flutter_test/flutter_test.dart';
import 'package:simpan_nota/core/utils/input_validator.dart';
import 'package:simpan_nota/features/profile/domain/profile_validator.dart';

void main() {
  group('InputValidator - Pure Function Unit Tests', () {
    test('1. validateEmail: memvalidasi email kosong, format salah, dan format benar', () {
      expect(InputValidator.validateEmail(null), 'Email harus diisi.');
      expect(InputValidator.validateEmail(''), 'Email harus diisi.');
      expect(InputValidator.validateEmail('bukanemail'), 'Format email tidak valid.');
      expect(InputValidator.validateEmail('user@'), 'Format email tidak valid.');
      expect(InputValidator.validateEmail('user@domain'), 'Format email tidak valid.');
      expect(InputValidator.validateEmail('user@domain.com'), isNull);
      expect(InputValidator.validateEmail('  user@test.co.id  '), isNull);
    });

    test('2. validatePassword: memvalidasi password kosong dan batas minimal karakter', () {
      expect(InputValidator.validatePassword(null), 'Password harus diisi.');
      expect(InputValidator.validatePassword(''), 'Password harus diisi.');
      expect(InputValidator.validatePassword('12345'), 'Password minimal 6 karakter.');
      expect(InputValidator.validatePassword('123456'), isNull);
      expect(InputValidator.validatePassword('strongPassword123'), isNull);
    });

    test('3. validateConfirmPassword: memvalidasi kecocokan konfirmasi password', () {
      expect(InputValidator.validateConfirmPassword('pass123', null), 'Konfirmasi password harus diisi.');
      expect(InputValidator.validateConfirmPassword('pass123', ''), 'Konfirmasi password harus diisi.');
      expect(InputValidator.validateConfirmPassword('pass123', 'pass456'), 'Konfirmasi password tidak cocok.');
      expect(InputValidator.validateConfirmPassword('pass123', 'pass123'), isNull);
    });

    test('4. validateName: memvalidasi nama wajib diisi dengan custom fieldName', () {
      expect(InputValidator.validateName(null), 'Nama lengkap harus diisi.');
      expect(InputValidator.validateName('   '), 'Nama lengkap harus diisi.');
      expect(InputValidator.validateName('', fieldName: 'Nama toko'), 'Nama toko harus diisi.');
      expect(InputValidator.validateName('Budi Santoso'), isNull);
    });

    test('5. normalisasi dan format nomor telepon Indonesia', () {
      expect(InputValidator.normalizePhoneNumber('0812-3456-7890'), '81234567890');
      expect(InputValidator.normalizePhoneNumber('+62 812 3456 7890'), '81234567890');
      expect(InputValidator.normalizePhoneNumber('6281234567890'), '81234567890');
      expect(InputValidator.formatIndonesianPhone('0812-3456-7890'), '+6281234567890');
      expect(InputValidator.formatIndonesianPhone(''), '');

      // Validasi panjang digit
      expect(InputValidator.validatePhoneNumber('123'), 'Nomor telepon tidak valid (8-15 digit).');
      expect(InputValidator.validatePhoneNumber('081234567890'), isNull);
      expect(InputValidator.validatePhoneNumber(null, isOptional: true), isNull);
      expect(InputValidator.validatePhoneNumber(null, isOptional: false), 'Nomor telepon harus diisi.');
    });
  });

  group('ProfileValidator - Domain Validation Unit Tests', () {
    test('1. validateDisplayName: validasi nama pengguna profil', () {
      expect(ProfileValidator.validateDisplayName(null), 'Nama pengguna tidak boleh kosong.');
      expect(ProfileValidator.validateDisplayName('   '), 'Nama pengguna tidak boleh kosong.');
      expect(ProfileValidator.validateDisplayName('A'), 'Nama pengguna minimal 2 karakter.');
      expect(ProfileValidator.validateDisplayName('Budi'), isNull);
    });

    test('2. cleanPhoneForInput: menghapus prefix +62/62/0 untuk form UI', () {
      expect(ProfileValidator.cleanPhoneForInput('+62812345678'), '812345678');
      expect(ProfileValidator.cleanPhoneForInput('62812345678'), '812345678');
      expect(ProfileValidator.cleanPhoneForInput('0812345678'), '812345678');
      expect(ProfileValidator.cleanPhoneForInput('-'), '');
      expect(ProfileValidator.cleanPhoneForInput(null), '');
    });

    test('3. validatePasswordChange: memvalidasi ubah kata sandi', () {
      expect(
        ProfileValidator.validatePasswordChange(newPassword: '123', confirmPassword: '123'),
        'Kata sandi minimal 6 karakter.',
      );
      expect(
        ProfileValidator.validatePasswordChange(newPassword: 'password123', confirmPassword: 'password456'),
        'Konfirmasi kata sandi tidak cocok.',
      );
      expect(
        ProfileValidator.validatePasswordChange(newPassword: 'password123', confirmPassword: 'password123'),
        isNull,
      );
    });
  });
}


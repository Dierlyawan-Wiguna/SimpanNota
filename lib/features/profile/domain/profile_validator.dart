import '../../../../core/utils/input_validator.dart';

/// Validator domain murni untuk fitur Profile.
/// Memisahkan seluruh aturan bisnis validasi form profil dari tampilan UI (Separation of Concerns).
class ProfileValidator {
  ProfileValidator._();

  /// Validasi nama tampilan profil
  static String? validateDisplayName(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Nama pengguna tidak boleh kosong.';
    }
    if (trimmed.length < 2) {
      return 'Nama pengguna minimal 2 karakter.';
    }
    return null;
  }

  /// Membersihkan nomor telepon untuk ditampilkan di controller dengan prefix +62
  static String cleanPhoneForInput(String? phone) {
    if (phone == null || phone.trim() == '-' || phone.trim().isEmpty) return '';
    var clean = phone.trim();
    if (clean.startsWith('+62')) {
      clean = clean.substring(3);
    } else if (clean.startsWith('62')) {
      clean = clean.substring(2);
    } else if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    return clean;
  }

  /// Memvalidasi format nomor telepon profil
  static String? validatePhoneNumber(String? phone, {bool isOptional = true}) {
    return InputValidator.validatePhoneNumber(phone, isOptional: isOptional);
  }

  /// Format nomor telepon profil ke format internasional (+62)
  static String formatPhone(String? rawPhone) {
    return InputValidator.formatIndonesianPhone(rawPhone);
  }

  /// Membersihkan input Telegram Chat ID dari spasi ekstra
  static String sanitizeTelegramChatId(String? value) {
    if (value == null) return '';
    return value.trim();
  }

  /// Validasi Telegram Chat ID.
  /// Opsional (boleh kosong atau null).
  /// Mendukung ID numerik positif (chat pribadi) dan negatif (grup/supergroup/channel).
  static String? validateTelegramChatId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final clean = value.trim();

    if (clean.startsWith('@')) {
      return 'Telegram Chat ID harus berupa angka ID (misal: 12345678 atau -100...), bukan username (@).';
    }

    // Mendukung ID pribadi (misal: 123456789) atau ID grup/supergroup (misal: -1001234567890)
    final telegramIdRegex = RegExp(r'^-?[0-9]{5,16}$');
    if (!telegramIdRegex.hasMatch(clean)) {
      return 'Telegram Chat ID hanya boleh berupa angka.';
    }
    return null;
  }

  /// Validasi pengubahan kata sandi akun
  static String? validatePasswordChange({
    required String? newPassword,
    required String? confirmPassword,
  }) {
    final pass = newPassword ?? '';
    final confirm = confirmPassword ?? '';

    if (pass.length < 6) {
      return 'Kata sandi minimal 6 karakter.';
    }
    if (pass != confirm) {
      return 'Konfirmasi kata sandi tidak cocok.';
    }
    return null;
  }
}


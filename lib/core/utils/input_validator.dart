/// Utility kelas murni (Pure Functions) untuk memvalidasi input formulir secara terpusat.
/// Menerapkan prinsip DRY (Don't Repeat Yourself) dan Single Responsibility Principle.
class InputValidator {
  InputValidator._();

  /// Regex standar RFC 5322 untuk validasi email
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  /// Validasi alamat email
  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email harus diisi.';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Format email tidak valid.';
    }
    return null;
  }

  /// Validasi kata sandi (minimal 6 karakter)
  static String? validatePassword(String? value, {int minLength = 6}) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password harus diisi.';
    }
    if (password.length < minLength) {
      return 'Password minimal $minLength karakter.';
    }
    return null;
  }

  /// Validasi konfirmasi kata sandi
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    final confirm = confirmPassword ?? '';
    if (confirm.isEmpty) {
      return 'Konfirmasi password harus diisi.';
    }
    if (confirm != (password ?? '')) {
      return 'Konfirmasi password tidak cocok.';
    }
    return null;
  }

  /// Validasi nama wajib diisi
  static String? validateName(String? value, {String fieldName = 'Nama lengkap'}) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return '$fieldName harus diisi.';
    }
    return null;
  }

  /// Normalisasi nomor telepon: membuang karakter non-digit dan prefix 0 atau 62
  static String normalizePhoneNumber(String? rawPhone) {
    if (rawPhone == null) return '';
    var digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    } else if (digits.startsWith('62')) {
      digits = digits.substring(2);
    }
    return digits;
  }

  /// Memformat nomor telepon ke standar internasional Indonesia (+62)
  static String formatIndonesianPhone(String? rawPhone) {
    final normalized = normalizePhoneNumber(rawPhone);
    if (normalized.isEmpty) return '';
    return '+62$normalized';
  }

  /// Validasi nomor telepon
  static String? validatePhoneNumber(String? rawPhone, {bool isOptional = true}) {
    final normalized = normalizePhoneNumber(rawPhone);
    if (normalized.isEmpty) {
      return isOptional ? null : 'Nomor telepon harus diisi.';
    }
    if (normalized.length < 8 || normalized.length > 15) {
      return 'Nomor telepon tidak valid (8-15 digit).';
    }
    return null;
  }
}


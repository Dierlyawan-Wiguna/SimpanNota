import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpan_nota/core/utils/file_upload_validator.dart';

void main() {
  group('FileUploadValidator Extension Tests (Issue 2)', () {
    test('isSupportedExtension returns true for standard JPEG (.jpg, .jpeg)', () {
      expect(FileUploadValidator.isSupportedExtension('nota_belanja.jpg'), isTrue);
      expect(FileUploadValidator.isSupportedExtension('struk_elektronik.jpeg'), isTrue);
    });

    test('isSupportedExtension returns true for PNG, WEBP, and HEIC', () {
      expect(FileUploadValidator.isSupportedExtension('bukti_shopee.png'), isTrue);
      expect(FileUploadValidator.isSupportedExtension('garansi_hp.webp'), isTrue);
      expect(FileUploadValidator.isSupportedExtension('foto_kamera_iphone.heic'), isTrue);
    });

    test('isSupportedExtension handles uppercase and mixed-case extensions', () {
      expect(FileUploadValidator.isSupportedExtension('NOTA_BESAR.JPG'), isTrue);
      expect(FileUploadValidator.isSupportedExtension('Bukti.PnG'), isTrue);
      expect(FileUploadValidator.isSupportedExtension('Kamera.HEIC'), isTrue);
    });

    test('isSupportedExtension returns false for dangerous executable or script files', () {
      expect(FileUploadValidator.isSupportedExtension('payload.exe'), isFalse);
      expect(FileUploadValidator.isSupportedExtension('script.sh'), isFalse);
      expect(FileUploadValidator.isSupportedExtension('app.apk'), isFalse);
      expect(FileUploadValidator.isSupportedExtension('source.dart'), isFalse);
    });

    test('isSupportedExtension returns false for documents and archives', () {
      expect(FileUploadValidator.isSupportedExtension('nota.pdf'), isFalse);
      expect(FileUploadValidator.isSupportedExtension('faktur.docx'), isFalse);
      expect(FileUploadValidator.isSupportedExtension('arsip.zip'), isFalse);
      expect(FileUploadValidator.isSupportedExtension('gambar.gif'), isFalse);
    });

    test('isSupportedExtension returns false for paths without extension', () {
      expect(FileUploadValidator.isSupportedExtension('unnamed_file'), isFalse);
      expect(FileUploadValidator.isSupportedExtension('/data/user/0/cache/tempfile'), isFalse);
    });
  });

  group('FileUploadValidator Sanitization & MIME Type Tests', () {
    test('sanitizeFileName removes illegal filesystem characters', () {
      final sanitized = FileUploadValidator.sanitizeFileName('struk*toko:elektronik?2026.jpg');
      expect(sanitized.contains('*'), isFalse);
      expect(sanitized.contains(':'), isFalse);
      expect(sanitized.contains('?'), isFalse);
      expect(sanitized.endsWith('.jpg'), isTrue);
    });

    test('sanitizeFileName replaces spaces with underscores', () {
      final sanitized = FileUploadValidator.sanitizeFileName('Nota Pembelian Laptop Asus.png');
      expect(sanitized, 'Nota_Pembelian_Laptop_Asus.png');
    });

    test('sanitizeFileName strips directory paths and extracts basename only', () {
      final sanitizedWin = FileUploadValidator.sanitizeFileName(r'C:\Users\Downloads\bukti.jpg');
      expect(sanitizedWin, 'bukti.jpg');

      final sanitizedUnix = FileUploadValidator.sanitizeFileName('/sdcard/DCIM/Camera/nota.jpeg');
      expect(sanitizedUnix, 'nota.jpeg');
    });

    test('sanitizeFileName handles empty or whitespace-only input safely', () {
      expect(FileUploadValidator.sanitizeFileName(''), 'unnamed_file.jpg');
      expect(FileUploadValidator.sanitizeFileName('   '), 'unnamed_file.jpg');
    });

    test('getMimeType maps known extensions correctly', () {
      expect(FileUploadValidator.getMimeType('foto.jpg'), 'image/jpeg');
      expect(FileUploadValidator.getMimeType('foto.jpeg'), 'image/jpeg');
      expect(FileUploadValidator.getMimeType('foto.png'), 'image/png');
      expect(FileUploadValidator.getMimeType('foto.webp'), 'image/webp');
      expect(FileUploadValidator.getMimeType('foto.heic'), 'image/heic');
    });

    test('getMimeType falls back to octet-stream for unknown extensions', () {
      expect(FileUploadValidator.getMimeType('dokumen.bin'), 'application/octet-stream');
      expect(FileUploadValidator.getMimeType('dokumen.xyz'), 'application/octet-stream');
    });
  });

  group('FileUploadValidator validateFilePath Tests', () {
    test('validateFilePath returns failure when path is null or empty', () {
      final resNull = FileUploadValidator.validateFilePath(null);
      expect(resNull.isValid, isFalse);
      expect(resNull.errorMessage, contains('tidak boleh kosong'));

      final resEmpty = FileUploadValidator.validateFilePath('   ');
      expect(resEmpty.isValid, isFalse);
      expect(resEmpty.errorMessage, contains('tidak boleh kosong'));
    });

    test('validateFilePath returns failure when file has no extension', () {
      final res = FileUploadValidator.validateFilePath('/var/tmp/no_extension_file');
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('tidak memiliki ekstensi'));
    });

    test('validateFilePath returns failure for unsupported file extensions', () {
      final resPdf = FileUploadValidator.validateFilePath('/storage/emulated/0/invoice.pdf');
      expect(resPdf.isValid, isFalse);
      expect(resPdf.errorMessage, contains('tidak didukung'));

      final resMp4 = FileUploadValidator.validateFilePath('/storage/emulated/0/video.mp4');
      expect(resMp4.isValid, isFalse);
      expect(resMp4.errorMessage, contains('tidak didukung'));
    });

    test('validateFilePath returns success with sanitized name and MIME type for valid image paths', () {
      final res = FileUploadValidator.validateFilePath('/cache/struk_belanja_2026.jpg');
      expect(res.isValid, isTrue);
      expect(res.sanitizedFileName, 'struk_belanja_2026.jpg');
      expect(res.mimeType, 'image/jpeg');
    });
  });

  group('FileUploadValidator validateBytes Tests (Memory & Size Bounds)', () {
    test('validateBytes returns failure when buffer is empty', () {
      final res = FileUploadValidator.validateBytes([], 'foto.jpg');
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('kosong'));
    });

    test('validateBytes returns failure for unsupported extension in buffer check', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final res = FileUploadValidator.validateBytes(bytes, 'malicious.bat');
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('tidak didukung'));
    });

    test('validateBytes returns success when bytes are within max limit', () {
      // 100 KB payload
      final bytes = Uint8List(100 * 1024);
      final res = FileUploadValidator.validateBytes(bytes, 'nota_normal.png');
      expect(res.isValid, isTrue);
      expect(res.fileSizeBytes, 100 * 1024);
      expect(res.mimeType, 'image/png');
    });

    test('validateBytes fails when payload exceeds max allowed bytes', () {
      // Set custom max 1 KB, test with 2 KB
      final bytes = Uint8List(2048);
      final res = FileUploadValidator.validateBytes(bytes, 'nota_oversized.jpg', maxBytes: 1024);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('melebihi batas'));
    });

    test('validateBytes respects default 10MB limit', () {
      expect(FileUploadValidator.maxFileSizeBytes, 10 * 1024 * 1024);
      expect(FileUploadValidator.recommendedMaxBytes, 2 * 1024 * 1024);
    });
  });
}

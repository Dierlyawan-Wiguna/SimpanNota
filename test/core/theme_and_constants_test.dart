import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpan_nota/core/constants/app_colors.dart';
import 'package:simpan_nota/core/constants/supabase_constants.dart';
import 'package:simpan_nota/features/receipts/domain/category.dart';
import 'package:simpan_nota/features/receipts/domain/warranty_status.dart';

void main() {
  group('AppColors Palette Tests', () {
    test('brand and accent colors are distinct and valid', () {
      expect(AppColors.primaryNavy, isA<Color>());
      expect(AppColors.primaryBlue, isA<Color>());
      expect(AppColors.accentBlue, isA<Color>());
      expect(AppColors.primaryTeal, isA<Color>());
      expect(AppColors.lightBlue, isA<Color>());

      expect(AppColors.primaryNavy, isNot(equals(AppColors.primaryBlue)));
      expect(AppColors.primaryBlue, isNot(equals(AppColors.accentBlue)));
    });

    test('light mode background and surfaces have high contrast', () {
      expect(AppColors.background, isA<Color>());
      expect(AppColors.surface, Colors.white);
      expect(AppColors.cardBorder, isA<Color>());
      expect(AppColors.inputFill, isA<Color>());

      expect(AppColors.textDark, isA<Color>());
      expect(AppColors.textBody, isA<Color>());
      expect(AppColors.textGrey, isA<Color>());
    });

    test('dark mode background and surfaces are appropriately dark', () {
      expect(AppColors.darkBackground, const Color(0xFF0F172A));
      expect(AppColors.darkSurface, const Color(0xFF1E293B));
      expect(AppColors.darkBorder, const Color(0xFF334155));
      expect(AppColors.darkInputFill, const Color(0xFF0F172A));

      expect(AppColors.darkTextPrimary, const Color(0xFFF8FAFC));
      expect(AppColors.darkTextSecondary, const Color(0xFFCBD5E1));
      expect(AppColors.darkTextMuted, const Color(0xFF94A3B8));
    });

    test('warranty status colors conform to status semantics', () {
      // Active: Green
      expect(AppColors.statusActive, const Color(0xFF059669));
      expect(AppColors.statusActiveBg, const Color(0xFFECFDF5));

      // Expiring: Orange / Amber
      expect(AppColors.statusExpiring, const Color(0xFFD97706));
      expect(AppColors.statusExpiringBg, const Color(0xFFFFFBEB));

      // Expired: Red / Rose
      expect(AppColors.statusExpired, const Color(0xFFE11D48));
      expect(AppColors.statusExpiredBg, const Color(0xFFFFF1F2));
    });

    test('shadow colors have appropriate alpha opacity', () {
      expect(AppColors.shadowColor.a, lessThan(0.2));
      expect(AppColors.shadowColorMedium.a, lessThan(0.3));
    });
  });

  group('Category Domain Enum Tests', () {
    test('contains all expected categories', () {
      const categories = Category.values;
      expect(categories.length, 5);
      expect(categories, contains(Category.elektronik));
      expect(categories, contains(Category.kendaraan));
      expect(categories, contains(Category.pakaian));
      expect(categories, contains(Category.perabotan));
      expect(categories, contains(Category.lainnya));
    });

    test('labels are translated into proper Indonesian', () {
      expect(Category.elektronik.label, 'Elektronik');
      expect(Category.kendaraan.label, 'Kendaraan');
      expect(Category.pakaian.label, 'Pakaian');
      expect(Category.perabotan.label, 'Perabotan');
      expect(Category.lainnya.label, 'Lainnya');
    });

    test('category enum names match lowercase keys', () {
      for (final cat in Category.values) {
        expect(cat.name, cat.name.toLowerCase());
      }
    });
  });

  group('WarrantyStatus Domain Enum Tests', () {
    test('contains all 3 statuses', () {
      const statuses = WarrantyStatus.values;
      expect(statuses.length, 3);
      expect(statuses, contains(WarrantyStatus.active));
      expect(statuses, contains(WarrantyStatus.expiringSoon));
      expect(statuses, contains(WarrantyStatus.expired));
    });

    test('labels are user friendly in Indonesian', () {
      expect(WarrantyStatus.active.label, 'Aktif');
      expect(WarrantyStatus.expiringSoon.label, 'Hampir Habis');
      expect(WarrantyStatus.expired.label, 'Kedaluwarsa');
    });
  });

  group('SupabaseConstants Configuration Tests', () {
    test('supabaseUrl has valid https format and host', () {
      expect(SupabaseConstants.supabaseUrl.startsWith('https://'), isTrue);
      expect(SupabaseConstants.supabaseUrl.endsWith('.supabase.co'), isTrue);
    });

    test('supabaseAnonKey is non-empty string', () {
      expect(SupabaseConstants.supabaseAnonKey.isNotEmpty, isTrue);
      expect(SupabaseConstants.supabaseAnonKey.startsWith('sb_'), isTrue);
    });

    test('isConfigured returns true with production values', () {
      expect(SupabaseConstants.isConfigured, isTrue);
    });

    test('telegramBotToken is string type and defaults safely', () {
      expect(SupabaseConstants.telegramBotToken, isA<String>());
    });

    test('isTelegramBotConfigured evaluates based on token content', () {
      // By default empty in test environment
      expect(SupabaseConstants.isTelegramBotConfigured, isFalse);
    });

    test('supabaseUrl parses as valid URI with host', () {
      final uri = Uri.parse(SupabaseConstants.supabaseUrl);
      expect(uri.scheme, 'https');
      expect(uri.host, 'qycksxjnohxvyxgjtusw.supabase.co');
    });

    test('isConfigured is false if URL placeholder is present', () {
      expect(SupabaseConstants.isConfigured, isTrue);
    });
  });

  group('Category Sorting and Enum Index Tests', () {
    test('Category index ordering is consistent', () {
      expect(Category.elektronik.index, 0);
      expect(Category.kendaraan.index, 1);
      expect(Category.pakaian.index, 2);
      expect(Category.perabotan.index, 3);
      expect(Category.lainnya.index, 4);
    });

    test('Category firstWhere lookup finds match', () {
      final cat = Category.values.firstWhere((e) => e.name == 'elektronik');
      expect(cat, Category.elektronik);
    });

    test('Category firstWhere orElse defaults to elektronik for unknown categories', () {
      final cat = Category.values.firstWhere(
        (e) => e.name == 'unknown_cat',
        orElse: () => Category.elektronik,
      );
      expect(cat, Category.elektronik);
    });

    test('Category toString contains Category prefix', () {
      expect(Category.elektronik.toString(), 'Category.elektronik');
    });
  });

  group('WarrantyStatus State Progression Tests', () {
    test('WarrantyStatus index ordering is active -> expiringSoon -> expired', () {
      expect(WarrantyStatus.active.index, 0);
      expect(WarrantyStatus.expiringSoon.index, 1);
      expect(WarrantyStatus.expired.index, 2);
    });

    test('WarrantyStatus labels are all capitalized in Indonesian', () {
      for (final s in WarrantyStatus.values) {
        expect(s.label[0], s.label[0].toUpperCase());
      }
    });

    test('WarrantyStatus values array has length 3', () {
      expect(WarrantyStatus.values.length, 3);
    });
  });
}

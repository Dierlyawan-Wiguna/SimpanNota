import 'package:flutter_test/flutter_test.dart';
import 'package:simpan_nota/features/receipts/domain/category.dart';
import 'package:simpan_nota/features/receipts/domain/receipt.dart';
import 'package:simpan_nota/features/receipts/domain/warranty_status.dart';

void main() {
  group('Receipt Warranty Expiration & Timezone Normalization Tests (Issue 4)', () {
    test('normalizeDate removes hour, minute, second, and millisecond components', () {
      final dateWithTime = DateTime(2026, 11, 25, 23, 45, 12, 345);
      final normalized = Receipt.normalizeDate(dateWithTime);

      expect(normalized.year, 2026);
      expect(normalized.month, 11);
      expect(normalized.day, 25);
      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
      expect(normalized.second, 0);
      expect(normalized.millisecond, 0);
    });

    test('expirationDate calculates months only correctly', () {
      final receipt = Receipt(
        productName: 'Kulkas LG',
        category: Category.elektronik,
        storeName: 'Electronic City',
        purchaseDate: DateTime(2026, 1, 15, 14, 30),
        warrantyMonths: 12,
        warrantyDays: 0,
        imagePath: '/mock/kulkas.jpg',
      );

      final exp = receipt.expirationDate;
      expect(exp.year, 2027);
      expect(exp.month, 1);
      expect(exp.day, 15);
      expect(exp.hour, 0);
      expect(exp.minute, 0);
    });

    test('expirationDate calculates days only correctly', () {
      final receipt = Receipt(
        productName: 'Earphone TWS',
        category: Category.elektronik,
        storeName: 'Tokopedia',
        purchaseDate: DateTime(2026, 3, 10, 8, 15),
        warrantyMonths: 0,
        warrantyDays: 14,
        imagePath: '/mock/earphone.jpg',
      );

      final exp = receipt.expirationDate;
      expect(exp.year, 2026);
      expect(exp.month, 3);
      expect(exp.day, 24);
    });

    test('expirationDate calculates combination of months and days', () {
      final receipt = Receipt(
        productName: 'Laptop Asus',
        category: Category.elektronik,
        storeName: 'Asus Center',
        purchaseDate: DateTime(2026, 5, 1),
        warrantyMonths: 1,
        warrantyDays: 15,
        imagePath: '/mock/laptop.jpg',
      );

      final exp = receipt.expirationDate;
      expect(exp.year, 2026);
      expect(exp.month, 6);
      expect(exp.day, 16);
    });

    test('expirationDate handles end-of-month leap year boundaries', () {
      final leapYearReceipt = Receipt(
        productName: 'Smartwatch',
        category: Category.elektronik,
        storeName: 'Garmin Store',
        purchaseDate: DateTime(2024, 1, 31),
        warrantyMonths: 1,
        warrantyDays: 0,
        imagePath: '/mock/watch.jpg',
      );

      // Dart DateTime(2024, 1 + 1, 31) -> 2024-03-02
      expect(leapYearReceipt.expirationDate.year, 2024);
      expect(leapYearReceipt.expirationDate.month, 3);
    });

    test('expirationDate with zero months and zero days equals purchase date at midnight', () {
      final receipt = Receipt(
        productName: 'Kabel USB',
        category: Category.lainnya,
        storeName: 'Warung Tech',
        purchaseDate: DateTime(2026, 8, 20, 19, 45),
        warrantyMonths: 0,
        warrantyDays: 0,
        imagePath: '/mock/cable.jpg',
      );

      final exp = receipt.expirationDate;
      expect(exp.year, 2026);
      expect(exp.month, 8);
      expect(exp.day, 20);
      expect(exp.hour, 0);
    });
  });

  group('Receipt Remaining Days Calculation Tests (Midnight & Boundary Precision)', () {
    final baseReceipt = Receipt(
      productName: 'Mesin Cuci',
      category: Category.elektronik,
      storeName: 'Hartono',
      purchaseDate: DateTime(2026, 6, 1),
      warrantyMonths: 6, // Expiration: 2026-12-01
      warrantyDays: 0,
      imagePath: '/mock/mesin.jpg',
    );

    test('remainingDaysAsOf returns positive number when warranty is active', () {
      final refDate = DateTime(2026, 11, 1);
      final days = baseReceipt.remainingDaysAsOf(refDate);
      expect(days, 30);
    });

    test('remainingDaysAsOf returns 0 when reference date is exact expiration day at morning', () {
      final refMorning = DateTime(2026, 12, 1, 6, 30);
      expect(baseReceipt.remainingDaysAsOf(refMorning), 0);
    });

    test('remainingDaysAsOf returns 0 when reference date is exact expiration day at night (23:59:59)', () {
      final refNight = DateTime(2026, 12, 1, 23, 59, 59);
      expect(baseReceipt.remainingDaysAsOf(refNight), 0);
    });

    test('remainingDaysAsOf returns -1 one day after expiration', () {
      final refDayAfter = DateTime(2026, 12, 2, 0, 1);
      expect(baseReceipt.remainingDaysAsOf(refDayAfter), -1);
    });

    test('remainingDaysAsOf is unaffected by timezone hour shifts within the same calendar day', () {
      final dateUtc0 = DateTime(2026, 11, 20, 0, 0);
      final dateUtc7 = DateTime(2026, 11, 20, 17, 0);
      final dateUtc11 = DateTime(2026, 11, 20, 23, 59);

      final days0 = baseReceipt.remainingDaysAsOf(dateUtc0);
      final days7 = baseReceipt.remainingDaysAsOf(dateUtc7);
      final days11 = baseReceipt.remainingDaysAsOf(dateUtc11);

      expect(days0, days7);
      expect(days7, days11);
      expect(days0, 11);
    });

    test('remainingDays matches remainingDaysAsOf(DateTime.now())', () {
      expect(baseReceipt.remainingDays, baseReceipt.remainingDaysAsOf(DateTime.now()));
    });
  });

  group('Receipt WarrantyStatus Boundary Tests (Issue 4 - H-30 & H-0 Transitions)', () {
    final targetReceipt = Receipt(
      productName: 'Monitor 4K',
      category: Category.elektronik,
      storeName: 'Official Store',
      purchaseDate: DateTime(2026, 10, 1),
      warrantyMonths: 1, // Expiration: 2026-11-01
      warrantyDays: 0,
      imagePath: '/mock/monitor.jpg',
    );

    test('statusAsOf returns WarrantyStatus.active when remaining days > 30 (H-31)', () {
      final refDate = DateTime(2026, 10, 1); // 31 days remaining
      expect(targetReceipt.remainingDaysAsOf(refDate), 31);
      expect(targetReceipt.statusAsOf(refDate), WarrantyStatus.active);
    });

    test('statusAsOf returns WarrantyStatus.expiringSoon at exact H-30 boundary', () {
      final refDate = DateTime(2026, 10, 2); // 30 days remaining
      expect(targetReceipt.remainingDaysAsOf(refDate), 30);
      expect(targetReceipt.statusAsOf(refDate), WarrantyStatus.expiringSoon);
    });

    test('statusAsOf returns WarrantyStatus.expiringSoon at H-29', () {
      final refDate = DateTime(2026, 10, 3); // 29 days remaining
      expect(targetReceipt.remainingDaysAsOf(refDate), 29);
      expect(targetReceipt.statusAsOf(refDate), WarrantyStatus.expiringSoon);
    });

    test('statusAsOf returns WarrantyStatus.expiringSoon at H-7', () {
      final refDate = DateTime(2026, 10, 25); // 7 days remaining
      expect(targetReceipt.remainingDaysAsOf(refDate), 7);
      expect(targetReceipt.statusAsOf(refDate), WarrantyStatus.expiringSoon);
    });

    test('statusAsOf returns WarrantyStatus.expiringSoon at H-1', () {
      final refDate = DateTime(2026, 10, 31); // 1 day remaining
      expect(targetReceipt.remainingDaysAsOf(refDate), 1);
      expect(targetReceipt.statusAsOf(refDate), WarrantyStatus.expiringSoon);
    });

    test('statusAsOf returns WarrantyStatus.expiringSoon at H-0 (expiration day)', () {
      final refDate = DateTime(2026, 11, 1); // 0 days remaining
      expect(targetReceipt.remainingDaysAsOf(refDate), 0);
      expect(targetReceipt.statusAsOf(refDate), WarrantyStatus.expiringSoon);
    });

    test('statusAsOf returns WarrantyStatus.expired at H+1 (-1 day)', () {
      final refDate = DateTime(2026, 11, 2); // -1 days remaining
      expect(targetReceipt.remainingDaysAsOf(refDate), -1);
      expect(targetReceipt.statusAsOf(refDate), WarrantyStatus.expired);
    });

    test('statusAsOf returns WarrantyStatus.expired long after expiration (-100 days)', () {
      final refDate = DateTime(2027, 2, 9);
      expect(targetReceipt.remainingDaysAsOf(refDate), -100);
      expect(targetReceipt.statusAsOf(refDate), WarrantyStatus.expired);
    });

    test('status getter matches statusAsOf(DateTime.now())', () {
      expect(targetReceipt.status, targetReceipt.statusAsOf(DateTime.now()));
    });
  });

  group('Receipt WarrantyDurationLabel Tests', () {
    test('returns Bulan and Hari when both > 0', () {
      final r = Receipt(
        productName: 'A',
        category: Category.elektronik,
        storeName: 'B',
        purchaseDate: DateTime(2026, 1, 1),
        warrantyMonths: 3,
        warrantyDays: 10,
        imagePath: '/mock/a.jpg',
      );
      expect(r.warrantyDurationLabel, '3 Bulan 10 Hari');
    });

    test('returns Bulan only when warrantyDays is 0', () {
      final r = Receipt(
        productName: 'A',
        category: Category.elektronik,
        storeName: 'B',
        purchaseDate: DateTime(2026, 1, 1),
        warrantyMonths: 12,
        warrantyDays: 0,
        imagePath: '/mock/a.jpg',
      );
      expect(r.warrantyDurationLabel, '12 Bulan');
    });

    test('returns Hari only when warrantyMonths is 0', () {
      final r = Receipt(
        productName: 'A',
        category: Category.elektronik,
        storeName: 'B',
        purchaseDate: DateTime(2026, 1, 1),
        warrantyMonths: 0,
        warrantyDays: 45,
        imagePath: '/mock/a.jpg',
      );
      expect(r.warrantyDurationLabel, '45 Hari');
    });

    test('returns 0 Hari when both are 0', () {
      final r = Receipt(
        productName: 'A',
        category: Category.elektronik,
        storeName: 'B',
        purchaseDate: DateTime(2026, 1, 1),
        warrantyMonths: 0,
        warrantyDays: 0,
        imagePath: '/mock/a.jpg',
      );
      expect(r.warrantyDurationLabel, '0 Hari');
    });
  });

  group('Receipt Serialization & Immutability Tests', () {
    final testReceipt = Receipt(
      id: 99,
      productName: 'iPad Air M2',
      category: Category.elektronik,
      storeName: 'iBox Central Park',
      purchaseDate: DateTime(2026, 7, 10, 11, 20),
      warrantyMonths: 24,
      warrantyDays: 5,
      imagePath: '/storage/ipad.png',
      warrantyCardPath: '/storage/warranty_card.jpg',
    );

    test('toMap converts all attributes accurately', () {
      final map = testReceipt.toMap();

      expect(map['id'], 99);
      expect(map['productName'], 'iPad Air M2');
      expect(map['category'], 'elektronik');
      expect(map['storeName'], 'iBox Central Park');
      expect(map['warrantyMonths'], 24);
      expect(map['warrantyDays'], 5);
      expect(map['imagePath'], '/storage/ipad.png');
      expect(map['warrantyCardPath'], '/storage/warranty_card.jpg');
    });

    test('fromMap restores Receipt object completely', () {
      final map = testReceipt.toMap();
      final restored = Receipt.fromMap(map);

      expect(restored.id, testReceipt.id);
      expect(restored.productName, testReceipt.productName);
      expect(restored.category, testReceipt.category);
      expect(restored.storeName, testReceipt.storeName);
      expect(restored.warrantyMonths, testReceipt.warrantyMonths);
      expect(restored.warrantyDays, testReceipt.warrantyDays);
      expect(restored.imagePath, testReceipt.imagePath);
      expect(restored.warrantyCardPath, testReceipt.warrantyCardPath);
    });

    test('toJson formats correctly for external API integration', () {
      final json = testReceipt.toJson();

      expect(json['id'], 99);
      expect(json['title'], 'iPad Air M2');
      expect(json['body'], 'iBox Central Park');
      expect(json['userId'], 1);
    });

    test('toSupabaseMap formats keys with snake_case and date string', () {
      final supaMap = testReceipt.toSupabaseMap();

      expect(supaMap['id'], 99);
      expect(supaMap['product_name'], 'iPad Air M2');
      expect(supaMap['category'], 'elektronik');
      expect(supaMap['store_name'], 'iBox Central Park');
      expect(supaMap['purchase_date'], '2026-07-10');
      expect(supaMap['warranty_months'], 24);
      expect(supaMap['warranty_days'], 5);
      expect(supaMap['image_path'], '/storage/ipad.png');
      expect(supaMap['warranty_card_path'], '/storage/warranty_card.jpg');
    });

    test('fromJson handles snake_case and title/body fallbacks', () {
      final apiJson = {
        'id': '101',
        'product_name': 'Kamera Sony A7 IV',
        'category': 'elektronik',
        'store_name': 'Focus Nusantara',
        'purchase_date': '2026-04-12T00:00:00.000',
        'warranty_months': '12',
        'warranty_days': '0',
        'image_path': '/img/camera.jpg',
      };

      final parsed = Receipt.fromJson(apiJson);

      expect(parsed.id, 101);
      expect(parsed.productName, 'Kamera Sony A7 IV');
      expect(parsed.category, Category.elektronik);
      expect(parsed.storeName, 'Focus Nusantara');
      expect(parsed.warrantyMonths, 12);
      expect(parsed.warrantyDays, 0);
    });

    test('copyWith produces modified copy while keeping unmodified fields', () {
      final updated = testReceipt.copyWith(
        productName: 'iPad Pro M4',
        warrantyMonths: 36,
      );

      expect(updated.id, testReceipt.id);
      expect(updated.productName, 'iPad Pro M4');
      expect(updated.warrantyMonths, 36);
      expect(updated.warrantyDays, testReceipt.warrantyDays);
      expect(updated.storeName, testReceipt.storeName);
      expect(updated.category, testReceipt.category);
    });

    test('10 year warranty calculation handles 120 months accurately', () {
      final longWarranty = Receipt(
        productName: 'Solar Panel System',
        category: Category.lainnya,
        storeName: 'Solar ID',
        purchaseDate: DateTime(2025, 1, 1),
        warrantyMonths: 120,
        warrantyDays: 0,
        imagePath: '/mock/solar.jpg',
      );

      expect(longWarranty.expirationDate.year, 2035);
      expect(longWarranty.expirationDate.month, 1);
      expect(longWarranty.expirationDate.day, 1);
      expect(longWarranty.warrantyDurationLabel, '120 Bulan');
    });

    test('3-year leap year period calculation (2024 leap year)', () {
      final leapReceipt = Receipt(
        productName: 'MacBook Air',
        category: Category.elektronik,
        storeName: 'Apple Store',
        purchaseDate: DateTime(2024, 2, 29),
        warrantyMonths: 24,
        warrantyDays: 0,
        imagePath: '/mock/mac.jpg',
      );

      expect(leapReceipt.expirationDate.year, 2026);
      expect(leapReceipt.expirationDate.month, 3);
    });

    test('December to February year rollover calculation', () {
      final rolloverReceipt = Receipt(
        productName: 'Speaker Bluetooth',
        category: Category.elektronik,
        storeName: 'JBL Store',
        purchaseDate: DateTime(2026, 12, 15),
        warrantyMonths: 3,
        warrantyDays: 0,
        imagePath: '/mock/jbl.jpg',
      );

      expect(rolloverReceipt.expirationDate.year, 2027);
      expect(rolloverReceipt.expirationDate.month, 3);
      expect(rolloverReceipt.expirationDate.day, 15);
    });

    test('statusAsOf exactly at H-7 reminder boundary triggers expiringSoon', () {
      final r = Receipt(
        productName: 'PS5 Pro',
        category: Category.elektronik,
        storeName: 'Sony Center',
        purchaseDate: DateTime(2026, 1, 1),
        warrantyMonths: 1, // Exp: 2026-02-01
        warrantyDays: 0,
        imagePath: '/mock/ps5.jpg',
      );

      final hMinus7Date = DateTime(2026, 1, 25);
      expect(r.remainingDaysAsOf(hMinus7Date), 7);
      expect(r.statusAsOf(hMinus7Date), WarrantyStatus.expiringSoon);
    });

    test('statusAsOf exactly at H-14 boundary triggers expiringSoon', () {
      final r = Receipt(
        productName: 'PS5 Pro',
        category: Category.elektronik,
        storeName: 'Sony Center',
        purchaseDate: DateTime(2026, 1, 1),
        warrantyMonths: 1,
        warrantyDays: 0,
        imagePath: '/mock/ps5.jpg',
      );

      final hMinus14Date = DateTime(2026, 1, 18);
      expect(r.remainingDaysAsOf(hMinus14Date), 14);
      expect(r.statusAsOf(hMinus14Date), WarrantyStatus.expiringSoon);
    });

    test('statusAsOf at H-60 triggers active status', () {
      final r = Receipt(
        productName: 'PS5 Pro',
        category: Category.elektronik,
        storeName: 'Sony Center',
        purchaseDate: DateTime(2026, 1, 1),
        warrantyMonths: 3, // Exp: 2026-04-01
        warrantyDays: 0,
        imagePath: '/mock/ps5.jpg',
      );

      final hMinus60Date = DateTime(2026, 1, 31);
      expect(r.remainingDaysAsOf(hMinus60Date), 60);
      expect(r.statusAsOf(hMinus60Date), WarrantyStatus.active);
    });

    test('statusAsOf at H+30 triggers expired status', () {
      final r = Receipt(
        productName: 'PS5 Pro',
        category: Category.elektronik,
        storeName: 'Sony Center',
        purchaseDate: DateTime(2026, 1, 1),
        warrantyMonths: 1, // Exp: 2026-02-01
        warrantyDays: 0,
        imagePath: '/mock/ps5.jpg',
      );

      final hPlus30Date = DateTime(2026, 3, 3);
      expect(r.remainingDaysAsOf(hPlus30Date), -30);
      expect(r.statusAsOf(hPlus30Date), WarrantyStatus.expired);
    });
  });
}
